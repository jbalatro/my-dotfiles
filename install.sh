#!/usr/bin/env bash
# Fresh EndeavourOS/Arch setup for these dotfiles (mango + quickshell rice).
# Usage: git clone <repo> ~/dotfiles/.config && ~/dotfiles/.config/install.sh [--xorg]
#   --xorg   also install the old bspwm/polybar/eww stack
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XORG=0
[[ "${1:-}" == "--xorg" ]] && XORG=1
FAILED=()

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# The configs hardcode ~/dotfiles/.config, so the repo has to live there.
if [[ "$REPO" != "$HOME/dotfiles/.config" ]]; then
    echo "warning: configs expect the repo at ~/dotfiles/.config (it is at $REPO)"
    if [[ ! -e "$HOME/dotfiles/.config" ]]; then
        mkdir -p "$HOME/dotfiles"
        ln -s "$REPO" "$HOME/dotfiles/.config"
        echo "linked ~/dotfiles/.config -> $REPO"
    fi
fi

# ---------------------------------------------------------------- packages
PACMAN=(
    base-devel git stow
    # shell, terminal, browser
    fish kitty firefox fastfetch
    # network, audio, bluetooth, power
    networkmanager pipewire pipewire-pulse wireplumber bluez bluez-utils
    power-profiles-daemon brightnessctl playerctl
    # wayland bits
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk polkit
    grim slurp wl-clipboard
    # qt runtime for quickshell
    qt6-base qt6-declarative qt6-wayland qt6-svg qt6-5compat
    # gsettings (light/dark switching)
    dconf glib2
    # fonts
    ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-liberation
    noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
    adwaita-fonts cantarell-fonts
    # icons, cursor, gtk
    adwaita-icon-theme adwaita-icon-theme-legacy adwaita-cursors
    breeze-icons gtk3 gtk4 libadwaita
    # scripts
    jq wget xdg-utils yt-dlp deno
    quickshell
)

# AUR packages are tried one by one so a single rename doesn't abort the rest.
AUR=(
    mangowc-git
    awww
    wayfreeze
    ttf-material-icons
)

XORG_PACMAN=(
    bspwm sxhkd polybar picom feh rofi dunst maim xclip xdotool xorg-xrandr
)
XORG_AUR=(eww)

say "Updating system and installing pacman packages"
sudo pacman -Syu --needed --noconfirm
(( XORG )) && PACMAN+=("${XORG_PACMAN[@]}")
for p in "${PACMAN[@]}"; do
    if ! sudo pacman -S --needed --noconfirm "$p"; then FAILED+=("pacman:$p"); fi
done

say "Installing AUR packages"
if ! command -v yay >/dev/null; then
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" \
        && (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
fi
(( XORG )) && AUR+=("${XORG_AUR[@]}")
for p in "${AUR[@]}"; do
    if ! yay -S --needed --noconfirm "$p"; then FAILED+=("aur:$p"); fi
done

# ---------------------------------------------------------------- services
say "Enabling services"
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon \
    || FAILED+=("services")
fc-cache -f

# ---------------------------------------------------------------- shell
say "Setting fish as default shell"
if [[ "$SHELL" != */fish ]]; then chsh -s "$(command -v fish)" || FAILED+=("chsh"); fi

# ---------------------------------------------------------------- dotfiles
say "Linking configs into ~/.config"
mkdir -p "$HOME/.config"
for d in "$REPO"/*/; do
    name="$(basename "$d")"
    case "$name" in firefox|wallpaper) continue ;; esac   # handled separately
    target="$HOME/.config/$name"
    if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$d")" ]]; then
        continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        mv "$target" "$target.bak.$(date +%s)"
        echo "backed up existing $target"
    fi
    ln -s "${d%/}" "$target"
    echo "linked $name"
done

# bspwmrc and the old scripts read wallpapers from ~/wallpaper
[[ -e "$HOME/wallpaper" ]] || ln -s "$REPO/wallpaper" "$HOME/wallpaper"

say "Linking Firefox user.js / userChrome.css"
profile="$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name '*.default-release' 2>/dev/null | head -n1)"
if [[ -n "$profile" ]]; then
    mkdir -p "$profile/chrome"
    ln -sf "$REPO/firefox/user.js" "$profile/user.js"
    ln -sf "$REPO/firefox/userChrome.css" "$profile/chrome/userChrome.css"
    echo "linked into $profile"
else
    echo "no Firefox profile yet: start Firefox once, then re-run this script"
fi

# ---------------------------------------------------------------- environment
say "Environment"
if [[ -d /sys/class/power_supply/BAT0 ]]; then
    echo "battery detected: set happybar_pc_type=LAPTOP in $REPO/environment.d/happybar.conf"
fi

gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null

# ---------------------------------------------------------------- summary
say "Done"
if ((${#FAILED[@]})); then
    echo "These steps failed and need a manual look:"
    printf '  - %s\n' "${FAILED[@]}"
fi
cat <<EOF

Manual follow-ups:
  - Mango monitor rules are for a 3-monitor desktop; add an eDP-1 rule in mango/config.conf.
  - Set happybar_pc_type=LAPTOP in environment.d/happybar.conf on the laptop.
  - Log out, pick the mango session (or run 'mango' from a TTY), and log back in.
EOF
