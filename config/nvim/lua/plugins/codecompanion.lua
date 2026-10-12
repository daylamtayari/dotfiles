-- codecompanion.nvim — in-editor AI chat/agent.
--
-- Default adapter is Anthropic; the Codex ACP adapter is also wired up as an
-- alternative (select it per-chat). API keys are pulled at runtime via the
-- 1Password CLI (`cmd:op read ...`, vault "Employee") so no secret lands in git.
--
-- MCP tools/resources/prompts are provided through the mcphub extension (see
-- plugins/mcphub.lua and ~/.config/mcphub/servers.json).
--
-- Codex support requires the `codex-acp` binary on PATH; Anthropic needs no
-- extra binary. Treesitter is a dependency for rendering chat markdown.
return {
	"olimorris/codecompanion.nvim",
	-- lazy.nvim defaults to `lazy = true` (see configs/lazy.lua), so this has to
	-- be explicit to load at startup.
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
	},
	opts = {
		-- `interactions` replaced `strategies` in v19; the old key is a
		-- deprecated alias slated for removal in v20.0.0. `background` drives
		-- chat compaction and the tools judge, and defaults to copilot, which
		-- is not configured here — so it has to be set too.
		interactions = {
			chat = { adapter = "anthropic" },
			inline = { adapter = "anthropic" },
			cmd = { adapter = "anthropic" },
			background = { adapter = "anthropic" },
		},
		adapters = {
			http = {
				anthropic = function()
					return require("codecompanion.adapters").extend("anthropic", {
						env = {
							api_key = "cmd:op read 'op://Employee/Anthropic API Key/password'",
						},
					})
				end,
			},
			acp = {
				codex = function()
					return require("codecompanion.adapters").extend("codex", {
						env = {
							OPENAI_API_KEY = "cmd:op read 'op://Employee/OpenAI API Key/password'",
						},
					})
				end,
			},
		},
		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					make_tools = true,
					show_server_tools_in_chat = true,
					-- Must stay false: mcphub's variables.lua writes to
					-- `interactions.chat.variables`, which codecompanion v19
					-- removed. Enabling it throws `pairs(nil)` on every hub
					-- refresh. Resources are still reachable as slash commands.
					make_vars = false,
					make_slash_commands = true,
				},
			},
		},
	},
}
