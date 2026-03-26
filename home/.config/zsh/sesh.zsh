# Sesh session picker (Alt+S from outside tmux)
if command -v sesh &>/dev/null && command -v fzf &>/dev/null; then
  function sesh-sessions() {
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
