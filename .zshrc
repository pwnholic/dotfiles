if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

alias zshconfig="vim ~/.zshrc"
alias nv="nvim"
alias clocf="cloc --exclude-dir=.git --by-file-by-lang ."
alias chromium="flatpak run org.chromium.Chromium"
alias okular="flatpak run org.kde.okular"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
ENABLE_CORRECTION="false"

source $ZSH/oh-my-zsh.sh
source ~/.config/zsh_plugins/powerlevel10k/powerlevel10k.zsh-theme
source ~/.config/zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

export LANG=en_US.UTF-8
export EDITOR='nvim'
export GOPATH=$HOME/Dev/go
export GOBIN=$GOPATH/bin
export JAVA_HOME=/opt/jdk-20.0.1
export GO111MODULE="on"
export PKG_CONFIG_PATH=/usr/lib/pkgconfig
export BUN_INSTALL="$HOME/.bun/bin"
export CARGO_BIN="$HOME/.cargo/bin"
export LOCAL_BIN="$HOME/.local/bin"
export MASON_BIN="$HOME/.local/share/nvim/mason/bin"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -s "/home/user007/.bun/_bun" ] && source "/home/user007/.bun/_bun"

if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi

export PATH=$PATH:$GOPATH:$GOBIN:$JAVA_HOME:$MASON:$PKG_CONFIG_PATH:$BUN_INSTALL:$CARGO_BIN:$LOCAL_BIN:$MASON_BIN:$OPEN_AI_KEY
