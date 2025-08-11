BEGIN="\[\e[1;37;42m\]"
MIDDLE="\[\e[0;30;47m\]"
END="\[\e[m\]"
HOST_NAME="my-vim"
export PS1="${BEGIN} \u@${HOST_NAME} ${MIDDLE} \w ${END} "

# goenv
export PATH="$PATH:/usr/local/go/bin"

GOROOT=$(go env GOROOT)
export PATH="$PATH:${GOROOT}/bin"

GOPATH=$(go env GOPATH)
export PATH="$PATH:${GOPATH}/bin"

# nodenv
eval "$(nodenv init -)"

# shell autocompletion about uv/uvx
eval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"
