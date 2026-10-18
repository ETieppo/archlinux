local scratchpads = {
	claude = {
		name = "claude",
		class = "claude",
		key = "slash",
		launch = 'glide-bin --new-instance --profile "$HOME/.local/share/claude-glide" --name claude https://claude.ai',
		width = 520,
	},
}

local launchTimeout = 15000
local launching = {}

local function WindowSelector(w)
	return "address:" .. w.address
end

local function FindWindow(scratchpad)
	for _, w in ipairs(hl.get_windows()) do
		if w.class == scratchpad.class then
			return w
		end
	end
	return nil
end

local function FindScratchpad(w)
	for _, scratchpad in pairs(scratchpads) do
		if w.class == scratchpad.class then
			return scratchpad
		end
	end
	return nil
end

local function Place(scratchpad, w)
	local monitor = hl.get_active_monitor()
	local gaps = hl.get_config("general.gaps_out")
	local reserved = monitor.reserved
	local height = math.floor(monitor.height - reserved.top - reserved.bottom - gaps.top - gaps.bottom)
	local x = math.floor(monitor.x + monitor.width - reserved.right - gaps.right - scratchpad.width)
	local y = math.floor(monitor.y + reserved.top + gaps.top)
	hl.dispatch(hl.dsp.window.resize({ x = scratchpad.width, y = height, window = WindowSelector(w) }))
	hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = WindowSelector(w) }))
end

local function Show(scratchpad, w)
	local workspace = hl.get_active_workspace()
	hl.dispatch(hl.dsp.window.move({ workspace = tostring(workspace.id), window = WindowSelector(w), follow = false }))
	Place(scratchpad, w)
	hl.dispatch(hl.dsp.focus({ window = WindowSelector(w) }))
end

local function Hide(scratchpad, w)
	hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. scratchpad.name, window = WindowSelector(w), follow = false }))
end

local function Launch(scratchpad)
	if launching[scratchpad.name] then
		return
	end
	launching[scratchpad.name] = true
	hl.timer(function()
		launching[scratchpad.name] = false
	end, { timeout = launchTimeout, type = "oneshot" })
	hl.dispatch(hl.dsp.exec_cmd(scratchpad.launch))
end

local function ToggleScratchpad(scratchpad)
	local w = FindWindow(scratchpad)
	if w == nil then
		Launch(scratchpad)
	elseif w.workspace == nil or w.workspace.id ~= hl.get_active_workspace().id then
		Show(scratchpad, w)
	elseif w.active then
		Hide(scratchpad, w)
	else
		hl.dispatch(hl.dsp.focus({ window = WindowSelector(w) }))
	end
end

local function Setup(mod)
	for _, scratchpad in pairs(scratchpads) do
		hl.window_rule({
			name = "scratchpad-" .. scratchpad.name,
			match = { class = "^" .. scratchpad.class .. "$" },
			float = true,
			size = { scratchpad.width, "monitor_h*0.85" },
		})
		hl.bind(mod .. " + " .. scratchpad.key, function()
			ToggleScratchpad(scratchpad)
		end)
	end

	hl.on("window.open", function(w)
		local scratchpad = FindScratchpad(w)
		if scratchpad ~= nil and launching[scratchpad.name] then
			launching[scratchpad.name] = false
			Place(scratchpad, w)
		end
	end)

	hl.bind("Escape", function()
		local w = hl.get_active_window()
		local scratchpad = w ~= nil and FindScratchpad(w) or nil
		if scratchpad ~= nil then
			Hide(scratchpad, w)
		end
	end, { non_consuming = true })
end

return {
	scratchpads = scratchpads,
	ToggleScratchpad = ToggleScratchpad,
	Setup = Setup,
}
