# Track dotfiles-owned prompt inputs instead of reading generated p10k internals.
_dotfiles_p10k_reset_cache_if_needed() {
  emulate -L zsh

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
  local zsh_cache_dir="${ZSH_CACHE_DIR:-${cache_dir}/zsh}"
  local user="${(%):-%n}"
  local dump_file="${cache_dir}/p10k-dump-${user}.zsh"
  local instant_prompt_file="${cache_dir}/p10k-instant-prompt-${user}.zsh"
  local prompt_cache_dir="${cache_dir}/p10k-${user}"
  local signature_file="${zsh_cache_dir}/p10k-layout-signature"
  local signature_tmp="${signature_file}.$$"
  local -a left_prompt_elements=(
    dir
    vcs
    command_execution_time
    newline
    prompt_char
  )
  local gitstatus_disabled=0
  local signature

  if (( ${+DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE} )); then
    left_prompt_elements=("${DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE[@]}")
  fi

  case "${${DOTFILES_P10K_DISABLE_GITSTATUS-}:l}" in
    1|true|yes|on)
      gitstatus_disabled=1
      ;;
  esac

  signature="v1|left=${(j: :)left_prompt_elements}|gitstatus=${gitstatus_disabled}"

  if [[ -r "${signature_file}" ]] && [[ "$(<"${signature_file}")" == "${signature}" ]]; then
    return
  fi

  command mkdir -p -- "${zsh_cache_dir}" || return
  print -r -- "${signature}" >| "${signature_tmp}" || {
    command rm -f -- "${signature_tmp}"
    return
  }

  command rm -f -- "${dump_file}" "${dump_file}.zwc" "${instant_prompt_file}" "${instant_prompt_file}.zwc"
  command rm -rf -- "${prompt_cache_dir}"
  command mv -f -- "${signature_tmp}" "${signature_file}" || {
    command rm -f -- "${signature_tmp}"
    return
  }
}

_dotfiles_p10k_reset_cache_if_needed
unfunction _dotfiles_p10k_reset_cache_if_needed
