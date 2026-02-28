#!/usr/bin/env bash

set -Eeuo pipefail

# ----------------------------------------
# Logging
# ----------------------------------------
LOG_DIR="$HOME/ubuntu-terminal-bootstrap/logs"
LOG_FILE="$LOG_DIR/setup.log"
mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "🚀 Ubuntu Terminal Bootstrap Started"
echo "🕒 $(date)"
echo "========================================"

# ----------------------------------------
# Helpers
# ----------------------------------------
command_exists() {
  command -v "$1" >/dev/null 2>&1
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
sudo apt update -y

# ----------------------------------------
# 2. Basic packages
# ----------------------------------------
echo "📦 Installing basic packages..."
BASIC_PACKAGES=(
  git curl wget unzip zip
  zsh ripgrep fd-find
  build-essential ca-certificates
  fzf
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
# 3. Nerd Font (JetBrainsMono)
# ----------------------------------------
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

# ----------------------------------------
# Ensure ~/.local/bin is in PATH
# ----------------------------------------
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.zshrc
fi

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
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >>~/.zshrc
fi

# ----------------------------------------
# 6. fzf shell integration
# ----------------------------------------
echo "🔍 Setting up fzf..."
if ! grep -q "fzf.zsh" ~/.zshrc; then
  echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >>~/.zshrc
fi

# ----------------------------------------
# 7. Set Zsh as default shell (REAL MACHINE ONLY)
# ----------------------------------------

if [ -f /.dockerenv ] || [ -n "${CI:-}" ]; then
  echo "⚠️ Container/CI detected, skipping chsh"
else
  if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔁 Setting Zsh as default shell..."
    chsh -s "$(which zsh)"
  else
    echo "✔ Zsh already default shell"
  fi
fi

# ----------------------------------------
# 8. Neovim (Docker-safe)
# ----------------------------------------
echo "📝 Installing Neovim..."

NVIM_DIR="$HOME/.local/nvim"
NVIM_BIN="$HOME/.local/bin/nvim"
mkdir -p "$HOME/.local/bin"

if ! command -v nvim >/dev/null 2>&1; then
  if [ -f /.dockerenv ] || [ -n "${CI:-}" ]; then
    echo "🐳 Docker/CI detected – using tarball Neovim"

    curl -LO https://github.com/neovim/neovim/releases/download/v0.10.3/nvim-linux64.tar.gz
    tar -xzf nvim-linux64.tar.gz
    mv nvim-linux64 "$NVIM_DIR"
    ln -sf "$NVIM_DIR/bin/nvim" "$NVIM_BIN"
    rm nvim-linux64.tar.gz

  else
    echo "🖥️ Real system detected – using AppImage"

    curl -L https://github.com/neovim/neovim/releases/download/v0.10.3/nvim.appimage \
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
NVIM_DIR="$HOME/.config/nvim"

if [ ! -d "$NVIM_DIR" ]; then
  git clone https://github.com/LazyVim/starter "$NVIM_DIR"
else
  echo "✔ LazyVim already exists"
fi

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
