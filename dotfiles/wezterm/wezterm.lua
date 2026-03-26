local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("appearance")(config)
require("keybindings")(config)
require("workspaces")(config)

return config
