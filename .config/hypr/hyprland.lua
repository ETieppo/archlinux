pcall(require, "gpu")
require("keymaps")
require("scratchpads").Setup("ALT")
require("utils")

hl.env("GTK_USE_PORTAL", "1")

hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto", scale = 1 })
hl.monitor({ output = "DP-1", mode = "prefered", position = "auto-left", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "prefered", position = "auto-left", scale = 1 })

hl.on("hyprland.start", function()
	hl.exec_cmd("qs kill; qs -d")
	hl.exec_cmd("sleep 1 && darkman set dark")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("pkill -x gammastep; gammastep")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("fm1d --fm=vifm-term")
end)

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

hl.window_rule({
	name = "youtube-pip",
	match = { class = "glide-glide", title = "Picture-in-Picture" },
	float = true,
	pin = true,
	no_focus = true,
	size = { 640, 360 },
	min_size = { 640, 360 },
	max_size = { 640, 360 },
	move = { "monitor_w-window_w-10", "40" },
})

hl.config({
	dwindle = { preserve_split = true },
	master = { new_status = "master" },
	general = {
		gaps_in = 2,
		gaps_out = 6,
		border_size = 1,
		col = {
			active_border = { colors = { "rgba(33ccffee)", 0x33CC, "rgba(33ccffee)" }, angle = 45 },
			inactive_border = { colors = { "#EAFBFF66", 0x33CC, "#EAFBFF66" }, angle = 45 },
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 45,
		rounding_power = 1,
		active_opacity = 1,
		inactive_opacity = 1,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "#00000000",
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
		allow_session_lock_restore = true,
	},

	input = {
		kb_layout = "us,ru",
		kb_variant = ",phonetic",
		kb_model = "",
		follow_mouse = 1,
		sensitivity = 0,
		repeat_delay = 300,
		repeat_rate = 35,

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

hl.layer_rule({
	name = "quickshell-region-no-anim",
	match = { namespace = "^quickshell-region$" },
	no_anim = true,
})
