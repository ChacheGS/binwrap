#!/usr/bin/env bash
# tests/test_reviewer.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Reviewer alias tests ==="

setup_fake_claude

TEST_BINWRAP_HOME=$(mktemp -d)
mkdir -p "$TEST_BINWRAP_HOME/claude/modes"
echo "You are a concise code reviewer." > "$TEST_BINWRAP_HOME/claude/modes/reviewer.md"
cp "$SCRIPT_DIR/../extensions/claude/reviewer.sh" "$TEST_BINWRAP_HOME/claude/reviewer.sh"

# Test: --reviewer loads modes/reviewer.md as system prompt (no value consumed)
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --reviewer 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "--reviewer: translates to --append-system-prompt with file content" \
    "--append-system-prompt You are a concise code reviewer." "$received"

# Test: --reviewer alongside other flags
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --reviewer --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "--reviewer: other flags still forwarded" "--model sonnet" "$received"
assert_contains "--reviewer: --append-system-prompt present" "--append-system-prompt" "$received"

# Test: --reviewer with missing modes/reviewer.md → exit 1
rm "$TEST_BINWRAP_HOME/claude/modes/reviewer.md"
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --reviewer 2>&1)
exit_code=$?
binary_called=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--reviewer missing file: exits 1" "1" "$exit_code"
assert_contains "--reviewer missing file: error mentions reviewer" "reviewer" "$output"
assert_equals "--reviewer missing file: binary not called" "" "$binary_called"

rm -rf "$TEST_BINWRAP_HOME"
teardown_fake_claude
print_summary "Reviewer alias tests"
