return {
	{
		"nvim-telescope/telescope.nvim",
		lazy = false,
		opts = function()
			local conf = require(".configs.telescope")

			conf.defaults.mappings.i = {
				["<C-j>"] = require("telescope.actions").move_selection_next,
				["<Esc>"] = require("telescope.actions").close,
			}

			-- or
			-- table.insert(conf.defaults.mappings.i, your table)

			return conf
		end,
	},
}
