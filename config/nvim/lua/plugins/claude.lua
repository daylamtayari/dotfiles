return {
	"greggh/claude-code.nvim",
	lazy = false, -- Load immediately on startup
	dependencies = {
		"nvim-lua/plenary.nvim", -- Required for git operations
	},
	config = function()
		require("claude-code").setup()
	end,
}
