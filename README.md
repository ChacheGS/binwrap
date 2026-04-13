# binwrap

A binary-agnostic CLI wrapper that intercepts custom flags and translates them into real arguments before delegating to the target binary.

## Origin

This started with a leak. When Anthropic accidentally published the Claude Code source code, people who dug through it found something interesting: an "undercover mode." A system prompt that instructs the assistant to write git output like a human developer, no traces of AI authorship. It was wired in as an internal-only feature for Anthropic employees.

Since the prompt was out in the open, generalizing it wasn't hard. Tool-specific references came out, writing style guidelines went in. The result is what you see here: a tool-agnostic version you can toggle with a unix flag.

Is it useful? Probably not for most people. Does it add overhead? A fair bit. But it's a clean primitive, usable for all binaries, and the undercover use case is what made it worth building; all tests and extensions are Claude Code-themed for this reason.

For now it's just an argument translator, but the mechanism allows for everything you can code, and can be used to add, rename, ignore arguments and flags, or customize just about anything tools don't natively support.

## How it works

```bash
binwrap <binary> [args...]
```

`binwrap` reads its first argument as the target binary, then processes remaining args. For any `--flag` or `--flag=value` it finds a matching `$BINWRAP_HOME/<binary>/<flag>.sh` handler, it sources it; otherwise the flag is forwarded unchanged.

> **Note:** single-dash flags (`-f`, `-v`, etc.) are not intercepted and always forwarded as-is.

## Setup

1. Clone this repo somewhere permanent:

   ```bash
   git clone <repo> ~/.local/share/binwrap
   ```

2. Add aliases to your `~/.zshrc` or `~/.bashrc`:

   ```bash
   alias claude='~/.local/share/binwrap/binwrap claude'
   ```

3. Install extensions:

   ```bash
   bash ~/.local/share/binwrap/install.sh
   ```

4. Reload your shell: `source ~/.zshrc`

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `BINWRAP_HOME` | `~/.config/binwrap` | Root for all installed handlers and data |

Handlers are looked up at `$BINWRAP_HOME/<binary>/<flag>.sh`. Data files (e.g. mode prompts) live alongside handlers under `$BINWRAP_HOME/<binary>/`.

## Shipped extensions (claude)

### `--mode <name>`

Loads `$BINWRAP_HOME/claude/mode/<name>.md` as a system prompt.

```bash
claude --mode undercover
```

### `--undercover`

Alias: loads `$BINWRAP_HOME/claude/mode/undercover.md` as a system prompt. No argument consumed.

```bash
claude --undercover
```

### `--as <persona> <task>`

Builds a system prompt from two arguments.

```bash
claude --as "a senior engineer" "review this code for security issues"
# → --append-system-prompt "You are a senior engineer. Your task: review this code for security issues"
```

### `--using <file1> [file2] ...`

Reads one or more files and concatenates their content into a system prompt. Consumes arguments until the next `--flag`.

```bash
claude --using context.md notes.md --model sonnet
```

## Adding your own extensions

1. Create `$BINWRAP_HOME/<binary>/<flag>.sh`
2. Implement the handler contract:
   - `BINWRAP_HOME` and `BINWRAP_BINARY` are available from the dispatcher
   - Consume positional args by reading `$1` and calling `shift`
   - On success: append translated args to `WRAPPED_BIN_ARGS`
   - On failure: set `WRAPPER_ERROR="<message>"` and `return`
   - Never call `exit` directly from a handler
3. Add tests in `tests/test_<flag>.sh`

### Handler patterns

**No-arg (alias):** don't shift, just append to `WRAPPED_BIN_ARGS`.

**Single-arg:** read `$1`, shift once.

**Fixed N-arg:** read and shift N times, checking each `$1` is not a `--flag`.

**Variadic:** loop while `$# -gt 0 && "$1" != --*`, shifting each iteration.

## Running tests

```bash
bash tests/run_tests.sh
```
