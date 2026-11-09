-- Run from any directory with: nvim --headless -u NONE -i NONE -n
--   -c 'lua dofile("/path/to/nvim_cathedral/tests/workflow.lua")'
-- Requires Python, IPython, and R on PATH; no plugins are loaded.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.opt.hidden = true
vim.opt.swapfile = false
require("config")
vim.opt.timeoutlen = 20
local repl = require("repl")
local checks = 0
local source_win = vim.api.nvim_get_current_win()

local function check(condition, message)
  assert(condition, message)
  checks = checks + 1
end

local function keys(text)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(text, true, false, true), "xt", false)
end

local function code(ft, lines, row, col)
  keys("<Esc>")
  vim.api.nvim_set_current_win(source_win)
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = ft
  vim.api.nvim_win_set_cursor(0, { row or 1, col or 0 })
end

local function output(kind)
  return table.concat(vim.api.nvim_buf_get_lines(repl.terminals[kind].buf, 0, -1, false), "\n")
end

local function await_output(kind, text)
  check(vim.wait(15000, function()
    return output(kind):find(text, 1, true) ~= nil
  end, 20), "Missing " .. kind .. " output: " .. text .. "\n" .. output(kind))
end

local function test()
  code("markdown", { "alpha beta gamma" })
  keys("<C-S-Right>")
  check(vim.fn.mode() == "v" and vim.fn.col(".") == 5, "Select the first word")
  keys("<C-S-Right>")
  check(vim.fn.mode() == "v" and vim.fn.col(".") == 10, "Extend to the second word")
  keys("<C-Right>y")
  check(vim.fn.getreg('"') == "alpha beta gamma", "Ctrl+Right extends and y copies")
  keys("<Esc>")
  vim.api.nvim_win_set_cursor(0, { 1, 15 })
  keys("<C-S-Left><C-S-Left>")
  check(vim.fn.mode() == "v" and vim.fn.col(".") == 7, "Extend left without leaving Visual mode")
  keys("<C-Left>y")
  check(vim.fn.getreg('"') == "alpha beta gamma", "Ctrl+Left extends left")

  code("markdown", { "alpha beta gamma" })
  keys("i<C-S-Right>y")
  check(vim.fn.getreg('"') == "alpha", "Word selection works from Insert mode")
  code("markdown", { "alpha beta" }, 1, 5)
  keys("<C-S-Right>d")
  check(vim.api.nvim_get_current_line() == "alpha ", "Selection skips whitespace and d deletes the word")

  vim.cmd("rightbelow vnew")
  local other_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(source_win)
  keys("i<C-l>")
  check(vim.api.nvim_get_current_win() == other_win, "Ctrl+l switches windows from Insert mode")
  keys("<C-h>")
  check(vim.api.nvim_get_current_win() == source_win, "Ctrl+h switches windows from Normal mode")
  vim.api.nvim_win_close(other_win, true)

  code("python", { "# %%", "print('PY_CELL_ONE')", "# %%", "print('PY_CELL_TWO')" })
  keys(" pp")
  local python_job = repl.terminals.python.job
  local python_buf = repl.terminals.python.buf
  local windows = #vim.api.nvim_tabpage_list_wins(0)
  keys(" pp")
  check(repl.terminals.python.job == python_job and #vim.api.nvim_tabpage_list_wins(0) == windows,
    "Repeated pp reuses the Python session and window")
  keys(" r")
  await_output("python", "PY_CELL_ONE")
  check(not repl.terminals.ipython, "Run honors explicit Python even when IPython is installed")
  check(not output("python"):find("PY_CELL_TWO", 1, true), "Only the current cell runs")
  check(vim.api.nvim_win_get_cursor(0)[1] == 4, "Cell execution advances to the next cell")
  keys(" r")
  await_output("python", "PY_CELL_TWO")

  for _, win in ipairs(vim.fn.win_findbuf(python_buf)) do
    vim.api.nvim_win_close(win, true)
  end
  keys(" pp")
  check(repl.terminals.python.buf == python_buf and repl.terminals.python.job == python_job,
    "Reopening a hidden REPL preserves its buffer and job")

  local selection = "print('PY_SELECTION_OK')"
  local line = "not_python " .. selection .. " not_python"
  local first = line:find(selection, 1, true)
  code("python", { line }, 1, first - 1)
  keys("v")
  vim.api.nvim_win_set_cursor(0, { 1, first + #selection - 2 })
  keys(" r")
  await_output("python", "PY_SELECTION_OK")
  check(vim.fn.mode() == "n", "Executing a selection returns to Normal mode")

  code("python", { "not_python", "print('PY_LINEWISE_OK')", "not_python" }, 2, 8)
  keys("V r")
  await_output("python", "PY_LINEWISE_OK")

  -- Starting on a marker must run that cell, not the preceding one.
  code("python", { "# %%", "not_python", "# %%", "print('PY_MARKER_OK')" }, 3)
  keys(" r")
  await_output("python", "PY_MARKER_OK")

  code("python", { "print('IPYTHON_OK')" })
  keys(" ii")
  local ipython_job = repl.terminals.ipython.job
  windows = #vim.api.nvim_tabpage_list_wins(0)
  keys(" ii")
  check(repl.terminals.ipython.job == ipython_job and #vim.api.nvim_tabpage_list_wins(0) == windows,
    "Repeated ii reuses IPython")
  keys(" r")
  await_output("ipython", "IPYTHON_OK")

  code("r", { "# %%", "answer <- 6 * 7", "print(answer)", "# %%" })
  keys(" rr")
  local r_job = repl.terminals.r.job
  windows = #vim.api.nvim_tabpage_list_wins(0)
  keys(" rr")
  check(repl.terminals.r.job == r_job and #vim.api.nvim_tabpage_list_wins(0) == windows,
    "Repeated rr reuses R")
  keys(" r")
  await_output("r", "42")
  check(vim.api.nvim_win_get_cursor(0)[1] <= 4, "Trailing empty cell does not move beyond the buffer")
  code("r", { "print(answer + 1)" })
  keys(" r")
  await_output("r", "43")

  keys(" tt")
  local shell_buf = vim.api.nvim_get_current_buf()
  check(vim.bo.buftype == "terminal", "tt opens a bottom terminal")
  code("python", { "print('RIGHT_REPL_ONLY')" })
  keys(" r")
  await_output("ipython", "RIGHT_REPL_ONLY")
  check(not table.concat(vim.api.nvim_buf_get_lines(shell_buf, 0, -1, false), "\n")
    :find("RIGHT_REPL_ONLY", 1, true), "The bottom shell receives no execution commands")
  code("sh", { "echo SHOULD_NOT_RUN" })
  local shell_lines = vim.api.nvim_buf_line_count(shell_buf)
  local notifications = {}
  local notify = vim.notify
  vim.notify = function(message) table.insert(notifications, message) end
  keys(" r")
  vim.notify = notify
  check(#notifications == 1 and vim.api.nvim_buf_line_count(shell_buf) == shell_lines,
    "Shell buffers are excluded from REPL execution")

  code("python", { "print('PY_RESTART_OK')" })
  vim.fn.jobstop(python_job)
  check(vim.wait(3000, function() return vim.fn.jobwait({ python_job }, 0)[1] ~= -1 end, 20),
    "Python job stopped")
  keys(" pp r")
  check(repl.terminals.python.job ~= python_job, "A stopped interpreter can be restarted")
  await_output("python", "PY_RESTART_OK")
end

local ok, err = xpcall(test, debug.traceback)
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
    pcall(vim.fn.jobstop, vim.b[buf].terminal_job_id)
  end
end
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit")
else
  print("Passed " .. checks .. " workflow checks (Python, IPython, R, selection, navigation).")
  vim.cmd("qa!")
end
