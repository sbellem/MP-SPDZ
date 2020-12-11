#!/usr/bin/env bash

./random-shamir.x -i 0 -N 8 -T 1 \
    & ./random-shamir.x -i 1 -N 8 -T 1 \
    & ./random-shamir.x -i 2 -N 8 -T 1 \
    & ./random-shamir.x -i 3 -N 8 -T 1 \
    & ./random-shamir.x -i 4 -N 8 -T 1 \
    & ./random-shamir.x -i 5 -N 8 -T 1 \
    & ./random-shamir.x -i 6 -N 8 -T 1 \
    & ./random-shamir.x -i 7 -N 8 -T 1
