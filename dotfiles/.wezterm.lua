local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ---------------
-- カラースキーマの設定
-- ---------------
config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Builtin Dark"

-- ---------------
-- タブバーの表示無効
-- ---------------
config.enable_tab_bar = true
config.window_decorations = "RESIZE"
-- config.hide_tab_bar_if_only_one_tab = true
-- config.use_fancy_tab_bar = true
config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

config.colors = {
	tab_bar = {
		background = "#1e1e2e",

		active_tab = {
			bg_color = "#cba6f7",
			fg_color = "#1e1e2e",
			intensity = "Bold",
		},

		inactive_tab = {
			bg_color = "#313244",
			fg_color = "#cdd6f4",
		},

		inactive_tab_hover = {
			bg_color = "#45475a",
			fg_color = "#ffffff",
			italic = true,
		},

		new_tab = {
			bg_color = "#1e1e2e",
			fg_color = "#a6adc8",
		},
	},
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.active_pane.title

	-- ディレクトリ名だけにする
	title = title:gsub(".*[/\\]", "")

	-- アイコンつける（nerd font前提）
	local icon = " "

	if tab.is_active then
		return {
			{ Text = " " .. icon .. title .. " " },
		}
	else
		return {
			{ Foreground = { Color = "#6c7086" } },
			{ Text = " " .. icon .. title .. " " },
		}
	end
end)

-- ---------------
-- フォントの設定
-- ---------------
config.font = wezterm.font_with_fallback({
	-- { family = "Source Han Code JP" },
	-- { family = "Maple Mono NF CN" },
	{ family = "Meslo LG L DZ for Powerline" },
	{ family = "Hiragino Maru Gothic ProN W4" },
})

-- ---------------
-- 背景画像の設定
-- ---------------
config.background = {
	{
		source = {
			Gradient = {
				colors = { "#11111b", "#11111b" }, -- グラデーションのカラーセット
				orientation = {
					Linear = { angle = -30.0 }, -- グラデーションの方向と角度
				},
			},
		},
		opacity = 1, -- 透明度
		horizontal_align = "Right", -- 水平方向の画像位置
		width = "100%", -- 画像の幅 (%指定も可能)
		height = "100%", -- 高さ
	},
	-- { -- テンプレート
	-- 	source = {
	-- 		File = "",
	-- 	},
	-- 	opacity = 1, -- 透明度
	-- 	vertical_align = "Bottom", -- 垂直方向の画像位置
	-- 	horizontal_align = "Right", -- 水平方向の画像位置
	-- 	vertical_offset = "80", -- 垂直方向のオフセット
	-- 	horizontal_offset = "200", -- 水平方向のオフセット
	-- 	repeat_x = "NoRepeat", -- 画像をx方向に繰り返すか
	-- 	repeat_y = "NoRepeat", -- 画像をy方向に繰り返すか
	-- 	width = "1072", -- 画像の幅 (%指定も可能)
	-- 	height = "1800", -- 画像の高さ (%指定も可能)
	-- },
	-- { -- 星街すいせい
	-- 	source = {
	-- 		File = os.getenv("HOME") .. "/Pictures/D13E-jOsUrL.png",
	-- 	},
	-- 	opacity = 0.37,
	-- 	vertical_align = "Bottom",
	-- 	horizontal_align = "Right",
	-- 	repeat_x = "NoRepeat",
	-- 	repeat_y = "NoRepeat",
	-- 	width = "1066",
	-- 	height = "1790",
	-- },
	-- { -- 聖王
	-- 	source = {
	-- 		File = os.getenv("HOME") .. "/Pictures/romancing_saga_rs_seiou.PNG",
	-- 	},
	-- 	opacity = 0.41,
	-- 	vertical_align = "Bottom",
	-- 	horizontal_align = "Right",
	-- 	repeat_x = "NoRepeat",
	-- 	repeat_y = "NoRepeat",
	-- 	width = "1247",
	-- 	height = "1795",
	-- },
	{ -- アルカイザー
		source = {
			File = os.getenv("HOME") .. "/Pictures/romancing_saga_rs_alkaizer.PNG",
		},
		opacity = 0.23,
		vertical_align = "Bottom",
		horizontal_align = "Right",
		repeat_x = "NoRepeat",
		repeat_y = "NoRepeat",
		width = "1247",
		height = "1795",
	},
}

-- ---------------
-- Ctrl + [j/k/l/;]の文字変換を有効
-- https://github.com/wezterm/wezterm/blob/abc92e56e0565b6221935762ee0856318dbc7a34/docs/config/lua/config/macos_forward_to_ime_modifier_mask.md?plain=1#L5
-- ---------------
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

-- ---------------
-- キーバインド
-- ---------------
local act = wezterm.action
wezterm.on("update-right-status", function(window, pane)
	window:set_right_status(window:active_workspace())
end)

config.keys = {
	-- Shift+Enterで改行を送信
	{ key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

	-- Command + n（新しいウィンドウ）を無効化
	-- { key = "n", mods = "CMD", action = wezterm.action.DisableDefaultAssignment },

	-- Command + f（検索）を無効化
	{ key = "f", mods = "CMD", action = wezterm.action.DisableDefaultAssignment },

	-- ---------------
	-- Workspaces / Sessions
	-- https://wezterm.org/recipes/workspaces.html
	-- ---------------
	-- Show the launcher in fuzzy selection mode and have it list all workspaces and allow activating one.
	{ key = "s", mods = "CMD", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
	-- Prompt for a name to use for a new workspace and switch to it.
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
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
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

-- ---------------
-- プロジェクト用レイアウトの自動生成
-- ---------------
local mux = wezterm.mux

-- 既に同名workspaceが存在するかチェック
local function workspace_exists(name)
	local windows = mux.all_windows()
	for _, win in ipairs(windows) do
		if win:get_workspace() == name then
			return true
		end
	end
	return false
end

-- $HOMEを使って可搬性アップ
local HOME = os.getenv("HOME")

local function setup_blog()
	local name = "blog"
	if workspace_exists(name) then
		return
	end

	-- tab1: nvim 用
	local t, p, w = mux.spawn_window({
		workspace = name,
		cwd = HOME .. "/workspace/hodalog-hugo",
		-- args = { "zsh", "-lc", "docker container exec -it nvim-dev bash --login" },
		args = { "zsh", "-lc", "$SHELL" },
	})
	t:set_title("nvim")

	-- tab2: ai cli 作業用（必要ならコマンドを好みに調整してね）
	local t2 = w:spawn_tab({
		cwd = HOME .. "/workspace/hodalog-hugo",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t2:set_title("ai-cli")

	-- tab3: git / docker / その他操作用
	local t3 = w:spawn_tab({
		cwd = HOME .. "/workspace/hodalog-hugo",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t3:set_title("ops")
end

local function setup_stable_diffusion()
	local name = "stable-diffusion"
	if workspace_exists(name) then
		return
	end

	-- tab1: 上= nvim / 下= Ops でその他操作
	local t, p, w = mux.spawn_window({
		workspace = name,
		cwd = HOME .. "/workspace/stable_diffusion_modal",
		-- args = { "zsh", "-lc", "docker container exec -it nvim-dev bash --login" },
		args = { "zsh", "-lc", "$SHELL" },
	})
	t:set_title("nvim+ops")

	-- 下ペインにシェル
	p:split({
		direction = "Bottom",
		size = 0.20,
		args = { "zsh", "-lc", "$SHELL" },
	})
end

local function setup_my_pde()
	local name = "my-pde"
	if workspace_exists(name) then
		return
	end

	-- tab1: nvim 用
	local t, p, w = mux.spawn_window({
		workspace = name,
		cwd = HOME .. "/workspace/my-pde",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t:set_title("nvim")

	-- tab2: ai cli 作業用（必要ならコマンドを好みに調整してね）
	local t2 = w:spawn_tab({
		cwd = HOME .. "/workspace/my-pde",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t2:set_title("ai-cli")

	-- tab3: git / docker / その他操作用
	local t3 = w:spawn_tab({
		cwd = HOME .. "/workspace/my-pde",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t3:set_title("ops")
end

local function setup_new_project()
	local name = "new-project"
	if workspace_exists(name) then
		return
	end

	-- tab1: nvim 用
	local t, p, w = mux.spawn_window({
		workspace = name,
		cwd = HOME .. "/workspace/new-project",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t:set_title("nvim")

	-- tab2: ai cli 作業用（必要ならコマンドを好みに調整してね）
	local t2 = w:spawn_tab({
		cwd = HOME .. "/workspace/new-project",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t2:set_title("ai-cli")

	-- tab3: git / docker / その他操作用
	local t3 = w:spawn_tab({
		cwd = HOME .. "/workspace/new-project",
		args = { "zsh", "-lc", "$SHELL" },
	})
	t3:set_title("ops")
end

wezterm.on("gui-startup", function()
	-- 既存ウィンドウがあっても、同名WSがなければ作成する
	setup_blog()
	setup_stable_diffusion()
	setup_my_pde()
	setup_new_project()
	mux.set_active_workspace("blog")
end)

-- CMD+SHIFT+R で layout を追加生成（既にあればスキップ）
wezterm.on("setup-project-layouts", function()
	setup_blog()
	setup_stable_diffusion()
	setup_my_pde()
	setup_new_project()
end)
table.insert(config.keys, {
	key = "R",
	mods = "CMD|SHIFT",
	action = wezterm.action.EmitEvent("setup-project-layouts"),
})

return config
