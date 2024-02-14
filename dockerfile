FROM golang:alpine as build

RUN mkdir /caddy
WORKDIR /caddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM alpine:latest as run
COPY --from=build /caddy/caddy /usr/local/bin/caddy
RUN apk add --no-cache ca-certificates \
    && rm -rf /var/cache/apk/*

EXPOSE 80 443
CMD ["/usr/local/bin/caddy", "run", "--environ", "--config", "/etc/caddy/Caddyfile"]
