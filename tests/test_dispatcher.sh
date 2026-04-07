#!/usr/bin/env bash
# tests/test_dispatcher.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../claude"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Dispatcher tests ==="

setup_fake_claude

# Test: args with no matching handler are forwarded to claude unchanged
> "$FAKE_CLAUDE_LOG"
"$WRAPPER" --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "pass-through: unknown flag forwarded" "--model sonnet" "$received"

# Test: multiple unknown args all forwarded
> "$FAKE_CLAUDE_LOG"
"$WRAPPER" --model sonnet --no-stream 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "pass-through: multiple unknown flags forwarded" "--model sonnet --no-stream" "$received"

# Test: no args — claude called with empty args
> "$FAKE_CLAUDE_LOG"
"$WRAPPER" 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "pass-through: no args" "" "$received"

teardown_fake_claude
print_summary "Dispatcher tests"
