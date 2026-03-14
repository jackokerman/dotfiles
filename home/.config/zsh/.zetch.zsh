# zetch - Minimal zsh plugin manager with parallel installs
#
# Usage:
#   zetch install <plugins...>       Clone missing plugins in parallel
#   zetch <owner/repo>               Source a plugin (auto-detects init file)
#   zetch compinit <fpath-dirs...>   Prepend dirs to fpath and run compinit
#   zetch update                     Pull all installed plugins
#
# Example (.zshrc):
#   source $ZDOTDIR/.zetch.zsh
#
#   plugins=(romkatv/powerlevel10k zsh-users/zsh-completions Aloxaf/fzf-tab)
#   zetch install $plugins
#
#   zetch romkatv/powerlevel10k
#   zetch compinit $HOME/.local/share/zsh/site-functions $ZPLUGINDIR/zsh-completions/src
#   zetch Aloxaf/fzf-tab

ZPLUGINDIR="${ZPLUGINDIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"
[[ -d "$ZPLUGINDIR" ]] || mkdir -p "$ZPLUGINDIR"

zetch() {
  case "$1" in
    install)
      shift
      local repo dest missing=()
      for repo in "$@"; do
        dest="$ZPLUGINDIR/${repo##*/}"
        [[ -d "$dest" ]] || missing+=("$repo")
      done
      (( ${#missing} == 0 )) && return
      for repo in "${missing[@]}"; do
        dest="$ZPLUGINDIR/${repo##*/}"
        git clone --quiet --depth 1 "https://github.com/$repo" "$dest" &
      done
      wait
      ;;

    compinit)
      shift
      local dir
      for dir in "$@"; do
        [[ -d "$dir" ]] && fpath=("$dir" $fpath)
      done
      if ! (( $+functions[_complete] )); then
        autoload -Uz compinit && compinit
      fi
      compdef _zetch zetch
      ;;

    update)
      local gitdir
      for gitdir in "$ZPLUGINDIR"/*/.git(/N); do
        local dir="${gitdir:h}"
        echo "Updating ${dir:t}..."
        (cd "$dir" && git pull --quiet)
      done
      ;;

    */*)
      local repo="$1"
      local name="${repo##*/}"
      local dest="$ZPLUGINDIR/$name"

      if [[ ! -d "$dest" ]]; then
        git clone --quiet --depth 1 "https://github.com/$repo" "$dest"
      fi

      local canonical="$dest/$name.plugin.zsh"
      if [[ -L "$canonical" || -f "$canonical" ]]; then
        source "$canonical"
        return
      fi

      local initfile
      for initfile in \
        "$dest"/*.plugin.zsh(N[1]) \
        "$dest"/*.zsh-theme(N[1]) \
        "$dest"/*.zsh(N[1]) \
        "$dest"/*.sh(N[1]); do
        ln -sf "$initfile" "$canonical"
        source "$canonical"
        return
      done
      ;;

    *)
      echo "zetch: unknown command '$1'" >&2
      return 1
      ;;
  esac
}

_zetch() {
  if (( CURRENT == 2 )); then
    _describe 'command' '(
      install:Clone\ missing\ plugins\ in\ parallel
      compinit:Prepend\ dirs\ to\ fpath\ and\ run\ compinit
      update:Pull\ all\ installed\ plugins
    )'
  fi
}
