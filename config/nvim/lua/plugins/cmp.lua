return {
	"hrsh7th/nvim-cmp",
	version = false, -- last release is way too old
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		{
			"garymjr/nvim-snippets",
			opts = {
				friendly_snippets = true,
			},
			dependencies = { "rafamadriz/friendly-snippets" },
		},
	},
	-- Not all LSP servers add brackets when completing a function.
	-- To better deal with this, LazyVim adds a custom option to cmp,
	-- that you can configure. For example:
	--
	-- ```lua
	-- opts = {
	--   auto_brackets = { "python" }
	-- }
	-- ```
	opts = function(_, opts)
		opts.snippet = {
			expand = function(item)
				return LazyVim.cmp.expand(item.body)
			end,
		}
		table.insert(opts.sources, { name = "snippets" })
	end,
}
