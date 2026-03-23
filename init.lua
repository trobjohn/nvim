require("config")

-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- plugins
require("plugins")

-- repl code
local repl = require("repl")

-- Openers (normal mode)
--vim.keymap.set("n", "<leader>p", repl.open_python, { desc = "Open Python REPL" })
--vim.keymap.set("n", "<leader>i", repl.open_ipython, { desc = "Open IPython REPL" })
--vim.keymap.set("n", "<leader>r", repl.open_r, { desc = "Open R REPL" })

-- Runners (visual mode)
vim.keymap.set("v", "<leader>p", repl.run_visual_python, { desc = "Run selection in Python REPL" })
vim.keymap.set("v", "<leader>i", repl.run_visual_ipython, { desc = "Run selection in IPython" })
vim.keymap.set("v", "<leader>r", repl.run_visual_r, { desc = "Run selection in R" })

-- Cell runners (normal mode)
vim.keymap.set("n", "<leader>p", repl.run_cell_python, { desc = "Run cell in Python REPL" })
vim.keymap.set("n", "<leader>i", repl.run_cell_ipython, { desc = "Run cell in IPython" })
vim.keymap.set("n", "<leader>r", repl.run_cell_r, { desc = "Run cell in R" })

-- Line numbers
vim.opt.number = true        -- absolute line numbers
vim.opt.relativenumber = false

vim.keymap.set("n", "<leader>ln", function()
  vim.opt.number = not vim.opt.number:get()
end, { desc = "Toggle line numbers" })

-- Start in insert mode, if file opened
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    if vim.bo.buftype == "" then
      vim.cmd("startinsert")
    end
  end,
})

-- default/realign focus
local aug = vim.api.nvim_create_augroup("auto_insert_on_focus", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = aug,
  callback = function()
    local bt = vim.bo.buftype
    local ft = vim.bo.filetype

    -- skip weird/special windows
    if bt == "nofile" or bt == "prompt" or bt == "help" or bt == "quickfix" then
      return
    end

    -- terminals and normal editable files should go straight to insert
    if bt == "" or bt == "terminal" then
      vim.schedule(function()
        if vim.api.nvim_get_current_win() ~= 0 then
          vim.cmd("startinsert")
        end
      end)
    end
  end,
})


vim.api.nvim_create_autocmd("FocusGained", {
  group = aug,
  callback = function()
    local bt = vim.bo.buftype
    if bt == "" or bt == "terminal" then
      vim.schedule(function()
        vim.cmd("startinsert")
      end)
    end
  end,
})

-- Timer
vim.keymap.set('n', '<leader>o', function()
  local mins = vim.fn.input('Pomodoro minutes [25]: ')
  mins = mins ~= '' and mins or '25'
  vim.fn.jobstart('sleep ' .. mins .. 'm && notify-send -u critical "Sprint done!"')
  print('Timer started: ' .. mins .. 'm')
end, { desc = 'Start pomodoro' })
