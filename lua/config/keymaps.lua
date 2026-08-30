-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

--  New undo block after a comma.
vim.keymap.set("i", ",", ",<C-g>u")

-- New undo block after a semicolon.
vim.keymap.set("i", ";", ";<C-g>u")

--  New undo block after a period
vim.keymap.set("i", ".", ".<C-g>u")

--  New undo block after an exclamation mark.
vim.keymap.set("i", "!", "!<C-g>u")

--  New undo block after a question mark
vim.keymap.set("i", "?", "?<C-g>u")

--  New undo block after an asignment operator
vim.keymap.set("i", "=", "=<C-g>u")

-- dap
local dap = require("dap")

-- Debugger
vim.keymap.set("n", "<F1>", dap.continue, {
  desc = "DAP Continue",
})

vim.keymap.set("n", "<F2>", dap.step_into, {
  desc = "DAP Step Into",
})

vim.keymap.set("n", "<F3>", dap.step_over, {
  desc = "DAP Step Over",
})

vim.keymap.set("n", "<F4>", dap.step_out, {
  desc = "DAP Step Out",
})

vim.keymap.set("n", "<F5>", dap.restart, {
  desc = "DAP Restart",
})

vim.keymap.set("n", "<F6>", dap.terminate, {
  desc = "DAP Terminate",
})

vim.keymap.set("n", "<F7>", dap.toggle_breakpoint, {
  desc = "DAP Toggle Breakpoint",
})
