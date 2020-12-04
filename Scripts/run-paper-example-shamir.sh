#!/usr/bin/env bash

prog="./paper-example-shamir.x"

$prog 0 3 & \
$prog 1 3 & \
$prog 2 3

#valgrind --leak-check=full $prog 0 3 & \
#valgrind --leak-check=full $prog 1 3 & \
#valgrind --leak-check=full $prog 2 3
#
#valgrind --leak-check=full --show-leak-kinds=all $prog 0 3 & \
#valgrind --leak-check=full --show-leak-kinds=all $prog 1 3 & \
#valgrind --leak-check=full --show-leak-kinds=all $prog 2 3
