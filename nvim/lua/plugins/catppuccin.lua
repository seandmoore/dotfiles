return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        blink_cmp        = true,
        neo_tree         = true,
        treesitter       = true,
        gitsigns         = true,
        which_key        = true,
        telescope        = { enabled = true },
        indent_blankline = { enabled = true },
        mini             = { enabled = true },
        lualine          = true,
        noice            = true,
      },
    },
  },
}
