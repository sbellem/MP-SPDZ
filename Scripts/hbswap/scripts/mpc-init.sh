#!/usr/bin/env bash
set -e

player=$1

# IMPORTANT: the hostname must be the one of player 0!
hostname=$2

# env vars are set in Dockerfile
prime=${PRIME:-52435875175126190479447740508185965837690552500527637822603658699938581184513}
n_parties=${N_PARTIES:-4}
threshold=${THRESHOLD:-1}

./malicious-shamir-party.x \
    --prime $prime \
    --nparties $n_parties \
    --threshold $threshold \
    --player $player \
    --hostname $hostname \
    --portnum 5000 \
    hbswap_init
