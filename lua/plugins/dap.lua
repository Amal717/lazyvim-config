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
            local telescope_builtin = require("telescope.builtin")

            ----------------------------------------------------------------------
            -- DAP UI
            ----------------------------------------------------------------------
            ---@diagnostic disable-next-line: missing-fields
            dapui.setup({
                layouts = {
                    {
                        elements = {
                            "scopes",
                            "breakpoints",
                            "stacks",
                            "watches",
                        },

                        size = 0.25,
                        position = "left",
                    },

                    {
                        elements = {
                            "repl",
                            "console",
                        },

                        size = 0.25,
                        position = "bottom",
                    },
                },

                controls = {
                    enabled = true,
                },

                floating = {
                    border = "rounded",
                },
            })

            ----------------------------------------------------------------------
            -- Virtual text
            ----------------------------------------------------------------------

            require("nvim-dap-virtual-text").setup({
                enabled = true,
                enabled_commands = true,
                highlight_changed_variables = true,
                highlight_new_as_changed = true,
                show_stop_reason = true,
                commented = false,
                virt_text_pos = "eol",
                all_frames = false,
            })

            ----------------------------------------------------------------------
            -- Signs
            ----------------------------------------------------------------------

            vim.fn.sign_define("DapBreakpoint", {
                text = "●",
                texthl = "DiagnosticSignError",
                linehl = "",
                numhl = "",
            })

            vim.fn.sign_define("DapBreakpointCondition", {
                text = "◆",
                texthl = "DiagnosticSignWarn",
                linehl = "",
                numhl = "",
            })

            vim.fn.sign_define("DapLogPoint", {
                text = "▶",
                texthl = "DiagnosticSignHint",
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
            -- GDB adapter for Linux
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
            -- Project root
            ----------------------------------------------------------------------

            local function project_root()
                local cwd = vim.fn.getcwd()

                local git_root = vim.fn.systemlist({
                    "git",
                    "-C",
                    cwd,
                    "rev-parse",
                    "--show-toplevel",
                })

                if vim.v.shell_error == 0 and git_root[1] then
                    return git_root[1]
                end

                return cwd
            end

            ----------------------------------------------------------------------
            -- Linux DAP configuration
            ----------------------------------------------------------------------

            dap.configurations.c = dap.configurations.c or {}
            dap.configurations.cpp = dap.configurations.cpp or {}

            local linux_configuration = {
                name = "Linux Debug",
                type = "gdb",
                request = "launch",

                program = function()
                    error("Use :Debug to select the Linux executable")
                end,

                cwd = "${workspaceFolder}",

                stopAtBeginningOfMainSubprogram = false,

                args = {},

                runInTerminal = false,
            }

            table.insert(dap.configurations.c, linux_configuration)
            table.insert(dap.configurations.cpp, linux_configuration)

            ----------------------------------------------------------------------
            -- Find DAP configuration by name
            ----------------------------------------------------------------------

            local function find_configuration(name)
                local configurations = {}

                for _, configuration in ipairs(dap.configurations.c or {}) do
                    if configuration.name == name then
                        table.insert(configurations, configuration)
                    end
                end

                for _, configuration in ipairs(dap.configurations.cpp or {}) do
                    if configuration.name == name then
                        table.insert(configurations, configuration)
                    end
                end

                if #configurations > 0 then
                    return configurations[1]
                end

                return nil
            end

            ----------------------------------------------------------------------
            -- Select Linux executable
            ----------------------------------------------------------------------

            local function select_linux_executable(callback)
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
                                vim.notify(
                                    "No file selected",
                                    vim.log.levels.ERROR
                                )

                                return
                            end

                            local path = entry.path or entry.value

                            telescope_actions.close(prompt_bufnr)

                            if not path then
                                vim.notify(
                                    "No file path found",
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
                                    "Selected path is not a regular file:\n"
                                    .. path,
                                    vim.log.levels.ERROR
                                )

                                return
                            end

                            if vim.fn.executable(path) ~= 1 then
                                vim.notify(
                                    "Selected file is not executable:\n"
                                    .. path,
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
                    launch_configuration.cwd = project_root()

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
                            if _G.start_stm32_debug then
                                _G.start_stm32_debug()
                            else
                                vim.notify(
                                    "STM32 debugger is not available. "
                                    .. "Check cortex-debug.lua.",
                                    vim.log.levels.ERROR
                                )
                            end
                        end
                    end
                )
            end

            ----------------------------------------------------------------------
            -- DAP UI listeners
            ----------------------------------------------------------------------

            -- dap.listeners.before.attach.dapui_config = function()
            --     dapui.open()
            -- end
            --
            -- dap.listeners.before.launch.dapui_config = function()
            --     dapui.open()
            -- end
            --
            -- dap.listeners.before.event_terminated.dapui_config = function()
            --     dapui.close()
            -- end
            --
            -- dap.listeners.before.event_exited.dapui_config = function()
            --     dapui.close()
            -- end

            ----------------------------------------------------------------------
            -- Keymaps
            ----------------------------------------------------------------------

            vim.keymap.set("n", "<F5>", dap.continue, {
                desc = "DAP Continue",
            })

            vim.keymap.set("n", "<F10>", dap.step_over, {
                desc = "DAP Step Over",
            })

            vim.keymap.set("n", "<F11>", dap.step_into, {
                desc = "DAP Step Into",
            })

            vim.keymap.set("n", "<F12>", dap.step_out, {
                desc = "DAP Step Out",
            })

            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, {
                desc = "DAP Toggle Breakpoint",
            })

            vim.keymap.set("n", "<leader>dB", function()
                dap.set_breakpoint(
                    vim.fn.input("Breakpoint condition: ")
                )
            end, {
                    desc = "DAP Conditional Breakpoint",
                })

            vim.keymap.set("n", "<leader>dr", dap.repl.open, {
                desc = "DAP REPL",
            })

            vim.keymap.set("n", "<leader>du", dapui.toggle, {
                desc = "DAP UI Toggle",
            })

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
