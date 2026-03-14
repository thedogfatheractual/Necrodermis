mod detect;
mod pkg;
mod log;
mod tui;

use std::io::{self, Write};
use std::process::{Command, Stdio};
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::ExecutableCommand;
use ratatui::prelude::*;

fn sudo_prompt() {
    // Already cached and valid — just refresh silently and return
    if Command::new("sudo")
        .args(["-n", "true"])
        .stdout(Stdio::null()).stderr(Stdio::null())
        .status().map(|s| s.success()).unwrap_or(false)
    {
        let _ = Command::new("sudo")
            .args(["-n", "-v"])
            .stdout(Stdio::null()).stderr(Stdio::null())
            .status();
        spawn_sudo_keepalive();
        return;
    }

    // Clear screen — we're in normal terminal mode here, before raw mode
    print!("\x1b[2J\x1b[H");
    io::stdout().flush().unwrap();

    println!();
    println!("  ╔══════════════════════════════════════════════════════════════╗");
    println!("  ║                                                              ║");
    println!("  ║          N E C R O D E R M I S   I N S T A L L E R         ║");
    println!("  ║                                                              ║");
    println!("  ║   Root access is required to graft the Necrodermis layer.   ║");
    println!("  ║   You will NOT be prompted again during installation.        ║");
    println!("  ║                                                              ║");
    println!("  ╚══════════════════════════════════════════════════════════════╝");
    println!();
    io::stdout().flush().unwrap();

    // Use sudo -v which reads from /dev/tty directly — works before raw mode,
    // and the default prompt "password for user:" appears on the tty naturally.
    let status = Command::new("sudo")
        .arg("-v")
        .status(); // inherits stdin/stdout/stderr — reads from real tty

    println!();
    match status {
        Ok(s) if s.success() => {
            println!("  \x1b[32m✓  Access granted. Initiating awakening sequence...\x1b[0m");
            println!();
            io::stdout().flush().unwrap();
            std::thread::sleep(std::time::Duration::from_millis(800));
        }
        _ => {
            println!("  \x1b[31m✗  Authentication failed. The tomb remains sealed.\x1b[0m");
            println!();
            io::stdout().flush().unwrap();
            std::process::exit(1);
        }
    }

    spawn_sudo_keepalive();
}

fn spawn_sudo_keepalive() {
    // Refresh sudo timestamp every 45s so it never expires during a long install.
    // CRITICAL: stdin/stdout/stderr all null — must NEVER write to terminal
    // once raw mode is active or it will corrupt the TUI.
    std::thread::spawn(|| {
        loop {
            std::thread::sleep(std::time::Duration::from_secs(45));
            let _ = Command::new("sudo")
                .args(["-n", "-v"])           // -n = non-interactive, never prompt
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
        }
    });
}

fn main() -> io::Result<()> {
    let (id, id_like) = detect::detect_distro();
    let family = detect::distro_family(&id, &id_like).to_string();

    // Grab sudo BEFORE raw mode — full terminal, unmissable, reads from real tty
    sudo_prompt();

    enable_raw_mode()?;
    io::stdout().execute(EnterAlternateScreen)?;

    let mut terminal = Terminal::new(CrosstermBackend::new(io::stdout()))?;
    let mut app = tui::App::new(id, family);

    let result = tui::run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    io::stdout().execute(LeaveAlternateScreen)?;

    result
}
