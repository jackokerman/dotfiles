# Sesh session picker (Alt+S)
if command -v sesh &>/dev/null && command -v fzf &>/dev/null; then
  function sesh-sessions() {
    if [[ -n "${TMUX:-}" ]]; then
      tmux display-popup -E -w 55% -h 60% 'sesh-pick'
      return
    fi

    {
      exec </dev/tty
      exec <&1
      sesh-pick
    }
  }

  zle -N sesh-sessions
  bindkey -M emacs '\es' sesh-sessions
  bindkey -M vicmd '\es' sesh-sessions
  bindkey -M viins '\es' sesh-sessions
fi
