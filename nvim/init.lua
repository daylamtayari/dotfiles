-----------------
-- Vim Options --
-----------------

-- Global Options: --
---------------------

vim.g.calvera_italic_comments = true
vim.g.calvera_italic_keywords = true
vim.g.calvera_contrast = false
vim.g.calvera_borders = true
vim.g.calvera_custom_colors = { selection = "#36366b" }
require('calvera').set()

-- Encoding Options:
vim.o.encoding="UTF-8"
vim.o.fileencoding="UTF-8"

-- Show relative line numbers and position:
vim.o.relativenumber=false
vim.o.number=true
vim.o.ruler=true

-- Tab settings (4 spaces, tabs are expressed as spaces and auto-indent):
vim.o.tabstop=4
vim.o.softtabstop=4
vim.o.shiftwidth=4
vim.o.expandtab=true
vim.o.autoindent=true

-- Color and Syntax Highlighting:
vim.o.termguicolors=true
vim.o.syntax='on'
--vim.o.cursorline=true
vim.o.showmatch=true

-- Folding settings (minimum lines to fold):
vim.o.foldminlines=15
vim.o.foldcolumn='2'
vim.o.foldexpr='nvim_treesitter#foldexpr()'

-- Disable line wrapping:
vim.o.wrap=false

-- Enable sign column:
vim.o.signcolumn='yes'

-- Show substitution live:
vim.o.inccommand='split'

-- Do not hide characters:
vim.o.conceallevel=0

-- Search settings:
vim.o.incsearch=true
vim.o.ignorecase=true

--Enable tab completion in command mode:
vim.o.wildmenu=true

-- Always show the status bar:
vim.o.laststatus=2



----------------------
-- Global Variables --
----------------------

-- VimTex Global Variables:
---------------------------
vim.g.vimtex_view_method="general"
vim.g.vimtex_view_general_viewer="okular"
vim.g.vimtex_compiler_progname="nvr"



---------------------------------
-- Configuration Files Imports --
---------------------------------
require('plugins')
