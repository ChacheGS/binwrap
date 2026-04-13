#!/usr/bin/env bash
# tests/helpers.sh — shared test utilities

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "  PASS: $1"
    ((PASS_COUNT++))
}

fail() {
    echo "  FAIL: $1"
    ((FAIL_COUNT++))
}

assert_equals() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$description"
    else
        fail "$description — expected: '$expected', got: '$actual'"
    fi
}

assert_contains() {
    local description="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$description"
    else
        fail "$description — expected to contain: '$needle', got: '$haystack'"
    fi
}

assert_exit_code() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$description (exit code $expected)"
    else
        fail "$description — expected exit $expected, got $actual"
    fi
}

# Creates a fake `claude` binary in a temp dir prepended to PATH.
# The fake binary logs its received args to $FAKE_CLAUDE_LOG (one call per line).
setup_fake_claude() {
    FAKE_CLAUDE_LOG=$(mktemp)
    FAKE_CLAUDE_DIR=$(mktemp -d)
    cat > "$FAKE_CLAUDE_DIR/claude" << 'FAKE_EOF'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_CLAUDE_LOG"
FAKE_EOF
    chmod +x "$FAKE_CLAUDE_DIR/claude"
    cp "$FAKE_CLAUDE_DIR/claude" "$FAKE_CLAUDE_DIR/testbin"
    export PATH="$FAKE_CLAUDE_DIR:$PATH"
    export FAKE_CLAUDE_LOG
    export FAKE_CLAUDE_DIR
}

teardown_fake_claude() {
    rm -f "$FAKE_CLAUDE_LOG"
    rm -rf "$FAKE_CLAUDE_DIR"
}

print_summary() {
    local suite="$1"
    echo ""
    echo "$suite: $PASS_COUNT passed, $FAIL_COUNT failed"
    [[ $FAIL_COUNT -eq 0 ]]
}
