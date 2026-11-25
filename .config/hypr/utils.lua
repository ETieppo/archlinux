local browserClassPatterns =
  { '^firefox', '^glide%-glide$', '^claude$', '^chrome%-' }
local terminalClassPatterns = { '^com%.mitchellh%.ghostty$', '^kitty$' }
local edgeTolerance = 4
local directionProps = {
  l = { isHorizontal = true, isForward = false },
  r = { isHorizontal = true, isForward = true },
  u = { isHorizontal = false, isForward = false },
  d = { isHorizontal = false, isForward = true },
}

local function ToRect(x, y, width, height)
  return { left = x, top = y, right = x + width, bottom = y + height }
end

local function GetWindowRect(w)
  return ToRect(w.at.x, w.at.y, w.size.x, w.size.y)
end

function GetMonitorLogicalSize(monitor)
  return monitor.width / monitor.scale, monitor.height / monitor.scale
end

local function GetMonitorRect(monitor)
  local width, height = GetMonitorLogicalSize(monitor)
  return ToRect(monitor.x, monitor.y, width, height)
end

local function GetAxisSides(direction)
  if directionProps[direction].isHorizontal then
    return 'left', 'right', 'top', 'bottom'
  end
  return 'top', 'bottom', 'left', 'right'
end

local function IsBeyond(origin, target, direction)
  local mainStart, mainEnd, crossStart, crossEnd = GetAxisSides(direction)
  local overlapsCrossAxis = target[crossStart] < origin[crossEnd]
    and target[crossEnd] > origin[crossStart]
  if directionProps[direction].isForward then
    return overlapsCrossAxis
      and target[mainStart] >= origin[mainEnd] - edgeTolerance
  end
  return overlapsCrossAxis
    and target[mainEnd] <= origin[mainStart] + edgeTolerance
end

local function TouchesBoundsEdge(rect, bounds, side)
  if side == 'left' or side == 'top' then
    return rect[side] <= bounds[side] + edgeTolerance
  end
  return rect[side] >= bounds[side] - edgeTolerance
end

local function ArrangeTowardEdge(bounds, direction)
  local mainStart, mainEnd, crossStart, crossEnd = GetAxisSides(direction)
  local targetSide = directionProps[direction].isForward and mainEnd
    or mainStart
  hl.dispatch(hl.dsp.layout 'movetoroot')
  local rect = GetWindowRect(hl.get_active_window())
  if
    not (
      TouchesBoundsEdge(rect, bounds, crossStart)
      and TouchesBoundsEdge(rect, bounds, crossEnd)
    )
  then
    hl.dispatch(hl.dsp.layout 'togglesplit')
    rect = GetWindowRect(hl.get_active_window())
  end
  if not TouchesBoundsEdge(rect, bounds, targetSide) then
    hl.dispatch(hl.dsp.layout 'swapsplit')
  end
end

function MoveWindowOrArrange(direction)
  return function()
    local w = hl.get_active_window()
    if w == nil then return end
    local shouldMove = w.floating or (w.fullscreen or 0) ~= 0
    local windowRect = GetWindowRect(w)
    local bounds = GetWindowRect(w)
    local tiledCount = 0
    if not shouldMove then
      for _, candidate in ipairs(hl.get_workspace_windows(w.workspace.id)) do
        if
          not candidate.floating
          and not candidate.hidden
          and candidate.mapped
        then
          local candidateRect = GetWindowRect(candidate)
          if
            candidate.address ~= w.address
            and IsBeyond(windowRect, candidateRect, direction)
          then
            shouldMove = true
            break
          end
          tiledCount = tiledCount + 1
          bounds.left = math.min(bounds.left, candidateRect.left)
          bounds.top = math.min(bounds.top, candidateRect.top)
          bounds.right = math.max(bounds.right, candidateRect.right)
          bounds.bottom = math.max(bounds.bottom, candidateRect.bottom)
        end
      end
    end
    if not shouldMove then
      local monitorRect = GetMonitorRect(w.monitor)
      for _, monitor in ipairs(hl.get_monitors()) do
        if
          monitor.id ~= w.monitor.id
          and IsBeyond(monitorRect, GetMonitorRect(monitor), direction)
        then
          shouldMove = true
          break
        end
      end
    end
    if shouldMove then
      hl.dispatch(hl.dsp.window.move { direction = direction })
    elseif tiledCount > 1 then
      ArrangeTowardEdge(bounds, direction)
    end
  end
end

function SendShortcut(params)
  local release = function()
    params.state = 'up'
    hl.dispatch(hl.dsp.send_key_state(params))
  end
  return function()
    params.state = 'down'
    hl.dispatch(hl.dsp.send_key_state(params))
    hl.timer(release, { timeout = 20, type = 'oneshot' })
  end
end

local function MatchesClassPatterns(w, patterns)
  if w == nil then return nil end
  for _, pattern in ipairs(patterns) do
    if w.class:find(pattern) ~= nil then return true end
  end
  return false
end

function IsBrowser(w) return MatchesClassPatterns(w, browserClassPatterns) end

function IsTerminal(w) return MatchesClassPatterns(w, terminalClassPatterns) end

function TypeAndReset(text)
  return function()
    hl.dispatch(hl.dsp.exec_cmd("wtype '" .. text .. "'"))
    hl.dispatch(hl.dsp.submap 'reset')
  end
end
