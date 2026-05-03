local terminal = "kitty"
local fileManager = "thunar"
local menu = "rofi -show drun -theme ~/.config/rofi/menu.rasi"
local mainMod = "ALT"

hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto-left", scale = 1 })

hl.on("hyprland.start", function()
	hl.exec_cmd("swaync")
	hl.exec_cmd("waybar")
	hl.exec_cmd("sleep 1 && darkman set dark")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("gammastep")
  hl.exec_cmd("mpvpaper -o 'no-audio loop hwdec=auto vo=dmabuf-wayland' '*' '~/.local/share/wallpapers/totoro.mp4'")
end)

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

hl.config({
	dwindle = { preserve_split = true },
	master = { new_status = "master" },
	general = {
		gaps_in = 6,
		gaps_out = 6,
		border_size = 1,
		col = {
			active_border = { colors = { "rgba(89b4fa28)" }, angle = 45 },
			inactive_border = "rgba(1a1a1a60)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		rounding_power = 12,
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0x1a1a1aee,
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},

	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		follow_mouse = 1,
		sensitivity = 0,

		touchpad = {
			natural_scroll = true,
		},
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.window_rule({
	match = { class = "thunar" },
	float = true,
	size = { 900, 500 },
})

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("sleep 0.1; wtype -M ctrl a -m ctrl"), { release = true })
hl.bind(mainMod .. " + W", hl.dsp.send_shortcut({ mods = "CTRL", key = "W", window = "activewindow" }))
hl.bind(mainMod .. " + N", hl.dsp.send_shortcut({ mods = "CTRL", key = "N", window = "activewindow" }))
hl.bind(mainMod .. " + right", hl.dsp.send_shortcut({ mods = "", key = "End", window = "activewindow" }))
hl.bind(mainMod .. " + left", hl.dsp.send_shortcut({ mods = "", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.send_shortcut({ mods = "SHIFT", key = "End", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + up", hl.dsp.send_shortcut({ mods = "CTRL", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + down", hl.dsp.send_shortcut({ mods = "CTRL", key = "End", window = "activewindow" }))
hl.bind(
	mainMod .. " + SHIFT + up",
	hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "Home", window = "activewindow" })
)
hl.bind(
	mainMod .. " + SHIFT + down",
	hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "End", window = "activewindow" })
)

hl.bind(mainMod .. " + C", function()
	os.execute("wl-paste --primary | wl-copy &")
	hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("sleep 0.1; wtype -M ctrl f -m ctrl"), { release = true })
end)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("sleep 0.1; wtype -M ctrl r -m ctrl"), { release = true })
hl.bind(mainMod .. " + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "INSERT", window = "activewindow" }))
hl.bind("CTRL + Backspace", hl.dsp.send_shortcut({ mods = "", key = "Delete", window = "activewindow" }))
hl.bind("SUPER + up", hl.dsp.send_shortcut({ mods = "ALT", key = "Up", window = "activewindow" }))
hl.bind("SUPER + down", hl.dsp.send_shortcut({ mods = "ALT", key = "Down", window = "activewindow" }))

for i = 1, 9 do
	hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
	hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprpicker"))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, locked = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 1%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 1%-"), { repeating = true, locked = true })
hl.bind("Print", hl.dsp.exec_cmd("grim"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind(mainMod .. " + M", hl.dsp.exit())

