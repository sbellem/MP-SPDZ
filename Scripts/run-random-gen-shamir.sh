#!/usr/bin/env bash

prog="./random-gen-shamir.x"

#valgrind --leak-check=full --show-leak-kinds=all $prog 0 3 & \
#valgrind --leak-check=full --show-leak-kinds=all $prog 1 3 & \
#valgrind --leak-check=full --show-leak-kinds=all $prog 2 3
valgrind $prog 0 3 & \
valgrind $prog 1 3 & \
valgrind $prog 2 3
