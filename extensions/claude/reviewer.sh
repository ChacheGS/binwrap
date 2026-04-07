# extensions/claude/reviewer.sh
# Alias: --reviewer loads modes/reviewer.md as system prompt (no argument consumed).
# BINWRAP_HOME and BINWRAP_BINARY are set by the dispatcher.

_mode_file="${BINWRAP_HOME}/${BINWRAP_BINARY}/modes/reviewer.md"

if [[ ! -f "$_mode_file" ]]; then
    WRAPPER_ERROR="mode 'reviewer' not found at ${_mode_file}"
    return
fi

WRAPPED_BIN_ARGS+=("--append-system-prompt" "$(cat "$_mode_file")")
unset _mode_file
