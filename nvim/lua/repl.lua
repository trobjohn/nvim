local M = { terminals = {} }
local python_kind

local specs = {
  python = {
    cmd = { "python", "-i" },
    ext = "py",
    send_cmd = function(path)
      return ("exec(compile(open(%q).read(), %q, 'exec'), globals())"):format(path, path)
    end,
  },
  ipython = {
    cmd = { "ipython" },
    ext = "py",
    send_cmd = function(path)
      return ("%%run -i %q"):format(path)
    end,
  },
  r = {
    cmd = { "R" },
    ext = "R",
    send_cmd = function(path)
      return ("source(%q)"):format(path)
    end,
  },
}

local function current_kind()
  if vim.bo.filetype == "python" then
    return python_kind or (vim.fn.executable("ipython") == 1 and "ipython" or "python")
  elseif vim.bo.filetype == "r" then
    return "r"
  end
  vim.notify("REPL execution supports Python and R buffers.", vim.log.levels.WARN)
end

local function is_live_job(job)
  return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function visible_window_for_buffer(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" then
        return win
      end
    end
  end
end

local function open_term(kind)
  local spec = specs[kind]
  local state = M.terminals[kind] or {}
  M.terminals[kind] = state
  local source_win = vim.api.nvim_get_current_win()

  if is_live_job(state.job) and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    if not visible_window_for_buffer(state.buf) then
      vim.cmd("rightbelow vsplit")
      vim.api.nvim_win_set_buf(0, state.buf)
      vim.api.nvim_set_current_win(source_win)
    end
    return state.job
  end

  if vim.fn.executable(spec.cmd[1]) ~= 1 then
    vim.notify("Interpreter not found: " .. spec.cmd[1], vim.log.levels.WARN)
    return nil
  end

  vim.cmd("rightbelow vnew")
  state.buf = vim.api.nvim_get_current_buf()
  state.job = vim.fn.termopen(spec.cmd)
  vim.api.nvim_set_current_win(source_win)
  if state.job <= 0 then
    state.job = nil
    vim.notify("Could not start " .. spec.cmd[1], vim.log.levels.ERROR)
  end
  return state.job
end

function M.open_python()
  local job = open_term("python")
  if job then
    python_kind = "python"
  end
  return job
end

function M.open_ipython()
  local job = open_term("ipython")
  if job then
    python_kind = "ipython"
  end
  return job
end

function M.open_repl_for_current_buffer()
  local kind = current_kind()
  if kind then
    return open_term(kind)
  end
end

local function get_visual_selection(mode)
  -- Visual marks '< and '> describe the previous selection until Visual mode ends.
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))
  local block_start, block_end = math.min(cs, ce), math.max(cs, ce)
  if ls > le or (ls == le and cs > ce) then
    ls, le, cs, ce = le, ls, ce, cs
  end

  local lines = vim.fn.getline(ls, le)
  local function through_char(line, col)
    -- Columns are byte offsets; include the complete final UTF-8 character.
    return col - 1 + #vim.fn.matchstr(line:sub(col), "^.")
  end
  if mode == "\22" then
    for i, line in ipairs(lines) do
      lines[i] = line:sub(block_start, through_char(line, block_end))
    end
  elseif mode ~= "V" then
    -- Trim the end first so a selection within one line uses original columns.
    lines[#lines] = lines[#lines]:sub(1, through_char(lines[#lines], ce))
    lines[1] = lines[1]:sub(cs)
  end
  return table.concat(lines, "\n") .. "\n"
end

local CELL_PAT = "^%s*#%s*%%%%"

local function get_cell_text()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local first, last = 1, #lines
  for i = row, 1, -1 do
    if lines[i]:match(CELL_PAT) then
      first = i + 1
      break
    end
  end
  for i = first, #lines do
    if lines[i]:match(CELL_PAT) then
      last = i - 1
      break
    end
  end
  if first > last then
    return ""
  end
  return table.concat(vim.list_slice(lines, first, last), "\n") .. "\n"
end

local function goto_next_cell()
  local last = vim.api.nvim_buf_line_count(0)
  for i = vim.api.nvim_win_get_cursor(0)[1] + 1, last do
    if vim.fn.getline(i):match(CELL_PAT) then
      local target = i + 1
      while target <= last and vim.fn.getline(target):match("^%s*$") do
        target = target + 1
      end
      if target <= last then
        vim.api.nvim_win_set_cursor(0, { target, 0 })
      end
      return
    end
  end
end

local function write_temp(ext, text)
  -- A different path per run prevents a rapid second run overwriting queued code.
  local path = vim.fn.tempname() .. "." .. ext
  local ok, err = pcall(function()
    local file = assert(io.open(path, "w"))
    file:write(text)
    file:close()
  end)
  if not ok then
    vim.notify("Failed writing temp file: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end
  return path
end

function M.run_current_context()
  local kind = current_kind()
  if not kind then
    return
  end
  local mode = vim.fn.mode()
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local text = is_visual and get_visual_selection(mode) or get_cell_text()
  if not text:match("%S") then
    return
  end

  local job = open_term(kind)
  if not job then
    return
  end
  local path = write_temp(specs[kind].ext, text)
  if not path then
    return
  end
  if vim.fn.chansend(job, specs[kind].send_cmd(path) .. "\r") == 0 then
    vim.notify("Could not send code to the interpreter.", vim.log.levels.WARN)
    return
  end

  if is_visual then
    vim.cmd("normal! " .. string.char(27))
  else
    goto_next_cell()
  end
end

return M
