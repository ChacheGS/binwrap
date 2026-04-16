#!/usr/bin/env bash
# tests/test_envvars.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WRAPPER="$SCRIPT_DIR/../binwrap"
source "$SCRIPT_DIR/helpers.sh"

echo "=== Env Vars handler tests ==="

setup_fake_claude

# Override fake binary to log env vars we care about
cat > "$FAKE_CLAUDE_DIR/claude" << 'FAKE_EOF'
#!/usr/bin/env bash
echo "ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}" >> "$FAKE_CLAUDE_LOG"
FAKE_EOF
chmod +x "$FAKE_CLAUDE_DIR/claude"

TEST_BINWRAP_HOME=$(mktemp -d)
mkdir -p "$TEST_BINWRAP_HOME/claude/provider"
cp "$SCRIPT_DIR/../extensions/claude/provider.sh" "$TEST_BINWRAP_HOME/claude/provider.sh"
cp "$SCRIPT_DIR/../extensions/claude/provider/openrouter.sh" "$TEST_BINWRAP_HOME/claude/provider/openrouter.sh"

# Test: --provider openrouter injects ANTHROPIC_BASE_URL
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --provider openrouter 2>/dev/null
received=$(cat "$FAKE_CLAUDE_LOG")
assert_equals "--provider openrouter: sets ANTHROPIC_BASE_URL" \
    "ANTHROPIC_BASE_URL=https://openrouter.ai/api" "$received"

# Test: unknown provider produces error, binary not called
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --provider nonexistent 2>/dev/null
exit_code=$?
received=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--provider nonexistent: exits with error" 1 "$exit_code"
assert_equals "--provider nonexistent: binary not called" "" "$received"

# Test: --provider without value produces error
> "$FAKE_CLAUDE_LOG"
BINWRAP_HOME="$TEST_BINWRAP_HOME" "$WRAPPER" claude --provider 2>/dev/null
exit_code=$?
received=$(cat "$FAKE_CLAUDE_LOG")
assert_exit_code "--provider with no value: exits with error" 1 "$exit_code"
assert_equals "--provider with no value: binary not called" "" "$received"

rm -rf "$TEST_BINWRAP_HOME"
teardown_fake_claude
print_summary "Env Vars handler tests"
