# OH-MY-ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bira"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# BUN
[ -s "/home/tieppo/.bun/_bun" ] && source "/home/tieppo/.bun/_bun"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ANGULAR
source <(ng completion script)

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ZED
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="$HOME/.local/bin/zed-sudoedit"
export VISUAL="$HOME/.local/bin/zed-sudoedit"

fastfetch
