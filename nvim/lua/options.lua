local opt = vim.opt

opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"
opt.cursorline     = true

opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true

opt.wrap           = false
opt.scrolloff      = 8
opt.sidescrolloff  = 8

opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = false
opt.incsearch      = true

opt.termguicolors  = true
opt.showmode       = false
opt.splitright     = true
opt.splitbelow     = true

opt.undofile       = true
opt.swapfile       = false
opt.backup         = false

opt.updatetime     = 250
opt.timeoutlen     = 300

opt.completeopt    = { "menuone", "noselect" }

vim.g.mapleader      = " "
vim.g.maplocalleader = " "
