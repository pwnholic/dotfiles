--- t09: fzf-lua picker wiring (lazy triggers, root-aware cwd, ui.select).
---
--- Real pickers open an fzf UI, which cannot be driven headlessly; the wiring is
--- therefore verified where it is decidable: declared triggers, provider
--- existence, cwd policy, keymaps, and the `vim.ui.select` registration.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local defaults = require("core.defaults")
local pack = require("core.pack")
local picker = require("plugins.fzf_lua")

-- Declaration + lazy triggers.
local spec = pack.get("fzf-lua")
T.check(spec ~= nil, "fzf-lua is declared")
T.equal(spec and spec.cmd, { "FzfLua" }, "command trigger declared")
T.check(spec and spec.reloadable == true, "picker configuration is reloadable")
local triggers = vim.iter(spec and spec.keys or {})
    :map(function(key)
        return key[1] .. ":" .. tostring(key.mode)
    end)
    :totable()
for _, expected in ipairs({
    "<leader>ff:n",
    "<leader>fg:n",
    "<leader>fw:n",
    "<leader>fw:x",
    "<leader>gs:n",
}) do
    T.check(vim.tbl_contains(triggers, expected), ("key trigger %s is declared"):format(expected))
end

-- Stubs exist while the plugin is unloaded, and the mappings do not.
T.check(
    vim.fn.maparg("<leader>ff", "n", false, true).desc ~= nil,
    "file picker key exists as a stub"
)

-- Loading the plugin applies the configuration.
T.check(pack.load("fzf-lua"), "fzf-lua loads (installed through vim.pack)")
T.check(package.loaded["fzf-lua"] ~= nil, "fzf-lua module is loaded")
T.check(vim.api.nvim_get_commands({}).FzfLua ~= nil, ":FzfLua command is available after loading")

-- Keymaps are real now, with the configured modes and descriptions.
local files_map = vim.fn.maparg("<leader>ff", "n", false, true)
T.check(
    files_map.desc ~= nil and files_map.desc:find("find files", 1, true) ~= nil,
    "file picker keymap is applied"
)
local word_visual = vim.fn.maparg("<leader>fw", "x", false, true)
T.check(word_visual.desc ~= nil, "grep-word is mapped in visual mode too")
T.equal(
    vim.fn.maparg("<leader>fw", "n", false, true).desc ~= nil,
    true,
    "grep-word is mapped in normal mode"
)

-- Every configured picker maps to a provider that exists in the installed version.
local FzfLua = require("fzf-lua")
for name, entry in pairs(picker.pickers()) do
    T.check(
        type(FzfLua[entry.provider]) == "function",
        ("provider %q for picker %q exists"):format(entry.provider, name)
    )
end

-- `vim.ui.select` is taken over (so :LspExec/:Toggles use the picker).
local ui_source = debug.getinfo(vim.ui.select, "S").source or ""
T.check(ui_source:find("fzf%-lua") ~= nil, "vim.ui.select is fzf-lua's: " .. ui_source)

-- Root-aware cwd: files/grep use the project root, buffer-local pickers do not.
local base = T.tmpdir("picker")
local project = vim.fs.joinpath(base, "proj")
vim.fn.mkdir(project, "p")
T.write(vim.fs.joinpath(project, ".git", "HEAD"), { "ref: refs/heads/main" })
T.write(vim.fs.joinpath(project, "code.lua"), { "return 1" })
vim.cmd.cd(vim.fn.fnameescape(project))
vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(project, "code.lua")))
T.equal(picker.picker_opts("files").cwd, project, "file picker uses the project root")
T.equal(picker.picker_opts("grep").cwd, project, "grep picker uses the project root")
T.equal(picker.picker_opts("git_status").cwd, project, "git picker uses the project root")
T.equal(picker.picker_opts("buffers").cwd, nil, "buffer picker is not cwd-bound")
T.equal(picker.picker_opts("resume").cwd, nil, "resume picker is not cwd-bound")

-- The policy is configuration-driven.
defaults.values.picker.use_project_root = false
T.equal(picker.picker_opts("files").cwd, nil, "use_project_root = false disables the root cwd")
defaults.values.picker.use_project_root = true

-- Disabled keys are neither mapped nor declared.
defaults.values.picker.keys.help = false
picker.map_keys()
local unmapped = vim.fn.maparg("<leader>fh", "n", false, true)
T.check(unmapped.desc == nil or unmapped.desc == "", "disabled picker key is not mapped")
defaults.values.picker.keys.help = "<leader>fh"
picker.map_keys()
T.check(vim.fn.maparg("<leader>fh", "n", false, true).desc ~= nil, "re-enabling maps the key again")

-- Teardown returns `vim.ui.select` to Neovim (and configuration can restore it).
picker.teardown()
local after_teardown = debug.getinfo(vim.ui.select, "S").source or ""
T.check(
    after_teardown:find("fzf%-lua") == nil,
    "teardown deregisters vim.ui.select: " .. after_teardown
)
picker.configure()
local after_reconfigure = debug.getinfo(vim.ui.select, "S").source or ""
T.check(after_reconfigure:find("fzf%-lua") ~= nil, "re-configuring registers vim.ui.select again")

-- Unknown pickers fail loudly (no silent no-op).
T.check(not pcall(picker.picker_opts, "nope"), "unknown picker name is rejected")

T.finish()
