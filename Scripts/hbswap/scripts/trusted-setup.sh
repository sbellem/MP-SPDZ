#!/usr/bin/env bash
set -e

players=4

setup() {
  Scripts/setup-ssl.sh $players
}

compile() {
  ./compile.py -v -C -F 256 $1
}
