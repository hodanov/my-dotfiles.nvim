FROM golang:1.13-alpine
ENV GITHUB_USER_NAME='hodanov'
RUN apk --no-cache update \
    && apk add git \
    # Hot reload
    && go get github.com/oxequa/realize \
    # REPL
    && go get github.com/motemen/gore/cmd/gore \
    # Completion on gore and highlight on gore
    && go get github.com/mdempsky/gocode \
    && go get github.com/k0kubun/pp \
    # Add all golang default packages
    && go get golang.org/x/tools/cmd/... \
    # Linter
    && go get golang.org/x/lint/golint
WORKDIR /go/src/github.com/${GITHUB_USER_NAME}
