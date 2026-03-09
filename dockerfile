FROM golang:alpine as build

RUN mkdir /caddy
WORKDIR /caddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare
    --with github.com/mholt/caddy-l4

FROM alpine:latest as run
# 1. 安装 libcap 工具
RUN apk add --no-cache ca-certificates libcap \
    && rm -rf /var/cache/apk/*

COPY --from=build /caddy/caddy /usr/local/bin/caddy

# 2. 赋予 caddy 二进制文件绑定低位端口的权限
RUN setcap cap_net_bind_service=+ep /usr/local/bin/caddy

EXPOSE 80 443
CMD ["/usr/local/bin/caddy", "run", "--environ", "--config", "/etc/caddy/Caddyfile"]
