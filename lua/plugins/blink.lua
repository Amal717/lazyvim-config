return {
    "saghen/blink.cmp",
    opts = {
        sources = {
            default = {
                "lsp",
                "path",
                "buffer",
                -- "snippets", -- Uncomment only if you actually want snippets
            },
        },

        keymap = {
            preset = "default",
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<Tab>"] = { "accept", "fallback" },
        },

        completion = {
            documentation = {
                auto_show = false,
                window = {
                    border = "rounded",
                },
            },

            signature = {
                enabled = true,
                window = {
                    border = "rounded",
                },
            },
            menu = {
                max_height = 5,
            },

            ghost_text = {
                enabled = false,
            },

            list = {
                selection = {
                    preselect = true,
                },
            },
        },

        fuzzy = {
            implementation = "prefer_rust_with_warning",
            sorts = {
                "exact",
                "score",
                "sort_text",
            },
        },
    },
}
