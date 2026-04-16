# extensions/claude/provider.sh
# Translates --provider <name> → set environment variables to connect to another provider
# Reads $1 (provider name) from the dispatcher's positional stream and shifts it.
# BINWRAP_HOME and BINWRAP_BINARY are set by the dispatcher.
# Sets WRAPPER_ERROR on failure.
# Provider files append to WRAPPED_BIN_ENV on success.

if [[ $# -eq 0 || "$1" == -* ]]; then
    WRAPPER_ERROR="--provider requires a value"
    return
fi

_provider_name="$1"
shift

_provider_file="${BINWRAP_HOME}/${BINWRAP_BINARY}/provider/${_provider_name}.sh"

if [[ ! -f "$_provider_file" ]]; then
    WRAPPER_ERROR="provider '${_provider_name}' not found at ${_provider_file}"
    unset _provider_name _provider_file
    return
fi

# shellcheck source=/dev/null
source "$_provider_file"

unset _provider_name _provider_file
