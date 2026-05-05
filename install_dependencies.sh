#!/bin/bash

# Brew dependencies
brew tap jayadamsmorgan/yatoro
dependencies=(pngpaste neovim
  lazygit gh imagemagick node
  coursier/formulas/coursier git-delta
  asciiquarium btop rg
  gleanwork/tap/glean-cli
  yatoro)

# Iterate through list and then brew install each one
for i in "${dependencies[@]}"; do
  brew install "$i"
done

# Install mermaid via npm
npm install -g @mermaid-js/mermaid-cli

# Setup coursier
cs setup

# cursor
curl https://cursor.com/install -fsS | bash
echo \"export PATH="$HOME/.local/bin:$PATH\"" >>~/.zshrc
