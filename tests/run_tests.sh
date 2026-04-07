#!/usr/bin/env bash
# tests/run_tests.sh — discovers and runs all test_*.sh suites

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FAILED=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    [[ -f "$test_file" ]] || continue
    echo "Running $(basename "$test_file")..."
    bash "$test_file" || FAILED=1
done

if [[ $FAILED -eq 0 ]]; then
    echo ""
    echo "All test suites passed."
    exit 0
else
    echo ""
    echo "One or more test suites failed."
    exit 1
fi
