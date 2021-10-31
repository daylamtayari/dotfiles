local dashboard = require"alpha.themes.dashboard"
math.randomseed(os.time())

local function pick_color()
  local colors = {"String", "Identifier", "Keyword", "Number"}
  return colors[math.random(#colors)]
end

dashboard.section.header.val = {
  [[    __               __                   _         ]],
  [[   / /_  _________  / /_____  ____ _   __(_)___ ___ ]],
  [[  / __ \/ ___/ __ \/ //_/ _ \/ __ \ | / / / __ `__ \]],
  [[ / /_/ / /  / /_/ / ,< /  __/ / / / |/ / / / / / / /]],
  [[/_.___/_/   \____/_/|_|\___/_/ /_/|___/_/_/ /_/ /_/]]
}


dashboard.section.header.opts.hl = pick_color()
-- Set menu
dashboard.section.buttons.val = {
  dashboard.button( "e", "  > New file" , ":ene | startinsert <CR>"),
  dashboard.button( "f", "  > Find file", ":Files<CR>"),
  dashboard.button( "r", "  > Recent",    ":Telescope oldfiles<CR>"),
  dashboard.button( "c", "  > Chezmoi",   ":cd $HOME/.local/share/chezmoi | Files<CR>"),
  dashboard.button( "s", "  > Settings" , ":cd $HOME/.config/nvim/ | Files<CR>"),
  dashboard.button( "p", "  > Projects" , ":Telescope projects<CR>"),
  dashboard.button( "q", "  > Quit",      ":qa<CR>"),
}

--require("alpha").setup(dashboard.opts)

require'alpha'.setup(require'alpha.themes.dashboard'.opts)
