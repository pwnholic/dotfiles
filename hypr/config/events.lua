-- IPC event handlers (socket2 events surfaced through hl.on).
-- Only low-noise, high-value events: config reload feedback and a privacy
-- indicator for screen sharing. Handlers are defensive — a broken callback
-- must never destabilize the compositor.

local S = require("config.settings")

-- Config reload feedback: silent success is ambiguous; confirm it landed.
hl.on("config.reloaded", function()
	S.notify("Hyprland config reloaded")
end)

-- -- Screen-share privacy indicator: tell the user when a portal client starts
-- -- or stops capturing the screen. Data shape varies by client, so stringify
-- -- defensively.
-- hl.on("screenshare.state", function(...)
-- 	local ok, state = pcall(function(...)
-- 		local parts = {}
-- 		for i = 1, select("#", ...) do
-- 			table.insert(parts, tostring(select(i, ...)))
-- 		end
-- 		return table.concat(parts, ",")
-- 	end, ...)
-- 	if not ok then
-- 		state = "unknown"
-- 	end
-- 	if state:match("^1") or state:match("true") then
-- 		S.notify("Screen sharing STARTED (" .. state .. ")")
-- 	else
-- 		S.notify("Screen sharing stopped")
-- 	end
-- end)
