# NECRODERMIS — ENTIRE SYSTEM CONVERSION

```
STASIS DURATION: 60,247,891 YRS  //  47 MAINTENANCE FAULTS UNRESOLVED
LAST DIAGNOSTIC: 4,891 YEARS AGO  //  TOMB INTEGRITY BREACH DETECTED
RESURRECTION PROTOCOLS: ONLINE
```

> *The Silent King stirs. The stars remember.*

---

## WHAT IS THIS

Necrodermis is a Hyprland desktop theme built on the visual language of the Necrons — ancient, clinical, cold. Green phosphor on black. Diagnostic tone. 60 million years of deferred maintenance and absolutely zero patience for organic matter.

It is not subtle. It is not trying to be.

It skins your entire desktop — login screen, terminal, file manager, status bar, notifications, application launcher, audio visualiser, system monitor — into a unified tomb world aesthetic. Every component talks to every other component. It looks like one thing, not a pile of configs stapled together.

---

## CREDITS

Necrodermis is built on the scaffolding of **JaKooLit's Hyprland-Dots** — one of the finest Hyprland configurations available. The wallpaper system, startup scripts, keybind framework, window rules, and core DE infrastructure are their work. We do not claim otherwise.

**JaKooLit — Hyprland-Dots**
https://github.com/JaKooLit/Arch-Hyprland

Give them a star. They earned it.

Necrodermis contributes: visual theme, SDDM login experience, GTK/Qt styling, btop theme, icon recolour, weather widget, and lore layer.

SDDM theme base: **sddm-astronaut-theme** by Keyitdev (GPLv3+)
https://github.com/Keyitdev/sddm-astronaut-theme

---

## REQUIREMENTS

- Arch Linux based distro
- An internet connection
- Git
- That's it — the installer handles everything else

If you don't have Hyprland, select **Full install** mode. The installer will launch JaKooLit's setup — follow their prompts, and once complete, Necrodermis layers on top automatically.

---

## INSTALL

```bash
git clone https://github.com/thedogfatheractual/Necrodermis.git
cd Necrodermis
bash install.sh
```

The installer will ask you:

1. **Theme only** — skins an existing Hyprland setup, component by component, your choice what gets installed
2. **Full install** — sets up a complete Arch desktop via JaKooLit, then layers Necrodermis on top

Nothing is overwritten without a backup being taken first. Your previous configs are archived to `~/.config/necrodermis-backup-<timestamp>/` before anything is touched.

During SDDM setup you'll be asked for your nearest city or airport — this powers the weather widget on the login screen. You can skip it if you don't want weather.

---

## UNINSTALL

```bash
necrodermis-uninstall
```

That's it. The command is registered automatically during install. It will walk you through removing components one by one and restore your previous configs from backup where they exist.

If for some reason the command isn't available:

```bash
~/.local/share/necrodermis/uninstall.sh
```

---

## WHAT'S INCLUDED

| Component | Details |
|---|---|
| **SDDM** | Custom login screen — weather, moon phase, ASCII art, Necron lore — built on sddm-astronaut-theme |
| **Hyprland** | Keybinds, decorations, defaults — built on JaKooLit's framework |
| **Waybar** | Status bar — Necrodermis green palette |
| **Rofi** | Application launcher |
| **Kitty** | Terminal configuration |
| **GTK3/4** | System-wide GTK theme — Necrodermis-green-Dark-compact |
| **Qt6/Kvantum** | Qt application skin |
| **Btop** | Process monitor — custom Necrodermis theme |
| **Cava** | Audio visualiser |
| **Fastfetch** | System info display with Necron warrior ASCII art |
| **Swaync** | Notification centre |
| **Icons** | Flat-Remix-Necrodermis recolour |
| **Wallpapers** | Curated Necron art — installed to `~/Pictures/wallpapers/necrodermis/` |
| **GRUB** | Boot theme — Sautekh visual override for the bootloader |
| **Plymouth** | Initramfs splash screen — tomb world awakening sequence |
| **Firewall** | ufw — deny-all incoming, LAN-scoped rules for Steam, Sunshine, Transmission |
| **Hardening** | Kernel params, core dumps disabled, LLMNR off, root lock, hidepid |
| **CachyOS Repos** | Optimised package repos, CachyOS kernel, scx schedulers, gaming meta — v3/v4 CPUs only |
| **Fish** | Shell aliases — `sysupdate`, `sysclean` |

---

## SDDM WEATHER WIDGET

The login screen weather system is powered by the core of the **sitrep** project — a companion tool for pulling and rendering METAR weather data with ASCII art.

For details on how it works, see the sitrep repo:
https://github.com/thedogfatheractual/sitrep

Location is configured during install. To change it afterwards, edit the ICAO code in `/usr/share/sddm/themes/sddm-astronaut-theme/weather.sh`.

---

## SYSTEM ALIASES

Two aliases are added to your Fish config:

```fish
sysupdate   # yay -Syyu — full system + AUR update in one shot
sysclean    # clears package cache, removes orphans, trims logs, clears temp
```

---

## FIREWALL

Necrodermis installs **ufw** (Uncomplicated Firewall) with a hardened default policy:

- **Incoming:** deny all by default
- **Outgoing:** allow all
- **LAN rules** scoped to your local subnet (auto-detected during install)

### What's open out of the box

| Port(s) | Proto | Scope | Service |
|---|---|---|---|
| 27036 | TCP + UDP | LAN only | Steam Remote Play |
| 47984, 47989, 48010 | TCP | LAN only | Sunshine (HTTPS / HTTP / RTSP) |
| 47998, 47999, 48000, 48010 | UDP | LAN only | Sunshine (video / control / audio / mic) |
| 59480 | TCP + UDP | Anywhere | Transmission (BitTorrent peer port) |
| 6771 | UDP | LAN only | Transmission local peer discovery |
| 5353 | UDP | LAN only | mDNS (local network discovery) |
| 5355 | TCP + UDP | — | LLMNR — **blocked** |
| 22 | TCP | Anywhere | SSH — rate limited, **SSH itself not enabled** |

### How to open a port

```bash
# Allow a port globally
sudo ufw allow 8096/tcp comment "Jellyfin"

# Allow a port from your LAN only (safer)
sudo ufw allow from 10.0.0.0/24 to any port 8096 proto tcp comment "Jellyfin LAN"

# Allow a range of ports
sudo ufw allow 6881:6891/tcp comment "qBittorrent"

# Check what's currently open
sudo ufw status numbered

# Remove a rule by number
sudo ufw delete 5
```

### How to check your LAN subnet

```bash
ip route | grep -v default
```

The result will look like `10.0.0.0/24` or `192.168.1.0/24` — use that in your `from` rules to scope them to LAN only.

### Common applications

```bash
# Jellyfin
sudo ufw allow from 10.0.0.0/24 to any port 8096 proto tcp comment "Jellyfin"

# Syncthing
sudo ufw allow 22000/tcp comment "Syncthing TCP"
sudo ufw allow 22000/udp comment "Syncthing UDP"
sudo ufw allow from 10.0.0.0/24 to any port 8384 proto tcp comment "Syncthing UI"

# KDE Connect / GSConnect
sudo ufw allow 1714:1764/tcp comment "KDE Connect"
sudo ufw allow 1714:1764/udp comment "KDE Connect"

# SSH (if you need it)
sudo ufw allow 22/tcp comment "SSH"
```

### Disable / re-enable

```bash
sudo ufw disable   # turns it off (rules preserved)
sudo ufw enable    # turns it back on
sudo ufw reset     # wipes all rules — clean slate
```

---

## SYSTEM HARDENING

Necrodermis applies a set of security hardening measures during installation. Each one is optional and fully reversible.

### What gets hardened

| What | How | Reversible |
|---|---|---|
| Kernel network params | Disables IP forwarding, ICMP redirects, source routing, enables SYN cookies and martian logging | Delete `/etc/sysctl.d/99-necrodermis-hardening.conf` |
| Core dumps | Disabled — sensitive memory stays off disk | Delete `/etc/systemd/coredump.conf.d/necrodermis.conf` |
| LLMNR | Disabled in systemd-resolved — it's an info leak with no practical use | Delete `/etc/systemd/resolved.conf.d/necrodermis.conf` |
| ptrace scope | Set to 1 — processes can only trace their own children | Same sysctl file above |
| dmesg / kptr | Restricted to root — hides hardware info from unprivileged processes | Same sysctl file above |
| ASLR | Explicitly set to full (randomize_va_space=2) — probably already on | Same sysctl file above |
| Root account | Locked — direct root login disabled, sudo unaffected | `sudo passwd -u root` |
| /proc hidepid | Other users can't see your processes (single-user: mostly academic) | Remove hidepid line from `/etc/fstab` |
| umask 027 | New files aren't world-readable by default | Remove from `~/.config/fish/config.fish` |

### If something breaks

The sysctl file is self-contained and clearly labelled. To nuke all kernel hardening at once:

```bash
sudo rm /etc/sysctl.d/99-necrodermis-hardening.conf
sudo sysctl --system
```

To unlock root if you need it:

```bash
sudo passwd -u root
```

To remove hidepid:

```bash
sudo vim /etc/fstab   # remove the line containing hidepid
# reboot
```

Or just run `necrodermis-uninstall` and select hardening — it handles all of the above interactively.

---

## CACHYOS REPOSITORIES

On compatible hardware, Necrodermis can add the CachyOS repositories to any Arch-based system — EndeavourOS, vanilla Arch, Manjaro — and transform it into something approaching a CachyOS install.

### Hardware requirement

CachyOS packages are compiled for **x86-64-v3 minimum** (AVX2, BMI2). This means:

| CPU Generation | Level | Compatible |
|---|---|---|
| Intel Haswell (2013) and newer | v3+ | ✅ |
| AMD Ryzen (Zen+) and newer | v3+ | ✅ |
| Intel Ivy Bridge / Sandy Bridge | v2 | ❌ |
| AMD pre-Ryzen | v2 or lower | ❌ |

The installer detects your CPU level automatically and skips this section if your hardware can't run it.

### What gets added

- **CachyOS repos** — packages recompiled with LTO, PGO, and x86-64-v3/v4 flags. Faster binaries system-wide.
- **CachyOS kernel** (`linux-cachyos`) — BORE scheduler, full CachyOS compile flags, lower latency
- **scx-scheds** — userspace schedulers. `scx_lavd` is the one you want: latency-aware, gaming-optimised, autopilot mode just works
- **cachyos-gaming-meta** — gamemode, mangohud, proton-cachyos, wine-cachyos, and supporting tools in one package

### After installing the CachyOS kernel

If you're on GRUB:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Then reboot and select `linux-cachyos` from the boot menu. Once confirmed working, you can set it as default in `/etc/default/grub`.

### Switching schedulers

```bash
# Check what's running
scx_layered --help   # or whichever you want to test

# Change the default
sudo vim /etc/scx.conf
# Set SCX_SCHEDULER=scx_lavd (or scx_bpfland, scx_rustland, etc.)
sudo systemctl restart scx
```

---

## SCREENSHOTS

![Necrodermis](assets/screenshot.png)

---

```
ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL
```

The Sautekh Dynasty does not theme desktops.
It awakens them.

---

*Warhammer 40,000 and all associated lore, imagery, and terminology are the property of Games Workshop Ltd. This project is a fan work — unofficial, unaffiliated, not endorsed.*

*All other works, tools, themes, and frameworks referenced or incorporated in this project remain the property of their original creators. All credit belongs to them. The CREDITS section above acknowledges some of the key works this project builds on, but is not exhaustive — this project would not exist without the broader open source community and all the work that underpins it.*
