return {
	"folke/noice.nvim",
	opts = {
		lsp = {
			signature = {
				enabled = true,
				auto_open = {
					enabled = true,
					trigger = false, -- Auto-show on LSP trigger characters like ( and ,
					luasnip = true,
					throttle = 50,
				},
				view = nil, -- Use default view
				opts = {},
			},
		},
	},
}
