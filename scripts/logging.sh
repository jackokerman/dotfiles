#!/usr/bin/env bash
#
# Shared logging utilities for dotfiles scripts
# Source this file with: source "$(dirname "$0")/logging.sh"

COLOR_BLUE="\033[34m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_PURPLE="\033[35m"
COLOR_YELLOW="\033[33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1" >&2
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

verbose_info() {
    if [[ "${DOTTY_VERBOSE:-false}" == "true" ]]; then
        info "$1"
    fi
}
