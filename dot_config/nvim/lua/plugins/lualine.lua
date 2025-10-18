return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			icons_enabled = true,
			theme = "auto",
			component_separators = "",
			section_separators = { left = "", right = "" },
			disabled_filetypes = {
				statusline = {},
				winbar = {},
			},
			ignore_focus = {},
			always_divide_middle = true,
			always_show_tabline = true,
			globalstatus = true,
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = {
				"branch",
				{ "diff", colored = true, symbols = { added = " ", modified = " ", removed = " " } },
			},
			lualine_c = {
				{ "filetype", icon_only = true },
				"filename",
				{
					"diagnostics",
					sources = { "nvim_lsp" },
					symbols = {
						error = " ",
						warn = " ",
						info = " ",
						hint = " ",
					},
					always_visible = false,
				},
			},
			lualine_x = { "encoding", "fileformat" },
			lualine_y = { "progress", "location" },
			lualine_z = { { "datetime", style = "%H:%M" } },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		tabline = {},
		winbar = {},
		inactive_winbar = {},
		extensions = {},
	},
}
