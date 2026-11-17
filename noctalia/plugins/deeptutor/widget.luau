--!nonstrict

local RUNNING_COLOR = "primary"
local PARTIAL_COLOR = "warning"
local STOPPED_COLOR = "error"
local SERVICE_NAME = "DeepTutor + Bili"
local PROJECT_DIR = noctalia.expandPath("~/.config/noctalia/scripts")
local SCRIPT_PATH = PROJECT_DIR .. "/deeptutor.py"

local statusPending = false
local actionPending = false
local disposed = false
local serviceState = "checking"

local function isOn()
	return serviceState == "running" or serviceState == "partial"
end

local function render(state, status)
	serviceState = state
	local color = state == "running" and RUNNING_COLOR or state == "partial" and PARTIAL_COLOR or STOPPED_COLOR
	local leftClick = isOn() and "Stop " .. SERVICE_NAME or "Start " .. SERVICE_NAME
	local rightClick = isOn() and "Stop and clean up " .. SERVICE_NAME
		or state == "stopped" and "Unavailable while off"
		or "Wait for a valid status"
	barWidget.setGlyph("brain")
	barWidget.setText("")
	barWidget.setGlyphColor(color)
	barWidget.setTooltip({
		{ key = "Status", value = status },
		{ key = "Left click", value = leftClick },
		{ key = "Right click", value = rightClick },
	})
end

local function command(action)
	return {
		"uv",
		"run",
		"--project",
		PROJECT_DIR,
		SCRIPT_PATH,
		action,
	}
end

local function describeFailure(result)
	if result.timedOut then
		return "Status check timed out"
	end

	local output = (result.stderr ~= "" and result.stderr or result.stdout):gsub("%s+$", "")
	if output ~= "" then
		return output
	end

	return `Status check failed with exit code {result.exitCode}`
end

local function checkStatus()
	if statusPending or actionPending then
		return
	end

	statusPending = true
	local accepted = noctalia.runAsync(command("status"), function(result)
		if disposed then
			return
		end
		statusPending = false
		local status = result.stdout:gsub("^%s+", ""):gsub("%s+$", "")
		if result.exitCode ~= 0 then
			render("error", describeFailure(result))
			return
		end

		local deeptutorRunning = status:match("^running") ~= nil
		local biliRunning = status:match("Bili running") ~= nil
		local state = (deeptutorRunning and biliRunning) and "running"
			or (deeptutorRunning or biliRunning) and "partial"
			or "stopped"
		render(state, status)
	end)

	if not accepted then
		statusPending = false
		render("error", "Could not start status check")
	end
end

local function runAction(action)
	if disposed then
		return
	end
	if actionPending then
		noctalia.notifyError(SERVICE_NAME, "Another operation is still running. Please wait.")
		return
	end
	if serviceState ~= "running" and serviceState ~= "partial" and serviceState ~= "stopped" then
		noctalia.notifyError(SERVICE_NAME, "Wait for a successful status check before continuing.")
		return
	end
	if action == "start" and isOn() then
		noctalia.notifyError(SERVICE_NAME, "Already on. Only stop is available.")
		return
	end
	if action == "stop" and serviceState == "stopped" then
		noctalia.notifyError(SERVICE_NAME, "Already off. Start it before using stop.")
		return
	end

	actionPending = true
	barWidget.setTooltip(SERVICE_NAME .. ": " .. action .. " in progress…")
	local accepted = noctalia.runAsync(command(action), function(result)
		if disposed then
			return
		end
		actionPending = false
		if result.timedOut then
			noctalia.notifyError(SERVICE_NAME, "The " .. action .. " operation timed out.")
		elseif result.exitCode ~= 0 then
			local output = result.stderr ~= "" and result.stderr or result.stdout
			local message = output:gsub("^%s+", ""):gsub("%s+$", "")
			if #message > 500 then
				message = message:sub(-500)
			end
			noctalia.notifyError(SERVICE_NAME, message ~= "" and message or `Command failed: {action}`)
		end
		checkStatus()
	end)

	if not accepted then
		actionPending = false
		render("error", "Could not run " .. SERVICE_NAME .. " " .. action)
	end
end

function update()
	checkStatus()
end

function onClick()
	runAction(isOn() and "stop" or "start")
end

function onRightClick()
	runAction("stop")
end

function onIpc(event, _payload)
	if event == "refresh" then
		checkStatus()
	end
end

function onExit()
	disposed = true
end

noctalia.setUpdateInterval(1000)
render("checking", "Checking " .. SERVICE_NAME .. " status…")
checkStatus()
