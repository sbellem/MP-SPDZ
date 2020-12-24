#!/usr/bin/env bash
set -e

httpserver() {
  python3 Scripts/hbswap/python/server/start_server.py $1
}

mpcserver() {
  go run Scripts/hbswap/go/server/server.go $1 > Scripts/hbswap/log/mpc_server_$1.log 2>&1
}

httpserver 0 &
httpserver 1 &
httpserver 2 &
httpserver 3 &

mpcserver 0 &
mpcserver 1 &
mpcserver 2 &
mpcserver 3
