BEGIN="\[\e[1;37;42m\]"
MIDDLE="\[\e[0;30;47m\]"
END="\[\e[m\]"
HOST_NAME="my-vim"
export PS1="${BEGIN} \u@${HOST_NAME} ${MIDDLE} \w ${END} "

# goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
# export GOROOT=`go env GOROOT`
# export PATH=$PATH:$GOROOT/bin
export GOPATH=`go env GOPATH`
export PATH=$PATH:$GOPATH/bin

# nodenv
eval "$(nodenv init -)"