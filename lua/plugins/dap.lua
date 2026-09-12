return {
    {
        "mfussenegger/nvim-dap",

        dependencies = {
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
            "nvim-telescope/telescope.nvim",
        },

        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            ----------------------------------------------------------------------
            -- DAP UI
            ----------------------------------------------------------------------

            ---@diagnostic disable-next-line: missing-fields
            dapui.setup({
                layouts = {
                    {
                        position = "right",
                        size = 40,

                        elements = {
                            {
                                id = "scopes",
                                size = 1.0,
                            },

                            -- RTT disabled for now.
                            -- { id = "rtt", size = 0.5 },
                        },
                    },
                },
            })

            ----------------------------------------------------------------------
            -- Virtual text
            ----------------------------------------------------------------------
            require("nvim-dap-virtual-text").setup({
                enabled = true,

                enabled_commands = true,

                highlight_changed_variables = true,

                highlight_new_as_changed = false,

                show_stop_reason = true,

                commented = true,

                only_first_definition = false,

                all_references = false,

                virt_text_pos = "eol",

                virt_lines = false,

                virt_text_win_col = nil,

                clear_on_continue = false,

                display_callback = function(variable)
                    return variable.name .. " = " .. variable.value
                end,
            })

            ----------------------------------------------------------------------
            -- DAP signs
            ----------------------------------------------------------------------

            vim.fn.sign_define("DapBreakpoint", {
                text = "●",
                texthl = "DiagnosticSignError",
                linehl = "",
                numhl = "",
            })

            vim.fn.sign_define("DapStopped", {
                text = "→",
                texthl = "DiagnosticSignWarn",
                linehl = "CursorLine",
                numhl = "",
            })

            vim.fn.sign_define("DapBreakpointRejected", {
                text = "○",
                texthl = "DiagnosticSignHint",
                linehl = "",
                numhl = "",
            })

            ----------------------------------------------------------------------
            -- Linux GDB adapter
            ----------------------------------------------------------------------

            dap.adapters.gdb = {
                type = "executable",

                command = "gdb",

                args = {
                    "-i",
                    "dap",
                },
            }

            ----------------------------------------------------------------------
            -- Linux C configuration
            ----------------------------------------------------------------------

            dap.configurations.c = dap.configurations.c or {}

            table.insert(dap.configurations.c, {
                name = "Linux Debug",

                type = "gdb",
                request = "launch",

                -- This is replaced by the Telescope-selected executable.
                program = function()
                    error(
                        "Use :Debug or F1 to select the Linux executable"
                    )
                end,

                cwd = "${workspaceFolder}",

                stopAtBeginningOfMainSubprogram = false,
            })

            ----------------------------------------------------------------------
            -- Linux C++ configuration
            ----------------------------------------------------------------------

            dap.configurations.cpp = dap.configurations.cpp or {}

            table.insert(dap.configurations.cpp, {
                name = "Linux Debug",

                type = "gdb",
                request = "launch",

                -- This is replaced by the Telescope-selected executable.
                program = function()
                    error(
                        "Use :Debug or F1 to select the Linux executable"
                    )
                end,

                cwd = "${workspaceFolder}",

                stopAtBeginningOfMainSubprogram = false,
            })

            ----------------------------------------------------------------------
            -- Project root
            ----------------------------------------------------------------------

            local function project_root()
                return vim.fs.root(0, {
                    "CMakePresets.json",
                    ".git",
                    "Makefile",
                }) or vim.fn.getcwd()
            end

            ----------------------------------------------------------------------
            -- Find DAP configuration
            ----------------------------------------------------------------------

            local function find_configuration(name)
                local filetype = vim.bo.filetype

                local configurations = dap.configurations[filetype]

                if not configurations or #configurations == 0 then
                    configurations = dap.configurations.c
                end

                for _, configuration in ipairs(configurations or {}) do
                    if configuration.name == name then
                        return configuration
                    end
                end

                return nil
            end

            ----------------------------------------------------------------------
            -- Telescope Linux executable picker
            ----------------------------------------------------------------------

            local function select_linux_executable(callback)
                local telescope_builtin = require("telescope.builtin")
                local telescope_actions = require("telescope.actions")
                local telescope_action_state =
                require("telescope.actions.state")

                local root = project_root()
                local build_dir = root .. "/build"

                local build_stat = vim.uv.fs_stat(build_dir)

                if not build_stat or build_stat.type ~= "directory" then
                    vim.notify(
                        "Build directory not found:\n" .. build_dir,
                        vim.log.levels.ERROR
                    )
                    return
                end

                telescope_builtin.find_files({
                    cwd = build_dir,

                    prompt_title = "Select Linux executable",

                    hidden = true,

                    -- Search all files under build/.
                    -- We will validate that the selected file is executable.
                    find_command = {
                        "find",
                        ".",
                        "-type",
                        "f",
                        "-not",
                        "-path",
                        "*/.git/*",
                        "-print",
                    },

                    attach_mappings = function(prompt_bufnr, map)
                        local function select_file()
                            local entry =
                            telescope_action_state.get_selected_entry()

                            if not entry then
                                return
                            end

                            local path = entry.path or entry.value

                            telescope_actions.close(prompt_bufnr)

                            if not path then
                                vim.notify(
                                    "No file selected",
                                    vim.log.levels.ERROR
                                )
                                return
                            end

                            ------------------------------------------------------------------
                            -- Convert relative path to absolute path
                            ------------------------------------------------------------------

                            if path:sub(1, 1) ~= "/" then
                                path = build_dir .. "/" .. path
                            end

                            path = vim.fs.normalize(path)

                            ------------------------------------------------------------------
                            -- Validate selected file
                            ------------------------------------------------------------------

                            local stat = vim.uv.fs_stat(path)

                            if not stat or stat.type ~= "file" then
                                vim.notify(
                                    "Selected path is not a regular file",
                                    vim.log.levels.ERROR
                                )
                                return
                            end

                            if vim.fn.executable(path) ~= 1 then
                                vim.notify(
                                    "Selected file is not executable:\n" .. path,
                                    vim.log.levels.ERROR
                                )
                                return
                            end

                            callback(path)
                        end

                        map("i", "<CR>", select_file)
                        map("n", "<CR>", select_file)

                        return true
                    end,
                })
            end
            ----------------------------------------------------------------------
            -- Start Linux debugging
            ----------------------------------------------------------------------

            local function start_linux_debug()
                local configuration =
                find_configuration("Linux Debug")

                if not configuration then
                    vim.notify(
                        "Linux Debug configuration was not found",
                        vim.log.levels.ERROR
                    )
                    return
                end

                select_linux_executable(function(path)
                    local launch_configuration =
                    vim.deepcopy(configuration)

                    launch_configuration.program = path

                    dap.run(launch_configuration)
                end)
            end

            ----------------------------------------------------------------------
            -- Debug target selector
            ----------------------------------------------------------------------

            local function debug_target_selector()
                if dap.session() then
                    dap.continue()
                    return
                end

                vim.ui.select(
                    {
                        "Linux Debug",
                        "STM32 Debug",
                    },
                    {
                        prompt = "Select debug target:",
                    },
                    function(choice)
                        if not choice then
                            return
                        end

                        if choice == "Linux Debug" then
                            start_linux_debug()
                            return
                        end

                        if choice == "STM32 Debug" then
                            local configuration =
                            find_configuration("STM32 Debug")

                            if not configuration then
                                vim.notify(
                                    "STM32 Debug configuration was not found",
                                    vim.log.levels.ERROR
                                )
                                return
                            end

                            dap.run(configuration)
                        end
                    end
                )
            end

            ----------------------------------------------------------------------
            -- User command
            ----------------------------------------------------------------------

            vim.api.nvim_create_user_command(
                "Debug",
                debug_target_selector,
                {
                    desc = "Select Linux or STM32 debug target",
                }
            )
        end,
    },
}
