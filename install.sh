#!/usr/bin/env bash

# Bootstrap: installs dotty if needed, then installs these dotfiles.
# On work machines this is triggered automatically by provisioning.
#
# For manual setup on a fresh machine:
#   git clone https://github.com/jackokerman/dotfiles.git
#   cd dotfiles && ./install.sh

set -e

if ! command -v dotty >/dev/null 2>&1 && ! [[ -x "$HOME/.dotty/bin/dotty" ]]; then
    curl -fsSL https://raw.githubusercontent.com/jackokerman/dotty/main/install.sh | bash
fi

export PATH="$HOME/.dotty/bin:$PATH"
dotty install "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
