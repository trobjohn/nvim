# Codex CLI: the useful bits

## From the shell

```sh
cd ~/Desktop/nvim_reconciliation/nvim_cathedral
codex login --device-auth       # Sign in from SSH, if needed
codex                          # Start a new conversation here
codex resume                   # Pick a saved conversation for this directory
codex resume --all             # Find conversations from other directories
codex resume --last            # Continue this directory's latest conversation
codex resume "nvim-workbench"  # Resume a conversation you named
```

For everyday work, start with `codex resume` so you return to your existing thread.

## Inside Codex

| Command | Use |
|---|---|
| `/rename nvim-workbench` | Give this conversation a recognizable name |
| `/resume` | Switch to a saved conversation |
| `/fork` | Explore an alternative with a copy of this conversation |
| `/new` | Start a fresh conversation |
| `@lua/repl.lua` | Find and mention a file in your prompt |
| `/plan` | Discuss an implementation plan |
| `/diff` | Inspect the changes |
| `/review` | Ask for a code review |
| `/status` | Check the session, context usage, and limits |
| `/model` | Choose a model and reasoning effort |
| `/permissions` | Adjust editing and command permissions |
| `/compact` | Summarize earlier context when the conversation gets long |
| `/exit` | Leave; resume the conversation later |

Type `/` to browse the commands available in your installed version.

## Prompts that get work done

```text
Read @lua/repl.lua. Explain the execution path before changing anything.

Implement a reusable Codex terminal pane on Space+aa. Preserve the Python/R
REPLs and bottom shell. Add relevant workflow checks and update the README.

Run the relevant checks, fix failures, and summarize what changed.

Update RESEARCH.md with decisions, evidence, failed approaches, and next steps.
```

Save editor buffers before asking about them: a plain terminal session reads files on disk.
Saved chats preserve history; compaction summarizes working context. Keep durable research
conclusions in project files and ask Codex to read them when starting related threads.

## Keep the remote workspace alive

```sh
tmux new-session -A -s research  # Create or attach, then run nvim/Codex inside
```

Detach with **Ctrl+b**, release, then **d**. Reconnect and run the same command to return.

References: [official CLI reference](https://learn.chatgpt.com/docs/cli/reference),
[interactive commands](https://learn.chatgpt.com/docs/developer-commands),
[projects and saved chats](https://learn.chatgpt.com/docs/projects).
