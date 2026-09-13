return {
  {
    "jedrzejboczar/nvim-dap-cortex-debug",

    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "nvim-telescope/telescope.nvim",
    },

    config = function()
      local dap = require("dap")
      local telescope = require("telescope.builtin")
      local cortex_debug = require("dap-cortex-debug")

      ----------------------------------------------------------------------
      -- Cortex-Debug setup
      ----------------------------------------------------------------------

      cortex_debug.setup({
        debug = false,
      })

      ----------------------------------------------------------------------
      -- Workspace
      ----------------------------------------------------------------------

      local function workspace_root()
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
      -- Find OpenOCD configuration
      ----------------------------------------------------------------------

      local function find_openocd_config()
        local root = workspace_root()

        local configs = vim.fn.glob(
          root .. "/**/openocd.cfg",
          true,
          true
        )

        if #configs == 0 then
          vim.notify(
            "No openocd.cfg found in workspace.",
            vim.log.levels.ERROR
          )

          return nil
        end

        if #configs == 1 then
          return configs[1]
        end

        return configs
      end

      ----------------------------------------------------------------------
      -- Find ELF files
      ----------------------------------------------------------------------

      local function find_elf_files()
        local root = workspace_root()
        local build_dir = root .. "/build"

        if vim.fn.isdirectory(build_dir) == 0 then
          vim.notify(
            "Build directory not found: " .. build_dir,
            vim.log.levels.ERROR
          )

          return {}
        end

        local elf_files = vim.fn.glob(
          build_dir .. "/**/*.elf",
          true,
          true
        )

        local valid_elf_files = {}

        for _, elf_file in ipairs(elf_files) do
          if vim.fn.filereadable(elf_file) == 1 then
            table.insert(valid_elf_files, elf_file)
          end
        end

        return valid_elf_files
      end

      ----------------------------------------------------------------------
      -- Find ARM-compatible GDB
      ----------------------------------------------------------------------

      local function find_arm_gdb()
        local candidates = {
          "arm-none-eabi-gdb",
          "gdb-multiarch",
        }

        for _, executable in ipairs(candidates) do
          if vim.fn.executable(executable) == 1 then
            return executable
          end
        end

        vim.notify(
          "No ARM-compatible GDB found. Install gdb-multiarch.",
          vim.log.levels.ERROR
        )

        return nil
      end

      ----------------------------------------------------------------------
      -- Select an item using Telescope
      ----------------------------------------------------------------------

      local function select_from_telescope(items, prompt, callback)
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        pickers.new({}, {
          prompt_title = prompt,

          finder = finders.new_table({
            results = items,
          }),

          sorter = conf.generic_sorter({}),

          attach_mappings = function(prompt_bufnr, map)
            local function select_item()
              local selection = action_state.get_selected_entry()

              actions.close(prompt_bufnr)

              if selection then
                callback(selection.value)
              end
            end

            map("i", "<CR>", select_item)
            map("n", "<CR>", select_item)

            return true
          end,
        }):find()
      end

      ----------------------------------------------------------------------
      -- Select OpenOCD config
      ----------------------------------------------------------------------

      local function select_openocd_config(callback)
        local configs = find_openocd_config()

        if not configs then
          return
        end

        if type(configs) == "string" then
          callback(configs)
          return
        end

        select_from_telescope(
          configs,
          "Select OpenOCD configuration",
          callback
        )
      end

      ----------------------------------------------------------------------
      -- STM32 configuration
      ----------------------------------------------------------------------

      local stm32_configuration = {
        name = "STM32 Debug",
        type = "cortex-debug",
        request = "launch",

        cwd = "${workspaceFolder}",

        servertype = "openocd",
        serverpath = "openocd",

        runToEntryPoint = "main",

        -- Assigned dynamically before dap.run().
        executable = nil,
        configFiles = nil,
        gdbPath = nil,
      }

      ----------------------------------------------------------------------
      -- Start STM32 debugging
      ----------------------------------------------------------------------

      local function start_stm32_debug()
        local gdb_path = find_arm_gdb()

        if not gdb_path then
          return
        end

        local elf_files = find_elf_files()

        if #elf_files == 0 then
          vim.notify(
            "No .elf file found under " ..
            workspace_root() .. "/build",
            vim.log.levels.ERROR
          )

          return
        end

        local function launch_with_config(openocd_config)
          if not openocd_config then
            return
          end

          local function launch_debugger(elf_path)
            if not elf_path then
              return
            end

            local configuration = vim.deepcopy(stm32_configuration)

            configuration.gdbPath = gdb_path
            configuration.executable = elf_path
            configuration.configFiles = {
              openocd_config,
            }

            dap.run(configuration)
          end

          if #elf_files == 1 then
            launch_debugger(elf_files[1])
          else
            select_from_telescope(
              elf_files,
              "Select STM32 ELF",
              launch_debugger
            )
          end
        end

        select_openocd_config(launch_with_config)
      end

      ----------------------------------------------------------------------
      -- Expose launcher to dap.lua
      ----------------------------------------------------------------------

      _G.start_stm32_debug = start_stm32_debug

      ----------------------------------------------------------------------
      -- Register STM32 configurations
      ----------------------------------------------------------------------

      dap.configurations.c = dap.configurations.c or {}
      dap.configurations.cpp = dap.configurations.cpp or {}

      table.insert(dap.configurations.c, stm32_configuration)
      table.insert(dap.configurations.cpp, stm32_configuration)
    end,
  },
}
