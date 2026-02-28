# Ubuntu Terminal Bootstrap 🚀

A one-command setup script to configure a modern terminal environment on Ubuntu.

## What this installs

- System basics: git, curl, unzip, build tools
- Search & navigation: ripgrep, fd, fzf
- Zsh + Oh My Zsh
- Powerlevel10k prompt
- JetBrainsMono Nerd Font
- Neovim
- LazyVim (modern Neovim setup)

## Features

- ✅ Idempotent (safe to run multiple times)
- 🧾 Logged (`logs/setup.log`)
- ⚡ Fast and minimal
- 🧠 Beginner-proof, future-you friendly

## Usage

```bash
git clone https://github.com/<your-username>/ubuntu-terminal-bootstrap.git
cd ubuntu-terminal-bootstrap
chmod +x setup.sh
./setup.sh