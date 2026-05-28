local map = vim.keymap.set

map("n", "<leader>w",  "<cmd>w<cr>",          { desc = "Save" })
map("n", "<leader>q",  "<cmd>q<cr>",          { desc = "Quit" })
map("n", "<leader>x",  "<cmd>x<cr>",          { desc = "Save and quit" })
map("n", "<Esc>",      "<cmd>nohlsearch<cr>",  { desc = "Clear search highlight", silent = true })

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window",  silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })

map("v", "J", "<cmd>m '>+1<cr>gv=gv", { desc = "Move line down", silent = true })
map("v", "K", "<cmd>m '<-2<cr>gv=gv", { desc = "Move line up",   silent = true })

map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
