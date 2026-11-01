export EDITOR="nvim"
export SUDO_EDITOR=nvim
alias snvim="sudo XDG_CONFIG_HOME=$HOME/.config nvim"
alias dot='git --git-dir=$HOME/.archlinux --work-tree=$HOME'
alias ndot='git -C $HOME/.config/nvim'

# OH-MY-ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bira"
plugins=(git)
source $ZSH/oh-my-zsh.sh
source ~/.config/zsh/theme-colors.zsh

# NVM | NODE | BUN | TS | ANGULAR | NESTJS
[ -s "/home/tieppo/.bun/_bun" ] && source "/home/tieppo/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export PATH="$HOME/.local/bin:$PATH"

source ~/.config/quickshell/scripts/term-hook.zsh
export PATH="/usr/lib/qt6/bin:$PATH"

# RUST
export PATH="$PATH:$HOME/.cargo/bin"

# BREW
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
