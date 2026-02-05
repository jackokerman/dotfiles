# zfetch - Simple zsh plugin manager
# Inspired by https://github.com/nicknisi/dotfiles
#
# Usage:
#   zfetch "owner/repo"                    - Install and source a plugin
#   zfetch "owner/repo" "file.zsh"         - Install and source a specific file
#   zfetch update                          - Update all plugins
#   zfetch ls                              - List installed plugins

ZPLUGDIR="${ZFETCH_PLUGIN_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"
[[ -d "$ZPLUGDIR" ]] || mkdir -p "$ZPLUGDIR"
typeset -A plugins

zfetch() {
  case $1 in
    update)
      for name in ${(@k)plugins}; do
        echo "Updating ${name}..."
        (cd $plugins[$name] && git pull --quiet --recurse-submodules)
      done
      ;;
    ls)
      for name in ${(@k)plugins}; do
        echo "${name}: $plugins[$name]"
      done
      ;;
    completions)
      # zsh-completions needs fpath set before compinit, not a plugin file sourced
      local dest="$ZPLUGDIR/zsh-completions"
      plugins[zsh-users/zsh-completions]=$dest

      if [[ ! -d $dest ]]; then
        echo "Installing zsh-users/zsh-completions..."
        git clone --quiet --depth 1 "https://github.com/zsh-users/zsh-completions" "$dest"
      fi

      fpath=($dest/src $fpath)
      ;;
    *)
      local repo="$1"
      local plugin_file="${2:-"${repo##*/}.plugin.zsh"}"
      local dest="$ZPLUGDIR/${repo##*/}"
      plugins[$repo]=$dest

      if [[ ! -d $dest ]]; then
        echo "Installing ${repo}..."
        git clone --quiet --depth 1 "https://github.com/$repo" "$dest"
      fi

      local plugin="$dest/$plugin_file"
      [[ -f "$plugin" ]] && source "$plugin"
      ;;
  esac
}
