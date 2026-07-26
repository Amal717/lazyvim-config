return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      layouts = {
        sidebar = {
          layout = {
            width = 25, -- adjust this
          },
        },
      },

      formatters = {
        file = {
          icon_width = 2,
          filename_only = true,
        },
      },
    },
  },
}
