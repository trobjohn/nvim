-- lua/repl.lua

local M = {}

local function term_job_to_right()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_pos = vim.api.nvim_win_get_position(cur_win)

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)
    if pos[1] == cur_pos[1] and pos[2] > cur_pos[2] then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" then
        local ok, job = pcall(vim.api.nvim_buf_get_var, buf, "terminal_job_id")
        if ok then return job end
      end
    end
  end
  return nil
end

local function get_visual_selection()
  local srow, scol = unpack(vim.fn.getpos("'<"), 2, 3)
  local erow, ecol = unpack(vim.fn.getpos("'>"), 2, 3)

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  if #lines == 0 then return "" end

  lines[1] = string.sub(lines[1], scol)
  lines[#lines] = string.sub(lines[#lines], 1, ecol)

  return table.concat(lines, "\n")
end

function M.send_visual_to_right_term()
  local job = term_job_to_right()
  if not job then
    vim.notify("No terminal found to the right", vim.log.levels.WARN)
    return
  end

  local text = get_visual_selection()
  if text == "" then return end

  if not text:match("\n$") then
    text = text .. "\n"
  end

  vim.fn.chansend(job, text)
end

return M

