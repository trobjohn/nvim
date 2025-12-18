require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,        -- load immediately
    priority = 1000,     -- load before everything else
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },
})

