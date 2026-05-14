require("lua.options")
require("lua.lazy-bootstrap")

require("lazy").setup("lua.plugins", {
    change_detection = { notify = false },
    checker          = { enabled = true, notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip", "matchit", "matchparen",
                "netrwPlugin", "tarPlugin", "tohtml",
                "tutor", "zipPlugin",
            },
        },
    },
})

-- Basic keymaps
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>",        { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>",        { desc = "Quit" })
map("n", "<leader>x", "<cmd>x<cr>",        { desc = "Save and quit" })
map("n", "<Esc>",     "<cmd>nohlsearch<cr>")

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Buffer navigation
map("n", "<S-l>", "<cmd>bnext<cr>",     { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<cr>gv=gv")
map("v", "K", ":m '<-2<cr>gv=gv")

-- Keep cursor centered on search
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
