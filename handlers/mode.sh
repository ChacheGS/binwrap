# handlers/mode.sh
# Translates --mode <name> → --append-system-prompt <content>
# Reads $1 (mode name) from the dispatcher's positional stream and shifts it.
# Sets WRAPPER_ERROR on failure. Appends to CLAUDE_ARGS on success.

if [[ $# -eq 0 || "$1" == --* ]]; then
    WRAPPER_ERROR="--mode requires a value"
    return
fi

_mode_name="$1"
shift

_mode_file="${CLAUDE_EXTENSIONS_HOME}/modes/${_mode_name}.md"

if [[ ! -f "$_mode_file" ]]; then
    WRAPPER_ERROR="mode '${_mode_name}' not found at ${_mode_file}"
    return
fi

CLAUDE_ARGS+=("--append-system-prompt" "$(cat "$_mode_file")")
unset _mode_name _mode_file
