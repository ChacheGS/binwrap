#!/usr/bin/env bash
# tests/test_dispatcher.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Dispatcher tests ==="

setup_fake_claude

# Test: unknown flags forwarded to the binary unchanged
> "$FAKE_CLAUDE_LOG"
"$WRAPPER" claude --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "pass-through: unknown flag forwarded" "--model sonnet" "$received"

# Test: multiple unknown args all forwarded
> "$FAKE_CLAUDE_LOG"
"$WRAPPER" claude --model sonnet --no-stream 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "pass-through: multiple unknown flags forwarded" "--model sonnet --no-stream" "$received"

# Test: no extra args — binary called with empty args
> "$FAKE_CLAUDE_LOG"
"$WRAPPER" claude 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "pass-through: no args" "" "$received"

# Test: WRAPPER_ERROR causes exit 1, prints message to stderr, binary not called
TEMP_BINWRAP_HOME=$(mktemp -d)
mkdir -p "$TEMP_BINWRAP_HOME/testbin"
echo 'WRAPPER_ERROR="deliberate test error"' > "$TEMP_BINWRAP_HOME/testbin/failing.sh"

> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEMP_BINWRAP_HOME" "$WRAPPER" testbin --failing 2>&1)
exit_code=$?
binary_called=$(cat "$FAKE_CLAUDE_LOG")

assert_exit_code "error: exits 1 when WRAPPER_ERROR set" "1" "$exit_code"
assert_contains "error: prints binwrap prefix to stderr" "binwrap:" "$output"
assert_contains "error: message body in stderr" "deliberate test error" "$output"
assert_equals "error: binary not called" "" "$binary_called"

rm -rf "$TEMP_BINWRAP_HOME"

# Test: handler that calls exit → exit 1, binary not called
TEMP_BINWRAP_HOME2=$(mktemp -d)
mkdir -p "$TEMP_BINWRAP_HOME2/testbin"
echo 'exit 0' > "$TEMP_BINWRAP_HOME2/testbin/exits.sh"

> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEMP_BINWRAP_HOME2" "$WRAPPER" testbin --exits 2>&1)
exit_code=$?
binary_called=$(cat "$FAKE_CLAUDE_LOG")

assert_exit_code "sandbox: handler exit → exits 1" "1" "$exit_code"
assert_contains "sandbox: handler exit → error message" "called exit" "$output"
assert_equals "sandbox: handler exit → binary not called" "" "$binary_called"

rm -rf "$TEMP_BINWRAP_HOME2"

# Test: side-effects-only handler (no args appended) → binary still called, no error
TEMP_BINWRAP_HOME3=$(mktemp -d)
mkdir -p "$TEMP_BINWRAP_HOME3/testbin"
echo '# no-op handler' > "$TEMP_BINWRAP_HOME3/testbin/sideeffect.sh"

> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEMP_BINWRAP_HOME3" "$WRAPPER" testbin --sideeffect --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")

assert_equals "sandbox: side-effects-only handler → remaining args forwarded" "--model sonnet" "$received"

rm -rf "$TEMP_BINWRAP_HOME3"

# Test: missing binary argument → exit 1
output=$("$WRAPPER" 2>&1)
exit_code=$?
assert_exit_code "no binary arg: exits 1" "1" "$exit_code"
assert_contains "no binary arg: usage in stderr" "usage" "$output"

teardown_fake_claude
print_summary "Dispatcher tests"
