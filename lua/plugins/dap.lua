return {
  {
    "mfussenegger/nvim-dap",

    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      ----------------------------------------------------------------------
      -- DAP UI
      ----------------------------------------------------------------------

      dapui.setup()

      ----------------------------------------------------------------------
      -- Virtual text
      ----------------------------------------------------------------------

      require("nvim-dap-virtual-text").setup()

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
      -- Microsoft C/C++ DAP adapter
      ----------------------------------------------------------------------

      dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",

        command = vim.fn.expand(
          "~/.vscode/extensions/ms-vscode.cpptools-1.32.2-linux-x64/debugAdapters/bin/OpenDebugAD7"
        ),
      }

      ----------------------------------------------------------------------
      -- STM32 C debugging
      ----------------------------------------------------------------------

      dap.configurations.c = {
        {
          name = "STM32 Debug",
          type = "cppdbg",
          request = "launch",

          ------------------------------------------------------------------
          -- Automatically find the ELF
          ------------------------------------------------------------------

          program = function()
            local cwd = vim.fn.getcwd()

            local files = vim.fn.glob(
              cwd .. "/build/Debug/*.elf",
              false,
              true
            )

            if #files == 0 then
              error("No ELF file found in build/Debug/")
            end

            if #files > 1 then
              error("Multiple ELF files found in build/Debug/")
            end

            return files[1]
          end,

          ------------------------------------------------------------------
          -- Working directory
          ------------------------------------------------------------------

          cwd = "${workspaceFolder}",

          ------------------------------------------------------------------
          -- GDB
          ------------------------------------------------------------------

          MIMode = "gdb",
          miDebuggerPath = "gdb-multiarch",

          ------------------------------------------------------------------
          -- OpenOCD GDB server
          ------------------------------------------------------------------

          miDebuggerServerAddress = "localhost:3333",

          ------------------------------------------------------------------
          -- ARM target
          ------------------------------------------------------------------

          targetArchitecture = "arm",

          ------------------------------------------------------------------
          -- Stop when program starts
          ------------------------------------------------------------------

          stopAtEntry = true,

          ------------------------------------------------------------------
          -- GDB initialization
          ------------------------------------------------------------------

          setupCommands = {
            {
              text = "set architecture arm",
              description = "Set ARM architecture",
              ignoreFailures = false,
            },
          },
        },
      }

    end,
  },
}
