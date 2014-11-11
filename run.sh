#!/bin/bash

set -e

echo "generating..."
./generate.py $*

cd work

echo "making..."
make

echo "running..."
time ./solver_tb --vcd=solver.vcd 2>&1
# time ./solver_tb --stop-time=100ms

# | grep "note.*var" | sed 's/.* \(\-*\)var\([0-9]\)*$/\1\2/g' | xargs
