require('packer').startup(function(use)
	
	-- Heavily inspired by brokenbyte's NeoVim configurations.
	-- https://gitlab.com/brokenbyte/dotfiles/-/tree/master/dot_config/nvim
	
	------------------------------------------
	--		IDE Tools		--
	------------------------------------------
	
	use 'wbthomason/packer.nvim'					-- Plugin manager

	use {
		'nvim-lualine/lualine.nvim',				-- Fancy status line/tabline
		config = function()
			require("lualine_config")
		end
	}

	use {
		'neovim/nvim-lspconfig',				-- Nvim LSP config tool
		config = function()
			require("lsp_config")
		end
	}

	use {
		'williamboman/nvim-lsp-installer',			-- LSP Installer
		config = function()
			local util=require("util")
			local lsp_installer=require("nvim-lsp-installer")
			lsp_installer.on_server_ready(function(server)
				local opts= {
					on_attach=util.on_attach,
					capabilities=util.capabilities,
					update_in_insert=true,
				}
				server:setup(opts)
				vim.cmd [[ do User LspAttachBuffers ]]
			end)
		end
	}

	use {
		'simrat39/rust-tools.nvim',				-- Rust settings
		config=function()
			require("rust_tools_config")
		end
	}

	use {
		'ray-x/go.nvim',					-- Golang settings
		ft='go'
	}

	use 'nvim-lua/popup.nvim'					-- Popup helper
	use 'nvim-telescope/telescope.nvim'				-- Universal fuzzy finder

	use {
		'L3MON4D3/LuaSnip',					-- Snippet plugin
		config=function()
			require("luasnip_config")
		end
	}

	use {
		'hrsh7th/nvim-cmp',					-- Completion engine
		config=function()
			require("cmp_config")
		end
	}

	use 'hrsh7th/cmp-nvim-lsp'					-- LSP completion source
	use 'hrsh7th/cmp-cmdline'					-- Command line completion source
	use 'hrsh7th/cmp-buffer'					-- Buffer completion source
	use 'hrsh7th/cmp-path'						-- File path completion source
	use 'hrsh7th/cmp-omni'						-- Vim omnicompletion source
	use 'hrsh7th/cmp-nvim-lua'					-- Lua API completion
	use 'hrsh7th/cmp-calc'						-- In-buffer calculation
	use 'Saecki/crates.nvim'					-- Cargo.toml completion source
	use 'saadparwaiz1/cmp_luasnip'					-- Luasnip completion source
	use 'onsails/lspkind-nvim'					-- Pictograms for LSP
	use 'dhruvasagar/vim-table-mode'				-- Table mode

	use {
		'ahmedkhalf/project.nvim',				-- Project management plugin
		config=function()
			require("project_nvim").setup()
			require("telescope").load_extension('projects')
		end
	}

	use {
		'norcalli/nvim-colorizer.lua'.				-- Colorizer
		config=function()
			require('colorizer').setup()
		end
	}

	use {
		'lukas-reineke/headlines.nvim',				-- Horizontal highlights
		config=function()
			require("headlines").setup()
		end
	}

	use {
		'kristijanhusak/orgmove.nvim',				-- Orgmode
		branch='tree-sitter',
		config=function()
			require('orgmode').setup({
				org_agenda_files={'~/.config/nvim/org/agenda/**/*'},
				org_default_notes_file='~/.config/nvim/org/notes.org',
			})
		end
	}

	use {
		'akinsho/org-bullets.nvim',				-- Bullets 
		config=function()
			require('org-bullets').setup {
				symbols={ "◉", "○", "✸", "✿" }
			}
		end
	}

	use {
		'rmagatti/goto-preview',				-- Go-to preview on floating window
		config=function()
			require('goto-preview').setup{}
		end
	}

	use {
		'kevinhwang91/nvim-bqf',				-- Quickfix window helper
		config=function()
			require('bqf').setup()
		end
	}

	use 'nvim-lua/lsp_extensions.nvim'				-- Shows buffer contents
	use 'nvim-treesitter/nvim-treesitter'				-- Treesitter parser
	use 'nvim-treesitter/playground'				-- Show treesitter nodes

	use {
		'nvim-treesitter/nvim-treesitter-textobjects',		-- Additionnal treesitter text objects
		config=function()
			require('nvim-treesitter.configs').setup{
				textobjects={
					enable=true,
					keymaps={
						['.']='textsubjects-smart',
						[';']='textsubjects-container-outer',
					}
				},
			}
		end
	}

	use {
		'RRethy/nvim-treesitter-textsubjects'.			-- Additional treesitter test subjects
		config=function()
			require 'nvim-treesitter.configs'.setup{
				textsubjects={
					select={
						enable=true,
						keymaps={
							["af"]="@function.outer",
							["if"]="@function.inner".
							["ac"]="@class.outer",
							["ic"]="@class.inner",
						},
					},
				},
			}
		end
	}

	use {
		'ray-x/lsp_signature.nvim',				-- Displays function signature live
		config=function()
			require("lsp_signature").setup()
		end
	}

	use 'RishabhRD/nvim-lsputils'					-- Utils for LSP
	use 'tpope/vim-dadbod'						-- Database plugin
	
	use {
		'kristijanhusak/vim-dadbod-completion',			-- Database completion
		ft='sql'
	}

	use {
		'kristijanhusak/vim-dadbod-ui',				-- Database UI
		ft='sql'
	}

	use 'tpope/vim-surround'					-- Surround objects with quotes/brackets/braces
	use 'scrooloose/nerdcommenter'					-- Comment helper
	use 'RRethy/vim-illuminate'					-- Highlight word under cursor
	use 'junegunn/fzf.vim'						-- Fuzzy find files
	use 'mbbill/undotree'						-- Interative undo-tree navigation
	use 'voldikss/vim-floaterm'					-- Floating terminal window


	------------------------------------------
	--		Git Tools		--
	------------------------------------------
	
	use 'tpope/vim-fugitive'					-- Git wrapper for vim
	
	use {
		'lewis6991/gitsigns.nvim',				-- Git decoations
		config=function()
			require('gitsigns').setup()
		end
	}

	use 'TimUntersberger/neogit'					-- Magit for nvim
	use 'sindrets/diffview.nvim'					-- Enahnced diff management
	
	use {
		'rhysd/git-messenger.vim',				-- View git commit messages for line under the cursor
		cmd='GitMessenger'
	}


	------------------------------------------
	--		Autocompletion		--
	------------------------------------------
	
	use 'Shougo/neco-syntax'					-- Completion from syntax files
	use 'Shougo/neco-vim'						-- Vim completion
	use 'lervag/vimtex'						-- Latex helper
	use 'jiangmiao/auto-pairs'					-- Auto brace closing


	------------------------------------------
	--		Movement		--
	------------------------------------------
	
	use 'unblevable/quick-scope'					-- Faster left/right movement
	use 'junegunn/vim-slash'					-- Enhanced '/' searching
	use 'tpope/vim-unimpaired'					-- Additional vim navigation mappings


	------------------------------------------
	--		Text Objects		--
	------------------------------------------
	
	use 'wellle/targets.vim'					-- Enhanced text objects
	use 'chaoren/vim-wordmotion'					-- Enhanced word objects
	use 'junegunn/vim-after-objectif'				-- Adds an 'after' object


	------------------------------------------
	--		Formatting		--
	------------------------------------------
	
	use 'chiel92/vim-autoformat'					-- Auto reformatter
	use 'junegunn/vim-easy-align'					-- Quickly align around a character
	

	--------------------------------------------------
	--		Misc/Unsorted Plugins		--
	--------------------------------------------------
	
	use {
		'SmiteshP/nvim-gps',					-- Breadcrumbs in status line
		config=function()
			require('nvim-gps').setup()
		end
	}

	use 'lukas-reineke/indent-blankline.nvim'			-- Indentation lines
	use 'ojroques/vim-scrollstatus'					-- Scroll status
	use 'tpope/vim-repeat'						-- Allows the 'dot' command to repeat plugin actions
	use 'tpope/vim-eunuch'						-- Vim wrapper for common shell commands
	use 'kyazdani42/nvim-web-devicons'				-- NerdFonts icons
	
	use {
		'goolord/alpha-nvim',
		config=function()
			require("alpha_config")
		end
	}

	use 'nvim-lua/plenary.nvim'					-- Lua functions
	use 'psliwka/vim-smoothie'					-- Smooth scrolling

	use {
		'folke/todo-comments.nvim',				-- To do comment highlighting
		config=function()
			require("todo-comments").setup()
		end
	}

	use 'folke/trouble.nvim'					-- Diagnostics list/aggregator
	use 'folke/lsp-colors.nvim'					-- Extra LSP colours for error messages
	use 'dstein64/nvim-scrollview'					-- Scroll bars
	use 'fladson/vim-kitty'						-- Kitty terminal syntax highlighting


end)
