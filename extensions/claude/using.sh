# extensions/claude/using.sh
# Translates --using <file1> [file2] ... → --append-system-prompt <concatenated content>
# Consumes positional args until the next --flag or end of args.
# Files are concatenated with a newline between each.
# BINWRAP_HOME and BINWRAP_BINARY are set by the dispatcher.
# Sets WRAPPER_ERROR on failure. Appends to WRAPPED_BIN_ARGS on success.

if [[ $# -eq 0 || "$1" == --* ]]; then
    WRAPPER_ERROR="--using requires at least one file argument"
    return
fi

_using_content=""
_using_first=1

while [[ $# -gt 0 && "$1" != --* ]]; do
    _using_file="$1"
    shift

    if [[ ! -f "$_using_file" ]]; then
        WRAPPER_ERROR="--using: file not found: ${_using_file}"
        unset _using_content _using_file _using_first
        return
    fi

    if [[ $_using_first -eq 1 ]]; then
        _using_content="$(cat "$_using_file")"
        _using_first=0
    else
        _using_content+=$'\n'"$(cat "$_using_file")"
    fi
done

WRAPPED_BIN_ARGS+=("--append-system-prompt" "$_using_content")
unset _using_content _using_file _using_first
