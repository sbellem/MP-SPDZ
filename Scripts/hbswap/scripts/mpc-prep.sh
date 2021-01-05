#!/usr/bin/env bash
set -e

players=4
threshold=1
port=5000
prime=52435875175126190479447740508185965837690552500527637822603658699938581184513

prog="malicious-shamir-party.x"

run() {
    ./$prog -N $players -T $threshold -p 0 -pn $port -P $prime $1 &
    ./$prog -N $players -T $threshold -p 1 -pn $port -P $prime $1 &
    ./$prog -N $players -T $threshold -p 2 -pn $port -P $prime $1 &
    ./$prog -N $players -T $threshold -p 3 -pn $port -P $prime $1 
}

org() {
    cd Persistence/
    mv 'Transactions-P0.data' 'Pool-P0.data'
    mv 'Transactions-P1.data' 'Pool-P1.data'
    mv 'Transactions-P2.data' 'Pool-P2.data'
    mv 'Transactions-P3.data' 'Pool-P3.data'
}

run hbswap_init
org
