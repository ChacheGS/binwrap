#!/usr/bin/env bash
# tests/test_mode.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../claude"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Mode handler tests ==="

setup_fake_claude

# Set up a temp extensions home with a test mode file
TEST_EXTENSIONS_HOME=$(mktemp -d)
mkdir -p "$TEST_EXTENSIONS_HOME/modes"
echo "You are a helpful assistant in test mode." > "$TEST_EXTENSIONS_HOME/modes/test-mode.md"

# Test: --mode valid-name → --append-system-prompt <absolute-path>
> "$FAKE_CLAUDE_LOG"
CLAUDE_EXTENSIONS_HOME="$TEST_EXTENSIONS_HOME" "$WRAPPER" --mode test-mode 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
expected_path="$TEST_EXTENSIONS_HOME/modes/test-mode.md"
assert_equals "--mode: translates to --append-system-prompt with full path" \
    "--append-system-prompt $expected_path" "$received"

# Test: --mode valid-name alongside other flags
> "$FAKE_CLAUDE_LOG"
CLAUDE_EXTENSIONS_HOME="$TEST_EXTENSIONS_HOME" "$WRAPPER" --mode test-mode --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "--mode: other flags still forwarded" "--model sonnet" "$received"
assert_contains "--mode: --append-system-prompt present" "--append-system-prompt" "$received"

# Test: --mode missing-name → exit 1, informative error, claude not called
> "$FAKE_CLAUDE_LOG"
output=$(CLAUDE_EXTENSIONS_HOME="$TEST_EXTENSIONS_HOME" "$WRAPPER" --mode nonexistent 2>&1)
exit_code=$?
claude_called=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--mode missing: exits 1" "1" "$exit_code"
assert_contains "--mode missing: error mentions mode name" "nonexistent" "$output"
assert_equals "--mode missing: claude not called" "" "$claude_called"

# Test: --mode with no value provided → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(CLAUDE_EXTENSIONS_HOME="$TEST_EXTENSIONS_HOME" "$WRAPPER" --mode 2>&1)
exit_code=$?
assert_exit_code "--mode no value: exits 1" "1" "$exit_code"

# Test: --mode followed immediately by another flag (no value) → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(CLAUDE_EXTENSIONS_HOME="$TEST_EXTENSIONS_HOME" "$WRAPPER" --mode --model 2>&1)
exit_code=$?
assert_exit_code "--mode flag-as-value: exits 1" "1" "$exit_code"
assert_contains "--mode flag-as-value: error mentions requirement" "--mode requires a value" "$output"

rm -rf "$TEST_EXTENSIONS_HOME"
teardown_fake_claude
print_summary "Mode handler tests"
