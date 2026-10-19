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

local browserClassPatterns = { "^glide%-glide$", "^claude$", "^chrome%-" }

function IsBrowser(w)
	if w == nil then
		return false
	end
	for _, pattern in ipairs(browserClassPatterns) do
		if w.class:find(pattern) ~= nil then
			return true
		end
	end
	return false
end

function TypeText(text)
	return hl.dsp.exec_cmd("wtype '" .. text .. "'")
end


