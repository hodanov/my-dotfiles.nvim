BEGIN="\[\e[1;37;42m\]"
MIDDLE="\[\e[0;30;47m\]"
END="\[\e[m\]"
HOST_NAME="my-vim"
export PS1="${BEGIN} \u@${HOST_NAME} ${MIDDLE} \w ${END} "

# goenv
export GOENV_ROOT="$HOME/.goenv" # /root/.goenv
export PATH="$GOENV_ROOT/bin:$PATH" # /root/.goenv/bin:$PATH
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH" # /root/.goenv/versions/1.1x.x:$PATH
export PATH="$PATH:$GOPATH/bin" # $PATH:/root/go/1.16.0/bin

# nodenv
eval "$(nodenv init -)"
