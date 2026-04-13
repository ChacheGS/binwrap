#!/usr/bin/env bash
# tests/test_mode.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Mode handler tests ==="

setup_fake_claude

TEST_BINWRAP_HOME=$(mktemp -d)
mkdir -p "$TEST_BINWRAP_HOME/claude/mode"
echo "You are a helpful assistant in test mode." > "$TEST_BINWRAP_HOME/claude/mode/test-mode.md"
cp "$SCRIPT_DIR/../extensions/claude/mode.sh" "$TEST_BINWRAP_HOME/claude/mode.sh"

# Test: --mode valid-name → --append-system-prompt <file content>
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --mode test-mode 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
expected_content="You are a helpful assistant in test mode."
assert_equals "--mode: translates to --append-system-prompt with file content" \
    "--append-system-prompt $expected_content" "$received"

# Test: --mode valid-name alongside other flags
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --mode test-mode --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "--mode: other flags still forwarded" "--model sonnet" "$received"
assert_contains "--mode: --append-system-prompt present" "--append-system-prompt" "$received"

# Test: --mode missing-name → exit 1, informative error, binary not called
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --mode nonexistent 2>&1)
exit_code=$?
binary_called=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--mode missing: exits 1" "1" "$exit_code"
assert_contains "--mode missing: error mentions mode name" "nonexistent" "$output"
assert_equals "--mode missing: binary not called" "" "$binary_called"

# Test: --mode with no value provided → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --mode 2>&1)
exit_code=$?
assert_exit_code "--mode no value: exits 1" "1" "$exit_code"

# Test: --mode followed immediately by another flag → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --mode --model 2>&1)
exit_code=$?
assert_exit_code "--mode flag-as-value: exits 1" "1" "$exit_code"
assert_contains "--mode flag-as-value: error mentions requirement" "--mode requires a value" "$output"

rm -rf "$TEST_BINWRAP_HOME"
teardown_fake_claude
print_summary "Mode handler tests"
