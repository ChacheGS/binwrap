#!/usr/bin/env bash
# tests/test_subcommand.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Subcommand tests ==="

setup_fake_claude

TEST_BINWRAP_HOME=$(mktemp -d)

# Handler tree:
#   testbin/
#     top.sh             ← --top at root level
#     sub/
#       sub.sh           ← --sub for testbin sub
#       deep/
#         deep.sh        ← --deep for testbin sub deep

mkdir -p "$TEST_BINWRAP_HOME/testbin/sub/deep"

echo 'WRAPPED_BIN_ARGS+=("--top-ran")' > "$TEST_BINWRAP_HOME/testbin/top.sh"
echo 'WRAPPED_BIN_ARGS+=("--sub-ran")' > "$TEST_BINWRAP_HOME/testbin/sub/sub.sh"
echo 'WRAPPED_BIN_ARGS+=("--deep-ran")' > "$TEST_BINWRAP_HOME/testbin/sub/deep/deep.sh"

# Test: flag at root level, no subcommand
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" testbin --top 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "subcommand: root flag resolves without subcommand" "--top-ran" "$received"

# Test: subcommand descent — flag resolves in subcommand dir
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" testbin sub --sub 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "subcommand: subcommand forwarded to binary" "sub" "$received"
assert_contains "subcommand: flag resolves in subcommand dir" "--sub-ran" "$received"

# Test: flag before subcommand resolves at root level
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" testbin --top sub --sub 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "subcommand: root flag before subcommand" "--top-ran" "$received"
assert_contains "subcommand: subcommand flag after descent" "--sub-ran" "$received"

# Test: root-level flag does not resolve after descent (passes through)
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" testbin sub --top 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "subcommand: unknown flag after descent passed through" "--top" "$received"

# Test: unknown positional arg (no matching subdir) passes through unchanged
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" testbin unknown --top 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "subcommand: unknown positional forwarded" "unknown" "$received"
assert_contains "subcommand: root flag still resolves with unknown positional" "--top-ran" "$received"

# Test: two-level descent
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" testbin sub deep --deep 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_contains "subcommand: two-level descent forwards both subcommands" "sub" "$received"
assert_contains "subcommand: two-level descent forwards second subcommand" "deep" "$received"
assert_contains "subcommand: flag resolves at second subcommand level" "--deep-ran" "$received"

rm -rf "$TEST_BINWRAP_HOME"
teardown_fake_claude
print_summary "Subcommand tests"
