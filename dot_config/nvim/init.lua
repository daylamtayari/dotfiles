vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

local opt = vim.opt

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require("configs.lazy")

-- load plugins
require("lazy").setup({
	{
		"LazyVim/LazyVim",
		import = "lazyvim.plugins",
		opts = {
			colorscheme = "gruvbox",
		},
	},
	{ import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

vim.schedule(function()
	require("mappings")
end)

-- Global Options

-- Encoding Options:
vim.o.encoding = "UTF-8"
vim.o.fileencoding = "UTF-8"

-- Show relative line numbers and position:
vim.o.relativenumber = false
vim.o.number = true
vim.o.ruler = true

-- Tab settings (4 spaces, tabs are expressed as spaces and auto-indent):
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.autoindent = true

-- Color and Syntax Highlighting:
vim.o.termguicolors = true
vim.o.syntax = "on"
--vim.o.cursorline=true
vim.o.showmatch = true

-- Disable line wrapping:
vim.o.wrap = false

-- Do not hide characters:
vim.o.conceallevel = 0

-- Search settings:
vim.o.incsearch = true
vim.o.ignorecase = true

--Enable tab completion in command mode:
vim.o.wildmenu = true
