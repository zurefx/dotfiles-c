#!/usr/bin/env bash
set -e

REPO="https://github.com/zurefx/dotfiles-c"
DOTDIR="/tmp/dotfiles-c"

if [ "$EUID" -eq 0 ]; then
  echo "[!] No ejecutes como root"
  exit 1
fi

echo "[+] Actualizando sistema"
sudo apt update

echo "[+] Instalando dependencias BSPWM"

sudo apt install -y \
xorg \
xinit \
bspwm \
sxhkd \
polybar \
picom \
kitty \
rofi \
feh \
scrot \
eza \
bat \
xclip \
lxappearance \
zsh \
git \
curl \
fastfetch \
fonts-powerline

# -------------------------------------------------
# OH MY ZSH
# -------------------------------------------------

echo "[+] Instalando Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

echo "[+] Instalando plugins ZSH"

git clone https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true

# -------------------------------------------------
# POWERLEVEL10K
# -------------------------------------------------
echo "[+] Instalando Powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "$HOME/.powerlevel10k" 2>/dev/null || true
# -------------------------------------------------
# CLONAR DOTFILES
# -------------------------------------------------

echo "[+] Clonando dotfiles"

rm -rf "$DOTDIR"
git clone "$REPO" "$DOTDIR"

# -------------------------------------------------
# COPIAR CONFIG
# -------------------------------------------------

echo "[+] Copiando configuraciones"

mkdir -p "$HOME/.config"
cp -r "$DOTDIR/config/"* "$HOME/.config/"

# -------------------------------------------------
# HOME FILES
# -------------------------------------------------

echo "[+] Copiando archivos home"

cp "$DOTDIR/home/.zshrc" "$HOME/"
cp "$DOTDIR/home/.p10k.zsh" "$HOME/"

# -------------------------------------------------
# FONTS
# -------------------------------------------------

echo "[+] Instalando fuentes"

sudo mkdir -p /usr/local/share/fonts/zurefx
sudo cp "$DOTDIR/fonts/"* /usr/local/share/fonts/zurefx/

fc-cache -fv

# -------------------------------------------------
# SHELL
# -------------------------------------------------

echo "[+] Cambiando shell a zsh"

chsh -s "$(which zsh)"

# -------------------------------------------------
# CLEAN
# -------------------------------------------------

rm -rf "$DOTDIR"

echo ""
echo "================================="
echo "✔ INSTALACION COMPLETADA"
echo "================================="
echo ""
echo "Inicia BSPWM con:"
echo ""
echo "startx"
