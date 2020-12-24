#!/usr/bin/env bash
set -e

compile() {
  ./compile.py -v -C -F 256 $1
}

compile hbswap_init
compile hbswap_trade_prep
compile hbswap_trade
