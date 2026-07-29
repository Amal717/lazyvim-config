return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",

    opts = {
      indent = {
        char = "│",
        highlight = "IblIndent",
      },

      whitespace = {
        remove_blankline_trail = false,
      },

      scope = {
        enabled = true,
        char = "│",
        highlight = "IblScope",
      },
    },
  },
}
