return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "p",
						desc = "Projects",
						action = ":lua Snacks.dashboard.pick('projects')",
					},
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{
						icon = " ",
						key = "u",
						desc = "Update Plugins",
						action = ":Lazy update",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
                                                               .____   __ _
  __o__   _______ _ _  _                                     /     /
  \    ~\                                                  /      /
    \     '\                                         ..../      .'
     . ' ' . ~\                                      ' /       /
    .  _    .  ~ \  .+~\~ ~ ' ' " " ' ' ~ - - - - - -''_      /
   .  <#  .  - - -/' . ' \  __                          '~ - \
    .. -           ~-.._ / |__|  ( )  ( )  ( )  0  o    _ _    ~ .
  .-'                                               .- ~    '-.    -.
 <                      . ~ ' ' .             . - ~             ~ -.__~_. _ _
   ~- .               .          . . . . ,- ~
         ' ~ - - - - =.   <#>    .         \.._
                     .     ~      ____ _ .. ..  .- .
                      .         '        ~ -.        ~ -.
                        ' . . '               ~ - .       ~-.
                                                    ~ - .      ~ .
                                                           ~ -...0..~. ____]],
			},
			sections = {
				{ section = "header", hl = "SnacksDashboardNormal" },
				{ section = "keys", gap = 1, padding = 1 },
			},
		},
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		picker = { enabled = true, help = false, matcher = { frecency = true } },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},
}
