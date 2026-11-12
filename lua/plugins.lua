require("lazy").setup({
  {
    "samharju/synthweave.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("synthweave")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "auto" },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup({})

      treesitter.install({
        "bash",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "r",
        "vim",
        "vimdoc",
      })

      -- Neovim 0.12 provides highlighting; start it when a parser is available.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.nvim",
    },
    ft = { "markdown" },
    opts = {},
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" },
      { "<leader>fe", "<cmd>Neotree filesystem reveal left<cr>", desc = "Explorer (reveal)" },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "disabled",
        use_libuv_file_watcher = true,
      },
      window = {
        position = "left",
        width = 32,
      },
      default_component_configs = {
        git_status = {
          symbols = {
            added = "✚",
            modified = "",
            deleted = "✖",
            renamed = "󰁕",
            untracked = "",
          },
        },
      },
    },
  },
  {
    "nvim-mini/mini.tabline",
    version = false,
    config = function()
      require("mini.tabline").setup({
        show_icons = true,
      })
    end,
  },
}, {
  rocks = {
    enabled = false,
  },
})
