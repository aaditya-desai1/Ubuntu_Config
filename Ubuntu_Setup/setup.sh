#!/usr/bin/env bash
set -Eeuo pipefail

# ----------------------------------------
# Globals
# ----------------------------------------
NEOVIM_VERSION="v0.10.3"
LOG_DIR="$HOME/ubuntu-terminal-bootstrap/logs"
LOG_FILE="$LOG_DIR/setup.log"
IS_CI=false

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

if [ -f /.dockerenv ] || [ -n "${CI:-}" ]; then
  IS_CI=true
fi

echo "========================================"
echo "🚀 Ubuntu Terminal Bootstrap Started"
echo "🕒 $(date)"
echo "CI Mode: $IS_CI"
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

install_if_missing() {
  if ! dpkg -s "$1" >/dev/null 2>&1; then
    sudo apt install -y "$1"
  else
    echo "✔ $1 already installed"
  fi
}

# ----------------------------------------
# 1. System update
# ----------------------------------------
echo "🔄 Updating system..."
sudo apt update

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

# fd fix (Ubuntu uses fdfind)
mkdir -p ~/.local/bin
if command_exists fdfind && ! command_exists fd; then
  ln -sf "$(which fdfind)" ~/.local/bin/fd
fi

# ----------------------------------------
# 3. Nerd Font (skip in CI/Docker)
# ----------------------------------------
if [ "$IS_CI" = true ]; then
  echo "⚠️ CI/Docker detected, skipping Nerd Font installation"
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

# Ensure ~/.local/bin in PATH
ensure_line 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc

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

if grep -q '^ZSH_THEME=' ~/.zshrc; then
  sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
else
  ensure_line 'ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
fi

# ----------------------------------------
# 6. fzf shell integration (APT-safe)
# ----------------------------------------
echo "🔍 Setting up fzf..."
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  ensure_line 'source /usr/share/doc/fzf/examples/key-bindings.zsh' ~/.zshrc
  ensure_line 'source /usr/share/doc/fzf/examples/completion.zsh' ~/.zshrc
fi

# ----------------------------------------
# 7. Set Zsh as default shell (real machine only)
# ----------------------------------------
if [ "$IS_CI" = true ]; then
  echo "⚠️ CI/Docker detected, skipping chsh"
else
  if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔁 Setting Zsh as default shell..."
    chsh -s "$(which zsh)"
  else
    echo "✔ Zsh already default shell"
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
  if [ "$IS_CI" = true ]; then
    echo "🐳 Docker/CI detected – using tarball Neovim"

    curl -LO "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz"
    rm -rf "$NVIM_ROOT"
    tar -xzf nvim-linux64.tar.gz
    mv nvim-linux64 "$NVIM_ROOT"
    ln -sf "$NVIM_ROOT/bin/nvim" "$NVIM_BIN"
    rm nvim-linux64.tar.gz

  else
    echo "🖥️ Real system detected – using AppImage"
    curl -L "https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim.appimage" \
      -o "$NVIM_BIN"
    chmod +x "$NVIM_BIN"
  fi

  echo "✔ Neovim installed"
else
  echo "✔ Neovim already installed"
fi

# ----------------------------------------
# 9. LazyVim
# ----------------------------------------
echo "🎯 Installing LazyVim..."
NVIM_CONFIG="$HOME/.config/nvim"

if [ ! -d "$NVIM_CONFIG" ]; then
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
else
  echo "✔ LazyVim already exists"
fi

# ----------------------------------------
# 10. Verification (CI critical)
# ----------------------------------------
echo "🔎 Verifying installations..."
command -v git
command -v zsh
command -v fzf
command -v nvim

# ----------------------------------------
# Done
# ----------------------------------------
echo "========================================"
echo "✅ Setup completed successfully"
echo "🕒 $(date)"
echo "📄 Log saved to $LOG_FILE"
echo "========================================"

echo ""
echo "NEXT STEPS:"
echo "1. Restart terminal"
echo "2. Set terminal font to: JetBrainsMono Nerd Font"
echo "3. Run: zsh"
echo "4. Run: nvim"
