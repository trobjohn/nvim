# nvim

Minimal Neovim for a terminal-first data science and REPL workflow.

## Philosophy

This setup is trying to be a small workbench, not a general-purpose editor and not a clone of VS Code.

The priorities are:

- start typing quickly
- keep the UI minimal
- make terminals and REPLs feel nearby and cheap
- support cell-based and selection-based execution
- avoid heavyweight plugin abstractions when a small amount of Lua is clearer

The config is intentionally opinionated. It bends Neovim toward an insert-forward, terminal-adjacent workflow because that is a better fit for exploratory coding than strict modal purity.

## Workflow Model

There are really two execution spaces:

- the right pane is a Python or R REPL
- the bottom pane is a generic shell / scratch terminal

The default idea is:

1. Open a file.
2. Start typing immediately.
3. Open the right-side interpreter for that file when needed.
4. Send the current cell or visual selection into that interpreter.
5. Keep a bottom terminal around for unrelated shell work.

This is meant to support an editor + REPL loop without needing notebook machinery or a large plugin stack.

## REPL Design

The REPL integration is intentionally a little hacky and direct.

- code is written to a temp file
- the temp file is executed in the managed Python or R interpreter, regardless of window position
- filetype determines the language; `pp` and `ii` explicitly choose plain Python or IPython
- repeated open commands reuse a live session and redisplay its buffer if its pane was closed
- sessions are shared per interpreter type, so variables persist between files

Currently the unified path supports:

- Python
- R

Python defaults to IPython when available, otherwise plain Python. After explicitly opening Python or IPython, the run key uses that choice. The bottom shell is for typing shell commands directly and is never a code-execution target.

## Key Ideas

- `<leader>rr`: open the right-side interpreter for the current buffer
- `<leader>pp`: open or reuse plain Python on the right
- `<leader>ii`: open or reuse IPython on the right
- `<leader>r`: run the current cell in Normal mode, or the current visual selection in Visual mode
- `<leader>tt`: open a bottom terminal for general shell work
- `<leader>pomo`: start a Pomodoro timer; enter minutes or accept the 25-minute default
- `<leader>e`: toggle the file explorer
- `<C-s>`: save
- `<C-q>`: quit the current window

The leader is Space. There is one execution key: Space+r. It opens an interpreter if needed and always sends a temporary-file execution command, never pasted code. With no `# %%` markers, it runs the whole buffer. After running a cell it moves to the next cell when one exists.

To highlight and run code: press Ctrl+Shift+Right or Ctrl+Shift+Left to start selecting words, repeat to extend, then press Space+r. Once selecting, Ctrl+Right/Left also extends by word. Ordinary Visual mode (`v` or `V`, followed by motions) works too. Use `y` to copy a selection or `d` to delete it.

Ctrl+h/j/k/l moves left/down/up/right between panes from Normal, Insert, and Terminal modes. Leaving Insert or Terminal mode for an editing pane lands in Normal mode; press `i` to type. Terminal panes automatically enter Terminal mode. Press Escape to leave Terminal mode for navigation or scrollback.

`h/l` and arrow keys cross line boundaries, and long lines wrap visually at words.

## Android over SSH

Ctrl+[ is the built-in alternative to Escape in Neovim. It leaves Insert mode or cancels a Visual selection; this configuration also treats it as Escape in a terminal pane, returning to Terminal-Normal mode without stopping the interpreter. See [Neovim's Insert-mode documentation](https://github.com/neovim/neovim/blob/master/runtime/doc/insert.txt).

The Android SSH client is Termius. Use Ctrl+[ as the hardware-keyboard Escape alternative, or the Escape key in Termius's extended keyboard. Termius provides a keyboard add-on with extra terminal keys; see its [Android client page](https://www.termius.com/free-ssh-client-for-android).

The remote workflow is: connect Android to the tailnet, SSH to the development machine, then run Neovim inside a tmux session on that machine. A detached tmux session keeps the editor and its REPLs running across SSH disconnections; reconnect and attach to resume. See [Tailscale on Android](https://tailscale.com/docs/install/android) and [tmux's getting-started guide](https://github.com/tmux/tmux/wiki/Getting-Started).

## Mode Behavior

This config is not trying to force traditional modal habits.

- ordinary editing starts in Insert mode
- terminal buffers re-enter Insert mode automatically
- regular code navigation no longer forces Insert on every buffer or window hop

That compromise is meant to preserve the "just type" feeling without making mature-code navigation miserable.

## Plugins

The plugin set is intentionally small:

- `lazy.nvim` for plugin management
- `synthweave.nvim` for colors
- `lualine.nvim` for a lightweight statusline
- `neo-tree.nvim` for file browsing
- `mini.tabline` for buffer tabs
- Tree-sitter for syntax highlighting and indentation
- `render-markdown.nvim` for Markdown rendering (`<leader>mm` toggles it)

Most of the workflow value comes from the custom Lua, not from plugin complexity.

## Workflow Checks

With Python, IPython, and R on `PATH`, run from this configuration directory:

```sh
nvim --headless -u NONE -i NONE -n -c 'lua dofile("tests/workflow.lua")'
```

These checks exercise the actual mappings and interpreters without loading plugins: selection, cell execution, session reuse and restart, window navigation, and keeping execution separate from the bottom shell.
