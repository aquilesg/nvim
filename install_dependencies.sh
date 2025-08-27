#!/bin/bash

# Brew dependencies
dependencies=(pngpaste neovim lazygit gh imagemagick node coursier/formulas/coursier)

# Iterate through list and then brew install each one
for i in "${dependencies[@]}"; do
  brew install "$i"
done

# Install mermaid via npm
npm install -g @mermaid-js/mermaid-cli

# Setup coursier
cs setup
