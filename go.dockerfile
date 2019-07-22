FROM golang:1.12.7-alpine
WORKDIR /go/app
RUN apk --no-cache update && \
    apk add git