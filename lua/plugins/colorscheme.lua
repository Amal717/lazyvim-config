return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    opts = {
      flavour = "mocha",

      custom_highlights = function(colors)
        return {
          -- Subtle indent guides
          IblIndent = {
            fg = colors.surface0,
            nocombine = true,
          },

          -- Slightly brighter active scope
          IblScope = {
            fg = colors.surface2,
            nocombine = true,
          },
        }
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
