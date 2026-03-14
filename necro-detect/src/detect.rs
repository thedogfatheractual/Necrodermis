use std::fs;

pub fn detect_distro() -> (String, String) {
    let content = fs::read_to_string("/etc/os-release")
        .unwrap_or_default();

    let mut id = String::from("unknown");
    let mut id_like = String::new();

    for line in content.lines() {
        if line.starts_with("ID=") {
            id = line.trim_start_matches("ID=")
                .trim_matches('"')
                .to_lowercase();
        }
        if line.starts_with("ID_LIKE=") {
            id_like = line.trim_start_matches("ID_LIKE=")
                .trim_matches('"')
                .to_lowercase();
        }
    }

    (id, id_like)
}

pub fn distro_family(id: &str, id_like: &str) -> &'static str {
    for check in &[id, id_like] {
        let family = check.split_whitespace().find_map(|word| match word {
            "arch" | "cachyos" | "manjaro" | "endeavouros" => Some("arch"),
            "fedora" | "nobara"                            => Some("fedora"),
            "opensuse-tumbleweed" | "opensuse-leap"        => Some("opensuse"),
            "void"                                         => Some("void"),
            _                                              => None,
        });
        if family.is_some() {
            return family.unwrap();
        }
    }
    "unknown"
}
