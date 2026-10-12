-- nvim-mcp — exposes this Neovim instance to MCP clients (Claude Code,
-- opencode) over an RPC socket. The `nvim-mcp` binary comes from the crate's
-- own cargo build; clients find the socket by globbing for
-- `nvim-mcp.<escaped-project-root>.<pid>.sock`.
--
-- The plugin's default socket dir is $TMPDIR, which on macOS is a ~49-char
-- `/var/folders/...` path. Unix sockets cap out at 104 bytes, so anything but a
-- shallow project root overflows and `serverstart()` fails with "Failed to
-- start server: invalid argument". We compute the path ourselves and fall back
-- to /tmp (which nvim-mcp's Rust side always searches too) when the default
-- would be too long, then tighten the socket to owner-only since /tmp is shared.
local SUN_PATH_MAX = 104

local function escape_path(path)
	return (path:gsub("^%s+", ""):gsub("%s+$", ""):gsub("/", "%%"))
end

local function project_root()
	local root = vim.fs.root(0, ".git")
	return root or vim.fn.getcwd()
end

local function socket_dirs()
	local dirs = {}
	local xdg = os.getenv("XDG_RUNTIME_DIR")
	local tmpdir = os.getenv("TMPDIR")
	if xdg and xdg ~= "" then
		table.insert(dirs, xdg)
	elseif tmpdir and tmpdir ~= "" then
		table.insert(dirs, tmpdir)
	end
	table.insert(dirs, "/tmp")
	return dirs
end

local function pipe_path()
	local name = string.format("nvim-mcp.%s.%d.sock", escape_path(project_root()), vim.fn.getpid())
	local last
	for _, dir in ipairs(socket_dirs()) do
		last = dir:gsub("/+$", "") .. "/" .. name
		if #last <= SUN_PATH_MAX then
			return last
		end
	end
	vim.notify(
		("nvim-mcp: socket path is %d bytes, over the %d-byte limit; RPC server will not start"):format(
			#last,
			SUN_PATH_MAX
		),
		vim.log.levels.WARN
	)
	return last
end

return {
	"linw1995/nvim-mcp",
	lazy = false,
	-- Lua half only. The `nvim-mcp` server binary comes from the flake input of
	-- the same name (see modules/nvim.nix), not from the crate's
	-- `cargo install --path .`: that build fails to link here, since aws-lc-sys
	-- cannot find libiconv under the Nix-provided toolchain.
	build = false,
	config = function()
		local pipe = pipe_path()
		require("nvim-mcp").setup({ pipe = pipe })
		-- /tmp is world-writable and the socket is an unrestricted RPC channel
		-- into this editor, so keep it owner-only.
		vim.uv.fs_chmod(pipe, tonumber("600", 8))
	end,
}
