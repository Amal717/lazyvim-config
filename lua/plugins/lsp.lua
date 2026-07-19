return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                clangd = require("lsp.clangd"),
            },
        },
    },
}
