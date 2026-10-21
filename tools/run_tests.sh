#!/bin/bash
# Runs the automated test suite headless, in two halves (each in its own
# process, so neither gets near the time limit). Exit code 0 = all passed.
#   tools/run_tests.sh        both halves
#   tools/run_tests.sh 1|2    one half
cd "$(dirname "$0")/.."
run() {
  timeout 590 ../tools/godot --headless --path . --audio-driver Dummy res://tests/TestRunner.tscn -- --part=$1 2>&1 \
    | grep -v -E "^\s*$|leaked|at: |resources still in use|ObjectDB"
  return ${PIPESTATUS[0]}
}
if [ -n "$1" ]; then run $1; exit $?; fi
run 1; a=$?
run 2; b=$?
[ $a -eq 0 ] && [ $b -eq 0 ]
