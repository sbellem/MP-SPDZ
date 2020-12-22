#!/usr/bin/env bash

./random-shamir.x -i 0 -N 7 \
    & ./random-shamir.x -i 1 -N 7 -T 3 \
    & ./random-shamir.x -i 2 -N 7 -T 3 \
    & ./random-shamir.x -i 3 -N 7 -T 3 \
    & ./random-shamir.x -i 4 -N 7 -T 3 \
    & ./random-shamir.x -i 5 -N 7 -T 3 \
    & ./random-shamir.x -i 6 -N 7 -T 3
