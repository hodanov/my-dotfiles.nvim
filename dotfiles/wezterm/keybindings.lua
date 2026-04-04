local wezterm = require("wezterm")
local act = wezterm.action

if wezterm.GLOBAL.workspace_selector_mode == nil then
	wezterm.GLOBAL.workspace_selector_mode = "fuzzy"
end

local function prompt_new_workspace()
	return act.PromptInputLine({
		description = wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { AnsiColor = "Fuchsia" } },
			{ Text = "Enter name for new workspace" },
		}),
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
			end
		end),
	})
end

local function build_workspace_choices(current)
	local choices = {}
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		table.insert(choices, {
			id = name,
			label = "Switch to workspace: `" .. name .. "`",
		})
	end
	table.insert(choices, {
		id = "__new__",
		label = "Create new Workspace (current is `" .. current .. "`)",
	})
	return choices
end

local function select_workspace()
	return wezterm.action_callback(function(window, pane)
		local choices = build_workspace_choices(window:active_workspace())

		window:perform_action(
			act.InputSelector({
				title = "Select Workspace",
				fuzzy = true,
				fuzzy_description = "Workspace > ",
				choices = choices,
				action = wezterm.action_callback(function(w, p, id)
					if not id then
						return
					end
					if id == "__new__" then
						w:perform_action(prompt_new_workspace(), p)
					else
						w:perform_action(act.SwitchToWorkspace({ name = id }), p)
					end
				end),
			}),
			pane
		)
	end)
end

local function toggle_workspace_selector_mode()
	return wezterm.action_callback(function(window, _)
		local current = wezterm.GLOBAL.workspace_selector_mode
		local next = current == "fuzzy" and "launcher" or "fuzzy"
		wezterm.GLOBAL.workspace_selector_mode = next
		window:toast_notification("WezTerm", "Workspace selector: " .. next, nil, 2000)
	end)
end

local function dispatch_workspace_selector()
	return wezterm.action_callback(function(window, pane)
		local mode = wezterm.GLOBAL.workspace_selector_mode
		if mode == "fuzzy" then
			window:perform_action(select_workspace(), pane)
		else
			window:perform_action(act.ShowLauncherArgs({ flags = "WORKSPACES" }), pane)
		end
	end)
end

return function(config)
	-- Ctrl + [j/k/l/;]の文字変換を有効
	-- https://github.com/wezterm/wezterm/blob/abc92e56e0565b6221935762ee0856318dbc7a34/docs/config/lua/config/macos_forward_to_ime_modifier_mask.md?plain=1#L5
	config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

	config.keys = {
		-- Ctrl+[をEscapeとして送信（IME転送をバイパス）
		{ key = "[", mods = "CTRL", action = act.SendKey({ key = "Escape" }) },

		-- Shift+Enterで改行を送信
		{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

		-- Command + f（検索）を無効化
		{ key = "f", mods = "CMD", action = act.DisableDefaultAssignment },

		-- Workspaces
		{ key = "s", mods = "CMD", action = dispatch_workspace_selector() },
		{ key = "S", mods = "CMD|SHIFT", action = toggle_workspace_selector_mode() },
		{ key = "W", mods = "CTRL|SHIFT", action = prompt_new_workspace() },
		{ key = "n", mods = "CMD", action = act.SwitchWorkspaceRelative(1) },
	}
end
