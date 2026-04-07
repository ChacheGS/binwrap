#!/usr/bin/env bash
# tests/test_using.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== --using handler tests ==="

setup_fake_claude

TEST_BINWRAP_HOME=$(mktemp -d)
mkdir -p "$TEST_BINWRAP_HOME/claude"
cp "$SCRIPT_DIR/../extensions/claude/using.sh" "$TEST_BINWRAP_HOME/claude/using.sh"

TEST_FILES_DIR=$(mktemp -d)
echo "Context from file one." > "$TEST_FILES_DIR/one.md"
echo "Context from file two." > "$TEST_FILES_DIR/two.md"

# Test: --using single file → --append-system-prompt <file content>
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --using "$TEST_FILES_DIR/one.md" 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "--using single file: content passed as system prompt" \
    "--append-system-prompt Context from file one." "$received"

# Test: --using two files → concatenated content
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude \
    --using "$TEST_FILES_DIR/one.md" "$TEST_FILES_DIR/two.md" 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "--using two files: first file content present" "Context from file one." "$received"
assert_contains "--using two files: second file content present" "Context from file two." "$received"

# Test: --using stops at next --flag, remaining flags forwarded
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude \
    --using "$TEST_FILES_DIR/one.md" --model sonnet 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "--using stops at flag: --model forwarded" "--model sonnet" "$received"
assert_contains "--using stops at flag: --append-system-prompt present" "--append-system-prompt" "$received"

# Test: --using with a missing file → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --using /nonexistent/file.md 2>&1)
exit_code=$?
binary_called=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--using missing file: exits 1" "1" "$exit_code"
assert_contains "--using missing file: error mentions filename" "file.md" "$output"
assert_equals "--using missing file: binary not called" "" "$binary_called"

# Test: --using with no file arguments → exit 1
> "$FAKE_CLAUDE_LOG"
output=$(BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --using 2>&1)
exit_code=$?
assert_exit_code "--using no args: exits 1" "1" "$exit_code"

rm -rf "$TEST_BINWRAP_HOME" "$TEST_FILES_DIR"
teardown_fake_claude
print_summary "--using handler tests"
