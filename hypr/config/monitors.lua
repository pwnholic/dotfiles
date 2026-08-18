-- Monitor & workspace rules.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Monitors/
--       https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Output names come from `hyprctl monitors`; edit them in settings.lua,
-- not here.

local S = require("config.settings")

-- ===== Monitors =====

hl.monitor({
	output = S.monitors.external,
	mode = "1920x1080@100",
	position = "0x0",
	scale = 1,
	bitdepth = 10,
	cm = "auto",
})

hl.monitor({
	output = S.monitors.internal,
	mode = "1920x1200@144",
	position = "1920x0",
	scale = 1,
	-- 10-bit + cm=auto: panel runs XRGB2101010. Note: hardwareCursorsInUse is
	-- false either way (tested at 8-bit too), so this is NOT a cursor tradeoff;
	-- software cursor on this hybrid Intel/NVIDIA setup is expected.
	bitdepth = 10,
	cm = "auto",
})

-- Fallback for any monitor without an explicit rule above (docs-recommended):
-- preferred mode, auto-placed to the right of existing ones.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- ===== Workspace rules =====
-- Workspaces are dynamic by design (no static numbered/persistent rules);
-- these are the few rules that add real behavior on top of that.

-- Roman-numeral labels for the Noctalia bar: give each numbered workspace a
-- default name of its Roman numeral (I, II, ... IX) so the bar shows them as
-- Roman numerals. Workspaces stay dynamic; the name is only the display label.
local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
for i = 1, S.workspaces.num_per_monitor do
	hl.workspace_rule({ workspace = tostring(i), default_name = ROMAN[i] or tostring(i) })
end

-- Scratchpad dropdown: the first time SUPER+S toggles the special workspace,
-- auto-spawn a terminal in it — an instant dropdown console (docs example
-- pattern, terminal comes from settings.lua).
hl.workspace_rule({ workspace = "special", on_created_empty = "[float] " .. S.apps.terminal })

-- Smart gaps (docs pattern): a single visible tiled window, or any fullscreen
-- window, gets zero gaps / border / rounding. A maximized editor or a fullscreen
-- video then looks truly edge-to-edge.
-- hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, rounding = 0 })
