local S = require("config.settings")

-- "1920x1080@100" -> 1920, 1080
local function parse_mode(mode)
	local w, h = tostring(mode):match("^(%d+)x(%d+)")
	return tonumber(w) or 0, tonumber(h) or 0
end

-- "1920x0" / "-1920x60" -> x, y (nil if not an absolute position)
local function parse_position(position)
	local x, y = tostring(position):match("^(%-?%d+)x(%-?%d+)$")
	return tonumber(x), tonumber(y)
end

local external_mode = "1920x1080@74.97"
local internal_mode = "1920x1200@144"

-- Side of the external monitor relative to the internal one.
local directions = {
	top = true,
	bottom = true,
	left = true,
	right = true,
}

-- Compute the absolute position of the external monitor from its direction;
-- absolute positions are returned unchanged.
local function external_position()
	local value = S.monitors.external.position
	if parse_position(value) then
		return value
	end

	local direction = directions[value] and value or "left"
	local ix, iy = parse_position(S.monitors.internal.position)
	ix, iy = ix or 0, iy or 0
	local iw, ih = parse_mode(internal_mode)
	local ew, eh = parse_mode(external_mode)

	if direction == "left" then
		return (ix - ew) .. "x" .. (iy + math.floor((ih - eh) / 2))
	elseif direction == "right" then
		return (ix + iw) .. "x" .. (iy + math.floor((ih - eh) / 2))
	elseif direction == "top" then
		return (ix + math.floor((iw - ew) / 2)) .. "x" .. (iy - eh)
	end
	return (ix + math.floor((iw - ew) / 2)) .. "x" .. (iy + ih)
end

local outputs = {
	{
		name = S.monitors.external.name,
		mode = external_mode,
		position = external_position(),
	},
	{
		name = S.monitors.internal.name,
		mode = internal_mode,
		position = S.monitors.internal.position,
	},
}

for _, monitor in ipairs(outputs) do
	hl.monitor({
		output = monitor.name,
		mode = monitor.mode,
		position = monitor.position,
		scale = 1,
		bitdepth = 10,
		cm = "auto",
	})
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local names = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
for index = 1, S.workspaces.count do
	hl.workspace_rule({
		workspace = tostring(index),
		default_name = names[index] or tostring(index),
	})
end

hl.workspace_rule({
	workspace = "special",
	on_created_empty = "[float] " .. S.apps.terminal,
})
