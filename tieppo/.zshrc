export EDITOR="nvim"

# OH-MY-ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="darkblood"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# NVM | NODE | BUN | TS | ANGULAR | NESTJS
[ -s "/home/tieppo/.bun/_bun" ] && source "/home/tieppo/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
source <(ng completion script)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
