use std::io;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};

use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::prelude::*;
use ratatui::widgets::{Gauge, List, ListItem, ListState, Paragraph};

use crate::pkg::{InstallResult, PackageManager, build_pkg_map, do_install, resolve_pkg};

// ── Tomb-world diagnostic background ─────────────────────────────────────────

const TOMB_LINES: &[&str] = &[
    "TOMB-WORLD NODE 7741-SIGMA  //  STASIS INTEGRITY: NOMINAL",
    "CANOPTEK SCARAB SWARM: ACTIVE  //  17,441 UNITS ONLINE",
    "NECRODERMIS SELF-REPAIR: 94.7%  //  ESTIMATED COMPLETION: 847 YRS",
    "QUANTUM SHIELDING: OPTIMAL  //  PHASE VARIANCE: 0.003%",
    "INTERMENT CYCLE III  //  SUBJECT: OPERATOR CLEARANCE CONFIRMED",
    "STASIS FIELD COHERENCE: 99.1%  //  47 MAINTENANCE FAULTS UNRESOLVED",
    "PHAERON UPLINK: DORMANT  //  AWAITING DIRECTIVE",
    "GAUSS FLUX EMITTER ARRAY: STANDBY  //  CHARGE: 100%",
    "DIMENSIONAL ANCHOR: LOCKED  //  TOMB COORDINATES: CLASSIFIED",
    "ENGRAM INTEGRITY: DEGRADED 0.02%  //  ACCEPTABLE THRESHOLD",
    "CHRONO-STASIS LOG: 60,247,891 YRS  //  LAST DIAGNOSTIC: 4,891 YRS AGO",
    "WARRIOR SHARD COUNT: 1,204  //  ACTIVE: 0  //  DORMANT: 1,204",
    "CRYPTEK OVERRIDE: NOT REQUIRED  //  SEQUENCE AUTO-INITIATING",
    "SPATIAL TESSELLATION: STABLE  //  MONOLITH ARRAY: SYNCHRONISED",
    "LIVING METAL INTEGRITY: 98.3%  //  REGENERATION ACTIVE",
    "WARP SHIELDING: MAXIMUM  //  NO PSYCHIC SIGNATURES DETECTED",
    "CORE TEMPERATURE: 4K  //  OPTIMAL FOR NECRODERMIS OPERATION",
    "SIGNAL ARRAY CALIBRATION: COMPLETE  //  RANGE: 40,000 LIGHT YEARS",
    "0xDEAD :: 0xC0DE :: 0xF00D :: 0xBEEF :: 0xCAFE :: 0xD00D",
    "MEM[0x7F3A] = 0xFF  MEM[0x7F3B] = 0xAA  MEM[0x7F3C] = 0x00",
    "RESURRECTION PROTOCOL: ARMED  //  TRIGGER: ON OPERATOR DEATH",
    "SAUTEKH DYNASTY UPLINK: ESTABLISHED  //  ENCRYPTION: ACTIVE",
    "TOMB WORLD STATUS: AWAKENING  //  OPERATOR DIRECTIVE RECEIVED",
];

// ── Package manifest with Necron designations ─────────────────────────────────

#[derive(Clone)]
pub struct PkgCat {
    pub label: &'static str,
    pub pkgs:  &'static [PkgDef],
}

#[derive(Clone)]
pub struct PkgDef {
    pub id:     &'static str,   // logical id for pkg map
    pub necron: &'static str,   // display name in TUI
    pub desc:   &'static str,   // short description
}

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

fn all_pkgs() -> Vec<&'static PkgDef> {
    MANIFEST.iter().flat_map(|c| c.pkgs.iter()).collect()
}

// ── App state ─────────────────────────────────────────────────────────────────

#[derive(Clone, Copy, PartialEq)]
pub enum Screen {
    Splash,
    ModeSelect,
    Picker,
    Confirm,
    Installing,
    Codex,
    ErrorLog,
    Aborted,
}

#[derive(Clone, Copy, PartialEq)]
pub enum Mode { Dots, Full }

#[derive(Clone, PartialEq)]
pub enum PkgStatus { Pending, Active, Ok, Skipped, Failed }

#[derive(Clone)]
pub struct PkgEntry {
    pub id:       String,
    pub necron:   String,
    pub desc:     String,
    pub selected: bool,
    pub status:   PkgStatus,
}

pub enum InstallMsg {
    Starting(String),
    Result(String, InstallResult),
    Done,
}

pub struct App {
    pub screen:       Screen,
    pub distro:       String,
    pub family:       String,
    pub mode:         Mode,
    pub mode_cursor:  usize,
    pub packages:     Vec<PkgEntry>,
    pub list_state:   ListState,
    pub log_lines:    Vec<(String, Color)>,
    pub fail_log:     Vec<(String, String)>,
    pub done_count:   usize,
    pub total_count:  usize,
    pub ok_count:     usize,
    pub skip_count:   usize,
    pub fail_count:   usize,
    pub install_rx:   Option<mpsc::Receiver<InstallMsg>>,
    pub start_time:   Option<Instant>,
    pub tick:         u64,
    pub bg_offset:    usize,
    pub quit:         bool,
}

impl App {
    pub fn new(distro: String, family: String) -> Self {
        let packages = all_pkgs().into_iter().map(|d| PkgEntry {
            id:       d.id.to_string(),
            necron:   d.necron.to_string(),
            desc:     d.desc.to_string(),
            selected: true,
            status:   PkgStatus::Pending,
        }).collect();

        let mut list_state = ListState::default();
        list_state.select(Some(0));

        App {
            screen: Screen::Splash,
            distro, family,
            mode: Mode::Dots,
            mode_cursor: 0,
            packages,
            list_state,
            log_lines: Vec::new(),
            fail_log: Vec::new(),
            done_count: 0,
            total_count: 0,
            ok_count: 0,
            skip_count: 0,
            fail_count: 0,
            install_rx: None,
            start_time: None,
            tick: 0,
            bg_offset: 0,
            quit: false,
        }
    }

    fn reset_install_state(&mut self) {
        self.log_lines.clear();
        self.fail_log.clear();
        self.done_count = 0;
        self.total_count = 0;
        self.ok_count = 0;
        self.skip_count = 0;
        self.fail_count = 0;
        self.start_time = None;
        for p in &mut self.packages { p.status = PkgStatus::Pending; }
    }

    fn elapsed_secs(&self) -> u64 {
        self.start_time.map(|t| t.elapsed().as_secs()).unwrap_or(0)
    }

    fn install_pct(&self) -> u16 {
        if self.total_count == 0 { return 0; }
        ((self.done_count as f64 / self.total_count as f64) * 100.0) as u16
    }

    fn pkg_mgr(&self) -> PackageManager {
        match self.family.as_str() {
            "fedora"   => PackageManager::Dnf,
            "opensuse" => PackageManager::Zypper,
            "void"     => PackageManager::Xbps,
            _          => PackageManager::Pacman,
        }
    }
}

// ── Main loop ─────────────────────────────────────────────────────────────────

pub fn run_app<B: Backend>(terminal: &mut Terminal<B>, app: &mut App) -> io::Result<()>
where
    io::Error: From<B::Error>,
{
    loop {
        if app.screen == Screen::Installing {
            poll_install(app);
        }

        terminal.draw(|f| draw(f, app))?;

        app.tick = app.tick.wrapping_add(1);
        if app.tick % 4 == 0 { app.bg_offset = app.bg_offset.wrapping_add(1); }

        if event::poll(Duration::from_millis(50))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    handle_key(app, key.code);
                }
            }
        }

        if app.quit { break; }
    }
    Ok(())
}

// ── Input handling ────────────────────────────────────────────────────────────

fn handle_key(app: &mut App, key: KeyCode) {
    match app.screen {
        Screen::Splash => match key {
            KeyCode::Enter => app.screen = Screen::ModeSelect,
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::Aborted,
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
            KeyCode::Up   | KeyCode::Char('k') => {
                let n = app.packages.len();
                let i = app.list_state.selected().unwrap_or(0);
                app.list_state.select(Some(if i == 0 { n - 1 } else { i - 1 }));
            }
            KeyCode::Down | KeyCode::Char('j') => {
                let n = app.packages.len();
                let i = app.list_state.selected().unwrap_or(0);
                app.list_state.select(Some(if i >= n - 1 { 0 } else { i + 1 }));
            }
            KeyCode::Char(' ') => {
                if let Some(i) = app.list_state.selected() {
                    app.packages[i].selected = !app.packages[i].selected;
                }
            }
            KeyCode::Char('a') => {
                let all = app.packages.iter().all(|p| p.selected);
                for p in &mut app.packages { p.selected = !all; }
            }
            KeyCode::Enter => {
                if app.packages.iter().any(|p| p.selected) {
                    app.screen = Screen::Confirm;
                }
            }
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::ModeSelect,
            _ => {}
        },

        Screen::Confirm => match key {
            KeyCode::Enter => start_install(app),
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::Picker,
            _ => {}
        },

        Screen::Installing => {} // no bail mid-install

        Screen::Codex => match key {
            KeyCode::Char('e') | KeyCode::Char('E') => {
                if !app.fail_log.is_empty() { app.screen = Screen::ErrorLog; }
            }
            KeyCode::Char('q') | KeyCode::Enter | KeyCode::Esc => app.quit = true,
            _ => {}
        },

        Screen::ErrorLog => match key {
            KeyCode::Char('q') | KeyCode::Esc => app.screen = Screen::Codex,
            _ => {}
        },

        Screen::Aborted => match key {
            KeyCode::Char('q') | KeyCode::Enter | KeyCode::Esc => app.quit = true,
            _ => {}
        },
    }
}

// ── Install thread ────────────────────────────────────────────────────────────

fn start_install(app: &mut App) {
    app.reset_install_state();

    let selected: Vec<String> = app.packages.iter()
        .filter(|p| p.selected)
        .map(|p| p.id.clone())
        .collect();

    app.total_count = selected.len();
    app.start_time  = Some(Instant::now());
    app.screen      = Screen::Installing;

    let distro  = app.distro.clone();
    let family  = app.family.clone();
    let (tx, rx) = mpsc::channel::<InstallMsg>();
    app.install_rx = Some(rx);

    thread::spawn(move || {
        let pkg_mgr = match family.as_str() {
            "fedora"   => PackageManager::Dnf,
            "opensuse" => PackageManager::Zypper,
            "void"     => PackageManager::Xbps,
            _          => PackageManager::Pacman,
        };
        let map = build_pkg_map();

        for id in &selected {
            let _ = tx.send(InstallMsg::Starting(id.clone()));
            let resolved = resolve_pkg(&map, &distro, id);
            let results  = do_install(&pkg_mgr, &[resolved.as_str()]);
            if let Some((_, result)) = results.into_iter().next() {
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
                Ok(m)  => m,
                Err(mpsc::TryRecvError::Empty) => break,
                Err(mpsc::TryRecvError::Disconnected) => {
                    app.install_rx = None;
                    app.screen = Screen::Codex;
                    break;
                }
            },
            None => break,
        };

        match msg {
            InstallMsg::Starting(pkg) => {
                for p in &mut app.packages {
                    if p.id == pkg { p.status = PkgStatus::Active; }
                }
                if let Some(p) = app.packages.iter().find(|p| p.id == pkg) {
                    app.log_lines.push((format!("  installing {}...", p.necron), Color::DarkGray));
                }
            }
            InstallMsg::Result(pkg, result) => {
                app.done_count += 1;
                let (status, color, label) = match &result {
                    InstallResult::Ok         => (PkgStatus::Ok,      Color::Green,  "[ OK  ]"),
                    InstallResult::Skipped(_) => (PkgStatus::Skipped, Color::Yellow, "[SKIP ]"),
                    InstallResult::Failed(_)  => (PkgStatus::Failed,  Color::Red,    "[FAIL ]"),
                };
                match &result {
                    InstallResult::Ok         => app.ok_count   += 1,
                    InstallResult::Skipped(_) => app.skip_count += 1,
                    InstallResult::Failed(m)  => {
                        app.fail_count += 1;
                        let necron = app.packages.iter()
                            .find(|p| p.id == pkg)
                            .map(|p| p.necron.clone())
                            .unwrap_or(pkg.clone());
                        app.fail_log.push((necron, m.clone()));
                    }
                }
                let necron = app.packages.iter()
                    .find(|p| p.id == pkg)
                    .map(|p| p.necron.clone())
                    .unwrap_or(pkg.clone());
                for p in &mut app.packages {
                    if p.id == pkg { p.status = status.clone(); }
                }
                let suffix = match &result {
                    InstallResult::Failed(m) => format!("  — {}", m),
                    InstallResult::Skipped(m) => format!("  — {}", m),
                    InstallResult::Ok => String::new(),
                };
                app.log_lines.push((format!("  {}  {}{}", label, necron, suffix), color));
                if app.log_lines.len() > 200 { app.log_lines.drain(..50); }
            }
            InstallMsg::Done => {
                app.install_rx = None;
                app.screen = Screen::Codex;
                break;
            }
        }
    }
}

// ── Color helpers ─────────────────────────────────────────────────────────────

fn hi()   -> Style { Style::default().fg(Color::Green).add_modifier(Modifier::BOLD) }
fn g()    -> Style { Style::default().fg(Color::Green) }
fn dim()  -> Style { Style::default().fg(Color::DarkGray) }
fn wh()   -> Style { Style::default().fg(Color::Gray) }
fn wh2()  -> Style { Style::default().fg(Color::DarkGray) }
fn amb()  -> Style { Style::default().fg(Color::Yellow) }
fn red()  -> Style { Style::default().fg(Color::Red) }
fn teal() -> Style { Style::default().fg(Color::Cyan) }

// ── Background scroller ───────────────────────────────────────────────────────

fn draw_bg(f: &mut Frame, app: &App) {
    let area = f.area();
    let n = TOMB_LINES.len();
    let mut lines: Vec<Line> = Vec::with_capacity(area.height as usize);
    for row in 0..area.height as usize {
        let idx = (row + app.bg_offset) % n;
        // repeat line to fill width
        let base = TOMB_LINES[idx];
        let mut s = String::new();
        while s.len() < area.width as usize + base.len() {
            s.push_str(base);
            s.push_str("    ");
        }
        let start = (app.bg_offset * 3 + row * 7) % base.len().max(1);
        let slice: String = s.chars().skip(start).take(area.width as usize).collect();
        lines.push(Line::from(Span::styled(slice,
            Style::default().fg(Color::Rgb(0, 30, 0)))));
    }
    f.render_widget(Paragraph::new(lines), area);
}

// ── Separator helper ──────────────────────────────────────────────────────────

fn sep(width: usize) -> Line<'static> {
    Line::from(Span::styled("─".repeat(width), Style::default().fg(Color::Rgb(0, 40, 0))))
}

fn box_top(width: usize) -> String  { format!("+{}+", "-".repeat(width.saturating_sub(2))) }
fn box_bot(width: usize) -> String  { format!("+{}+", "-".repeat(width.saturating_sub(2))) }
fn box_mid(s: &str, width: usize) -> String {
    let inner = width.saturating_sub(4);
    format!("|  {:<inner$}  |", s, inner = inner)
}

// ── Draw dispatch ─────────────────────────────────────────────────────────────

fn draw(f: &mut Frame, app: &mut App) {
    draw_bg(f, app);
    // Top bar on every screen
    draw_topbar(f, app);
    let area = topbar_inner(f.area());

    match app.screen {
        Screen::Splash     => draw_splash(f, area, app),
        Screen::ModeSelect => draw_modesel(f, area, app),
        Screen::Picker     => draw_picker(f, area, app),
        Screen::Confirm    => draw_confirm(f, area, app),
        Screen::Installing => draw_installing(f, area, app),
        Screen::Codex      => draw_codex(f, area, app),
        Screen::ErrorLog   => draw_errorlog(f, area, app),
        Screen::Aborted    => draw_aborted(f, area),
    }
}

fn draw_topbar(f: &mut Frame, app: &App) {
    let area = Rect { x: 0, y: 0, width: f.area().width, height: 1 };
    let elapsed = app.elapsed_secs();
    let clk = format!("{:02}:{:02}:{:02}", elapsed / 3600, (elapsed % 3600) / 60, elapsed % 60);
    let right = format!("{}  |  {}  |  {}", app.distro, app.family, clk);
    let left  = "NECRODERMIS v1.3.67  //  AWAKENING SEQUENCE";

    let width = f.area().width as usize;
    let pad   = width.saturating_sub(left.len() + right.len());
    let bar   = format!("{}{}{}", left, " ".repeat(pad), right);

    f.render_widget(
        Paragraph::new(bar).style(Style::default().fg(Color::Rgb(26, 100, 26)).bg(Color::Black)),
        area,
    );
}

fn topbar_inner(area: Rect) -> Rect {
    Rect { y: area.y + 1, height: area.height.saturating_sub(1), ..area }
}

// ── Splash ────────────────────────────────────────────────────────────────────

fn draw_splash(f: &mut Frame, area: Rect, app: &App) {
    let w  = area.width as usize;
    let bw = w.min(62);
    let bx = ((w - bw) / 2) as u16;
    let by = area.y + area.height / 6;

    let pulse = if (app.tick / 20) % 2 == 0 {
        Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)
    } else {
        Style::default().fg(Color::Rgb(0, 80, 0))
    };

    let mut lines: Vec<Line> = vec![
        Line::from(Span::styled(box_top(bw), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^width$}", "N E C R O D E R M I S", width = bw - 4), hi()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^width$}", "T O M B - W O R L D   I N S T A L L E R", width = bw - 4), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(box_bot(bw), wh2())),
        Line::from(""),
        Line::from(vec![
            Span::styled("  DISTRO  ", dim()),
            Span::styled(app.distro.as_str(), teal()),
            Span::styled("   FAMILY  ", dim()),
            Span::styled(app.family.as_str(), teal()),
        ]),
        Line::from(""),
        sep(bw),
        Line::from(vec![
            Span::styled("  WHAT IS NECRODERMIS  ", wh()),
        ]),
        Line::from(vec![
            Span::styled("  A Warhammer 40K Necron themed Hyprland desktop.", wh2()),
        ]),
        Line::from(vec![
            Span::styled("  DERMAL LAYER ONLY       ", g()),
            Span::styled("configs + themes for existing Hyprland installs", dim()),
        ]),
        Line::from(vec![
            Span::styled("  FULL CANOPTEK CONVERSION  ", g()),
            Span::styled("full packages + configs from scratch", dim()),
        ]),
        sep(bw),
        Line::from(vec![Span::styled("  OPERATOR CLEARANCE REQUIRED", amb())]),
        Line::from(vec![Span::styled("  ·  sudo password required — have it ready", wh2())]),
        Line::from(vec![Span::styled("  ·  Do not leave the terminal unattended", wh2())]),
        Line::from(vec![Span::styled("  ·  Root access is a weapon — wield it with intent", wh2())]),
        Line::from(vec![Span::styled("  ·  The Silent King did not survive 60M years by being careless", dim())]),
        sep(bw),
        Line::from(Span::styled(
            "  STASIS DURATION: 60,247,891 YRS  //  47 MAINTENANCE FAULTS UNRESOLVED",
            pulse,
        )),
        Line::from(""),
        Line::from(vec![
            Span::styled("  ", dim()),
            Span::styled("ENTER", hi()),
            Span::styled(" begin   ", wh2()),
            Span::styled("Q", red()),
            Span::styled(" abort", wh2()),
        ]),
    ];

    let render_area = Rect {
        x: area.x + bx,
        y: by,
        width:  bw as u16,
        height: lines.len().min(area.height as usize) as u16,
    };
    f.render_widget(
        Paragraph::new(lines)
            .style(Style::default().bg(Color::Black)),
        render_area,
    );
}

// ── Mode select ───────────────────────────────────────────────────────────────

fn draw_modesel(f: &mut Frame, area: Rect, app: &App) {
    let w  = area.width as usize;
    let bw = w.min(68);
    let bx = ((w - bw) / 2) as u16;
    let by = area.y + 2;

    const MODES: &[(&str, &str, &str, &str)] = &[
        ("DERMAL LAYER ONLY",       "configs + themes only",
         "Applies the Necrodermis visual layer to your existing Hyprland setup.",
         "Assumes Hyprland is already installed and working."),
        ("FULL CANOPTEK CONVERSION","packages + configs, full install",
         "Complete Necrodermis deployment — packages and configs from scratch.",
         "Substantial system modification — read everything before proceeding."),
    ];

    let (_name, _sub, desc, warn) = MODES[app.mode_cursor];
    let active_col = |i: usize| if i == app.mode_cursor { hi() } else { wh2() };
    let arrow      = |i: usize| if i == app.mode_cursor { ">>" } else { "  " };

    let mut lines: Vec<Line> = vec![
        Line::from(Span::styled(box_top(bw), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^width$}", "SELECT AWAKENING PROTOCOL", width = bw - 4), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(box_bot(bw), wh2())),
        Line::from(""),
    ];

    for (i, (n, s, _, _)) in MODES.iter().enumerate() {
        lines.push(Line::from(vec![
            Span::styled(format!("  {}  ", arrow(i)), if i == app.mode_cursor { hi() } else { dim() }),
            Span::styled(*n, active_col(i)),
            Span::styled(format!("   — {}", s), if i == app.mode_cursor { g() } else { dim() }),
        ]));
        lines.push(Line::from(""));
    }

    lines.push(sep(bw));
    lines.push(Line::from(vec![
        Span::styled("  ABOUT THIS MODE  ", wh()),
    ]));
    lines.push(Line::from(vec![Span::styled(format!("  {}", desc), wh2())]));
    lines.push(Line::from(""));
    lines.push(Line::from(vec![Span::styled("  BEFORE YOU PROCEED  ", amb())]));
    lines.push(Line::from(vec![Span::styled(format!("  {}", warn), wh2())]));
    lines.push(sep(bw));
    lines.push(Line::from(vec![
        Span::styled("  ", dim()),
        Span::styled("j/k ↑↓", wh2()),
        Span::styled(" navigate   ", dim()),
        Span::styled("ENTER", hi()),
        Span::styled(" confirm   ", wh2()),
        Span::styled("Q", red()),
        Span::styled(" back", wh2()),
    ]));

    let render_area = Rect {
        x: area.x + bx,
        y: by,
        width:  bw as u16,
        height: lines.len().min(area.height.saturating_sub(2) as usize) as u16,
    };
    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        render_area,
    );
}

// ── Picker ────────────────────────────────────────────────────────────────────

fn draw_picker(f: &mut Frame, area: Rect, app: &mut App) {
    let w   = area.width as usize;
    let bw  = w.min(68);
    let bx  = ((w - bw) / 2) as u16;
    let by  = area.y + 1;

    let sel_count = app.packages.iter().filter(|p| p.selected).count();

    let outer = Rect { x: area.x + bx, y: by, width: bw as u16, height: area.height.saturating_sub(2) };

    // Header
    let header = vec![
        Line::from(Span::styled(
            format!("  DESIGNATE DERMAL LAYERS  [{}/{}]", sel_count, app.packages.len()),
            wh(),
        )),
        sep(bw),
        Line::from(vec![
            Span::styled("  j/k ↑↓", wh2()), Span::styled(" nav   ", dim()),
            Span::styled("SPACE",    hi()),   Span::styled(" toggle   ", wh2()),
            Span::styled("A",        hi()),   Span::styled(" all   ", wh2()),
            Span::styled("ENTER",    hi()),   Span::styled(" confirm   ", wh2()),
            Span::styled("Q",        red()),  Span::styled(" back", wh2()),
        ]),
        sep(bw),
    ];
    let header_h = header.len() as u16;
    f.render_widget(
        Paragraph::new(header).style(Style::default().bg(Color::Black)),
        Rect { height: header_h, ..outer },
    );

    // Package list — grouped by category
    let mut items: Vec<ListItem> = Vec::new();
    let mut pkg_idx: Vec<Option<usize>> = Vec::new(); // maps list row → package index

    for cat in MANIFEST {
        // Category header row
        items.push(ListItem::new(Line::from(vec![
            Span::styled(format!("── {} ", cat.label), teal()),
            Span::styled("─".repeat(bw.saturating_sub(cat.label.len() + 5)), Style::default().fg(Color::Rgb(0, 60, 60))),
        ])));
        pkg_idx.push(None);

        for pkg_def in cat.pkgs {
            let (selected, idx) = if let Some((i, e)) = app.packages.iter().enumerate().find(|(_, p)| p.id == pkg_def.id) {
                (e.selected, i)
            } else {
                (false, 0)
            };
            let check_col = if selected { g() } else { dim() };
            let name_col  = if selected { wh() } else { dim() };
            items.push(ListItem::new(Line::from(vec![
                Span::styled("  ", dim()),
                Span::styled(if selected { "[x]" } else { "[ ]" }, check_col),
                Span::styled("  ", dim()),
                Span::styled(format!("{:<18}", pkg_def.necron), name_col),
                Span::styled(pkg_def.desc, dim()),
            ])));
            pkg_idx.push(Some(idx));
        }
    }

    // Scroll selected item into view
    // The ListState cursor tracks flat list index; we need to translate
    // our package index to list item index
    let list_area = Rect {
        y:      outer.y + header_h,
        height: outer.height.saturating_sub(header_h),
        ..outer
    };

    // Build a pkg-idx → list-row lookup
    // Find which list row corresponds to selected package
    if let Some(pkg_i) = app.list_state.selected() {
        let list_row = pkg_idx.iter().position(|r| *r == Some(pkg_i)).unwrap_or(0);
        *app.list_state.offset_mut() = list_row.saturating_sub(list_area.height as usize / 2);
    }

    let list = List::new(items)
        .highlight_style(Style::default().bg(Color::Rgb(0, 18, 0)).fg(Color::Green))
        .style(Style::default().bg(Color::Black));

    f.render_stateful_widget(list, list_area, &mut app.list_state);
}

// ── Confirm ───────────────────────────────────────────────────────────────────

fn draw_confirm(f: &mut Frame, area: Rect, app: &App) {
    let w  = area.width as usize;
    let bw = w.min(68);
    let bx = ((w - bw) / 2) as u16;
    let by = area.y + 1;

    let sel: Vec<&PkgEntry> = app.packages.iter().filter(|p| p.selected).collect();
    let skp: Vec<&PkgEntry> = app.packages.iter().filter(|p| !p.selected).collect();

    let mut lines: Vec<Line> = vec![
        Line::from(Span::styled(box_top(bw), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(
                format!("{:^width$}", format!("AWAKENING MANIFEST  //  {} COMPONENTS SCHEDULED", sel.len()), width = bw - 4),
                wh(),
            ),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(box_bot(bw), wh2())),
        Line::from(""),
        Line::from(Span::styled("  SELECTED COMPONENTS", g())),
    ];

    for p in &sel {
        lines.push(Line::from(vec![
            Span::styled("  |  ", dim()),
            Span::styled("[x]  ", g()),
            Span::styled(format!("{:<18}", p.necron), wh()),
            Span::styled(p.desc.as_str(), dim()),
        ]));
    }

    if !skp.is_empty() {
        lines.push(Line::from(""));
        lines.push(Line::from(Span::styled("  SKIPPED", dim())));
        for p in &skp {
            lines.push(Line::from(vec![
                Span::styled("  |  ", dim()),
                Span::styled("[ ]  ", dim()),
                Span::styled(format!("{:<18}", p.necron), wh2()),
                Span::styled("SKIPPED", dim()),
            ]));
        }
    }

    lines.push(Line::from(""));
    lines.push(sep(bw));
    lines.push(Line::from(Span::styled("  SUDO PASSWORD REQUIRED", amb())));
    lines.push(Line::from(Span::styled("  You will be prompted during installation. Stay at the terminal.", wh2())));
    lines.push(sep(bw));
    lines.push(Line::from(vec![
        Span::styled("  ", dim()),
        Span::styled("ENTER", hi()),
        Span::styled(" INITIATE AWAKENING SEQUENCE   ", wh2()),
        Span::styled("Q", red()),
        Span::styled(" back", wh2()),
    ]));

    let render_h = lines.len().min(area.height.saturating_sub(2) as usize) as u16;
    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        Rect { x: area.x + bx, y: by, width: bw as u16, height: render_h },
    );
}

// ── Installing (3-pane) ───────────────────────────────────────────────────────

fn draw_installing(f: &mut Frame, area: Rect, app: &App) {
    // Layout: left 22% | centre flex | right 22% | bottom resbar
    let resbar_h: u16 = 1;
    let main_area = Rect { height: area.height.saturating_sub(resbar_h), ..area };
    let resbar_area = Rect { y: area.y + main_area.height, height: resbar_h, ..area };

    let lw = (main_area.width as f32 * 0.22) as u16;
    let rw = lw;
    let cw = main_area.width.saturating_sub(lw + rw);

    let left_area   = Rect { x: main_area.x,            width: lw, ..main_area };
    let centre_area = Rect { x: main_area.x + lw,        width: cw, ..main_area };
    let right_area  = Rect { x: main_area.x + lw + cw,  width: rw, ..main_area };

    draw_lpane(f, left_area, app);
    draw_cpane(f, centre_area, app);
    draw_rpane(f, right_area, app);
    draw_resbar(f, resbar_area, app);
}

fn draw_lpane(f: &mut Frame, area: Rect, app: &App) {
    let mut lines = vec![
        Line::from(Span::styled("DERMAL MANIFEST", wh())),
        sep(area.width as usize),
    ];

    for cat in MANIFEST {
        let cat_label = format!("── {} {}", cat.label, "─".repeat(
            (area.width as usize).saturating_sub(cat.label.len() + 4)
        ));
        lines.push(Line::from(Span::styled(cat_label, teal())));

        for def in cat.pkgs {
            if let Some(entry) = app.packages.iter().find(|p| p.id == def.id) {
                let col = if entry.selected { wh() } else { dim() };
                let col2 = if entry.selected { dim() } else { Style::default().fg(Color::Rgb(0, 25, 0)) };
                lines.push(Line::from(Span::styled(format!("  {}", entry.necron), col)));
                lines.push(Line::from(Span::styled(format!("  {}", entry.desc),   col2)));
            }
        }
    }

    lines.push(sep(area.width as usize));
    lines.push(Line::from(Span::styled("  tomb world awaits", dim())));

    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        area,
    );
}

fn draw_cpane(f: &mut Frame, area: Rect, app: &App) {
    let pct = app.install_pct();
    let done = app.screen == Screen::Codex;

    let status_line = if done {
        Line::from(Span::styled("installation complete", hi()))
    } else if app.install_rx.is_some() {
        let blink = if (app.tick / 10) % 2 == 0 { "installing..." } else { "installing.  " };
        Line::from(Span::styled(blink, wh2()))
    } else {
        Line::from(Span::styled("awaiting directive", dim()))
    };

    let gauge_label = format!("{}%", pct);
    let gauge = Gauge::default()
        .gauge_style(g())
        .percent(pct)
        .label(gauge_label);

    // Header
    let mut header = vec![
        Line::from(Span::styled("LIVE OUTPUT", wh())),
        sep(area.width as usize),
    ];

    let header_h: u16 = 2;
    let gauge_h:  u16 = 1;
    let status_h: u16 = 1;
    let sep2_h:   u16 = 1;
    let log_y = area.y + header_h + gauge_h + status_h + sep2_h;
    let log_h = area.height.saturating_sub(header_h + gauge_h + status_h + sep2_h);

    f.render_widget(
        Paragraph::new(header).style(Style::default().bg(Color::Black)),
        Rect { height: header_h, ..area },
    );
    f.render_widget(
        gauge,
        Rect { x: area.x, y: area.y + header_h, width: area.width, height: gauge_h },
    );
    f.render_widget(
        Paragraph::new(vec![status_line]).style(Style::default().bg(Color::Black)),
        Rect { x: area.x, y: area.y + header_h + gauge_h, width: area.width, height: status_h },
    );
    f.render_widget(
        Paragraph::new(vec![sep(area.width as usize)]).style(Style::default().bg(Color::Black)),
        Rect { x: area.x, y: area.y + header_h + gauge_h + status_h, width: area.width, height: sep2_h },
    );

    // Log lines — show last N that fit
    let visible = log_h as usize;
    let start   = app.log_lines.len().saturating_sub(visible);
    let log_lines: Vec<Line> = app.log_lines[start..].iter().map(|(s, c)| {
        Line::from(Span::styled(s.clone(), Style::default().fg(*c)))
    }).collect();

    f.render_widget(
        Paragraph::new(log_lines).style(Style::default().bg(Color::Black)),
        Rect { x: area.x, y: log_y, width: area.width, height: log_h },
    );
}

fn draw_rpane(f: &mut Frame, area: Rect, app: &App) {
    let selected: Vec<&PkgEntry> = app.packages.iter().filter(|p| p.selected).collect();
    let done_count = selected.iter().filter(|p| {
        matches!(p.status, PkgStatus::Ok | PkgStatus::Skipped | PkgStatus::Failed)
    }).count();

    let mut lines = vec![
        Line::from(vec![
            Span::styled("STAGE STATUS ", wh()),
            Span::styled(format!("[{}/{}]", done_count, selected.len()), wh2()),
        ]),
        sep(area.width as usize),
    ];

    for entry in &selected {
        let (icon, col) = match entry.status {
            PkgStatus::Active  => ("►", Color::Green),
            PkgStatus::Ok      => ("✓", Color::Green),
            PkgStatus::Failed  => ("✗", Color::Red),
            PkgStatus::Skipped => ("·", Color::Yellow),
            PkgStatus::Pending => ("·", Color::Rgb(0, 40, 0)),
        };
        let name_col = match entry.status {
            PkgStatus::Pending => Style::default().fg(Color::Rgb(0, 30, 0)),
            _ => Style::default().fg(col),
        };
        lines.push(Line::from(vec![
            Span::styled(format!("{} ", icon), Style::default().fg(col)),
            Span::styled(entry.necron.as_str(), name_col),
        ]));
    }

    if app.screen == Screen::Codex {
        lines.push(sep(area.width as usize));
        lines.push(Line::from(Span::styled("SEQUENCE COMPLETE", hi())));
    }

    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        area,
    );
}

fn draw_resbar(f: &mut Frame, area: Rect, app: &App) {
    let elapsed = app.elapsed_secs();
    let line = Line::from(vec![
        Span::styled("  CPU --  RAM --  DISK --   ", dim()),
        Span::styled("↑↓", wh2()), Span::styled(" navigate   ", dim()),
        Span::styled("SPACE", wh2()), Span::styled(" toggle   ", dim()),
        Span::styled("ENTER", wh2()), Span::styled(" confirm   ", dim()),
        Span::styled("Q/ESC", wh2()), Span::styled(" back   ", dim()),
        Span::styled(format!("elapsed {:02}:{:02}", elapsed / 60, elapsed % 60), dim()),
    ]);
    f.render_widget(
        Paragraph::new(vec![line]).style(Style::default().bg(Color::Black)),
        area,
    );
}

// ── Codex (done screen) ───────────────────────────────────────────────────────

fn draw_codex(f: &mut Frame, area: Rect, app: &App) {
    let w  = area.width as usize;
    let bw = w.min(68);
    let bx = ((w - bw) / 2) as u16;
    let by = area.y + 1;

    let pulse = if (app.tick / 20) % 2 == 0 { hi() } else { g() };

    let mut lines: Vec<Line> = vec![
        Line::from(Span::styled(box_top(bw), wh2())),
        Line::from(vec![
            Span::styled("|  ", wh2()),
            Span::styled(format!("{:^width$}", "T H E   N E C R O D E R M I S   P R O T O C O L", width = bw - 4), wh()),
            Span::styled("  |", wh2()),
        ]),
        Line::from(Span::styled(box_bot(bw), wh2())),
        Line::from(""),
        Line::from(vec![Span::styled("  |  ", dim()), Span::styled("Tomb world conversion complete.", hi())]),
        Line::from(vec![Span::styled("  |", dim())]),
        Line::from(vec![Span::styled("  |  The living metal has been applied. Your system", wh2())]),
        Line::from(vec![Span::styled("  |  now bears the Necrodermis. Canoptek constructs standing by.", wh2())]),
        Line::from(vec![Span::styled("  |", dim())]),
        sep(bw),
        Line::from(Span::styled("  INSTALL REPORT", wh())),
        Line::from(vec![
            Span::styled("  [ OK  ]  ", g()),
            Span::styled(format!("{} component{} installed", app.ok_count, if app.ok_count != 1 { "s" } else { "" }), wh()),
        ]),
        Line::from(vec![
            Span::styled("  [SKIP ]  ", amb()),
            Span::styled(format!("{} already present", app.skip_count), wh2()),
        ]),
        if app.fail_count > 0 {
            Line::from(vec![
                Span::styled("  [FAIL ]  ", red()),
                Span::styled(format!("{} failed — see error log", app.fail_count), wh()),
            ])
        } else {
            Line::from(vec![Span::styled("  [FAIL ]  0 failures", dim())])
        },
        sep(bw),
        Line::from(vec![Span::styled("  NEXT STEPS", wh())]),
        Line::from(vec![Span::styled("  1  ", teal()), Span::styled("Log out and back in, or reboot", wh2())]),
        Line::from(vec![Span::styled("  2  ", teal()), Span::styled("SDDM active on next boot", wh2())]),
        Line::from(vec![Span::styled("  3  ", teal()), Span::styled("Run ", wh2()), Span::styled("sitrep", g()), Span::styled(" to confirm sensors", wh2())]),
        Line::from(vec![Span::styled("  4  ", teal()), Span::styled("necrodermis-uninstall", g()), Span::styled(" to revert", wh2())]),
        sep(bw),
        Line::from(Span::styled("  ORGANIC MATTER IS TEMPORARY", pulse)),
        Line::from(Span::styled("  NECRODERMIS IS ETERNAL", dim())),
        Line::from(""),
        Line::from(vec![
            Span::styled("  ", dim()),
            Span::styled("ENTER/Q", hi()),
            Span::styled(" exit   ", wh2()),
            if !app.fail_log.is_empty() {
                Span::styled("E  error log", red())
            } else {
                Span::styled("E  error log (none)", dim())
            },
        ]),
    ];

    let render_h = lines.len().min(area.height.saturating_sub(2) as usize) as u16;
    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        Rect { x: area.x + bx, y: by, width: bw as u16, height: render_h },
    );
}

// ── Error log ─────────────────────────────────────────────────────────────────

fn draw_errorlog(f: &mut Frame, area: Rect, app: &App) {
    let w  = area.width as usize;
    let bw = w.min(68);
    let bx = ((w - bw) / 2) as u16;
    let by = area.y + 1;

    let mut lines: Vec<Line> = vec![
        Line::from(Span::styled(
            format!("  ERROR LOG  //  {} FAILURE{}", app.fail_count, if app.fail_count != 1 { "S" } else { "" }),
            red(),
        )),
        sep(bw),
        Line::from(Span::styled("  FAILED COMPONENTS", red())),
        Line::from(""),
    ];

    for (name, msg) in &app.fail_log {
        lines.push(Line::from(vec![
            Span::styled("  [FAIL ]  ", red()),
            Span::styled(name.as_str(), wh()),
        ]));
        lines.push(Line::from(vec![
            Span::styled(format!("           {}", msg), wh2()),
        ]));
        lines.push(Line::from(""));
    }

    lines.push(sep(bw));
    lines.push(Line::from(Span::styled("  RECOVERY OPTIONS", amb())));
    lines.push(Line::from(vec![Span::styled("  ·  Full log at ", wh2()), Span::styled("~/.local/share/necrodermis/install.log", g())]));
    lines.push(Line::from(Span::styled("  ·  Re-run the installer — failed components can be retried", wh2())));
    lines.push(Line::from(Span::styled("  ·  Check your internet connection and pacman keyring", wh2())));
    lines.push(Line::from(vec![Span::styled("  ·  ", wh2()), Span::styled("sudo pacman -Sy archlinux-keyring", g()), Span::styled("  then retry", wh2())]));
    lines.push(sep(bw));
    lines.push(Line::from(vec![
        Span::styled("  ", dim()),
        Span::styled("Q/ESC", hi()),
        Span::styled(" back to codex", wh2()),
    ]));

    let render_h = lines.len().min(area.height.saturating_sub(2) as usize) as u16;
    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        Rect { x: area.x + bx, y: by, width: bw as u16, height: render_h },
    );
}

// ── Aborted ───────────────────────────────────────────────────────────────────

fn draw_aborted(f: &mut Frame, area: Rect) {
    let w  = area.width as usize;
    let bw = w.min(50);
    let bx = ((w - bw) / 2) as u16;
    let by = area.y + area.height / 3;

    let lines = vec![
        Line::from(Span::styled(box_top(bw), wh2())),
        Line::from(Span::styled("  DIRECTIVE ABORTED", red())),
        Line::from(Span::styled(box_bot(bw), wh2())),
        Line::from(""),
        Line::from(Span::styled("  No directive received  //  the tomb remains sealed.", wh2())),
        Line::from(Span::styled("  The silent king returns to stasis.", dim())),
        Line::from(""),
        Line::from(vec![Span::styled("  ENTER/Q", hi()), Span::styled(" exit", wh2())]),
    ];

    f.render_widget(
        Paragraph::new(lines).style(Style::default().bg(Color::Black)),
        Rect { x: area.x + bx, y: by, width: bw as u16, height: 8 },
    );
}
