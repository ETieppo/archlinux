typeset -gA theme_color_props=(
  directory        '#702ded'
  symlink          '#c930c7'
  executable       '#ff6a00'
  media            '#94002F'
  special          '#e41951'
  prompt_user      '#01dc84'
  prompt_root      '#ff0051'
  prompt_path      '#0271b6'
  prompt_git       '#fffc67'
  prompt_git_dirty '#ff0051'
  prompt_error     '#ff0051'
  grep_match       '#ff0051'
)
typeset -gA ls_type_code_role_props=(
  di directory
  ln symlink
  ex executable
  or special
  mi special
  so special
  pi special
  do special
  bd special
  cd special
  su special
  sg special
  tw special
  ow special
  st special
)
typeset -gA ls_type_code_style_props=(
  di '1;'
  ex '1;'
  ln '3;'
  or '3;'
)
typeset -gA dircolors_value_role_props=(
  '01;35' media
  '00;36' media
  '01;31' special
)
typeset -ga media_extension_props=(
  mp3 flac ogg opus wav aac m4a
  mp4 mkv webm mov avi m4v wmv flv
  png jpg jpeg gif webp svg bmp ico avif tif tiff
)
typeset -ga special_extension_props=(
  zip tar tgz txz gz xz zst bz2 7z rar lz4 lzma deb rpm jar
)
typeset -ga ghostty_direct_terminfo_props=(~/.terminfo/*/xterm-ghostty-direct(N))
typeset -ga theme_ls_entry_props=()
typeset -g theme_ls_entry=""
typeset -g theme_ls_code=""
typeset -g theme_ls_value=""
typeset -g theme_extension=""

function hex_to_foreground_sgr {
  local hex_without_hash=${1#\#}
  print -r -- "38;2;$(( 16#${hex_without_hash[1,2]} ));$(( 16#${hex_without_hash[3,4]} ));$(( 16#${hex_without_hash[5,6]} ))"
}

for theme_ls_entry in ${(s.:.)LS_COLORS}; do
  theme_ls_code=${theme_ls_entry%%=*}
  theme_ls_value=${theme_ls_entry#*=}
  if [[ $theme_ls_code == \*.* && -n ${dircolors_value_role_props[$theme_ls_value]} ]]; then
    theme_ls_entry_props+=("$theme_ls_code=$(hex_to_foreground_sgr ${theme_color_props[${dircolors_value_role_props[$theme_ls_value]}]})")
  elif (( ! ${+ls_type_code_role_props[$theme_ls_code]} )); then
    theme_ls_entry_props+=("$theme_ls_entry")
  fi
done

for theme_ls_code in ${(k)ls_type_code_role_props}; do
  theme_ls_entry_props+=("$theme_ls_code=${ls_type_code_style_props[$theme_ls_code]}$(hex_to_foreground_sgr ${theme_color_props[${ls_type_code_role_props[$theme_ls_code]}]})")
done

for theme_extension in $media_extension_props; do
  theme_ls_entry_props+=("*.$theme_extension=$(hex_to_foreground_sgr ${theme_color_props[media]})")
done

for theme_extension in $special_extension_props; do
  theme_ls_entry_props+=("*.$theme_extension=$(hex_to_foreground_sgr ${theme_color_props[special]})")
done

export LS_COLORS="${(j.:.)theme_ls_entry_props}"
export GREP_COLORS="mt=1;$(hex_to_foreground_sgr ${theme_color_props[grep_match]})"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

[[ $TERM == xterm-ghostty ]] && (( $#ghostty_direct_terminfo_props )) && alias vifm='TERM=xterm-ghostty-direct vifm'

ZSH_THEME_GIT_PROMPT_PREFIX="%F{${theme_color_props[prompt_git]}}‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="› %f"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{${theme_color_props[prompt_git_dirty]}}●%F{${theme_color_props[prompt_git]}}"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{${theme_color_props[prompt_git]}}"
PROMPT="╭─%B%(!.%F{${theme_color_props[prompt_root]}}.%F{${theme_color_props[prompt_user]}})%n@%m%f %F{${theme_color_props[prompt_path]}}%~ %f%b"'$(git_prompt_info)'"
╰─%B%(!.#.$)%b "
RPROMPT="%B%(?..%F{${theme_color_props[prompt_error]}}%? ↵%f)%b"

unset ls_type_code_role_props ls_type_code_style_props dircolors_value_role_props media_extension_props special_extension_props
unset ghostty_direct_terminfo_props theme_ls_entry_props theme_ls_entry theme_ls_code theme_ls_value theme_extension
unfunction hex_to_foreground_sgr
