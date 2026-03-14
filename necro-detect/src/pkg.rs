use std::collections::HashMap;
use std::fs::OpenOptions;
use std::process::{Command, Stdio};

#[derive(Debug, Clone, PartialEq)]
pub enum PackageManager {
    Pacman,
    Yay,
    Dnf,
    Zypper,
    Xbps,
}

pub fn build_pkg_map() -> HashMap<String, String> {
    let mut map = HashMap::new();

    map.insert("arch:rofi".into(),    "rofi-wayland".into());
    map.insert("cachyos:rofi".into(), "rofi-wayland".into());
    map.insert("manjaro:rofi".into(), "rofi-wayland".into());

    map.insert("arch:swaync".into(),     "swaynotificationcenter".into());
    map.insert("cachyos:swaync".into(),  "swaynotificationcenter".into());
    map.insert("manjaro:swaync".into(),  "swaynotificationcenter".into());
    map.insert("fedora:swaync".into(),   "swaynotificationcenter".into());
    map.insert("opensuse:swaync".into(), "SwayNotificationCenter".into());
    map.insert("void:swaync".into(),     "swaynotificationcenter".into());

    map.insert("arch:nerd-fonts-terminess".into(),    "ttf-terminus-nerd".into());
    map.insert("cachyos:nerd-fonts-terminess".into(), "ttf-terminus-nerd".into());
    map.insert("fedora:nerd-fonts-terminess".into(),  "terminus-fonts".into());
    map.insert("void:nerd-fonts-terminess".into(),    "terminus-font".into());

    map.insert("fedora:pipewire-pulse".into(),   "pipewire-pulseaudio".into());
    map.insert("opensuse:pipewire-pulse".into(), "pipewire-pulseaudio".into());

    map.insert("arch:python3".into(),    "python".into());
    map.insert("cachyos:python3".into(), "python".into());
    map.insert("manjaro:python3".into(), "python".into());

    map.insert("arch:networkmanager-applet".into(),    "network-manager-applet".into());
    map.insert("cachyos:networkmanager-applet".into(), "network-manager-applet".into());
    map.insert("manjaro:networkmanager-applet".into(), "network-manager-applet".into());

    // brave — AUR only on arch-based
    map.insert("arch:brave".into(),    "brave-bin".into());
    map.insert("cachyos:brave".into(), "brave-bin".into());
    map.insert("manjaro:brave".into(), "brave-bin".into());
    map.insert("fedora:brave".into(),  "brave-browser".into());

    // vesktop — correct package name (was typo'd as vesktopalled)
    map.insert("arch:vesktop".into(),    "vesktop".into());
    map.insert("cachyos:vesktop".into(), "vesktop".into());
    map.insert("manjaro:vesktop".into(), "vesktop-bin".into());

    // gtk — map to nwg-look for GTK theming on Wayland
    map.insert("arch:gtk".into(),    "nwg-look".into());
    map.insert("cachyos:gtk".into(), "nwg-look".into());
    map.insert("fedora:gtk".into(),  "nwg-look".into());

    map
}

pub fn resolve_pkg(map: &HashMap<String, String>, distro: &str, pkg: &str) -> String {
    let key = format!("{}:{}", distro, pkg);
    map.get(&key).cloned().unwrap_or_else(|| pkg.to_string())
}

pub fn is_installed(pkg: &str) -> bool {
    Command::new("pacman")
        .args(["-Q", pkg])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

#[derive(Debug)]
pub enum InstallResult {
    Ok,
    Failed(String),
    Skipped(String),
}

pub fn do_install(pkg_mgr: &PackageManager, pkgs: &[&str]) -> Vec<(String, InstallResult)> {
    let mut results = Vec::new();

    for pkg in pkgs {
        if is_installed(pkg) {
            results.push((
                pkg.to_string(),
                InstallResult::Skipped(format!("{} already installed", pkg)),
            ));
            continue;
        }

        let log_file = OpenOptions::new()
            .create(true).append(true)
            .open("/tmp/necrodermis-install.log")
            .ok()
            .map(Stdio::from);
        let stderr_sink = log_file.unwrap_or_else(Stdio::null);

        let status = match pkg_mgr {
            PackageManager::Pacman => Command::new("sudo")
                .args(["pacman", "-S", "--needed", "--noconfirm", pkg])
                .stdout(Stdio::null())
                .stderr(stderr_sink)
                .status(),
            PackageManager::Yay => Command::new("yay")
                .args(["-S", "--needed", "--noconfirm", pkg])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status(),
            PackageManager::Dnf => Command::new("sudo")
                .args(["dnf", "install", "-y", pkg])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status(),
            PackageManager::Zypper => Command::new("sudo")
                .args(["zypper", "install", "-y", "--no-confirm", pkg])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status(),
            PackageManager::Xbps => Command::new("sudo")
                .args(["xbps-install", "-Sy", pkg])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status(),
        };

        let result = match status {
            Ok(s) if s.success() => InstallResult::Ok,
            Ok(s) => InstallResult::Failed(
                format!("exited with code {}", s.code().unwrap_or(-1))
            ),
            Err(e) => InstallResult::Failed(
                format!("failed to launch: {}", e)
            ),
        };

        results.push((pkg.to_string(), result));
    }

    results
}
