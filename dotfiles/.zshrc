####################
# Prompt settings
####################
HOST_NAME=`hostname`
USER_NAME=`whoami`

# Simple
# PS1="%K{cyan}%F{black} $USER_NAME@$HOST_NAME %f%k%F{cyan}%K{white}%k%f%F{black}%K{white} %d %k%f "

# Rich
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' %b'
precmd() {
  vcs_info
  PS1="%K{cyan}%F{black} %n@%m %f%k\
%F{cyan}%K{white}%F{black} %~ %f%k\
%F{white} %F{cyan}${vcs_info_msg_0_}%f
%(?.%F{cyan}.%F{yellow})❯%f "
}

export LC_ALL=en_US.UTF-8

####################
# Alias
####################
alias python="python3"
alias pip="pip3"
# alias nvim='docker container exec -it -w ${HOME}/workspace nvim-dev bash --login'
# bash --login -c "nvim \"\$@\"; exec bash --login"
nvim() {
  local host_pwd=$(pwd)
  docker container exec -it \
    -w "$host_pwd" \
    nvim-dev \
    bash --login -c "nvim \"\$@\""
}

####################
# Go path
####################
export PATH="$PATH:$(go env GOPATH)/bin"

####################
# Add Docker Desktop for Mac (docker)
####################
export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin/"

####################
# Load git and docker completion
####################
zstyle ':completion:*:*:git:*' script ~/.zsh/completion/git-completion.bash
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/hodanov/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

####################
# anyenv
####################
eval "$(anyenv init -)"

####################
# cursor cli
####################
export PATH="$HOME/.local/bin:$PATH"

####################
# curl
####################
export PATH="/usr/local/opt/curl/bin:$PATH"

####################
# ghq & peco
####################
# alias repo='cd $(ghq list --full-path --exact | peco)'

####################
# AI CLI
####################
alias al="claude"
export VISUAL=nvim
export EDITOR=nvim
export BLOG_IDEA_DRAFT_EXPORT_DIR="$HOME/workspace/hodalog-hugo/docs/idea"
# codex
eval "$(codex completion zsh)"
