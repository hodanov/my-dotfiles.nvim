local wezterm = require("wezterm")
local act = wezterm.action

return function(config)
	-- Ctrl + [j/k/l/;]の文字変換を有効
	-- https://github.com/wezterm/wezterm/blob/abc92e56e0565b6221935762ee0856318dbc7a34/docs/config/lua/config/macos_forward_to_ime_modifier_mask.md?plain=1#L5
	config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

	config.keys = {
		-- Shift+Enterで改行を送信
		{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

		-- Command + f（検索）を無効化
		{ key = "f", mods = "CMD", action = act.DisableDefaultAssignment },

		-- Workspaces
		{ key = "s", mods = "CMD", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
		{
			key = "W",
			mods = "CTRL|SHIFT",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Enter name for new workspace" },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:perform_action(
							act.SwitchToWorkspace({
								name = line,
							}),
							pane
						)
					end
				end),
			}),
		},
		{ key = "n", mods = "CMD", action = act.SwitchWorkspaceRelative(1) },
	}
end
