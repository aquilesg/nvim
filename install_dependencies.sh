#!/bin/bash

# Binaries the config shells out to. LSPs, formatters, and linters are not
# here -- mason installs those via :MasonInstallAll.
dependencies=(neovim
  git ripgrep tree-sitter-cli

  # Pickers and git integration
  lazygit gh git-delta

  # snacks.image rendering
  imagemagick mermaid-cli

  # markdown-preview.nvim build step
  yarn

  # nvim-metals bootstraps the server with `cs`
  coursier/formulas/coursier

  # Toggleterm floats
  btop jayadamsmorgan/yatoro/yatoro gleanwork/tap/glean-cli)

# claude-code: <leader>a float. obsidian: <leader>op* pomodoro keymaps, which
# call obsidian-cli from inside the app bundle. The nerd font supplies the
# statusline and devicon glyphs; it is the family kitty.conf asks for.
casks=(claude-code obsidian font-roboto-mono-nerd-font)

for i in "${dependencies[@]}"; do
  brew install "$i"
done

for i in "${casks[@]}"; do
  brew install --cask "$i"
done

# The pomodoro keymaps expect the app's CLI on PATH.
if [ ! -e /opt/homebrew/bin/obsidian ]; then
  ln -s /Applications/Obsidian.app/Contents/MacOS/obsidian-cli \
    /opt/homebrew/bin/obsidian
fi

# Install mermaid via npm
npm install -g @mermaid-js/mermaid-cli

# On the work computer (node managed by asdf) the global npm binary needs a
# reshim so `mmdc` resolves for the current node version.
if [ -n "$AWS_ENVIRONMENT" ]; then
  asdf reshim nodejs
fi

# Setup coursier
cs setup

# cursor
curl https://cursor.com/install -fsS | bash
if ! grep -q ".local/bin" ~/.zshrc; then
  # shellcheck disable=SC2016 # written literally so .zshrc expands it at shell start
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.zshrc
fi
