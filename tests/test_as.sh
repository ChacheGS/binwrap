#!/usr/bin/env bash
# tests/test_as.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== --as handler tests ==="

setup_fake_claude

TEST_BINWRAP_HOME=$(mktemp -d)
mkdir -p "$TEST_BINWRAP_HOME/claude"
cp "$SCRIPT_DIR/../extensions/claude/as.sh" "$TEST_BINWRAP_HOME/claude/as.sh"

# Test: --as <persona> <task> → --append-system-prompt "You are <persona>. Your task: <task>"
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --as "a senior engineer" "review this code" 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "--as: builds system prompt from persona and task" \
    "--append-system-prompt You are a senior engineer. Your task: review this code" "$received"

# Test: --as alongside other flags
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --as "a teacher" "explain this" --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "--as: other flags still forwarded" "--model sonnet" "$received"
assert_contains "--as: --append-system-prompt present" "--append-system-prompt" "$received"

# Test: --as with only one argument → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --as "a teacher" 2>&1)
exit_code=$?
binary_called=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--as one arg: exits 1" "1" "$exit_code"
assert_contains "--as one arg: error mentions requirement" "two arguments" "$output"
assert_equals "--as one arg: binary not called" "" "$binary_called"

# Test: --as with no arguments → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --as 2>&1)
exit_code=$?
assert_exit_code "--as no args: exits 1" "1" "$exit_code"

# Test: --as where second arg is a flag → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --as "a teacher" --model 2>&1)
exit_code=$?
assert_exit_code "--as flag-as-second-arg: exits 1" "1" "$exit_code"
assert_contains "--as flag-as-second-arg: error mentions requirement" "two arguments" "$output"

rm -rf "$TEST_BINWRAP_HOME"
teardown_fake_claude
print_summary "--as handler tests"
