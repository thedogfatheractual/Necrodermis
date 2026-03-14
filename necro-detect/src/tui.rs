use std::fs;
use std::io;
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::prelude::*;
use ratatui::widgets::Paragraph;

use crate::pkg::{InstallResult, PackageManager, build_pkg_map, do_install, resolve_pkg};

// ── Sysinfo ───────────────────────────────────────────────────────────────────

#[derive(Clone, Default)]
pub struct SysStats {
    pub cpu_pct:      u8,
    pub ram_used_gb:  f32,
    pub ram_total_gb: f32,
    pub disk_pct:     u8,
}

fn read_proc_stat() -> Option<(u64, u64)> {
    let content = fs::read_to_string("/proc/stat").ok()?;
    let line    = content.lines().next()?;
    let nums: Vec<u64> = line.split_whitespace()
        .skip(1).take(10)
        .filter_map(|s| s.parse().ok())
        .collect();
    if nums.len() < 4 { return None; }
    let idle  = nums[3] + nums.get(4).copied().unwrap_or(0);
    let total: u64 = nums.iter().sum();
    Some((idle, total))
}

fn spawn_sysinfo(stats: Arc<Mutex<SysStats>>) {
    thread::spawn(move || {
        let mut prev = read_proc_stat().unwrap_or((0, 1));
        loop {
            thread::sleep(Duration::from_secs(1));
            let cpu = if let Some(curr) = read_proc_stat() {
                let td = curr.1.saturating_sub(prev.1);
                let id = curr.0.saturating_sub(prev.0);
                prev = curr;
                if td > 0 { ((td - id) * 100 / td) as u8 } else { 0 }
            } else { 0 };

            let (mut ram_total, mut ram_avail) = (0f32, 0f32);
            if let Ok(m) = fs::read_to_string("/proc/meminfo") {
                for line in m.lines() {
                    let mut it = line.split_whitespace();
                    match it.next() {
                        Some("MemTotal:")     => { ram_total = it.next().and_then(|s| s.parse().ok()).unwrap_or(0.0) / 1_048_576.0; }
                        Some("MemAvailable:") => { ram_avail = it.next().and_then(|s| s.parse().ok()).unwrap_or(0.0) / 1_048_576.0; }
                        _ => {}
                    }
                }
            }

            let disk_pct = Command::new("df")
                .args(["--output=pcent", "/"])
                .output()
                .ok()
                .and_then(|o| String::from_utf8(o.stdout).ok())
                .and_then(|s| s.lines().nth(1)
                    .and_then(|l| l.trim().trim_end_matches('%').parse::<u8>().ok()))
                .unwrap_or(0);

            if let Ok(mut s) = stats.lock() {
                s.cpu_pct      = cpu;
                s.ram_used_gb  = ram_total - ram_avail;
                s.ram_total_gb = ram_total;
                s.disk_pct     = disk_pct;
            }
        }
    });
}

// ── Package manifest ──────────────────────────────────────────────────────────

pub struct PkgCat  { pub label: &'static str, pub pkgs: &'static [PkgDef] }
pub struct PkgDef  { pub id: &'static str, pub necron: &'static str, pub desc: &'static str }

const MANIFEST: &[PkgCat] = &[
    PkgCat { label: "CORE", pkgs: &[
        PkgDef { id: "hyprland", necron: "CANOPTEK SHELL",  desc: "Hyprland compositor"    },
        PkgDef { id: "hyprlock", necron: "STASIS LOCK",     desc: "Hyprlock screen locker" },
        PkgDef { id: "waybar",   necron: "SIGNAL ARRAY",    desc: "Waybar status bar"      },
        PkgDef { id: "rofi",     necron: "TOMB INTERFACE",  desc: "Rofi launcher"          },
        PkgDef { id: "kitty",    necron: "CORTEX NODE",     desc: "Kitty terminal"         },
        PkgDef { id: "fish",     necron: "COMMAND DIALECT", desc: "Fish shell"             },
        PkgDef { id: "swaync",   necron: "CANOPTEK ALERTS", desc: "SwayNC notifications"   },
    ]},
    PkgCat { label: "VISUAL", pkgs: &[
        PkgDef { id: "gtk",    necron: "DERMAL SKIN",    desc: "GTK / Qt / Kvantum"   },
        PkgDef { id: "walls",  necron: "TOMB MURALS",    desc: "Necron wallpapers"     },
        PkgDef { id: "btop",   necron: "PROCESS CRYPT",  desc: "btop monitor"          },
        PkgDef { id: "sddm",   necron: "AWAKENING GATE", desc: "SDDM login screen"     },
        PkgDef { id: "grub",   necron: "BOOT SEQUENCE",  desc: "GRUB theme"            },
    ]},
    PkgCat { label: "HARDENING", pkgs: &[
        PkgDef { id: "ufw",    necron: "PERIMETER WARD", desc: "ufw firewall"          },
        PkgDef { id: "kernel", necron: "CORTEX LOCK",    desc: "Kernel hardening"      },
    ]},
    PkgCat { label: "EXTRAS", pkgs: &[
        PkgDef { id: "sitrep",  necron: "ATMOSPHERIC DATA", desc: "Sitrep / METAR weather" },
        PkgDef { id: "brave",   necron: "COMMS RELAY",      desc: "Brave browser"           },
        PkgDef { id: "vesktop", necron: "DYNASTY COMMS",    desc: "Vesktop / Discord"       },
    ]},
];

fn all_pkg_defs() -> Vec<&'static PkgDef> {
    MANIFEST.iter().flat_map(|c| c.pkgs.iter()).collect()
}

// ── Types ─────────────────────────────────────────────────────────────────────

#[derive(Clone, Copy, PartialEq)]
pub enum Screen { Splash, ModeSelect, Picker, Confirm, Installing, Codex, ErrorLog }

#[derive(Clone, Copy, PartialEq)]
pub enum Mode { Dots, Full }

#[derive(Clone, PartialEq)]
pub enum PkgStatus { Pending, Active, Ok, Skipped, Failed }

pub struct PkgEntry {
    pub id: String, pub necron: String, pub desc: String,
    pub selected: bool, pub status: PkgStatus,
}

pub enum InstallMsg {
    Starting(String),
    Result(String, InstallResult),
    Done,
}

// ── App ───────────────────────────────────────────────────────────────────────

pub struct App {
    pub screen:      Screen,
    pub distro:      String,
    pub family:      String,
    pub mode:        Mode,
    pub mode_cursor: usize,
    pub packages:    Vec<PkgEntry>,
    pub pkg_cursor:  usize,
    pub log_lines:   Vec<(String, Color)>,
    pub fail_log:    Vec<(String, String)>,
    pub done_count:  usize,
    pub total_count: usize,
    pub ok_count:    usize,
    pub skip_count:  usize,
    pub fail_count:  usize,
    pub install_rx:  Option<std::sync::mpsc::Receiver<InstallMsg>>,
    pub start_time:  Option<Instant>,
    pub launch_time: Instant,
    pub tick:        u64,
    pub quit:        bool,
    pub stats:       Arc<Mutex<SysStats>>,
}

impl App {
    pub fn new(distro: String, family: String) -> Self {
        let packages = all_pkg_defs().into_iter().map(|d| PkgEntry {
            id: d.id.to_string(), necron: d.necron.to_string(), desc: d.desc.to_string(),
            selected: true, status: PkgStatus::Pending,
        }).collect();
        let stats = Arc::new(Mutex::new(SysStats::default()));
        spawn_sysinfo(Arc::clone(&stats));
        App {
            screen: Screen::Splash, distro, family,
            mode: Mode::Dots, mode_cursor: 0,
            packages, pkg_cursor: 0,
            log_lines: Vec::new(), fail_log: Vec::new(),
            done_count: 0, total_count: 0,
            ok_count: 0, skip_count: 0, fail_count: 0,
            install_rx: None, start_time: None,
            launch_time: Instant::now(), tick: 0, quit: false, stats,
        }
    }

    fn reset_install(&mut self) {
        self.log_lines.clear(); self.fail_log.clear();
        self.done_count = 0; self.total_count = 0;
        self.ok_count = 0; self.skip_count = 0; self.fail_count = 0;
        self.start_time = None;
        for p in &mut self.packages { p.status = PkgStatus::Pending; }
    }

    fn elapsed_secs(&self) -> u64 { self.start_time.map(|t| t.elapsed().as_secs()).unwrap_or(0) }
    fn install_pct(&self) -> u16 {
        if self.total_count == 0 { return 0; }
        ((self.done_count as f64 / self.total_count as f64) * 100.0) as u16
    }
    fn sys(&self) -> SysStats { self.stats.lock().ok().map(|s| s.clone()).unwrap_or_default() }
    fn step_idx(&self) -> usize {
        match self.screen {
            Screen::Splash => 0, Screen::ModeSelect => 1, Screen::Picker => 2,
            Screen::Confirm => 3, Screen::Installing => 4,
            Screen::Codex | Screen::ErrorLog => 5,
        }
    }
}

// ── Main loop ─────────────────────────────────────────────────────────────────

pub fn run_app<B: Backend>(terminal: &mut Terminal<B>, app: &mut App) -> io::Result<()>
where io::Error: From<B::Error> {
    loop {
        if app.screen == Screen::Installing { poll_install(app); }
        terminal.draw(|f| draw(f, app))?;
        app.tick = app.tick.wrapping_add(1);
        if event::poll(Duration::from_millis(50))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press { handle_key(app, key.code); }
            }
        }
        if app.quit { break; }
    }
    Ok(())
}

// ── Input ─────────────────────────────────────────────────────────────────────

fn handle_key(app: &mut App, key: KeyCode) {
    let n = app.packages.len();
    match app.screen {
        Screen::Splash => match key {
            KeyCode::Enter                     => app.screen = Screen::ModeSelect,
            KeyCode::Char('q') | KeyCode::Esc => app.quit = true,
            _ => {}
        },
        Screen::ModeSelect => match key {
            KeyCode::Up   | KeyCode::Char('k') => { if app.mode_cursor > 0 { app.mode_cursor -= 1; } }
            KeyCode::Down | KeyCode::Char('j') => { if app.mode_cursor < 1 { app.mode_cursor += 1; } }
            KeyCode::Enter => {
                app.mode = if app.mode_cursor == 0 { Mode::Dots } else { Mode::Full };
                app.screen = Screen::Picker;
            }
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::Splash,
            _ => {}
        },
        Screen::Picker => match key {
            KeyCode::Up   | KeyCode::Char('k') => { if app.pkg_cursor > 0 { app.pkg_cursor -= 1; } }
            KeyCode::Down | KeyCode::Char('j') => { if app.pkg_cursor < n - 1 { app.pkg_cursor += 1; } }
            KeyCode::Char(' ') => { app.packages[app.pkg_cursor].selected ^= true; }
            KeyCode::Char('a') => {
                let all = app.packages.iter().all(|p| p.selected);
                for p in &mut app.packages { p.selected = !all; }
            }
            KeyCode::Enter => { if app.packages.iter().any(|p| p.selected) { app.screen = Screen::Confirm; } }
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::ModeSelect,
            _ => {}
        },
        Screen::Confirm => match key {
            KeyCode::Enter                     => start_install(app),
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::Picker,
            _ => {}
        },
        Screen::Installing => {}
        Screen::Codex => match key {
            KeyCode::Char('e') | KeyCode::Char('E') => { if !app.fail_log.is_empty() { app.screen = Screen::ErrorLog; } }
            KeyCode::Char('q') | KeyCode::Enter | KeyCode::Esc => app.quit = true,
            _ => {}
        },
        Screen::ErrorLog => match key {
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::Codex,
            _ => {}
        },
    }
}

// ── Install thread ────────────────────────────────────────────────────────────

fn start_install(app: &mut App) {
    app.reset_install();
    let selected: Vec<String> = app.packages.iter().filter(|p| p.selected).map(|p| p.id.clone()).collect();
    app.total_count = selected.len();
    app.start_time  = Some(Instant::now());
    app.screen      = Screen::Installing;
    let distro = app.distro.clone();
    let family = app.family.clone();
    let (tx, rx) = std::sync::mpsc::channel::<InstallMsg>();
    app.install_rx = Some(rx);
    thread::spawn(move || {
        let pkg_mgr = match family.as_str() {
            "fedora" => PackageManager::Dnf, "opensuse" => PackageManager::Zypper,
            "void"   => PackageManager::Xbps, _         => PackageManager::Pacman,
        };
        let map = build_pkg_map();
        for id in &selected {
            let _ = tx.send(InstallMsg::Starting(id.clone()));
            let resolved = resolve_pkg(&map, &distro, id);
            if let Some((_, result)) = do_install(&pkg_mgr, &[resolved.as_str()]).into_iter().next() {
                let _ = tx.send(InstallMsg::Result(id.clone(), result));
            }
        }
        let _ = tx.send(InstallMsg::Done);
    });
}

fn poll_install(app: &mut App) {
    loop {
        let msg = match app.install_rx.as_ref() {
            Some(rx) => match rx.try_recv() {
                Ok(m) => m,
                Err(std::sync::mpsc::TryRecvError::Empty) => break,
                Err(std::sync::mpsc::TryRecvError::Disconnected) => {
                    app.install_rx = None; app.screen = Screen::Codex; break;
                }
            },
            None => break,
        };
        match msg {
            InstallMsg::Starting(id) => {
                for p in &mut app.packages { if p.id == id { p.status = PkgStatus::Active; } }
                let necron = app.packages.iter().find(|p| p.id == id).map(|p| p.necron.clone()).unwrap_or(id.clone());
                app.log_lines.push((format!("  installing {}...", necron), Color::Rgb(85, 85, 85)));
            }
            InstallMsg::Result(id, result) => {
                app.done_count += 1;
                let necron = app.packages.iter().find(|p| p.id == id).map(|p| p.necron.clone()).unwrap_or(id.clone());
                let (status, color, label) = match &result {
                    InstallResult::Ok         => (PkgStatus::Ok,      Color::Rgb(0, 170, 0), "[ OK  ]"),
                    InstallResult::Skipped(_) => (PkgStatus::Skipped, Color::Rgb(136,102, 0), "[SKIP ]"),
                    InstallResult::Failed(_)  => (PkgStatus::Failed,  Color::Rgb(136,  0, 0), "[FAIL ]"),
                };
                match &result {
                    InstallResult::Ok         => app.ok_count   += 1,
                    InstallResult::Skipped(_) => app.skip_count += 1,
                    InstallResult::Failed(m)  => { app.fail_count += 1; app.fail_log.push((necron.clone(), m.clone())); }
                }
                for p in &mut app.packages { if p.id == id { p.status = status.clone(); } }
                let suffix = match &result {
                    InstallResult::Failed(m) | InstallResult::Skipped(m) => format!("  — {}", m),
                    InstallResult::Ok => String::new(),
                };
                app.log_lines.push((format!("  {}  {}{}", label, necron, suffix), color));
                if app.log_lines.len() > 300 { app.log_lines.drain(..50); }
            }
            InstallMsg::Done => { app.install_rx = None; app.screen = Screen::Codex; break; }
        }
    }
}

// ── Style helpers ─────────────────────────────────────────────────────────────

fn hi()   -> Style { Style::default().fg(Color::Rgb(0, 204, 0)).add_modifier(Modifier::BOLD) }
fn g()    -> Style { Style::default().fg(Color::Rgb(0, 170, 0)) }
fn dim()  -> Style { Style::default().fg(Color::Rgb(26, 74, 26)) }
fn wh()   -> Style { Style::default().fg(Color::Rgb(136, 136, 136)) }
fn wh2()  -> Style { Style::default().fg(Color::Rgb(85, 85, 85)) }
fn amb()  -> Style { Style::default().fg(Color::Rgb(136, 102, 0)) }
fn red()  -> Style { Style::default().fg(Color::Rgb(136, 0, 0)) }
fn teal() -> Style { Style::default().fg(Color::Rgb(0, 119, 102)) }
fn blk()  -> Style { Style::default().bg(Color::Black) }

fn sep_line(width: u16) -> Line<'static> {
    Line::from(Span::styled("─".repeat(width as usize), Style::default().fg(Color::Rgb(26, 60, 26))))
}

fn bar_color(pct: u8) -> Color {
    if pct >= 85 { Color::Rgb(136, 0, 0) } else if pct >= 65 { Color::Rgb(136, 102, 0) } else { Color::Rgb(0, 136, 0) }
}

// ── Layout ────────────────────────────────────────────────────────────────────

struct Shell { topbar: Rect, left: Rect, centre: Rect, right: Rect, resbar: Rect }

fn shell_layout(area: Rect) -> Shell {
    let w  = area.width;
    let lw = (w as f32 * 0.21) as u16;
    let rw = lw;
    let cw = w.saturating_sub(lw + rw + 2);
    Shell {
        topbar: Rect { x: area.x, y: area.y,         width: w,  height: 1 },
        left:   Rect { x: area.x,             y: area.y + 1, width: lw, height: area.height.saturating_sub(2) },
        centre: Rect { x: area.x + lw + 1,    y: area.y + 1, width: cw, height: area.height.saturating_sub(2) },
        right:  Rect { x: area.x + lw + cw + 2, y: area.y + 1, width: rw, height: area.height.saturating_sub(2) },
        resbar: Rect { x: area.x, y: area.y + area.height.saturating_sub(1), width: w, height: 1 },
    }
}

// ── Draw root ─────────────────────────────────────────────────────────────────

fn draw(f: &mut Frame, app: &mut App) {
    f.render_widget(Paragraph::new("").style(blk()), f.area());
    let sh = shell_layout(f.area());
    draw_topbar(f, sh.topbar, app);
    draw_dividers(f, &sh);
    draw_resbar(f, sh.resbar, app);

    if matches!(app.screen, Screen::Installing | Screen::Codex | Screen::ErrorLog) {
        draw_left_manifest(f, sh.left, app);
    } else {
        draw_left_steps(f, sh.left, app);
    }

    match app.screen {
        Screen::Splash     => draw_right_splash(f, sh.right),
        Screen::ModeSelect => draw_right_mode(f, sh.right, app),
        Screen::Picker     => draw_right_picker(f, sh.right, app),
        Screen::Confirm    => draw_right_confirm(f, sh.right, app),
        Screen::Installing => draw_right_stages(f, sh.right, app),
        Screen::Codex | Screen::ErrorLog => draw_right_nextsteps(f, sh.right),
    }

    match app.screen {
        Screen::Splash     => draw_centre_splash(f, sh.centre, app),
        Screen::ModeSelect => draw_centre_mode(f, sh.centre, app),
        Screen::Picker     => draw_centre_picker(f, sh.centre, app),
        Screen::Confirm    => draw_centre_confirm(f, sh.centre, app),
        Screen::Installing => draw_centre_install(f, sh.centre, app),
        Screen::Codex      => draw_centre_codex(f, sh.centre, app),
        Screen::ErrorLog   => draw_centre_errorlog(f, sh.centre, app),
    }
}

fn draw_topbar(f: &mut Frame, area: Rect, app: &App) {
    let elapsed = app.launch_time.elapsed().as_secs();
    let clk   = format!("{:02}:{:02}:{:02}", elapsed / 3600, (elapsed % 3600) / 60, elapsed % 60);
    let right = format!("{}  |  {}  |  {}", app.distro, app.family, clk);
    let left  = "NECRODERMIS v1.3.72  //  AWAKENING SEQUENCE";
    let pad   = (area.width as usize).saturating_sub(left.len() + right.len());
    f.render_widget(
        Paragraph::new(format!("{}{}{}", left, " ".repeat(pad), right))
            .style(Style::default().fg(Color::Rgb(26, 100, 26)).bg(Color::Black)),
        area,
    );
}

fn draw_dividers(f: &mut Frame, sh: &Shell) {
    let style = Style::default().fg(Color::Rgb(26, 60, 26)).bg(Color::Black);
    for row in 0..sh.left.height {
        f.render_widget(Paragraph::new("│").style(style),
            Rect { x: sh.left.x + sh.left.width, y: sh.left.y + row, width: 1, height: 1 });
        f.render_widget(Paragraph::new("│").style(style),
            Rect { x: sh.centre.x + sh.centre.width, y: sh.centre.y + row, width: 1, height: 1 });
    }
}

fn draw_resbar(f: &mut Frame, area: Rect, app: &App) {
    let sys       = app.sys();
    let elapsed   = app.elapsed_secs();
    let ram_total = if sys.ram_total_gb > 0.0 { sys.ram_total_gb } else { 1.0 };
    let bar_w: usize = 20;

    let cpu_f  = (sys.cpu_pct as usize * bar_w / 100).min(bar_w);
    let ram_f  = ((sys.ram_used_gb / ram_total * bar_w as f32) as usize).min(bar_w);
    let disk_f = (sys.disk_pct as usize * bar_w / 100).min(bar_w);

    let spans = vec![
        Span::styled(" CPU [", wh2()),
        Span::styled("█".repeat(cpu_f),  Style::default().fg(bar_color(sys.cpu_pct))),
        Span::styled("░".repeat(bar_w - cpu_f), dim()),
        Span::styled(format!("] {:3}%  ", sys.cpu_pct), wh2()),

        Span::styled("RAM [", wh2()),
        Span::styled("█".repeat(ram_f),  Style::default().fg(bar_color((sys.ram_used_gb / ram_total * 100.0) as u8))),
        Span::styled("░".repeat(bar_w - ram_f), dim()),
        Span::styled(format!("] {:.1}/{:.0}GB  ", sys.ram_used_gb, ram_total), wh2()),

        Span::styled("DSK [", wh2()),
        Span::styled("█".repeat(disk_f), Style::default().fg(bar_color(sys.disk_pct))),
        Span::styled("░".repeat(bar_w - disk_f), dim()),
        Span::styled(format!("] {:3}%  ", sys.disk_pct), wh2()),

        Span::styled(match app.screen {
            Screen::Picker     => format!("  ↑↓ nav  SPC toggle  A all  ENT confirm  Q back  {:02}:{:02}", elapsed/60, elapsed%60),
            Screen::Installing => format!("  elapsed {:02}:{:02}", elapsed/60, elapsed%60),
            _                  => format!("  ENT confirm  Q back  {:02}:{:02}", elapsed/60, elapsed%60),
        }, dim()),
    ];

    f.render_widget(Paragraph::new(Line::from(spans)).style(blk()), area);
}

// ── Left — steps (pre-install) ────────────────────────────────────────────────

const STEPS: &[&str] = &[
    "TOMB WELCOME",
    "SELECT PROTOCOL",
    "DESIGNATE LAYERS",
    "CONFIRM MANIFEST",
    "AWAKENING SEQUENCE",
    "SEQUENCE COMPLETE",
];

fn draw_left_steps(f: &mut Frame, area: Rect, app: &App) {
    let step = app.step_idx();
    let mut lines = vec![
        Line::from(Span::styled("INSTALLATION STEPS", wh())),
        sep_line(area.width),
    ];
    for (i, s) in STEPS.iter().enumerate() {
        let (arrow, sty) = if i == step { ("► ", hi()) } else if i < step { ("✓ ", g()) } else { ("  ", dim()) };
        lines.push(Line::from(vec![Span::styled(arrow, sty), Span::styled(*s, sty)]));
        lines.push(Line::from(""));
    }
    lines.push(sep_line(area.width));
    lines.push(Line::from(Span::styled("github.com/", dim())));
    lines.push(Line::from(Span::styled("thedogfatheractual", dim())));
    lines.push(Line::from(Span::styled("/Necrodermis", dim())));
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

// ── Left — manifest (during install) ─────────────────────────────────────────

fn draw_left_manifest(f: &mut Frame, area: Rect, app: &App) {
    let mut lines = vec![
        Line::from(Span::styled("DERMAL MANIFEST", wh())),
        sep_line(area.width),
    ];
    for cat in MANIFEST {
        let hdr = format!("── {} {}", cat.label, "─".repeat((area.width as usize).saturating_sub(cat.label.len() + 4)));
        lines.push(Line::from(Span::styled(hdr, teal())));
        for def in cat.pkgs {
            if let Some(entry) = app.packages.iter().find(|p| p.id == def.id) {
                if !entry.selected { continue; }
                let (col, icon) = match entry.status {
                    PkgStatus::Active  => (hi(),  "► "),
                    PkgStatus::Ok      => (g(),   "✓ "),
                    PkgStatus::Failed  => (red(), "✗ "),
                    PkgStatus::Skipped => (amb(), "· "),
                    PkgStatus::Pending => (dim(), "  "),
                };
                lines.push(Line::from(vec![Span::styled(icon, col), Span::styled(entry.necron.as_str(), col)]));
            }
        }
    }
    lines.push(sep_line(area.width));
    lines.push(Line::from(Span::styled("tomb world awaits", dim())));
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

// ── Right panes ───────────────────────────────────────────────────────────────

fn draw_right_splash(f: &mut Frame, area: Rect) {
    let lines = vec![
        Line::from(Span::styled("OPERATOR CLEARANCE", wh())),
        sep_line(area.width),
        Line::from(""),
        Line::from(Span::styled("sudo required", amb())),
        Line::from(Span::styled("Have password ready.", wh2())),
        Line::from(""),
        Line::from(Span::styled("Do not leave the", wh2())),
        Line::from(Span::styled("terminal unattended.", wh2())),
        Line::from(""),
        Line::from(Span::styled("Root access is a", wh2())),
        Line::from(Span::styled("weapon — wield it", wh2())),
        Line::from(Span::styled("with intent.", wh2())),
        Line::from(""),
        sep_line(area.width),
        Line::from(Span::styled("The Silent King did", dim())),
        Line::from(Span::styled("not survive 60M yrs", dim())),
        Line::from(Span::styled("by being careless.", dim())),
    ];
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

const MODE_INFO: &[(&str, &[&str])] = &[
    ("DERMAL LAYER ONLY", &[
        "Applies visual layer", "to existing Hyprland.", "",
        "Configs: Waybar, Rofi,", "Hyprlock, Kitty, GTK.", "",
        "Does NOT install", "Hyprland packages.", "",
        "Est. time: 2-5 min",
    ]),
    ("FULL CANOPTEK CONV.", &[
        "Complete deployment.", "Packages + configs.", "",
        "Installs: Hyprland,", "Waybar, Rofi, Kitty,", "SDDM, Fish, btop.", "",
        "SDDM on next boot.", "",
        "Est. time: 10-30 min",
    ]),
];

fn draw_right_mode(f: &mut Frame, area: Rect, app: &App) {
    let (title, desc) = MODE_INFO[app.mode_cursor];
    let mut lines = vec![Line::from(Span::styled(title, wh())), sep_line(area.width), Line::from("")];
    for d in desc.iter() {
        lines.push(Line::from(Span::styled(*d, if d.is_empty() { dim() } else { wh2() })));
    }
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_right_picker(f: &mut Frame, area: Rect, app: &App) {
    let entry = &app.packages[app.pkg_cursor];
    let sel   = app.packages.iter().filter(|p| p.selected).count();
    let lines = vec![
        Line::from(Span::styled("COMPONENT INFO", wh())),
        sep_line(area.width),
        Line::from(""),
        Line::from(Span::styled(entry.necron.as_str(), hi())),
        Line::from(Span::styled(entry.desc.as_str(), wh2())),
        Line::from(""),
        sep_line(area.width),
        Line::from(vec![
            Span::styled(format!("{}", sel), g()),
            Span::styled(format!("/{} selected", app.packages.len()), wh2()),
        ]),
    ];
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_right_confirm(f: &mut Frame, area: Rect, app: &App) {
    let sel   = app.packages.iter().filter(|p| p.selected).count();
    let total = app.packages.len();
    let lines = vec![
        Line::from(Span::styled("MANIFEST SUMMARY", wh())),
        sep_line(area.width),
        Line::from(""),
        Line::from(vec![Span::styled(format!("{}", sel), hi()), Span::styled(" components", wh2())]),
        Line::from(vec![Span::styled(format!("{}", total - sel), wh2()), Span::styled(" skipped", dim())]),
        Line::from(""),
        sep_line(area.width),
        Line::from(Span::styled("SUDO REQUIRED", amb())),
        Line::from(""),
        Line::from(Span::styled("Stay at terminal", wh2())),
        Line::from(Span::styled("during installation.", wh2())),
    ];
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_right_stages(f: &mut Frame, area: Rect, app: &App) {
    let selected: Vec<&PkgEntry> = app.packages.iter().filter(|p| p.selected).collect();
    let done = selected.iter().filter(|p| matches!(p.status, PkgStatus::Ok | PkgStatus::Skipped | PkgStatus::Failed)).count();
    let mut lines = vec![
        Line::from(vec![
            Span::styled("STAGE STATUS ", wh()),
            Span::styled(format!("[{}/{}]", done, selected.len()), wh2()),
        ]),
        sep_line(area.width),
    ];
    for entry in &selected {
        let (icon, col) = match entry.status {
            PkgStatus::Active  => ("►", Color::Rgb(0, 204, 0)),
            PkgStatus::Ok      => ("✓", Color::Rgb(0, 170, 0)),
            PkgStatus::Failed  => ("✗", Color::Rgb(136, 0, 0)),
            PkgStatus::Skipped => ("·", Color::Rgb(136, 102, 0)),
            PkgStatus::Pending => ("·", Color::Rgb(26, 60, 26)),
        };
        let nsty = match entry.status { PkgStatus::Pending => dim(), _ => Style::default().fg(col) };
        lines.push(Line::from(vec![
            Span::styled(format!("{} ", icon), Style::default().fg(col)),
            Span::styled(entry.necron.as_str(), nsty),
        ]));
    }
    if app.screen == Screen::Codex {
        lines.push(sep_line(area.width));
        lines.push(Line::from(Span::styled("SEQUENCE COMPLETE", hi())));
    }
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_right_nextsteps(f: &mut Frame, area: Rect) {
    let lines = vec![
        Line::from(Span::styled("NEXT STEPS", wh())),
        sep_line(area.width),
        Line::from(""),
        Line::from(vec![Span::styled("1 ", teal()), Span::styled("Log out / reboot", wh2())]),
        Line::from(""),
        Line::from(vec![Span::styled("2 ", teal()), Span::styled("SDDM on next boot", wh2())]),
        Line::from(""),
        Line::from(vec![Span::styled("3 ", teal()), Span::styled("Run: sitrep", wh2())]),
        Line::from(""),
        Line::from(vec![Span::styled("4 ", teal()), Span::styled("necrodermis-uninstall", wh2())]),
        Line::from(vec![Span::styled("  ", dim()), Span::styled("to revert", wh2())]),
        Line::from(""),
        sep_line(area.width),
        Line::from(Span::styled("Q/ENT  exit", dim())),
        Line::from(Span::styled("E      error log", dim())),
    ];
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

// ── Centre panes ──────────────────────────────────────────────────────────────

fn draw_centre_splash(f: &mut Frame, area: Rect, app: &App) {
    let pulse = if (app.tick / 20) % 2 == 0 { hi() } else { g() };
    let bw    = (area.width as usize).min(54);

    let lines = vec![
        Line::from(""),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^w$}", "N E C R O D E R M I S", w = bw.saturating_sub(4)), hi()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^w$}", "T O M B - W O R L D   I N S T A L L E R", w = bw.saturating_sub(4)), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(""),
        Line::from(vec![
            Span::styled("  DISTRO  ", dim()), Span::styled(app.distro.as_str(), teal()),
            Span::styled("   FAMILY  ", dim()), Span::styled(app.family.as_str(), teal()),
        ]),
        Line::from(""),
        sep_line(bw as u16),
        Line::from(Span::styled("  WHAT IS NECRODERMIS", wh())),
        Line::from(""),
        Line::from(Span::styled("  A Warhammer 40K Necron themed Hyprland", wh2())),
        Line::from(Span::styled("  desktop for Arch-based distros.", wh2())),
        Line::from(""),
        Line::from(vec![Span::styled("  DERMAL LAYER ONLY        ", g()), Span::styled("configs + themes", dim())]),
        Line::from(vec![Span::styled("  FULL CANOPTEK CONVERSION ", g()), Span::styled("full install", dim())]),
        Line::from(""),
        sep_line(bw as u16),
        Line::from(Span::styled("  STASIS: 60,247,891 YRS  //  47 FAULTS UNRESOLVED", pulse)),
        Line::from(""),
        Line::from(vec![
            Span::styled("  ", dim()),
            Span::styled("ENTER", hi()), Span::styled(" begin awakening   ", wh2()),
            Span::styled("Q", red()), Span::styled(" the tomb remains sealed", wh2()),
        ]),
    ];
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_centre_mode(f: &mut Frame, area: Rect, app: &App) {
    let bw = area.width as usize;
    let mut lines = vec![
        Line::from(""),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^w$}", "SELECT AWAKENING PROTOCOL", w = bw.saturating_sub(4)), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(""),
    ];
    const MODES: &[(&str, &str)] = &[
        ("DERMAL LAYER ONLY",       "configs + themes for existing Hyprland"),
        ("FULL CANOPTEK CONVERSION","full packages + configs from scratch"),
    ];
    for (i, (name, sub)) in MODES.iter().enumerate() {
        let active = i == app.mode_cursor;
        let (arrow, nsty, ssty) = if active { ("  >>  ", hi(), g()) } else { ("      ", dim(), dim()) };
        lines.push(Line::from(vec![Span::styled(arrow, if active { hi() } else { dim() }), Span::styled(*name, nsty)]));
        lines.push(Line::from(vec![Span::styled("        ", dim()), Span::styled(*sub, ssty)]));
        lines.push(Line::from(""));
    }
    lines.push(sep_line(area.width));
    lines.push(Line::from(vec![
        Span::styled("  ", dim()),
        Span::styled("j/k ↑↓", wh2()), Span::styled(" navigate   ", dim()),
        Span::styled("ENTER", hi()), Span::styled(" confirm   ", wh2()),
        Span::styled("Q", red()), Span::styled(" back", wh2()),
    ]));
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_centre_picker(f: &mut Frame, area: Rect, app: &App) {
    let sel_count = app.packages.iter().filter(|p| p.selected).count();
    let cursor    = app.pkg_cursor;

    #[derive(Clone)]
    enum Row { Header(&'static str), Pkg(usize) }
    let mut rows: Vec<Row> = Vec::new();
    let mut idx = 0usize;
    for cat in MANIFEST {
        rows.push(Row::Header(cat.label));
        for _ in cat.pkgs { rows.push(Row::Pkg(idx)); idx += 1; }
    }

    let cursor_row = rows.iter().position(|r| matches!(r, Row::Pkg(i) if *i == cursor)).unwrap_or(0);
    let visible_h  = area.height.saturating_sub(4) as usize;
    let scroll     = cursor_row.saturating_sub(visible_h / 2);

    let mut lines = vec![
        Line::from(vec![
            Span::styled("DESIGNATE DERMAL LAYERS  ", wh()),
            Span::styled(format!("[{}/{}]", sel_count, app.packages.len()), if sel_count > 0 { g() } else { red() }),
        ]),
        sep_line(area.width),
    ];

    for row in rows.iter().skip(scroll).take(visible_h) {
        match row {
            Row::Header(cat) => {
                let hdr = format!("── {} {}", cat, "─".repeat(20));
                lines.push(Line::from(Span::styled(hdr, teal())));
            }
            Row::Pkg(i) => {
                let entry  = &app.packages[*i];
                let is_cur = *i == cursor;
                let (check, csty) = if entry.selected { ("[x]", if is_cur { hi() } else { g() }) } else { ("[ ]", dim()) };
                let nsty = if is_cur { hi() } else if entry.selected { wh() } else { dim() };
                let row_bg = if is_cur { Style::default().bg(Color::Rgb(0, 18, 0)) } else { blk() };
                lines.push(Line::from(vec![
                    Span::styled("  ", row_bg),
                    Span::styled(check, csty.patch(row_bg)),
                    Span::styled("  ", dim()),
                    Span::styled(format!("{:<18}", entry.necron), nsty.patch(row_bg)),
                    Span::styled(entry.desc.as_str(), if is_cur { wh2() } else { dim() }),
                ]));
            }
        }
    }

    lines.push(sep_line(area.width));
    lines.push(Line::from(vec![
        Span::styled("j/k", wh2()), Span::styled(" nav  ", dim()),
        Span::styled("SPC", wh2()), Span::styled(" toggle  ", dim()),
        Span::styled("A", wh2()),   Span::styled(" all  ", dim()),
        Span::styled("ENTER", hi()), Span::styled(" confirm  ", wh2()),
        Span::styled("Q", red()),   Span::styled(" back", wh2()),
    ]));

    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_centre_confirm(f: &mut Frame, area: Rect, app: &App) {
    let sel: Vec<&PkgEntry> = app.packages.iter().filter(|p| p.selected).collect();
    let skp: Vec<&PkgEntry> = app.packages.iter().filter(|p| !p.selected).collect();
    let bw = area.width as usize;
    let mut lines = vec![
        Line::from(""),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^w$}", format!("AWAKENING MANIFEST  //  {} COMPONENTS", sel.len()), w = bw.saturating_sub(4)), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(""),
    ];
    for p in &sel {
        lines.push(Line::from(vec![
            Span::styled("  [x]  ", g()),
            Span::styled(format!("{:<18}", p.necron), wh()),
            Span::styled(p.desc.as_str(), dim()),
        ]));
    }
    if !skp.is_empty() {
        lines.push(Line::from(""));
        for p in &skp {
            lines.push(Line::from(vec![
                Span::styled("  [ ]  ", dim()),
                Span::styled(format!("{:<18}", p.necron), wh2()),
                Span::styled("SKIPPED", dim()),
            ]));
        }
    }
    lines.push(Line::from(""));
    lines.push(sep_line(area.width));
    lines.push(Line::from(vec![
        Span::styled("  ", dim()),
        Span::styled("ENTER", hi()), Span::styled(" INITIATE AWAKENING   ", wh2()),
        Span::styled("Q", red()), Span::styled(" back", wh2()),
    ]));
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_centre_install(f: &mut Frame, area: Rect, app: &App) {
    let pct   = app.install_pct();
    let bar_w = area.width.saturating_sub(8) as usize;
    let filled = (pct as usize * bar_w / 100).min(bar_w);

    let mut lines = vec![
        Line::from(Span::styled("LIVE OUTPUT", wh())),
        sep_line(area.width),
        Line::from(vec![
            Span::styled("[", dim()),
            Span::styled("█".repeat(filled), g()),
            Span::styled("░".repeat(bar_w - filled), dim()),
            Span::styled("] ", dim()),
            Span::styled(format!("{}%", pct), if pct == 100 { hi() } else { wh2() }),
        ]),
    ];

    let dots = match (app.tick / 8) % 4 { 0 => ".   ", 1 => "..  ", 2 => "... ", _ => "...." };
    lines.push(if app.install_rx.is_some() {
        Line::from(Span::styled(format!("  installing{}", dots), wh2()))
    } else {
        Line::from(Span::styled("  installation complete", hi()))
    });
    lines.push(sep_line(area.width));

    let log_h = area.height.saturating_sub(5) as usize;
    let start = app.log_lines.len().saturating_sub(log_h);
    for (s, c) in &app.log_lines[start..] {
        lines.push(Line::from(Span::styled(s.as_str(), Style::default().fg(*c))));
    }

    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_centre_codex(f: &mut Frame, area: Rect, app: &App) {
    let pulse = if (app.tick / 20) % 2 == 0 { hi() } else { g() };
    let bw = area.width as usize;
    let lines = vec![
        Line::from(""),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^w$}", "T H E   N E C R O D E R M I S   P R O T O C O L", w = bw.saturating_sub(4)), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(format!("+{}+", "-".repeat(bw.saturating_sub(2))), wh2())),
        Line::from(""),
        Line::from(vec![Span::styled("  |  ", dim()), Span::styled("Tomb world conversion complete.", hi())]),
        Line::from(vec![Span::styled("  |  Your system now bears the Necrodermis.", wh2())]),
        Line::from(vec![Span::styled("  |  Canoptek constructs standing by.", wh2())]),
        Line::from(""),
        sep_line(area.width),
        Line::from(Span::styled("  INSTALL REPORT", wh())),
        Line::from(""),
        Line::from(vec![Span::styled("  [ OK  ]  ", g()), Span::styled(format!("{} installed", app.ok_count), wh())]),
        Line::from(vec![Span::styled("  [SKIP ]  ", amb()), Span::styled(format!("{} already present", app.skip_count), wh2())]),
        if app.fail_count > 0 {
            Line::from(vec![Span::styled("  [FAIL ]  ", red()), Span::styled(format!("{} failed — press E", app.fail_count), wh())])
        } else {
            Line::from(Span::styled("  [FAIL ]  0 failures", dim()))
        },
        Line::from(""),
        sep_line(area.width),
        Line::from(Span::styled("  ORGANIC MATTER IS TEMPORARY", pulse)),
        Line::from(Span::styled("  NECRODERMIS IS ETERNAL", dim())),
        Line::from(""),
        Line::from(vec![
            Span::styled("  ", dim()),
            Span::styled("ENTER/Q", hi()), Span::styled(" exit   ", wh2()),
            if !app.fail_log.is_empty() { Span::styled("E  view error log", red()) } else { Span::styled("", dim()) },
        ]),
    ];
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}

fn draw_centre_errorlog(f: &mut Frame, area: Rect, app: &App) {
    let mut lines = vec![
        Line::from(vec![
            Span::styled("ERROR LOG  //  ", red()),
            Span::styled(format!("{} FAILURE{}", app.fail_count, if app.fail_count != 1 { "S" } else { "" }), red()),
        ]),
        sep_line(area.width),
        Line::from(""),
    ];
    for (name, msg) in &app.fail_log {
        lines.push(Line::from(vec![Span::styled("  [FAIL ]  ", red()), Span::styled(name.as_str(), wh())]));
        lines.push(Line::from(vec![Span::styled(format!("           {}", msg), wh2())]));
        lines.push(Line::from(""));
    }
    lines.push(sep_line(area.width));
    lines.push(Line::from(Span::styled("  RECOVERY OPTIONS", amb())));
    lines.push(Line::from(vec![Span::styled("  ·  Log: ", wh2()), Span::styled("~/.local/share/necrodermis/install.log", g())]));
    lines.push(Line::from(Span::styled("  ·  Re-run installer to retry failed packages", wh2())));
    lines.push(Line::from(Span::styled("  ·  Check internet + pacman keyring", wh2())));
    lines.push(Line::from(vec![Span::styled("  ·  ", wh2()), Span::styled("sudo pacman -Sy archlinux-keyring", g()), Span::styled("  then retry", wh2())]));
    lines.push(Line::from(""));
    lines.push(Line::from(vec![Span::styled("  ", dim()), Span::styled("Q/ESC", hi()), Span::styled(" back to codex", wh2())]));
    f.render_widget(Paragraph::new(lines).style(blk()), area);
}
