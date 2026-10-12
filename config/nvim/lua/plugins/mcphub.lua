-- mcphub.nvim — MCP client/hub for Neovim; feeds MCP tools into CodeCompanion.
--
-- MCP servers are declared in ~/.config/mcphub/servers.json (managed
-- declaratively via modules/mcphub.nix). The `mcp-hub` node binary is bundled
-- alongside the plugin (build = "bundled_build.lua" + use_bundled_binary), which
-- avoids relying on a writable global npm prefix on this Nix-managed system.
return {
	"ravitemer/mcphub.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	build = "bundled_build.lua",
	config = function()
		require("mcphub").setup({
			use_bundled_binary = true,
		})
	end,
}
