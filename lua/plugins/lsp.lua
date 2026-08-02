return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = require("lsp.clangd"),

        -- CMake
        neocmake = require("lsp.neocmake"),
        autotools_ls = require("lsp.autotools"),
      },
    },
  },
}
