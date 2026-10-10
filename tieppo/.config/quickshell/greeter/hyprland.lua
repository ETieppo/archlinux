hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
  },
  animations = { enabled = false },
  input = { kb_layout = "us" },
})

hl.on("hyprland.start", function()
  hl.exec_cmd("env XDG_CACHE_HOME=/tmp/qs-greeter XDG_STATE_HOME=/tmp/qs-greeter XDG_DATA_HOME=/tmp/qs-greeter qs -p /etc/greetd/quickshell; hyprctl dispatch 'hl.dsp.exit()'")
end)
