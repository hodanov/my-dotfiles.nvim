FROM golang:1.13-alpine
WORKDIR /go/app
RUN apk --no-cache update && \
    apk add git
