require('packer').startup(function(use)

    -- Heavily inspired by brokenbyte's NeoVim configurations.
    -- https://gitlab.com/brokenbyte/dotfiles/-/tree/master/dot_config/nvim

    use 'yashguptaz/calvera-dark.nvim'
    ------------------------------------------
    --      IDE Tools       --
    ------------------------------------------

    use 'wbthomason/packer.nvim'                    -- Plugin manager

    use {
        'nvim-lualine/lualine.nvim',                -- Fancy status line/tabline
        config = function()
            require("lualine_config")
        end
    }

    use {
        'neovim/nvim-lspconfig',                -- Nvim LSP config tool
        config = function()
            require("lsp_config")
        end
    }

    use {
        'williamboman/nvim-lsp-installer',          -- LSP Installer
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
        'simrat39/rust-tools.nvim',             -- Rust settings
        config=function()
            require("rust_tools_config")
        end
    }

    use {
        'ray-x/go.nvim',                    -- Golang settings
        ft='go'
    }

    use 'nvim-lua/popup.nvim'                   -- Popup helper
    use 'nvim-telescope/telescope.nvim'             -- Universal fuzzy finder

    use {
        'L3MON4D3/LuaSnip',                 -- Snippet plugin
        config=function()
            require("luasnip_config")
        end
    }

    use {
        'hrsh7th/nvim-cmp',                 -- Completion engine
        config=function()
            require("cmp_config")
        end
    }

    use 'hrsh7th/cmp-nvim-lsp'                  -- LSP completion source
    use 'hrsh7th/cmp-cmdline'                   -- Command line completion source
    use 'hrsh7th/cmp-buffer'                    -- Buffer completion source
    use 'hrsh7th/cmp-path'                      -- File path completion source
    use 'hrsh7th/cmp-omni'                      -- Vim omnicompletion source
    use 'hrsh7th/cmp-nvim-lua'                  -- Lua API completion
    use 'hrsh7th/cmp-calc'                      -- In-buffer calculation
    use 'Saecki/crates.nvim'                    -- Cargo.toml completion source
    use 'saadparwaiz1/cmp_luasnip'                  -- Luasnip completion source
    use 'onsails/lspkind-nvim'                  -- Pictograms for LSP
    use 'dhruvasagar/vim-table-mode'                -- Table mode

    use {
        'ahmedkhalf/project.nvim',              -- Project management plugin
        config=function()
            require("project_nvim").setup()
            require("telescope").load_extension('projects')
        end
    }

    use {
        'norcalli/nvim-colorizer.lua',              -- Colorizer
        config=function()
            require('colorizer').setup()
        end
    }

    use {
        'lukas-reineke/headlines.nvim',             -- Horizontal highlights
        config=function()
            require("headlines").setup()
        end
    }

    use {
        'kristijanhusak/orgmode.nvim',              -- Orgmode
        config=function()
            require('orgmode').setup({
                org_agenda_files={'~/.config/nvim/org/agenda/**/*'},
                org_default_notes_file='~/.config/nvim/org/notes.org',
            })
        end
    }

    use {
        'akinsho/org-bullets.nvim',             -- Bullets
        config=function()
            require('org-bullets').setup {
                symbols={ "???", "???", "???", "???" }
            }
        end
    }

    use {
        'rmagatti/goto-preview',                -- Go-to preview on floating window
        config=function()
            require('goto-preview').setup{}
        end
    }

    use {
        'kevinhwang91/nvim-bqf',                -- Quickfix window helper
        config=function()
            require('bqf').setup()
        end
    }

    use 'nvim-lua/lsp_extensions.nvim'              -- Shows buffer contents
    use 'nvim-treesitter/nvim-treesitter'               -- Treesitter parser
    use 'nvim-treesitter/playground'                -- Show treesitter nodes

    use {
        'nvim-treesitter/nvim-treesitter-textobjects',      -- Additionnal treesitter text objects
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
        'RRethy/nvim-treesitter-textsubjects',          -- Additional treesitter test subjects
        config=function()
            require 'nvim-treesitter.configs'.setup{
                textsubjects={
                    select={
                        enable=true,
                        keymaps={
                            ["af"]="@function.outer",
                            ["if"]="@function.inner",
                            ["ac"]="@class.outer",
                            ["ic"]="@class.inner",
                        },
                    },
                },
            }
        end
    }

    use {
        'ray-x/lsp_signature.nvim',             -- Displays function signature live
        config=function()
            require("lsp_signature").setup()
        end
    }

    use 'RishabhRD/nvim-lsputils'                   -- Utils for LSP
    use 'tpope/vim-dadbod'                      -- Database plugin

    use {
        'kristijanhusak/vim-dadbod-completion',         -- Database completion
        ft='sql'
    }

    use {
        'kristijanhusak/vim-dadbod-ui',             -- Database UI
        ft='sql'
    }

    use 'tpope/vim-surround'                    -- Surround objects with quotes/brackets/braces
    use 'scrooloose/nerdcommenter'                  -- Comment helper
    use 'RRethy/vim-illuminate'                 -- Highlight word under cursor
    use 'junegunn/fzf.vim'                      -- Fuzzy find files
    use 'mbbill/undotree'                       -- Interative undo-tree navigation
    use 'voldikss/vim-floaterm'                 -- Floating terminal window


    ------------------------------------------
    --      Git Tools       --
    ------------------------------------------

    use 'tpope/vim-fugitive'                    -- Git wrapper for vim

    use {
        'lewis6991/gitsigns.nvim',              -- Git decoations
        config=function()
            require('gitsigns').setup()
        end
    }

    use 'TimUntersberger/neogit'                    -- Magit for nvim
    use 'sindrets/diffview.nvim'                    -- Enahnced diff management

    use {
        'rhysd/git-messenger.vim',              -- View git commit messages for line under the cursor
        cmd='GitMessenger'
    }


    ------------------------------------------
    --      Autocompletion      --
    ------------------------------------------

    use 'Shougo/neco-syntax'                    -- Completion from syntax files
    use 'Shougo/neco-vim'                       -- Vim completion
    use 'lervag/vimtex'                     -- Latex helper
    use 'jiangmiao/auto-pairs'                  -- Auto brace closing


    ------------------------------------------
    --      Movement        --
    ------------------------------------------

    use 'unblevable/quick-scope'                    -- Faster left/right movement
    use 'junegunn/vim-slash'                    -- Enhanced '/' searching
    use 'tpope/vim-unimpaired'                  -- Additional vim navigation mappings


    ------------------------------------------
    --      Text Objects        --
    ------------------------------------------

    use 'wellle/targets.vim'                    -- Enhanced text objects
    use 'chaoren/vim-wordmotion'                    -- Enhanced word objects
    use 'junegunn/vim-after-object'                 -- Adds an 'after' object


    ------------------------------------------
    --      Formatting      --
    ------------------------------------------

    use 'chiel92/vim-autoformat'                    -- Auto reformatter
    use 'junegunn/vim-easy-align'                   -- Quickly align around a character


    --------------------------------------------------
    --      Misc/Unsorted Plugins       --
    --------------------------------------------------

    use {
        'SmiteshP/nvim-gps',                    -- Breadcrumbs in status line
        config=function()
            require('nvim-gps').setup()
        end
    }

    use 'lukas-reineke/indent-blankline.nvim'           -- Indentation lines
    use 'ojroques/vim-scrollstatus'                 -- Scroll status
    use 'tpope/vim-repeat'                      -- Allows the 'dot' command to repeat plugin actions
    use 'tpope/vim-eunuch'                      -- Vim wrapper for common shell commands
    use 'kyazdani42/nvim-web-devicons'              -- NerdFonts icons

    use {
        'goolord/alpha-nvim',
        config=function()
            require("alpha_config")
        end
    }

    use 'nvim-lua/plenary.nvim'                 -- Lua functions
    use 'psliwka/vim-smoothie'                  -- Smooth scrolling

    use {
        'folke/todo-comments.nvim',             -- To do comment highlighting
        config=function()
            require("todo-comments").setup()
        end
    }

    use 'folke/trouble.nvim'                    -- Diagnostics list/aggregator
    use 'folke/lsp-colors.nvim'                 -- Extra LSP colours for error messages
    use 'dstein64/nvim-scrollview'              -- Scroll bars
    use 'fladson/vim-kitty'                     -- Kitty terminal syntax highlighting

    use {
        'sidebar-nvim/sidebar.nvim',            -- Sidebar in Nvim
        rocks={'luatz'},
        config=function()
            require('sidebar-nvim').setup({
                open=true,
                side="left",
                disable_closing_prompt=false,
                hide_statusline=true,
                update_interval=1000,
                sections={'datetime','git','diagnostics','todos','buffers', 'files'},
                datetime={
                    format="%H:%M %A %d of %B %Y",
                    clocks={
                        {
                            name="Phoenix",
                            tz="America/Phoenix",
                            offset=-7
                        },
                        {
                            name="UTC",
                            tz="Etc/UTC",
                            offset=0
                        }
                    }
                },
                buffers={
                    icon = "???"
                },
                files = {
                    icon = "???",
                    show_hidden = false
                },
            })
        end
    }

    use {
        'iamcco/markdown-preview.nvim',         -- Markdown preview in the browser
        run=[[sh -c 'cd app && yarn install']],
    }

    use {
        'mickael-menu/zk-nvim',
        config=function()
            require('zk').setup({
                picker='fzf',
                lsp = {
                    config = {
                        cmd={'zk','lsp'},
                        name='zk',
                    },
                    auto_attach={
                        enabled=true,
                        filetypes={'markdown'},
                    },
                },
            })
        end
    }

    use {
        'p00f/clangd_extensions.nvim',
        config=function()
            require("clangd_extensions").setup{
                server = {
                    -- options to pass to nvim-lspconfig
                    -- i.e. the arguments to require("lspconfig").clangd.setup({})
                },
                extensions = {
                    -- defaults:
                    -- Automatically set inlay hints (type hints)
                    autoSetHints = true,
                    -- Whether to show hover actions inside the hover window
                    -- This overrides the default hover handler
                    hover_with_actions = true,
                    -- These apply to the default ClangdSetInlayHints command
                    inlay_hints = {
                        -- Only show inlay hints for the current line
                        only_current_line = false,
                        -- Event which triggers a refersh of the inlay hints.
                        -- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
                        -- not that this may cause  higher CPU usage.
                        -- This option is only respected when only_current_line and
                        -- autoSetHints both are true.
                        only_current_line_autocmd = "CursorHold",
                        -- whether to show parameter hints with the inlay hints or not
                        show_parameter_hints = true,
                        -- prefix for parameter hints
                        parameter_hints_prefix = "<- ",
                        -- prefix for all the other hints (type, chaining)
                        other_hints_prefix = "=> ",
                        -- whether to align to the length of the longest line in the file
                        max_len_align = false,
                        -- padding from the left if max_len_align is true
                        max_len_align_padding = 1,
                        -- whether to align to the extreme right or not
                        right_align = false,
                        -- padding from the right if right_align is true
                        right_align_padding = 7,
                        -- The color of the hints
                        highlight = "Comment",
                    },
                    ast = {
                        role_icons = {
                            type = "???",
                            declaration = "???",
                            expression = "???",
                            specifier = "???",
                            statement = "???",
                            ["template argument"] = "???",
                        },

                        kind_icons = {
                            Compound = "???",
                            Recovery = "???",
                            TranslationUnit = "???",
                            PackExpansion = "???",
                            TemplateTypeParm = "???",
                            TemplateTemplateParm = "???",
                            TemplateParamObject = "???",
                        },

                        highlights = {
                            detail = "Comment",
                        },
                        memory_usage = {
                            border = "none",
                        },
                        symbol_info = {
                            border = "none",
                        },
                    },
                }
            }
            end
        }

end)
