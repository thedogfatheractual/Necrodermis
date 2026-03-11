# NECRODERMIS — SAUTEKH DYNASTY

```
STASIS DURATION: 60,247,891 YRS  //  47 MAINTENANCE FAULTS UNRESOLVED
RESURRECTION PROTOCOLS: ONLINE
```

> *The Silent King stirs. The stars remember.*

---

Necrodermis is a Hyprland desktop theme built on the visual language of the Necrons — ancient, clinical, cold. Green phosphor on black. It skins your entire desktop into a unified tombworld aesthetic. Every component talks to every other component.

Built on the scaffolding of **JaKooLit's Hyprland-Dots**. Give them a star: https://github.com/JaKooLit/Arch-Hyprland

---

## REQUIREMENTS

- Arch Linux, CachyOS, Manjaro, or EndeavourOS
- An internet connection

---

## INSTALL

```bash
git clone https://github.com/thedogfatheractual/Necrodermis.git
cd Necrodermis
bash install.sh
```

Choose **Theme only** to skin an existing Hyprland setup, or **Full install** to deploy everything from scratch. Nothing is overwritten without a backup first — previous configs are archived to `~/.config/necrodermis-backup-<timestamp>/`.

---

## UPDATE

```bash
cd ~/necrodermis && bash update.sh
```

Pulls the latest from the repo and redeploys only what has changed. No reinstall needed.

---

## UNINSTALL

```bash
necrodermis-uninstall
```

Registered automatically during install. Removes components one by one and restores backups where they exist. If the command isn't available: `~/.local/share/necrodermis/uninstall.sh`

---

## WHAT'S INCLUDED

| Component | Details |
|---|---|
| **SDDM** | Custom login screen — weather, moon phase, ASCII art, Necron lore |
| **Hyprland** | Keybinds, decorations, window rules — JaKooLit framework |
| **Waybar** | Status bar |
| **Rofi** | Application launcher — Canoptek Protocols |
| **Kitty** | Terminal |
| **GTK3/4** | Necrodermis-green-Dark-compact |
| **Qt6/Kvantum** | Qt application skin |
| **Btop** | Process monitor |
| **Cava** | Audio visualiser |
| **Fastfetch** | System info with Necron ASCII art |
| **Swaync** | Notification centre |
| **Icons** | Flat-Remix-Necrodermis recolour |
| **Wallpapers** | Necron art — `~/Pictures/wallpapers/necrodermis/` |
| **GRUB** | Boot theme |
| **Plymouth** | Splash screen — tomb world awakening sequence |
| **Fish** | Shell aliases — `sysupdate`, `sysclean` |

---

## CREDITS

- **JaKooLit** — Hyprland-Dots framework https://github.com/JaKooLit/Arch-Hyprland
- **Keyitdev** — sddm-astronaut-theme (GPLv3+) https://github.com/Keyitdev/sddm-astronaut-theme
- **ChrisTitusTech** — linutil https://github.com/ChrisTitusTech
- **ML4W** — Hyprland dotfiles https://github.com/mylinuxforwork/dotfiles

---

```
ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL
```

---

*Warhammer 40,000 and all associated lore, imagery, and terminology are the property of Games Workshop Ltd. This is an unofficial fan work. All referenced tools and frameworks remain the property of their original creators.*
