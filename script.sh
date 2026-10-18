#!/usr/bin/env bash
set -euo pipefail

ask() {
  read -rp "$1 [Y/n] " answer
  if [ -z "$answer" ]; then
    local answer="y"
  fi
  local answer="${answer,,}"
  local answer="${answer:0:1}"
  if [[ "$answer" == "y" ]]; then
    return 0
  fi
  return 1
}

cmd_exist() {
  command -v $1 >/dev/null 2>&1
}

if ! ping -c 1 1.1.1.1 >/dev/null 2>&1; then
  echo "no internet"
  exit 1
fi

echo "This script isn't really clean..."
echo "It exists to be run once on a fresh arch linux install"
echo "It will configure the OS how I like it"
echo "It creates backups when running, but if run twice, it might erase your files and configs"
echo "I'm not even sure that it won't break anything the first time"
echo "So please use it really carefully"
if ! ask "run the script?"; then
  exit 0
fi

start_bashrc="\
# stop if not running interactively
case \$- in
  *i*) ;;
  *) return ;;
esac
"

end_bashrc="\
# history
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s cmdhist

# shell behaviour
shopt -s checkwinsize
shopt -s globstar
"
exports="\
# exports
"
aliases="\
# aliases
"

if ask "enable multilib & ILoveCandy ? It may not work if you have touched the /etc/pacman.conf"; then
  conf_path="/etc/pacman.conf"
  if [ -f "$conf_path" ]; then
    sudo cp "$conf_path" "${conf_path}.bak"
  fi
  sudo sed -i '/^#\[multilib\]$/{N;s/^#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist$/[multilib]\nInclude = \/etc\/pacman.d\/mirrorlist/;}' "$conf_path"
  if ! sudo sed -n '/^\[options\]/,/^\[/p' "$conf_path" | grep -qx 'ILoveCandy'; then
    sudo sed -i '/^\[options\]/a ILoveCandy' "$conf_path"
  fi
  sudo pacman -Sy
fi

echo "git: install git & less and will 'help' you configure the .gitconfig"
if ask "use git?"; then
  sudo pacman -S --needed --noconfirm git less
  read -rp "name (John Doe): " name
  read -rp "email (john.doe@company.com): " email
  read -rp "editor (nvim): " editor
  cp contents/git/.gitconfig contents/git/.gitconfig.temp
  sed -i "s|^  name =.*|  name = $name|" contents/git/.gitconfig.temp
  sed -i "s|^  email =.*|  email = $email|" contents/git/.gitconfig.temp
  sed -i "s|^  editor =.*|  editor = $editor|" contents/git/.gitconfig.temp
  if [ -f ~/.gitconfig ]; then
    mv ~/.gitconfig ~/.gitconfig.bak
  fi
  cp contents/git/.gitconfig.temp ~/.gitconfig
  rm contents/git/.gitconfig.temp
fi

if ! cmd_exist "yay"; then
  echo "yay: just install yay"
  if ask "isntall yay? (required for the rest)"; then
    sudo pacman -Sy --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ../
    rm -rf yay/
  else
    exit 0
  fi
fi

echo "neovim: install it and configure it with LazyVim/Starter and little changes"
if ask "use neovim?"; then
  yay -S --needed --noconfirm neovim wl-clipboard
  conf_path="$HOME/.config/nvim"
  if [ -d "$conf_path" ]; then
    mv "$conf_path" "${conf_path}.bak"
  fi
  git clone https://github.com/LazyVim/starter "$conf_path"
  rm -rf "${conf_path}/.git/"
  cat contents/neovim/keymaps.lua >>"${conf_path}/lua/config/keymaps.lua"
  cat contents/neovim/options.lua >>"${conf_path}/lua/config/options.lua"
  cp contents/neovim/theme.lua "${conf_path}/lua/plugins/theme.lua"
  exports="${exports}export EDITOR=nvim\nexport VISUAL=nvim\n"
fi

if ask "remove favorites apps (it will just unpin them)?"; then
  gsettings set org.gnome.shell favorite-apps "[]"
fi

echo "ghostty: install it and add a custom keyboard shortcut to launch it: super + return"
if ask "use ghostty?"; then
  yay -S --needed --noconfirm ghostty
  conf_path="$HOME/.config/ghostty/config.ghostty"
  if [ -f "$conf_path" ]; then
    mv "$conf_path" "${conf_path}.bak"
  fi
  mkdir -p ~/.config/ghostty/
  cp contents/ghostty/config.ghostty "$conf_path"
  exports="${exports}export TERM=xterm-256color\n"
  schema="org.gnome.settings-daemon.plugins.media-keys"
  path_key="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ghostty/"
  gsettings set "$schema" custom-keybindings "['$path_key']"
  gsettings set "$schema.custom-keybinding:$path_key" name 'Ghostty'
  gsettings set "$schema.custom-keybinding:$path_key" command 'ghostty +new-window'
  gsettings set "$schema.custom-keybinding:$path_key" binding '<Super>Return'
fi

echo "yazi: install it and add the alias 'y' to laucnh it"
if ask "use yazi?"; then
  yay -S --needed --noconfirm yazi
  ya pkg add yazi-rs/flavors:catppuccin-latte
  ya pkg add yazi-rs/flavors:catppuccin-mocha
  conf_path="$HOME/.config/yazi/theme.toml"
  if [ -f "$conf_path" ]; then
    mv "$conf_path" "${conf_path}.bak"
  fi
  mkdir -p ~/.config/yazi/
  cp contents/yazi/theme.toml "$conf_path"
  aliases="${aliases}alias y='yazi'\n"
fi

echo "zed: install it and add the alias 'z' to laucnh it in the current directory"
if ask "use zed?"; then
  yay -S --needed --noconfirm zed-bin
  conf_path="$HOME/.config/zed/settings.json"
  if [ -f "$conf_path" ]; then
    mv "$conf_path" "${conf_path}.bak"
  fi
  mkdir -p "$HOME/.config/zed/"
  cp contents/zed/settings.json "$conf_path"
  aliases="${aliases}alias z='zed .'\n"
fi

echo "eza: install it and add the alias 'ls' to use it"
if ask "use eza?"; then
  yay -S --needed --noconfirm eza
  aliases="${aliases}alias ls='eza --icons --group-directories-first -lah'\n"
fi

echo "tree: install it and add the alias 'tree' to just skip node_modules/ and target/ directories"
if ask "use tree?"; then
  yay -S tree
  aliases="${aliases}alias tree='tree -I \"node_modules|target\" -C'\n"
fi

echo "docker: install docker & docker-compose with 'dc' for docker compose and 'dbx' for docker buildx as aliases"
if ask "use docker?"; then
  yay -S --needed --noconfirm docker docker-compose
  sudo usermod -aG docker $USER
  aliases="${aliases}alias dc='docker compose'\nalias dbx='docker buildx'\n"
fi

echo "fzf: install and use it"
if ask "use fzf?"; then
  yay -S --needed --noconfirm fzf
  end_bashrc="# fzf\nsource /usr/share/fzf/key-bindings.bash\n\n${end_bashrc}"
fi

echo "ports: so you don't have to remember 'sudo ss -tulpn'"
if ask "add ports alias?"; then
  aliases="${aliases}alias ports='sudo ss -tupln'\n"
fi

echo "starship: install and use it"
if ask "use starship?"; then
  yay -S --needed --noconfirm starship
  end_bashrc="${end_bashrc}\n# starship\neval \"\$(starship init bash)\"\n"
fi

echo "bashrc: to apply all the aliases and exports combined with a default conf"
if ask "apply suggested .bashrc?"; then
  conf_path="$HOME/.bashrc"
  if [ -f "$conf_path*" ]; then
    mv "$conf_path" "${conf_path}.bak"
  fi
  echo -e "${start_bashrc}\n${aliases}\n${exports}\n${end_bashrc}" >"$conf_path"
fi
