[[ -o interactive ]] || return
(( $+commands[qs] )) || return

typeset -g _qs_job=""
typeset -ga _qs_skip=(nvim vim vi nano less more man ssh mosh htop btop top fl tmux zellij claude lazygit fzf watch su sudoedit snvim psql mysql sqlite3)
typeset -ga _qs_repl=(python python3 node bun deno irb ghci iex lua)

_qs_preexec() {
  local -a w=(${(z)1})
  while [[ $w[1] == *=* || $w[1] == (sudo|doas|time|nohup|env) ]]; do shift w; done
  (( $#w )) || return
  (( ${_qs_skip[(Ie)${w[1]:t}]} )) && return
  (( $#w == 1 && ${_qs_repl[(Ie)${w[1]:t}]} )) && return
  _qs_job="$$-$EPOCHREALTIME"
  qs ipc call term start "$_qs_job" "$1" "$PWD" &>/dev/null &!
}

_qs_precmd() {
  local s=$?
  [[ -n $_qs_job ]] || return 0
  qs ipc call term end "$_qs_job" "$s" &>/dev/null &!
  _qs_job=""
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook preexec _qs_preexec
precmd_functions=(_qs_precmd ${precmd_functions:#_qs_precmd})
