# extensions/claude/as.sh
# Translates --as <persona> <task> → --append-system-prompt "You are <persona>. Your task: <task>"
# Consumes exactly two positional arguments.
# BINWRAP_HOME and BINWRAP_BINARY are set by the dispatcher.
# Sets WRAPPER_ERROR on failure. Appends to WRAPPED_BIN_ARGS on success.

if [[ $# -eq 0 || "$1" == --* ]]; then
    WRAPPER_ERROR="--as requires two arguments: <persona> <task>"
    return
fi

_as_persona="$1"
shift

if [[ $# -eq 0 || "$1" == --* ]]; then
    WRAPPER_ERROR="--as requires two arguments: <persona> <task>"
    unset _as_persona
    return
fi

_as_task="$1"
shift

WRAPPED_BIN_ARGS+=("--append-system-prompt" "You are ${_as_persona}. Your task: ${_as_task}")
unset _as_persona _as_task
