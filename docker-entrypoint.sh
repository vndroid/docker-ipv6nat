#!/bin/sh
# vim:sw=4:ts=4:et

set -e

BINARY="xtables-legacy-multi"

if iptables-nft -L 2> /dev/null | grep -q "Chain DOCKER "
then
    BINARY="xtables-nft-multi"
fi

ln -nfs "${BINARY}" /sbin/iptables
ln -nfs "${BINARY}" /sbin/iptables-save
ln -nfs "${BINARY}" /sbin/iptables-restore
ln -nfs "${BINARY}" /sbin/ip6tables
ln -nfs "${BINARY}" /sbin/ip6tables-save
ln -nfs "${BINARY}" /sbin/ip6tables-restore
hash -r

if [ "$1" = "docker-ipv6nat" ]; then
    exec /docker-entrypoint.d/docker-ipv6nat "--retry"
fi

exec "$@"