FROM --platform=$BUILDPLATFORM golang:1.19.7-alpine3.17 AS build
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/robbertkl/docker-ipv6nat
COPY . .
RUN [ "$TARGETPLATFORM" = "linux/amd64"  ] && echo GOOS=linux GOARCH=amd64 > .env || true
RUN [ "$TARGETPLATFORM" = "linux/arm64"  ] && echo GOOS=linux GOARCH=arm64 > .env || true
RUN [ "$TARGETPLATFORM" = "linux/arm/v6" ] && echo GOOS=linux GOARCH=arm GOARM=6 > .env || true
RUN [ "$TARGETPLATFORM" = "linux/arm/v7" ] && echo GOOS=linux GOARCH=arm GOARM=7 > .env || true
ENV CGO_ENABLED=0
RUN set -x \
    && apk add --no-cache binutils
RUN go env -w GO111MODULE=auto
RUN env $(cat .env | xargs) go build -o /docker-ipv6nat.$(echo "$TARGETPLATFORM" | sed -E 's/(^linux|\/)//g') ./cmd/docker-ipv6nat
RUN strip /docker-ipv6nat.*

FROM alpine:3.17 AS release
RUN set -x \
    && apk add --no-cache ip6tables \
    && mkdir /docker-entrypoint.d
COPY --from=build /docker-ipv6nat.* /docker-entrypoint.d/docker-ipv6nat
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-ipv6nat", "--retry"]
