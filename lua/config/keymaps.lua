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
