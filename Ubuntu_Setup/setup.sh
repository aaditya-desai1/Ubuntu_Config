#!/usr/bin/env bash
set -Eeuo pipefail

# ----------------------------------------
# Globals
# ----------------------------------------
NEOVIM_VERSION="v0.10.3"
LOG_DIR="$HOME/ubuntu-terminal-bootstrap/logs"
LOG_FILE="$LOG_DIR/setup.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# Detect environments
IS_CI=false
IS_DOCKER_BUILD=false

if [ -f /.dockerenv ] || [ -n "${CI:-}" ]; then
  IS_CI=true
fi

if [ "$(id -u)" -eq 0 ]; then
  IS_DOCKER_BUILD=true
fi

echo "========================================"
echo "🚀 Ubuntu Terminal Bootstrap Started"
echo "🕒 $(date)"
echo "CI Mode: $IS_CI"
echo "Docker Build Mode: $IS_DOCKER_BUILD"
echo "========================================"

# ----------------------------------------
# Helpers
# ----------------------------------------
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_line() {
  grep -qxF "$1" "$2" || echo "$1" >>"$2"
}

as_root() {
  if [ "$IS_DOCKER_BUILD" = true ]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_if_missing() {
  if ! dpkg -s "$1" >/dev/null 2>&1; then
    as_root apt install -y "$1"
  else
    echo "✔ $1 already installed"
  fi
}

# Ensure PATH for current shell (CI-safe)
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------
# 1. System update
# ----------------------------------------
echo "🔄 Updating system..."
as_root apt update

# ----------------------------------------
# 2. Basic packages
# ----------------------------------------
echo "📦 Installing basic packages..."

BASIC_PACKAGES=(
  git curl wget unzip zip
  zsh ripgrep fd-find
  build-essential ca-certificates
  fzf fontconfig
)

for pkg in "${BASIC_PACKAGES[@]}"; do
  install_if_missing "$pkg"
done

# fd fix
mkdir -p "$HOME/.local/bin"
if command_exists fdfind && ! command_exists fd; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# ----------------------------------------
# 3. Nerd Font (skip in CI/Docker)
# ----------------------------------------
if [ "$IS_CI" = true ] || [ "$IS_DOCKER_BUILD" = true ]; then
  echo "⚠️ Skipping Nerd Font installation (CI/Docker)"
else
  echo "🔤 Installing JetBrainsMono Nerd Font..."
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    cd "$FONT_DIR"
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip
    rm JetBrainsMono.zip
    fc-cache -fv
  else
    echo "✔ Nerd Font already installed"
  fi
fi

# ----------------------------------------
# 4. Oh My Zsh
# ----------------------------------------
echo "🐚 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✔ Oh My Zsh already installed"
fi

ensure_line 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"

# ----------------------------------------
# 5. Powerlevel10k
# ----------------------------------------
echo "⚡ Installing Powerlevel10k..."
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "✔ Powerlevel10k already installed"
fi

if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
  sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
else
  ensure_line 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"
fi

# ----------------------------------------
# 6. fzf shell integration (APT-safe)
# ----------------------------------------
echo "🔍 Setting up fzf..."
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  ensure_line 'source /usr/share/doc/fzf/examples/key-bindings.zsh' "$HOME/.zshrc"
  ensure_line 'source /usr/share/doc/fzf/examples/completion.zsh' "$HOME/.zshrc"
fi

# ----------------------------------------
# 7. Set Zsh as default shell (real machine only)
# ----------------------------------------
if [ "$IS_CI" = true ] || [ "$IS_DOCKER_BUILD" = true ]; then
  echo "⚠️ Skipping chsh (CI/Docker)"
else
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)"
  fi
fi

# ----------------------------------------
# 8. Neovim
# ----------------------------------------
echo "📝 Installing Neovim..."

NVIM_ROOT="$HOME/.local/nvim"
NVIM_BIN="$HOME/.local/bin/nvim"
mkdir -p "$HOME/.local/bin"

if ! command_exists nvim; then
  if [ "$IS_CI" = true ] || [ "$IS_DOCKER_BUILD" = true ]; then
    curl -LO "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz"
    rm -rf "$NVIM_ROOT"
    tar -xzf nvim-linux64.tar.gz
    mv nvim-linux64 "$NVIM_ROOT"
    ln -sf "$NVIM_ROOT/bin/nvim" "$NVIM_BIN"
    rm nvim-linux64.tar.gz
  else
    curl -L "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim.appimage" \
      -o "$NVIM_BIN"
    chmod +x "$NVIM_BIN"
  fi
fi

# ----------------------------------------
# 9. LazyVim
# ----------------------------------------
echo "🎯 Installing LazyVim..."
NVIM_CONFIG="$HOME/.config/nvim"

if [ ! -d "$NVIM_CONFIG" ]; then
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
fi

# ----------------------------------------
# 10. Verification
# ----------------------------------------
echo "🔎 Verifying installations..."
command -v git
command -v zsh
command -v fzf
command -v nvim
nvim --version

# ----------------------------------------
# Done
# ----------------------------------------
echo "========================================"
echo "✅ Setup completed successfully"
echo "🕒 $(date)"
echo "📄 Log saved to $LOG_FILE"
echo "========================================"
