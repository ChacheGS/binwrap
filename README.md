# claude-wrapper

A bash wrapper for the `claude` CLI that adds custom flags and translates them into real `claude` arguments.

## Setup

1. Clone this repo somewhere permanent, e.g. `~/.local/share/claude-wrapper`
2. Add an alias to your `~/.zshrc` or `~/.bashrc`:

   ```bash
   alias claude='/path/to/claude-wrapper/claude'
   ```

3. Reload your shell: `source ~/.zshrc`

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `CLAUDE_EXTENSIONS_HOME` | `~/.config/claude/extensions` | Root directory for all extension assets |

## Custom flags

### `--mode <name>`

Loads a system prompt from `$CLAUDE_EXTENSIONS_HOME/modes/<name>.md` and passes it to `claude` as `--append-system-prompt`.

```bash
# Create a mode file
mkdir -p ~/.config/claude/extensions/modes
echo "You are a concise code reviewer." > ~/.config/claude/extensions/modes/reviewer.md

# Use it
claude --mode reviewer
```

## Adding new custom flags

1. Create `handlers/<flag-name>.sh`
2. Implement the handler contract:
   - Read the flag's value from `$1` and call `shift` to consume it
   - On success: append translated args to `CLAUDE_ARGS`
   - On failure: set `WRAPPER_ERROR="<message>"` and `return`
3. Add tests in `tests/test_<flag-name>.sh`

No changes to the dispatcher needed.

## Running tests

```bash
bash tests/run_tests.sh
```
