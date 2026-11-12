require("config")

-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("plugins")

vim.opt.number = true
vim.opt.relativenumber = false

vim.keymap.set("n", "<leader>ln", function()
  vim.opt.number = not vim.opt.number:get()
end, { desc = "Toggle line numbers" })

local aug = vim.api.nvim_create_augroup("auto_insert_on_focus", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = aug,
  once = true,
  callback = function()
    if vim.bo.buftype == "" then
      vim.schedule(function()
        vim.cmd("startinsert")
      end)
    end
  end,
})

vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter", "WinEnter", "FocusGained" }, {
  group = aug,
  callback = function()
    if vim.bo.buftype ~= "terminal" then
      return
    end

    vim.schedule(function()
      if vim.bo.buftype == "terminal" then
        vim.cmd("startinsert")
      end
    end)
  end,
})

vim.keymap.set("n", "<leader>pomo", function()
  local mins = vim.fn.input("Pomodoro minutes [25]: ")
  mins = mins ~= "" and mins or "25"
  local mins_num = tonumber(mins)

  if not mins_num or mins_num <= 0 then
    vim.notify("Pomodoro minutes must be a positive number.", vim.log.levels.WARN)
    return
  end

  vim.fn.jobstart({ "sleep", tostring(mins_num) .. "m" }, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.fn.jobstart({
          "notify-send",
          "-u",
          "critical",
          "Sprint done!",
        })
      end
    end,
  })
  print("Timer started: " .. mins_num .. "m")
end, { desc = "Start pomodoro" })

local opt = vim.opt
opt.whichwrap:append("<,>,h,l,[,]")
opt.wrap = true
opt.linebreak = true
opt.clipboard = "unnamedplus"
