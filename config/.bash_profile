BEGIN="\[\e[1;37;42m\]"
MIDDLE="\[\e[0;30;47m\]"
END="\[\e[m\]"
HOST_NAME="my-vim"
export PS1="${BEGIN} \u@${HOST_NAME} ${MIDDLE} \w ${END} "

export GOPATH=`go env GOPATH`
export GOROOT=`go env GOROOT`
export GOBIN=$GOROOT/bin
export PATH=$PATH:`go env GOPATH`
export PATH=$PATH:`go env GOPATH`/bin
export PATH=$PATH:`go env GOROOT`/bin
