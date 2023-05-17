FROM --platform=$BUILDPLATFORM golang:1.20.4-alpine3.18 AS builder
ARG TARGETPLATFORM
WORKDIR /go/src/github.com/robbertkl/docker-ipv6nat
COPY . .
RUN [ "$TARGETPLATFORM" = "linux/amd64"  ] && echo GOOS=linux GOARCH=amd64 > .env || true
RUN [ "$TARGETPLATFORM" = "linux/arm64"  ] && echo GOOS=linux GOARCH=arm64 > .env || true
RUN [ "$TARGETPLATFORM" = "linux/arm/v6" ] && echo GOOS=linux GOARCH=arm GOARM=6 > .env || true
RUN [ "$TARGETPLATFORM" = "linux/arm/v7" ] && echo GOOS=linux GOARCH=arm GOARM=7 > .env || true
ENV CGO_ENABLED=0
RUN set -eux \
    && apk add --no-cache binutils \
    && mkdir /output
RUN go env -w GO111MODULE=on
RUN env $(cat .env | xargs) go build -o /output/docker-ipv6nat.$(echo "$TARGETPLATFORM" | sed -E 's/(^linux|\/)//g') ./build/docker-ipv6nat
RUN strip /docker-ipv6nat.*

FROM alpine:3.18 AS release
RUN set -eux \
    && apk add --no-cache ip6tables \
    && mkdir /docker-entrypoint.d
COPY --from=builder /output/docker-ipv6nat.* /docker-entrypoint.d/netd-v6nat
COPY docker-entrypoint.sh /usr/local/bin/
ENV NATPATH /docker-entrypoint.d
ENV PATH $NATPATH:$PATH
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["netd-v6nat", "--retry"]