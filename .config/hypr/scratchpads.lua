require 'utils'

local scratchpads = {
  claude = {
    name = 'claude',
    class = 'claude',
    key = 'slash',
    launch = 'firefox --new-instance --profile "$HOME/.local/share/claude-firefox" --name claude https://claude.ai',
    width = 520,
  },
}

local launchTimeout = 15000
local launching = {}

local function WindowSelector(w) return 'address:' .. w.address end

local function Place(scratchpad, w)
  local monitor = hl.get_active_monitor()
  local gaps = hl.get_config 'general.gaps_out'
  local reserved = monitor.reserved
  local logicalWidth, logicalHeight = GetMonitorLogicalSize(monitor)
  local height = math.floor(
    logicalHeight - reserved.top - reserved.bottom - gaps.top - gaps.bottom
  )
  local x = math.floor(
    monitor.x + logicalWidth - reserved.right - gaps.right - scratchpad.width
  )
  local y = math.floor(monitor.y + reserved.top + gaps.top)
  hl.dispatch(
    hl.dsp.window.resize {
      x = scratchpad.width,
      y = height,
      window = WindowSelector(w),
    }
  )
  hl.dispatch(hl.dsp.window.move { x = x, y = y, window = WindowSelector(w) })
end

local function SetPinned(w, pinned)
  hl.dispatch(
    hl.dsp.window.pin {
      action = pinned and 'enable' or 'disable',
      window = WindowSelector(w),
    }
  )
end

local function Show(scratchpad, w)
  SetPinned(w, false)
  hl.dispatch(
    hl.dsp.window.move {
      workspace = tostring(hl.get_active_workspace().id),
      window = WindowSelector(w),
      follow = false,
    }
  )
  Place(scratchpad, w)
  SetPinned(w, true)
  hl.dispatch(hl.dsp.focus { window = WindowSelector(w) })
end

local function Launch(scratchpad)
  if launching[scratchpad.name] then return end
  launching[scratchpad.name] = true
  hl.timer(
    function() launching[scratchpad.name] = false end,
    { timeout = launchTimeout, type = 'oneshot' }
  )
  hl.dispatch(hl.dsp.exec_cmd(scratchpad.launch))
end

local function ToggleScratchpad(scratchpad)
  local w = nil
  for _, candidate in ipairs(hl.get_windows()) do
    if candidate.class == scratchpad.class then
      w = candidate
      break
    end
  end
  if w == nil then
    Launch(scratchpad)
  elseif
    w.workspace == nil
    or w.workspace.name:find '^special:' ~= nil
    or not w.pinned
    or w.monitor == nil
    or w.monitor.id ~= hl.get_active_monitor().id
  then
    Show(scratchpad, w)
  else
    SetPinned(w, false)
    hl.dispatch(
      hl.dsp.window.move {
        workspace = 'special:' .. scratchpad.name,
        window = WindowSelector(w),
        follow = false,
      }
    )
  end
end

local function Setup(mod)
  for _, scratchpad in pairs(scratchpads) do
    hl.window_rule {
      name = 'scratchpad-' .. scratchpad.name,
      match = { class = '^' .. scratchpad.class .. '$' },
      float = true,
      size = { scratchpad.width, 'monitor_h*0.85' },
    }
    hl.bind(
      mod .. ' + ' .. scratchpad.key,
      function() ToggleScratchpad(scratchpad) end
    )
  end

  hl.on('window.open', function(w)
    for _, scratchpad in pairs(scratchpads) do
      if w.class == scratchpad.class and launching[scratchpad.name] then
        launching[scratchpad.name] = false
        Place(scratchpad, w)
        SetPinned(w, true)
        break
      end
    end
  end)
end

return {
  scratchpads = scratchpads,
  ToggleScratchpad = ToggleScratchpad,
  Setup = Setup,
}
