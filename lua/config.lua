
-- leader is space:
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Terminal panel commands:
vim.keymap.set( 'n', '<C-t>', ':belowright split | term<CR>', {noremap=true,silent=true})
vim.keymap.set('n', '<C-i>', ':rightbelow vsp | term ipython<CR>', { silent = true })
vim.keymap.set('n', '<C-p>', ':rightbelow vsp | term python<CR>', { silent = true })
vim.keymap.set('n', '<C-r>', ':rightbelow vsp | term R<CR>', { silent = true })

-- Ctrl+s to save:
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-s>", ":w<CR>", { silent = true })

-- Timeout delay
vim.opt.timeout = true
vim.opt.timeoutlen = 1500   -- mappings: be patient
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 10    -- keycodes: be fast

