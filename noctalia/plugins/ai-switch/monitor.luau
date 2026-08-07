--!nonstrict
-- monitor.luau — service headless: poll status ollama/deeptutor + info GPU,
-- lalu publish ke noctalia.state agar widget & panel ikut update.

local SVC = "/home/pwnholic/.local/bin/ai-svc"

local function tick()
  -- status ollama (ai-svc pakai bracket-pattern, tanpa self-match)
  noctalia.runAsync(SVC .. " ollama status", function(r)
    noctalia.state.set("ollama", r.exitCode == 0)
  end)

  -- status deeptutor
  noctalia.runAsync(SVC .. " deeptutor status", function(r)
    noctalia.state.set("deeptutor", r.exitCode == 0)
  end)

  -- info GPU (RTX 5050) dari system-monitor host
  local s = noctalia.systemStats()
  if s ~= nil and s.gpu ~= nil then
    noctalia.state.set("gpu", {
      tempC = s.gpu.tempC,
      usage = s.gpu.usagePercent,
      vramUsed = s.gpu.vramUsedBytes,
      vramTotal = s.gpu.vramTotalBytes,
    })
  end

  -- API ollama responsif?
  noctalia.runAsync("curl -sf -m 1 http://localhost:11434/api/tags >/dev/null 2>&1", function(r)
    noctalia.state.set("api", r.exitCode == 0)
  end)
end

noctalia.setUpdateInterval(2000)
function update()
  tick()
end
