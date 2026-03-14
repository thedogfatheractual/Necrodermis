mod detect;
mod pkg;
mod log;
mod tui;

use std::io;
use crossterm::terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen};
use crossterm::ExecutableCommand;
use ratatui::prelude::*;

fn main() -> io::Result<()> {
    let (id, id_like) = detect::detect_distro();
    let family = detect::distro_family(&id, &id_like).to_string();

    enable_raw_mode()?;
    io::stdout().execute(EnterAlternateScreen)?;

    let mut terminal = Terminal::new(CrosstermBackend::new(io::stdout()))?;
    let mut app = tui::App::new(id, family);

    let result = tui::run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    io::stdout().execute(LeaveAlternateScreen)?;

    result
}
