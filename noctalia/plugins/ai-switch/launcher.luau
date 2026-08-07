--!nonstrict
-- launcher.luau — widget bar: ikon bolt. Warna = status ollama (hijau=jalan).
-- Left-click membuka panel (dideklarasikan di manifest [widget.actions]).

local function render()
  local on = noctalia.state.get("ollama") == true
  barWidget.render(ui.row({ gap = 6, align = "center" }, {
    ui.glyph({ name = "bolt", size = 15, color = on and "#9ece6a" or "on_surface_variant" }),
  }))
end

noctalia.state.watch("ollama", function(v)
  render()
end)

function update()
  render()
end
noctalia.setUpdateInterval(1000)
