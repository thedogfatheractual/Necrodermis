mod detect;
mod pkg;
mod log;
mod tui;

use std::io::{self, Write};
use std::process::Command;
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::ExecutableCommand;
use ratatui::prelude::*;

fn sudo_prompt() {
    // Already have sudo? Refresh the timestamp and return immediately.
    if Command::new("sudo").args(["-n", "true"]).status()
        .map(|s| s.success()).unwrap_or(false)
    {
        // Extend the sudo timeout so it doesn't expire mid-install
        let _ = Command::new("sudo").args(["-v"]).status();
        return;
    }

    // Clear the screen and show a hard-to-miss prompt
    print!("\x1b[2J\x1b[H"); // clear + home
    io::stdout().flush().unwrap();

    println!();
    println!("  ╔══════════════════════════════════════════════════════════════╗");
    println!("  ║                                                              ║");
    println!("  ║          N E C R O D E R M I S   I N S T A L L E R         ║");
    println!("  ║                                                              ║");
    println!("  ║   Root access is required to graft the Necrodermis layer.   ║");
    println!("  ║                                                              ║");
    println!("  ║   Enter your sudo password below.                           ║");
    println!("  ║   You will NOT be prompted again during installation.        ║");
    println!("  ║                                                              ║");
    println!("  ╚══════════════════════════════════════════════════════════════╝");
    println!();
    print!("  sudo password: ");
    io::stdout().flush().unwrap();

    // Use sudo -S with a visible prompt — this reads from the real tty
    // before raw mode is enabled, so the password prompt works normally.
    let status = Command::new("sudo")
        .args(["-v", "--prompt="])   // -v validates + extends, --prompt= suppresses default prompt
        .status();

    match status {
        Ok(s) if s.success() => {
            println!();
            println!("  \x1b[32m✓ Access granted. Initiating awakening sequence...\x1b[0m");
            println!();
            std::thread::sleep(std::time::Duration::from_millis(900));
        }
        _ => {
            println!();
            println!("  \x1b[31m✗ Authentication failed. The tomb remains sealed.\x1b[0m");
            println!();
            std::process::exit(1);
        }
    }

    // Spawn a background thread that refreshes sudo every 60s
    // so it never expires mid-install regardless of how long packages take.
    std::thread::spawn(|| {
        loop {
            std::thread::sleep(std::time::Duration::from_secs(60));
            let _ = Command::new("sudo").args(["-v"]).status();
        }
    });
}

fn main() -> io::Result<()> {
    let (id, id_like) = detect::detect_distro();
    let family = detect::distro_family(&id, &id_like).to_string();

    // Grab sudo BEFORE raw mode — full terminal, unmissable prompt
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
