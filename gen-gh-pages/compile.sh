#!/usr/bin/env bash

export PATH="$HOME/.cask/bin:$HOME/.evm/bin:$PATH"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TARGET=$(readlink -f "$THIS_DIR/../dotfiles/emacs.d/README.org")

git clone https://github.com/rejeep/evm.git "$HOME/.evm"
evm config path /tmp
evm install emacs-25.1-travis --use --skip
export EMACS="$(evm bin)"

git clone https://github.com/cask/cask
export PATH=$(pwd)/cask/bin:$PATH

cask install
cask exec "$EMACS" --script generate-html.el

mv "$THIS_DIR/../dotfiles/emacs.d/README.html" .

