#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# GLOBALS
# ============================================================
USER_NAME="${SUDO_USER:-$USER}"
DOTFILES_REPO="https://github.com/zurefx/dotfiles-c"

BANNER="
        Made by: zurefx
  Repo: https://github.com/zurefx/dotfiles-c
         Kali Linux Dotfiles Installer
"

# ============================================================
# COLORES
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${CYAN}[➜]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✘]${NC} $1"; }

# ============================================================
# UI
# ============================================================
banner() {
  clear
  echo -e "${BOLD}${CYAN}${BANNER}${NC}"
}

step() {
  echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}\n"
}

# ============================================================
# CHECKS
# ============================================================
[[ $EUID -eq 0 ]] && {
  err "No corras el script como root. Usa tu usuario normal."
  exit 1
}

# Verificar que es Kali / Debian based
if ! command -v apt &>/dev/null; then
  err "Este instalador es para Kali Linux (apt-based). Abortando."
  exit 1
fi

# ============================================================
# CONFIRM
# ============================================================
banner
echo -e "${BOLD}Este script instalará:${NC}"
echo "  • Entorno bspwm completo"
echo "  • Polybar, Picom, Rofi, Kitty"
echo "  • Zsh + Oh My Zsh + Powerlevel10k"
echo "  • zsh-autosuggestions + zsh-syntax-highlighting"
echo "  • Dotfiles desde: ${DOTFILES_REPO}"
echo ""
read -rp "$(echo -e "${YELLOW}¿Continuar instalación? (Y/n):${NC} ")" ans
ans="${ans,,}"
[[ -n "$ans" && "$ans" != "y" && "$ans" != "yes" ]] && exit 0

# ============================================================
# SUDO (ONCE)
# ============================================================
step "Cacheando credenciales sudo"
sudo -v
# Mantener sudo vivo en background
while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

# ============================================================
# APT PACKAGES
# ============================================================
install_apt() {
  step "Actualizando repositorios"
  sudo apt update -y

  step "Instalando paquetes base"
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
    xclip \
    lxappearance \
    zsh \
    fonts-powerline \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    tmux \
    neovim \
    bat \
    thunar \
    dunst \
    flameshot \
    papirus-icon-theme \
    lxdm \
    brightnessctl \
    pamixer \
    pipewire \
    pipewire-pulse \
    wireplumber \
    network-manager \
    exa 2>/dev/null || true

  ok "Paquetes apt instalados"
}

# ============================================================
# FASTFETCH
# ============================================================
install_fastfetch() {
  step "Instalando fastfetch"

  if command -v fastfetch &>/dev/null; then
    ok "fastfetch ya instalado — skipping"
    return
  fi

  # Intentar desde apt primero (Kali reciente lo tiene)
  if sudo apt install -y fastfetch 2>/dev/null; then
    ok "fastfetch instalado via apt"
    return
  fi

  # Fallback: descargar el .deb desde GitHub releases
  info "Descargando fastfetch desde GitHub releases..."
  FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
    | grep "browser_download_url" \
    | grep "linux-amd64.deb" \
    | cut -d '"' -f 4 | head -1)

  if [[ -n "$FASTFETCH_URL" ]]; then
    tmpdir="$(mktemp -d)"
    curl -Lo "$tmpdir/fastfetch.deb" "$FASTFETCH_URL"
    sudo dpkg -i "$tmpdir/fastfetch.deb" || sudo apt install -f -y
    rm -rf "$tmpdir"
    ok "fastfetch instalado via .deb"
  else
    warn "No se pudo instalar fastfetch — instálalo manualmente después"
  fi
}

# ============================================================
# ZSH + OH MY ZSH
# ============================================================
setup_zsh() {
  step "Configurando Zsh"

  # Instalar Oh My Zsh
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "Oh My Zsh ya instalado — skipping"
  else
    info "Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh instalado"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # zsh-autosuggestions
  if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    ok "zsh-autosuggestions ya instalado"
  else
    info "Instalando zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions instalado"
  fi

  # zsh-syntax-highlighting
  if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    ok "zsh-syntax-highlighting ya instalado"
  else
    info "Instalando zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting instalado"
  fi

  ok "Plugins Zsh listos"
}

# ============================================================
# POWERLEVEL10K
# ============================================================
setup_p10k() {
  step "Instalando Powerlevel10k"

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

  if [[ -d "$P10K_DIR" ]]; then
    info "Powerlevel10k ya instalado — actualizando..."
    git -C "$P10K_DIR" pull
  else
    info "Clonando Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  fi

  ok "Powerlevel10k instalado"
}

# ============================================================
# DOTFILES
# ============================================================
setup_dotfiles() {
  step "Clonando dotfiles"

  DOTDIR="$HOME/dotfiles"

  if [[ -d "$DOTDIR/.git" ]]; then
    info "Dotfiles ya existen — haciendo pull..."
    git -C "$DOTDIR" pull
  else
    git clone "$DOTFILES_REPO" "$DOTDIR"
  fi

  mkdir -p "$HOME/.config"

  # Copiar configs
  [[ -d "$DOTDIR/config" ]] && cp -r "$DOTDIR/config/"* "$HOME/.config/" && ok "Configs copiadas"

  # Copiar archivos home
  [[ -f "$DOTDIR/home/.zshrc" ]]      && cp "$DOTDIR/home/.zshrc" "$HOME/"       && ok ".zshrc copiado"
  [[ -f "$DOTDIR/home/.p10k.zsh" ]]   && cp "$DOTDIR/home/.p10k.zsh" "$HOME/"    && ok ".p10k.zsh copiado"
  [[ -d "$DOTDIR/home/.mozilla" ]]    && cp -r "$DOTDIR/home/.mozilla" "$HOME/"   && ok ".mozilla copiado"
  [[ -d "$DOTDIR/home/.local" ]]      && cp -r "$DOTDIR/home/.local" "$HOME/"     && ok ".local copiado"

  # Permisos bspwm
  if [[ -f "$HOME/.config/bspwm/bspwmrc" ]]; then
    chmod +x "$HOME/.config/bspwm/bspwmrc"
    find "$HOME/.config/bspwm/scripts" -type f -exec chmod 755 {} \; 2>/dev/null || true
    ok "Permisos bspwm configurados"
  fi

  # Permisos polybar
  if [[ -f "$HOME/.config/polybar/launch.sh" ]]; then
    chmod +x "$HOME/.config/polybar/launch.sh"
    find "$HOME/.config/polybar/scripts" -type f -exec chmod 755 {} \; 2>/dev/null || true
    ok "Permisos polybar configurados"
  fi

  # Permisos bin
  if [[ -d "$HOME/.config/bin" ]]; then
    find "$HOME/.config/bin" -type f -exec chmod 755 {} \;
    ok "Permisos bin configurados"
  fi

  # Crear directorios útiles
  mkdir -p "$HOME/Documents" "$HOME/Downloads" "$HOME/CTF"
  ok "Directorios creados"
}

# ============================================================
# INSTALAR FUENTES
# ============================================================
setup_fonts() {
  step "Instalando fuentes"

  DOTDIR="$HOME/dotfiles"
  FONTS_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONTS_DIR"

  if [[ -d "$DOTDIR/fonts" ]]; then
    cp -r "$DOTDIR/fonts/"*.ttf "$FONTS_DIR/" 2>/dev/null || true
    cp -r "$DOTDIR/fonts/"*.otf "$FONTS_DIR/" 2>/dev/null || true
    fc-cache -fv &>/dev/null
    ok "Fuentes instaladas y caché actualizado"
  else
    warn "No se encontró el directorio fonts/ en los dotfiles"
  fi
}

# ============================================================
# ZSHRC — asegurar plugins + p10k activados
# ============================================================
patch_zshrc() {
  step "Parcheando .zshrc"

  ZSHRC="$HOME/.zshrc"

  # Si no existe .zshrc todavía, crear uno base
  if [[ ! -f "$ZSHRC" ]]; then
    cat > "$ZSHRC" << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
    ok ".zshrc creado desde cero"
    return
  fi

  # Si ya existe (viene de dotfiles), verificar que tenga p10k y plugins
  # Cambiar tema a p10k si no lo tiene
  if ! grep -q "powerlevel10k/powerlevel10k" "$ZSHRC"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
    info ".zshrc: tema cambiado a powerlevel10k"
  fi

  # Asegurar plugins
  if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
    sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
    info ".zshrc: plugins añadidos"
  fi

  # Asegurar source p10k
  if ! grep -q "p10k.zsh" "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh" >> "$ZSHRC"
    info ".zshrc: source p10k.zsh añadido"
  fi

  ok ".zshrc parcheado correctamente"
}

# ============================================================
# SHELL DEFAULT → ZSH
# ============================================================
setup_shell() {
  step "Configurando Zsh como shell por defecto"

  ZSH_BIN="$(which zsh)"

  # Añadir zsh a /etc/shells si no está
  grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells

  # Cambiar shell del usuario
  if [[ "$SHELL" != "$ZSH_BIN" ]]; then
    sudo chsh -s "$ZSH_BIN" "$USER_NAME"
    ok "Shell cambiado a zsh"
  else
    ok "Zsh ya es el shell por defecto"
  fi
}

# ============================================================
# SERVICIOS
# ============================================================
setup_services() {
  step "Habilitando servicios"

  sudo systemctl enable NetworkManager 2>/dev/null && ok "NetworkManager habilitado" || warn "NetworkManager no disponible"
  sudo systemctl start  NetworkManager 2>/dev/null || true

  sudo systemctl enable lxdm 2>/dev/null && ok "lxdm habilitado" || warn "lxdm no disponible"

  # .xinitrc para startx
  echo "exec bspwm" > "$HOME/.xinitrc"
  ok ".xinitrc configurado con bspwm"
}

# ============================================================
# XINITRC / XSESSION
# ============================================================
setup_xinit() {
  step "Configurando xinit"

  cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
# Lanzar bspwm
exec bspwm
EOF
  chmod +x "$HOME/.xinitrc"
  ok ".xinitrc listo"
}

# ============================================================
# SSH (OPCIONAL)
# ============================================================
setup_ssh() {
  banner
  echo ""
  read -rp "$(echo -e "${YELLOW}¿Generar claves SSH? (Y/n):${NC} ")" ans
  ans="${ans,,}"
  [[ -n "$ans" && "$ans" != "y" && "$ans" != "yes" ]] && return

  step "Generando claves SSH"

  DEFAULT_LABEL="$USER_NAME"

  echo -e "Modo de claves SSH:"
  echo "  1) Sin passphrase (rápido)"
  echo "  2) Con passphrase (recomendado)"
  read -rp "Opción [1]: " mode
  [[ "$mode" != "2" ]] && mode=1

  read -rp "Label para las claves [${DEFAULT_LABEL}]: " SSH_LABEL
  SSH_LABEL="${SSH_LABEL:-$DEFAULT_LABEL}"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  PASS_RSA=""
  PASS_ED=""

  if [[ "$mode" == "2" ]]; then
    while true; do
      read -s -p "Passphrase RSA: " p1; echo
      read -s -p "Confirmar: " p2; echo
      [[ "$p1" == "$p2" ]] && PASS_RSA="$p1" && break
      err "Las passphrases no coinciden"
    done
    read -s -p "Passphrase ED25519 (ENTER = igual que RSA): " q1; echo
    [[ -z "$q1" ]] && PASS_ED="$PASS_RSA" || PASS_ED="$q1"
  fi

  gen_key() {
    local path="$1" type="$2" bits="$3" pass="$4"
    if [[ -f "$path" ]]; then
      read -rp "[!] $path ya existe — ¿sobreescribir? (y/N): " ow
      [[ "${ow,,}" != "y" ]] && return
      cp "$path" "$path.bak" 2>/dev/null || true
      rm -f "$path" "$path.pub"
    fi
    if [[ "$type" == "rsa" ]]; then
      ssh-keygen -t rsa -b "$bits" -f "$path" -C "${SSH_LABEL}@$(hostname)" -N "$pass" -q
    else
      ssh-keygen -t ed25519 -f "$path" -C "${SSH_LABEL}@$(hostname)" -N "$pass" -q
    fi
    chmod 600 "$path"
    chmod 644 "$path.pub"
    ok "$type key generada"
  }

  gen_key "$HOME/.ssh/id_rsa"     "rsa"     4096 "$PASS_RSA"
  gen_key "$HOME/.ssh/id_ed25519" "ed25519" ""   "$PASS_ED"

  echo ""
  [[ -f "$HOME/.ssh/id_rsa.pub" ]]     && { echo -e "${CYAN}--- id_rsa.pub ---${NC}";     cat "$HOME/.ssh/id_rsa.pub";     echo; }
  [[ -f "$HOME/.ssh/id_ed25519.pub" ]] && { echo -e "${CYAN}--- id_ed25519.pub ---${NC}"; cat "$HOME/.ssh/id_ed25519.pub"; echo; }

  read -rp "Presiona ENTER para continuar..."
}

# ============================================================
# MAIN
# ============================================================
main() {
  banner

  install_apt
  install_fastfetch
  setup_zsh
  setup_p10k
  setup_dotfiles
  setup_fonts
  patch_zshrc
  setup_shell
  setup_services
  setup_xinit
  setup_ssh

  banner
  echo -e "${GREEN}${BOLD}"
  echo "  ✔  Instalación completa 🤙"
  echo ""
  echo -e "${NC}${CYAN}  Próximos pasos:${NC}"
  echo "  1. Reinicia o ejecuta: exec zsh"
  echo "  2. Ejecuta p10k configure  (si no se lanza solo)"
  echo "  3. Inicia sesión con: startx  o desde lxdm"
  echo ""
  echo -e "${YELLOW}  Repo: ${DOTFILES_REPO}${NC}"
  echo ""
}

main
