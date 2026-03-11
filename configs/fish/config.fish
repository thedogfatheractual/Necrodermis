source /usr/share/cachyos-fish-config/cachyos-config.fish


set -x HSA_OVERRIDE_GFX_VERSION 10.3.0

# Necrodermis — system aliases
alias sysupdate='yay -Syyu'
alias sysclean='sudo pacman -Scc && sudo pacman -Rns (pacman -Qtdq) 2>/dev/null; sudo journalctl --vacuum-time=2weeks && sudo rm -rf /tmp/* && paccache -rk2 && echo Done.'

# Necrodermis — system aliases
alias sysclean='sudo pacman -Scc && sudo pacman -Rns (pacman -Qtdq) 2>/dev/null; sudo journalctl --vacuum-time=2weeks && sudo rm -rf /tmp/* && paccache -rk2 && echo Done.'
alias logout='hyprctl dispatch exit'

# Necrodermis — system manifest on terminal launch
fastfetch

# Necrodermis — restrict default file permissions
umask 027
