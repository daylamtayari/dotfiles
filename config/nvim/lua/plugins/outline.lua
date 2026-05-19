return {
	"hedyhli/outline.nvim",
	config = function()
		require("outline").setup({
			providers = {
				priority = { "lsp", "coc", "markdown", "norg" },
				lsp = {
					blacklist_clients = {},
				},
				markdown = {
					filetypes = { "markdown" },
				},
			},
		})
	end,
}
