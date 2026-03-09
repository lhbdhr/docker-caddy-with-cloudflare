# 使用 buildx 提供的平台变量
FROM --platform=$BUILDPLATFORM golang:alpine AS build

# 接收来自 buildx 的构建参数
ARG TARGETOS
ARG TARGETARCH

RUN apk add --no-cache git

WORKDIR /caddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# 关键点：设置环境变量让 Go 进行原生交叉编译，而不是模拟运行
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4 \
    --output /caddy/caddy

FROM alpine:latest AS run
RUN apk add --no-cache ca-certificates libcap \
    && rm -rf /var/cache/apk/*

COPY --from=build /caddy/caddy /usr/local/bin/caddy
RUN setcap cap_net_bind_service=+ep /usr/local/bin/caddy

EXPOSE 80 443 2019
CMD ["/usr/local/bin/caddy", "run", "--environ", "--config", "/etc/caddy/Caddyfile"]