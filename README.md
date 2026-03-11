# NECRODERMIS — SAUTEKH DYNASTY

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


**ChrisTitusTech — linutil and the broader Linux education ecosystem**
https://github.com/ChrisTitusTech
If you've spent any time learning Linux properly, you've probably landed on his content. We have.

**ML4W — Hyprland dotfiles and configuration guides**
https://github.com/mylinuxforwork/dotfiles
A reference point for clean Hyprland configuration. Solid work.
SDDM theme base: **sddm-astronaut-theme** by Keyitdev (GPLv3+)
https://github.com/Keyitdev/sddm-astronaut-theme

---

## REQUIREMENTS

- Arch Linux, CachyOS, Manjaro, or EndeavourOS
- An internet connection
- That's it — the installer handles everything else

If you don't have Hyprland, select **Full install** mode. The installer will set up all packages and deploy Necrodermis configs automatically.

---

## INSTALL

```bash
git clone https://github.com/thedogfatheractual/Necrodermis.git
cd Necrodermis
bash install.sh
```

The installer will ask you:

1. **Theme only** — skins an existing Hyprland setup, component by component, your choice what gets installed
2. **Full install** — installs all packages and deploys Necrodermis configs, standalone

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
| **SDDM** | Custom login screen — weather, moon phase, ASCII art, Necron lore |
| **Hyprland** | Keybinds, decorations, defaults — built on JaKooLit's Hyprland-Dots framework |
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
| **Fish** | Shell aliases — `sysupdate`, `sysclean` |

---

## SDDM WEATHER WIDGET

The login screen weather system is powered by the core of the **sitrep** project — a companion tool for pulling and rendering METAR weather data with ASCII art.

For details on how it works, see the sitrep repo:
https://github.com/thedogfatheractual/sitrep

Location is configured during install. To change it afterwards, edit the ICAO code in `/usr/share/sddm/themes/simple_sddm_2/weather.sh`.

---

## SYSTEM ALIASES

Two aliases are added to your Fish config:

```fish
sysupdate   # yay -Syyu — full system + AUR update in one shot
sysclean    # clears package cache, removes orphans, trims logs, clears temp
```

---

## SCREENSHOTS

*Coming soon — Mac test run pending.*

---

```
ORGANIC MATTER IS TEMPORARY  //  NECRODERMIS IS ETERNAL
```

The Sautekh Dynasty does not theme desktops.
It awakens them.

---

*Warhammer 40,000 and all associated lore, imagery, and terminology are the property of Games Workshop Ltd. This project is a fan work — unofficial, unaffiliated, not endorsed.*

*All other works, tools, themes, and frameworks referenced or incorporated in this project remain the property of their original creators. All credit belongs to them. The CREDITS section above acknowledges some of the key works this project builds on, but is not exhaustive — this project would not exist without the broader open source community and all the work that underpins it.*
