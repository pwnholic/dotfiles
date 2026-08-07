--!nonstrict
-- panel.luau — panel floating AI Switch: 2 toggle (ollama serve, deeptutor
-- start) + status warna + info GPU/model. Status dari monitor service.

local SVC = "/home/pwnholic/.local/bin/ai-svc"
local ollama, deeptutor = false, false
local gpu, api = nil, nil
local open = false

local GREEN, RED, MUTED = "#9ece6a", "#f7768e", "surface_variant"

local function statusDot(on)
  return ui.box({ width = 10, height = 10, radius = 5, fill = on and GREEN or MUTED })
end

local function toggleRow(title, sub, on, handler)
  return ui.row({ gap = 10, align = "center" }, {
    statusDot(on),
    ui.column({ flexGrow = 1, gap = 2 }, {
      ui.label({ text = title, fontWeight = "medium", color = "on_surface" }),
      ui.label({ text = sub, fontSize = 11, color = "on_surface_variant" }),
    }),
    ui.toggle({ checked = on, onChange = handler }),
  })
end

local function gpuLine()
  if gpu == nil then return "GPU: — (menunggu sampel…)" end
  local t = gpu.tempC ~= nil and string.format("%.0f°C", gpu.tempC) or "?°C"
  local u = gpu.usage ~= nil and string.format("%d%%", gpu.usage) or "?%"
  local vm = gpu.vramUsed ~= nil and string.format("%.1f", gpu.vramUsed / 1e9) or "?"
  local vt = gpu.vramTotal ~= nil and string.format("%.1f", gpu.vramTotal / 1e9) or "?"
  return string.format("GPU: %s • util %s • VRAM %s/%s GB", t, u, vm, vt)
end

local function render()
  panel.render(ui.column({ flexGrow = 1, gap = 12 }, {
    -- header
    ui.row({ align = "center", justify = "space_between", gap = 8 }, {
      ui.label({ text = "AI Switch", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "onClose" }),
    }),
    -- toggles
    toggleRow("ollama serve", "localhost:11434 • GPU offload", ollama, "onToggleOllama"),
    toggleRow("deeptutor start", "backend + frontend (port 6968)", deeptutor, "onToggleDeep"),
    ui.separator({}),
    -- info
    ui.row({ gap = 8, align = "center" }, {
      ui.glyph({ name = "gauge", size = 14, color = "on_surface_variant" }),
      ui.label({ text = gpuLine(), color = "on_surface_variant", fontSize = 12, flexGrow = 1 }),
    }),
    ui.row({ gap = 8, align = "center" }, {
      ui.glyph({ name = "database", size = 14, color = "on_surface_variant" }),
      ui.label({
        text = "Model: qwen3-embedding:0.6b" .. (api == true and " • API: OK" or ""),
        color = "on_surface_variant", fontSize = 12, flexGrow = 1,
      }),
    }),
  }))
end

-- lifecycle
function onOpen(_context)
  open = true
  render()
end

function onClose()
  panel.close()
end

function onToggleOllama(value)
  local on = value == "true"
  if on then noctalia.runAsync(SVC .. " ollama start") else noctalia.runAsync(SVC .. " ollama stop") end
  ollama = on -- optimistis; monitor akan konfirmasi
  render()
end

function onToggleDeep(value)
  local on = value == "true"
  if on then noctalia.runAsync(SVC .. " deeptutor start") else noctalia.runAsync(SVC .. " deeptutor stop") end
  deeptutor = on
  render()
end

-- sinkronisasi dari monitor service
local function onState(key, value)
  if key == "ollama" and value ~= nil then ollama = (value == true) end
  if key == "deeptutor" and value ~= nil then deeptutor = (value == true) end
  if key == "gpu" and value ~= nil then gpu = value end
  if key == "api" and value ~= nil then api = value end
  if open then render() end
end
noctalia.state.watch("ollama", function(v) onState("ollama", v) end)
noctalia.state.watch("deeptutor", function(v) onState("deeptutor", v) end)
noctalia.state.watch("gpu", function(v) onState("gpu", v) end)
noctalia.state.watch("api", function(v) onState("api", v) end)
