# Necrodermis — fish config

# Suppress greeting
set fish_greeting ""

# Auto-start Hyprland on TTY1
if status is-login
    if test (tty) = /dev/tty1
        and not set -q WAYLAND_DISPLAY
        exec Hyprland
    end
end

# done plugin settings
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

# Man pages
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# AMD override
set -x HSA_OVERRIDE_GFX_VERSION 10.3.0

# PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# !! and !$ history shortcuts
function __history_previous_command
    switch (commandline -t)
    case "!"
        commandline -t $history[1]; commandline -f repaint
    case "*"
        commandline -i !
    end
end
function __history_previous_command_arguments
    switch (commandline -t)
    case "!"
        commandline -t ""
        commandline -f history-token-search-backward
    case "*"
        commandline -i '$'
    end
end
if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# History with timestamps
function history
    builtin history --show-time='%F %T '
end

# Quick backup
function backup --argument filename
    cp $filename $filename.bak
end

# Smart copy
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

# ls replacements
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.="eza -a | grep -e '^\.'"

# Necrodermis aliases
alias sysupdate='yay -Syyu'
alias sysclean='sudo pacman -Scc && sudo pacman -Rns (pacman -Qtdq) 2>/dev/null; sudo journalctl --vacuum-time=2weeks && sudo rm -rf /tmp/* && paccache -rk2 && echo Done.'
alias logout='hyprctl dispatch exit'

# Common utils
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias hw='hwinfo --short'
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
alias jctl="journalctl -p 3 -xb"
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias please='sudo'
alias tb='nc termbin.com 9999'

# Restrict default file permissions
umask 027

# Necrodermis — system manifest on terminal launch
fastfetch
