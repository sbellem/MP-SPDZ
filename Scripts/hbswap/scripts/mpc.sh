#!/usr/bin/env bash
set -e

#host=${1:-localhost}
chain_hostname=$1

httpserver() {
  python3 Scripts/hbswap/python/server/start_server.py $1
}

mpcserver() {
  go run Scripts/hbswap/go/server/server.go $1 $chain_hostname > Scripts/hbswap/log/mpc_server_$1.log 2>&1
}

mkdir -p Persistence
rm -rf Persistence/*

httpserver 0 &
httpserver 1 &
httpserver 2 &
httpserver 3 &

mpcserver 0 &
mpcserver 1 &
mpcserver 2 &
mpcserver 3
