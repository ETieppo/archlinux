pcall(require, "gpu")

local terminal = "env GTK_IM_MODULE=simple ghostty"
-- local fileManager = "thunar"
-- local menu = "ags run ~/.config/ags/widget/app.tsx"
local menu = "qs ipc call launcher toggle"
local mainMod = "ALT"

-- hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprpicker"))
hl.bind("switch:on:Lid Switch", function()
  hl.timer(function()
    hl.dispatch(hl.dsp.dpms({ action = "disable" }))
  end, { timeout = 500, type = "oneshot" })
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
  hl.timer(function()
    hl.dispatch(hl.dsp.dpms({ action = "enable" }))
  end, { timeout = 500, type = "oneshot" })
end, { locked = true })
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto-left", scale = 1 })

hl.on("hyprland.start", function()
  hl.exec_cmd("qs kill; qs -d")
  hl.exec_cmd("sleep 1 && darkman set dark")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("pkill -x gammastep; gammastep")
  hl.exec_cmd("hyprpaper")
end)

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

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
    rounding = 10,
    rounding_power = 12,
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

hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs ipc call claude toggle"))
hl.bind("Escape", function()
  local w = hl.get_active_window()
  if w ~= nil and w.class == "chrome-claude.ai__-Default" then
    hl.dispatch(hl.dsp.exec_cmd("qs ipc call claude close"))
  end
end, { non_consuming = true })
hl.window_rule({
  match = { class = "chrome-claude.ai__-Default" },
  float = true,
  workspace = "special:claude",
  size = "520 938",
  move = "1940 86",
})

hl.window_rule({
  match = { class = "thunar" },
  float = true,
  size = { 900, 500 },
})

function SendShortcut(params)
  local timer = function()
    local args = params
    args.state = "up"
    hl.dispatch(hl.dsp.send_key_state(args))
  end
  return function()
    local args = params
    args.state = "down"
    hl.dispatch(hl.dsp.send_key_state(args))
    hl.timer(timer, { timeout = 20, type = "oneshot" })
  end
end

local function IsBrowser(w)
  return w ~= nil and (w.class == "glide-glide" or w.class:find("^chrome%-") ~= nil)
end

local function TypeText(text)
  return hl.dsp.exec_cmd("wtype '" .. text .. "'")
end

local deadKeys = {
  { trigger = "E",     name = "acute",      symbol = "´", letters = { a = { "á", "Á" }, e = { "é", "É" }, i = { "í", "Í" }, o = { "ó", "Ó" }, u = { "ú", "Ú" } } },
  { trigger = "grave", name = "grave",      symbol = "`", letters = { a = { "à", "À" }, e = { "è", "È" }, i = { "ì", "Ì" }, o = { "ò", "Ò" }, u = { "ù", "Ù" } } },
  { trigger = "I",     name = "circumflex", symbol = "^", letters = { a = { "â", "Â" }, e = { "ê", "Ê" }, i = { "î", "Î" }, o = { "ô", "Ô" }, u = { "û", "Û" } } },
  { trigger = "N",     name = "tilde",      symbol = "~", letters = { a = { "ã", "Ã" }, o = { "õ", "Õ" }, n = { "ñ", "Ñ" } } },
  { trigger = "U",     name = "diaeresis",  symbol = "¨", letters = { a = { "ä", "Ä" }, e = { "ë", "Ë" }, i = { "ï", "Ï" }, o = { "ö", "Ö" }, u = { "ü", "Ü" } } },
  { trigger = "C",     name = "seila",      symbol = "¨", letters = { a = { "ä", "Ä" }, e = { "ë", "Ë" }, i = { "ï", "Ï" }, o = { "ö", "Ö" }, u = { "ü", "Ü" } } },
  { trigger = "C",     name = "cedilla",    symbol = "¸", letters = { c = { "ç", "Ç" } } },
}

local function TypeAndReset(text)
  return function()
    hl.dispatch(TypeText(text))
    hl.dispatch(hl.dsp.submap("reset"))
  end
end

for _, dead in ipairs(deadKeys) do
  hl.define_submap(dead.name, function()
    for letter, chars in pairs(dead.letters) do
      hl.bind(letter, TypeAndReset(chars[1]))
      hl.bind("SHIFT + " .. letter, TypeAndReset(chars[2]))
    end
    hl.bind("SPACE", TypeAndReset(dead.symbol))
    hl.bind("Shift_L", hl.dsp.no_op(), { ignore_mods = true, non_consuming = true })
    hl.bind("Shift_R", hl.dsp.no_op(), { ignore_mods = true, non_consuming = true })
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind("catchall", hl.dsp.submap("reset"))
  end)
  hl.bind("SUPER + " .. dead.trigger, hl.dsp.submap(dead.name))
end

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + A", SendShortcut({ mods = "CTRL", key = "A", window = "activewindow" }))
hl.bind(mainMod .. " + R", SendShortcut({ mods = "CTRL", key = "R", window = "activewindow" }))
hl.bind(mainMod .. " + L", function()
  local w = hl.get_active_window()
  if IsBrowser(w) then
    hl.dispatch(SendShortcut({ mods = "CTRL", key = "L", window = "activewindow" }))
  else
    hl.dispatch(SendShortcut({ mods = "ALT", key = "L", window = "activewindow" }))
  end
end)
hl.bind(mainMod .. " + C", function()
  local w = hl.get_active_window()
  if IsBrowser(w) then
    hl.dispatch(SendShortcut({ mods = "CTRL", key = "C", window = "activewindow" }))
  else
    hl.dispatch(SendShortcut({ mods = "CTRL SHIFT", key = "C", window = "activewindow" }))
  end
end)
hl.bind(mainMod .. " + V", SendShortcut({ mods = "CTRL SHIFT", key = "V", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + I", SendShortcut({ mods = "CTRL SHIFT", key = "code:31", window = "activewindow" }))
hl.bind(mainMod .. " + F", SendShortcut({ mods = "CTRL", key = "F", window = "activewindow" }))
hl.bind(mainMod .. " + X", SendShortcut({ mods = "CTRL", key = "X", window = "activewindow" }))
hl.bind(mainMod .. " + Z", SendShortcut({ mods = "CTRL", key = "Z", window = "activewindow" }))
hl.bind(mainMod .. " + W", SendShortcut({ mods = "CTRL", key = "W", window = "activewindow" }))
hl.bind(mainMod .. " + N", function()
  local w = hl.get_active_window()
  if w ~= nil and w.class == "com.mitchellh.ghostty" then
    hl.dispatch(SendShortcut({ mods = "ALT", key = "N", window = "activewindow" }))
  else
    hl.dispatch(SendShortcut({ mods = "CTRL", key = "N", window = "activewindow" }))
  end
end)
hl.bind(mainMod .. " + right", SendShortcut({ mods = "", key = "End", window = "activewindow" }))
hl.bind(mainMod .. " + left", SendShortcut({ mods = "", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + right", SendShortcut({ mods = "SHIFT", key = "End", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + left", SendShortcut({ mods = "SHIFT", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + up", SendShortcut({ mods = "CTRL", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + down", SendShortcut({ mods = "CTRL", key = "End", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + up", SendShortcut({ mods = "CTRL SHIFT", key = "Home", window = "activewindow" }))
hl.bind(mainMod .. " + SHIFT + down", SendShortcut({ mods = "CTRL SHIFT", key = "End", window = "activewindow" }))
hl.bind("CTRL + Backspace", SendShortcut({ mods = "", key = "Delete", window = "activewindow" }), { repeating = true })
hl.bind("SUPER + up", SendShortcut({ mods = "ALT", key = "Up", window = "activewindow" }))
hl.bind("SUPER + down", SendShortcut({ mods = "ALT", key = "Down", window = "activewindow" }))

for i = 1, 9 do
  hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
  hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
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
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && qs ipc call sys brightness"),
  { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && qs ipc call sys brightness"),
  { repeating = true, locked = true })
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("qs ipc call kbd up"), { repeating = true, locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("qs ipc call kbd down"), { repeating = true, locked = true })
hl.bind("Print", hl.dsp.exec_cmd("grim"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("qs ipc call screenshot region"))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.exec_cmd("qs ipc call screenshot full"))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.exec_cmd("qs ipc call screenshot region"))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.exec_cmd("qs ipc call screenshot region"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call launcher clipboard"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("qs ipc call lock lock"))
hl.bind("SUPER + ALT + F6", hl.dsp.exec_cmd("qs ipc call power cycle"))
hl.layer_rule({
  name = "quickshell-region-no-anim",
  match = { namespace = "^quickshell-region$" },
  no_anim = true,
})
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("F1", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("F2", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("F3", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("KP_Left", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("KP_Begin", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("KP_Right", hl.dsp.exec_cmd("playerctl next"), { locked = true })
-- hl.bind(mainMod .. " + M", hl.dsp.exit())
