#!/usr/bin/env bash
# install.sh — installs binwrap extensions into BINWRAP_HOME

set -euo pipefail

BINWRAP_HOME="${BINWRAP_HOME:-$HOME/.config/binwrap}"
EXTENSIONS_DIR="$(cd "$(dirname "$0")/extensions" && pwd)"

echo "binwrap installer"
echo "Destination: $BINWRAP_HOME"
echo ""

# Collect available extensions grouped by binary
declare -A EXTENSIONS
for binary_dir in "$EXTENSIONS_DIR"/*/; do
    binary="$(basename "$binary_dir")"
    handlers=()
    for handler in "$binary_dir"*.sh; do
        [[ -f "$handler" ]] && handlers+=("$(basename "${handler%.sh}")")
    done
    [[ ${#handlers[@]} -gt 0 ]] && EXTENSIONS["$binary"]="${handlers[*]}"
done

if [[ ${#EXTENSIONS[@]} -eq 0 ]]; then
    echo "No extensions found in $EXTENSIONS_DIR"
    exit 0
fi

SELECTED=()

for binary in "${!EXTENSIONS[@]}"; do
    echo "Extensions for $binary:"
    IFS=' ' read -ra handlers <<< "${EXTENSIONS[$binary]}"
    for handler in "${handlers[@]}"; do
        read -rp "  Install --${handler} for ${binary}? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            SELECTED+=("${binary}:${handler}")
        fi
    done
    echo ""
done

if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo "Nothing selected. Exiting."
    exit 0
fi

echo "Installing..."
for entry in "${SELECTED[@]}"; do
    binary="${entry%%:*}"
    handler="${entry##*:}"
    dest_dir="$BINWRAP_HOME/$binary"
    mkdir -p "$dest_dir"

    cp "$EXTENSIONS_DIR/$binary/${handler}.sh" "$dest_dir/${handler}.sh"
    echo "  installed: $dest_dir/${handler}.sh"

    # Copy accompanying data directory if present (e.g. modes/)
    if [[ -d "$EXTENSIONS_DIR/$binary/${handler}" ]]; then
        cp -r "$EXTENSIONS_DIR/$binary/${handler}/." "$dest_dir/${handler}/"
        echo "  installed: $dest_dir/${handler}/ (data)"
    fi
done

echo ""
echo "Done. Add this alias to your shell config:"
echo "  alias <binary>='$(cd "$(dirname "$0")" && pwd)/binwrap <binary>'"
