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

# Test: WRAPPER_ERROR causes exit 1, prints message to stderr, claude not called
TEMP_HANDLER_DIR=$(mktemp -d)
echo 'WRAPPER_ERROR="deliberate test error"' > "$TEMP_HANDLER_DIR/failing.sh"

> "$FAKE_CLAUDE_LOG"
output=$(WRAPPER_HANDLER_DIR="$TEMP_HANDLER_DIR" "$WRAPPER" --failing 2>&1)
exit_code=$?
claude_called=$(cat "$FAKE_CLAUDE_LOG")

assert_exit_code "error: exits 1 when WRAPPER_ERROR set" "1" "$exit_code"
assert_contains "error: prints wrapper prefix to stderr" "claude-wrapper:" "$output"
assert_contains "error: message body in stderr" "deliberate test error" "$output"
assert_equals "error: claude not called" "" "$claude_called"

rm -rf "$TEMP_HANDLER_DIR"

teardown_fake_claude
print_summary "Dispatcher tests"
