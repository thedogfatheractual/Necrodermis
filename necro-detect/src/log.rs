const RESET: &str = "\x1b[0m";
const GREEN: &str = "\x1b[32m";
const RED:   &str = "\x1b[31m";
const AMBER: &str = "\x1b[33m";
const DIM:   &str = "\x1b[2m";
const BOLD:  &str = "\x1b[1m";

pub enum LogStatus {
    Ok,
    Fail,
    Skip,
}

pub fn necro_log(status: LogStatus, msg: &str) {
    let (color, label) = match status {
        LogStatus::Ok   => (GREEN, " OK  "),
        LogStatus::Fail => (RED,   "FAIL "),
        LogStatus::Skip => (AMBER, "SKIP "),
    };
    println!(
        "{DIM}[{RESET}{BOLD}{color}{label}{RESET}{DIM}]{RESET}  {msg}",
        DIM = DIM, RESET = RESET, BOLD = BOLD, color = color, label = label, msg = msg,
    );
}
