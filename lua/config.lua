vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.keymap.set("n", "<leader>ii", function()
  require("repl").open_ipython()
end, { silent = true, desc = "Open IPython REPL on right" })

vim.keymap.set("n", "<leader>pp", function()
  require("repl").open_python()
end, { silent = true, desc = "Open Python REPL on right" })

vim.keymap.set("n", "<leader>rr", function()
  require("repl").open_repl_for_current_buffer()
end, { silent = true, desc = "Open Python/R REPL on right" })

vim.keymap.set({ "n", "x" }, "<leader>r", function()
  require("repl").run_current_context()
end, { silent = true, desc = "Run selection or cell in Python/R REPL" })

vim.keymap.set("n", "<leader>tt", function()
  vim.cmd("split | terminal")
  vim.cmd("wincmd J")
  vim.cmd("resize 4")
end, { noremap = true, silent = true, desc = "Open bottom terminal" })

vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-s>", ":w<CR>", { silent = true })

vim.keymap.set("i", "<C-q>", "<Esc>:q<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-q>", ":q<CR>", { silent = true })
vim.keymap.set("i", "<C-e>", "<Esc>:qa<CR>", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-e>", ":qa<CR>", { silent = true })

vim.opt.timeout = true
vim.opt.timeoutlen = 2500
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 100

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
  end,
})

vim.opt.listchars = {
  tab = "▸ ",
  trail = "·",
  space = "·",
}
vim.keymap.set("n", "<leader>w", function()
  vim.opt.list = not vim.opt.list:get()
end, { desc = "Toggle whitespace" })

vim.keymap.set("n", "<C-f>", "^", { silent = true })
vim.keymap.set("n", "<C-g>", "$", { silent = true })
vim.keymap.set("i", "<C-f>", "<C-o>^", { silent = true })
vim.keymap.set("i", "<C-g>", "<C-o>$", { silent = true })

vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })

vim.keymap.set("i", "<C-h>", [[<Esc><C-w>h]], { silent = true })
vim.keymap.set("i", "<C-j>", [[<Esc><C-w>j]], { silent = true })
vim.keymap.set("i", "<C-k>", [[<Esc><C-w>k]], { silent = true })
vim.keymap.set("i", "<C-l>", [[<Esc><C-w>l]], { silent = true })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true })
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { silent = true })
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { silent = true })
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { silent = true })
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { silent = true })

vim.keymap.set("v", ">", ">gv", { silent = true })
vim.keymap.set("v", "<", "<gv", { silent = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      vim.cmd("Neotree")
    end
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype == "neo-tree" and vim.fn.winnr("$") == 1 then
      vim.cmd("quit")
    end
  end,
})

vim.keymap.set("i", "<C-v>", "<C-o>v", { noremap = true })

local function select_word_with_direction(direction)
  local mode = vim.fn.mode()
  local motion = direction == "right" and "e" or "b"
  if mode == "v" or mode == "V" or mode == "\22" then
    return motion -- Extend the existing selection without toggling Visual mode.
  end

  local prefix = mode:sub(1, 1) == "i" and [[<C-\><C-n>]] or ""
  if direction == "right" then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    if line:sub(col, col):match("%s") then
      prefix = prefix .. "w"
    end
  end
  return prefix .. "v" .. motion
end

vim.keymap.set({ "n", "i", "x" }, "<C-S-Right>", function()
  return select_word_with_direction("right")
end, { expr = true, silent = true, desc = "Select or extend selection one word right" })

vim.keymap.set({ "n", "i", "x" }, "<C-S-Left>", function()
  return select_word_with_direction("left")
end, { expr = true, silent = true, desc = "Select or extend selection one word left" })

vim.keymap.set("n", "<C-Right>", "w", { silent = true })
vim.keymap.set("n", "<C-Left>", "b", { silent = true })
vim.keymap.set("i", "<C-Right>", "<C-o>w", { silent = true })
vim.keymap.set("i", "<C-Left>", "<C-o>b", { silent = true })
vim.keymap.set("x", "<C-Right>", "e", { silent = true })
vim.keymap.set("x", "<C-Left>", "b", { silent = true })

vim.keymap.set("n", "<leader>xx", "<cmd>Neotree toggle position=left<CR>", {
  silent = true,
  desc = "Toggle file tree",
})

vim.keymap.set("n", "<leader>mm", "<cmd>RenderMarkdown toggle<CR>", {
  silent = true,
  desc = "Toggle rendered Markdown/math",
})
