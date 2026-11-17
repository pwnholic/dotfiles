--!nonstrict

local RUNNING_COLOR = "#22C55E"
local STOPPED_COLOR = "#EF4444"
local PROJECT_DIR = noctalia.expandPath("~/.config/noctalia/scripts")
local SCRIPT_PATH = PROJECT_DIR .. "/deeptutor.py"

local statusPending = false
local actionPending = false
local disposed = false

local function render(running, status)
	barWidget.setGlyph("brain")
	barWidget.setText("")
	barWidget.setGlyphColor(running and RUNNING_COLOR or STOPPED_COLOR)
	barWidget.setTooltip({
		{ key = "Status", value = status },
		{ key = "Left click", value = "Start/stop" },
		{ key = "Right click", value = "Stop and clean up" },
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
	if statusPending then
		return
	end

	statusPending = true
	local accepted = noctalia.runAsync(command("status"), function(result)
		if disposed then
			return
		end
		statusPending = false
		local status = result.stdout:gsub("^%s+", ""):gsub("%s+$", "")
		if result.exitCode == 0 and status:match("^running") then
			render(true, status)
		else
			render(false, result.exitCode == 0 and status or describeFailure(result))
		end
	end)

	if not accepted then
		statusPending = false
		render(false, "Could not start status check")
	end
end

local function runAction(action)
	if actionPending then
		return
	end

	actionPending = true
	barWidget.setTooltip("DeepTutor: " .. action .. " in progress…")
	local accepted = noctalia.runAsync(command(action), function(result)
		if disposed then
			return
		end
		actionPending = false
		if result.timedOut then
			noctalia.notifyError("DeepTutor", "The " .. action .. " operation timed out.")
		elseif result.exitCode ~= 0 then
			local output = result.stderr ~= "" and result.stderr or result.stdout
			local message = output:gsub("^%s+", ""):gsub("%s+$", "")
			if #message > 500 then
				message = message:sub(-500)
			end
			noctalia.notifyError("DeepTutor", message ~= "" and message or `Command failed: {action}`)
		end
		checkStatus()
	end)

	if not accepted then
		actionPending = false
		render(false, "Could not run DeepTutor " .. action)
	end
end

function update()
	checkStatus()
end

function onClick()
	runAction("toggle")
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
render(false, "Checking DeepTutor status…")
checkStatus()
