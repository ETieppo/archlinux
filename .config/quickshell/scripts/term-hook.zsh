[[ -o interactive ]] || return
(( $+commands[qs] )) || return

typeset -g _qs_job=""

_qs_preexec() {
  _qs_job="$$-$EPOCHREALTIME"
  qs ipc call term start "$_qs_job" "$1" "$PWD" &>/dev/null &!
}

_qs_precmd() {
  local exit_status=$?
  [[ -n $_qs_job ]] || return 0
  qs ipc call term end "$_qs_job" "$exit_status" &>/dev/null &!
  _qs_job=""
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook preexec _qs_preexec
precmd_functions=(_qs_precmd ${precmd_functions:#_qs_precmd})
