--- t06: vim.pack orchestration (lazy triggers, deps, reloadable configs)
---      plus the configuration watcher.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local fs = require("lib.fs")
local pack = require("core.pack")

-- ---------------------------------------------------------------------------
-- Fixture plugins (local git repositories, no network)
-- ---------------------------------------------------------------------------

local base = T.tmpdir("pack")
local pack_dir = fs.data_path("site", "pack", "core", "opt")

--- @param name string
--- @return string source repo path
local function make_fixture(name)
    -- NOTE: `string.gsub()` returns (result, count); the results are always
    -- captured in locals here, never passed straight into another call.
    local slug = (name:gsub("-", "_"))
    local repo = vim.fs.joinpath(base, name, "repo")
    vim.fn.mkdir(vim.fs.joinpath(repo, "plugin"), "p")
    vim.fn.mkdir(vim.fs.joinpath(repo, "lua", slug), "p")
    -- The fixture defines the command that the spec declares as its `cmd`
    -- trigger (that is the contract the loader replays after loading).
    local parts = vim.split(name, "-", { plain = true })
    for i, part in ipairs(parts) do
        parts[i] = part:sub(1, 1):upper() .. part:sub(2)
    end
    local command = table.concat(parts, "")
    T.write(vim.fs.joinpath(repo, "plugin", name .. ".lua"), {
        ("vim.g.%s_sourced = (vim.g.%s_sourced or 0) + 1"):format(slug, slug),
        ('vim.api.nvim_create_user_command("%s", function() vim.g.%s_cmd = true end, {})'):format(
            command,
            slug
        ),
    })
    T.write(
        vim.fs.joinpath(repo, "lua", slug, "init.lua"),
        { 'return { name = "' .. name .. '" }' }
    )
    local run = vim.fn.system({
        "sh",
        "-c",
        -- Annotated tag on purpose: `git rev-parse <tag>` then yields the tag
        -- object, so the update check has to dereference it (`^{commit}`).
        (
            "cd %s && git init -q -b main . && git add -A && git -c user.email=t@t -c user.name=t commit -qm init"
            .. " && git -c user.email=t@t -c user.name=t tag -a v1.0.0 -m v1.0.0"
        ):format(vim.fn.shellescape(repo)),
    })
    T.check(vim.v.shell_error == 0, ("fixture %s created: %s"):format(name, tostring(run)))
    return repo
end

--- Simulate a plugin that was installed by a previous session.
--- @param name string
--- @param repo string
-- Installed the way vim.pack does (a local `file://` clone, no network). Using
-- vim.pack itself is deliberate: a directory that appears on disk *after* the
-- lockfile has been read is not treated as "installed", so a hand-made clone
-- would make vim.pack try to clone over it.
local function install_fixture(name, repo)
    local dest = vim.fs.joinpath(pack_dir, name)
    -- A previous run that failed early may have left a lockfile entry (and no
    -- directory) behind; vim.pack would then consider the fixture "installed".
    -- `del()` removes both, so the fixture is always installed from scratch.
    pcall(vim.pack.del, { name }, { force = true })
    vim.fn.delete(dest, "rf")
    local ok, err = pcall(
        vim.pack.add,
        { { src = "file://" .. repo, name = name } },
        { load = false, confirm = false }
    )
    T.check(ok, ("fixture %s installed through vim.pack: %s"):format(name, tostring(err)))
    T.check(fs.is_dir(dest), ("fixture %s is on disk"):format(name))
end

-- `require` searches `?.lua` before `?/init.lua`, so a flat file left next to a
-- module directory would silently win (and the directory would become dead code).
local core_lua = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "core")
T.check(
    vim.uv.fs_stat(vim.fs.joinpath(core_lua, "pack.lua")) == nil,
    "no flat core/pack.lua shadowing core/pack/init.lua"
)
T.check(
    debug.getinfo(require("core.pack").report_lines, "S").source:find("core/pack/init.lua", 1, true)
        ~= nil,
    "core.pack is loaded from core/pack/init.lua"
)
T.check(
    debug
        .getinfo(require("core.pack.update").state, "S").source
        :find("core/pack/update.lua", 1, true) ~= nil,
    "core.pack.update is loaded from core/pack/update.lua"
)
T.check(
    vim.uv.fs_stat(vim.fs.joinpath(core_lua, "lsp.lua")) == nil,
    "no flat core/lsp.lua shadowing core/lsp/init.lua"
)
T.check(
    debug.getinfo(require("core.lsp").hint_text, "S").source:find("core/lsp/init.lua", 1, true)
        ~= nil,
    "core.lsp is loaded from core/lsp/init.lua"
)

local src_cmd = make_fixture("core-demo")
local src_event = make_fixture("core-demo-event")
install_fixture("core-demo", src_cmd)
install_fixture("core-demo-event", src_event)

-- ---------------------------------------------------------------------------
-- Declarations and triggers
-- ---------------------------------------------------------------------------

local config_runs = {}
local messages = T.capture_notifications()

local function declare_fixtures()
    pack.register({
        src = "file://" .. src_cmd,
        name = "core-demo",
        cmd = { "CoreDemo" },
        version = "v1.0.0",
        keys = { { "<leader>zz", mode = "n", desc = "demo key trigger" } },
        ft = { "lua" },
        reloadable = true,
        config = function()
            config_runs["core-demo"] = (config_runs["core-demo"] or 0) + 1
            vim.g.core_demo_config_runs = config_runs["core-demo"]
            -- The plugin's own mapping, defined by its configuration (key trigger).
            vim.keymap.set("n", "<leader>zz", function()
                vim.g.core_demo_key = true
            end, { desc = "demo key (real)" })
        end,
    })

    pack.register({
        src = "file://" .. src_event,
        name = "core-demo-event",
        event = { { event = "User", pattern = "CoreDemoEvent" } },
        config = function()
            config_runs["core-demo-event"] = (config_runs["core-demo-event"] or 0) + 1
            vim.g.core_demo_event_config_runs = config_runs["core-demo-event"]
        end,
    })
end

declare_fixtures()
pack.setup_triggers()

-- Stubs exist for every declared trigger kind.
T.check(vim.api.nvim_get_commands({}).CoreDemo ~= nil, "command stub created")
T.check(vim.fn.maparg("<leader>zz", "n", false, true).desc ~= nil, "key stub created")
local ft_stub = false
for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "FileType" })) do
    if au.desc and au.desc:find("core-demo", 1, true) then
        ft_stub = true
    end
end
T.check(ft_stub, "filetype stub created")
T.equal(pack.is_loaded("core-demo"), false, "nothing loaded yet")

-- ---------------------------------------------------------------------------
-- Command trigger: stub -> load -> replay
-- ---------------------------------------------------------------------------

vim.cmd("CoreDemo")
T.equal(pack.is_loaded("core-demo"), true, "command trigger loaded the plugin")
T.equal(pack.is_configured("core-demo"), true, "config hook ran")
T.equal(vim.g.core_demo_sourced, 1, "plugin/ scripts were sourced exactly once")
T.equal(config_runs["core-demo"], 1, "config ran exactly once")
T.equal(
    vim.api.nvim_get_commands({}).CoreDemo ~= nil,
    true,
    "plugin-defined command is available after replay"
)

-- The replay reached the plugin's own command, not the (already removed) stub.
T.equal(vim.g.core_demo_cmd, true, "replayed command executed the plugin command")

-- Triggering again must not re-source or re-configure.
vim.cmd("CoreDemo")
T.equal(vim.g.core_demo_sourced, 1, "no double sourcing after a second trigger")
T.equal(config_runs["core-demo"], 1, "no double configuration")

-- ---------------------------------------------------------------------------
-- Key trigger: stub -> load -> re-dispatch
-- ---------------------------------------------------------------------------

local keys = vim.api.nvim_replace_termcodes("<leader>zz", true, false, true)
vim.api.nvim_feedkeys(keys, "x", false)
T.equal(vim.g.core_demo_key, true, "key trigger re-dispatched to the plugin mapping")

-- ---------------------------------------------------------------------------
-- Event trigger (User pattern)
-- ---------------------------------------------------------------------------

require("core.pack").setup_triggers()
vim.api.nvim_exec_autocmds("User", { pattern = "CoreDemoEvent" })
T.equal(pack.is_loaded("core-demo-event"), true, "event trigger loaded the plugin")
T.equal(config_runs["core-demo-event"], 1, "event plugin config ran")

-- ---------------------------------------------------------------------------
-- Reload re-applies reloadable configurations exactly once
-- ---------------------------------------------------------------------------

local before = {
    autocmds = T.autocmd_snapshot(),
    sourced = vim.g.core_demo_sourced,
    config_runs = config_runs["core-demo"],
}
local ok, problems = require("core.reload").reload({ changed = { "tests" } })
T.equal(ok, true, "reload with loaded plugins succeeded")
T.equal(problems, {}, "reload reported no problems")

-- `:ConfigReload` rebuilds the plugin registry from the configuration files, so
-- runtime declarations (these fixtures) have to be re-declared; that is the
-- documented extension model.
T.equal(config_runs["core-demo"], before.config_runs, "no config runs before re-declaration")
declare_fixtures()

local pack_new = require("core.pack")
T.equal(pack_new.is_loaded("core-demo"), true, "plugin stays loaded across reload")
T.equal(
    vim.g.core_demo_sourced,
    before.sourced,
    "plugin/ scripts were not sourced again after reload"
)
T.equal(config_runs["core-demo"], before.config_runs + 1, "reloadable config re-applied on reload")
T.equal(T.autocmd_snapshot(), before.autocmds, "no duplicated autocommands after reload")
T.check(T.notified(messages, "configuration reloaded"), "reload reported")

-- ---------------------------------------------------------------------------
-- Update check (advisory) works with an existing plugin
-- ---------------------------------------------------------------------------

local ran, result = pack.check_updates({ force = true, notify = false, wait = true })
T.equal(ran, true, "update check ran")
T.check(type(result.checked) == "number", "update check reports how many plugins it checked")

-- The fixture is pinned to an *annotated* tag that points at the checked-out
-- commit, so it must not be reported as updatable (regression: tag object vs
-- commit hash).
local fixture_updates = vim.iter(result.updates)
    :filter(function(u)
        return u.name == "core-demo"
    end)
    :totable()
T.equal(
    #fixture_updates,
    0,
    "annotated-tag refs resolve to commits: " .. vim.inspect(fixture_updates)
)

-- The automatic check is throttled and the throttle is persisted, so startup
-- does not hit the network on every launch.
local ran_again, throttled = pack.check_updates({ notify = false, wait = false })
T.equal(ran_again, false, "a second check within the interval is throttled")
T.equal(throttled.throttled, true, "throttle flag is reported")
T.check(
    require("lib.fs").is_file(require("lib.fs").state_path("core", "pack-update.json")),
    "update-check state is persisted"
)

-- ---------------------------------------------------------------------------
-- Cleanup: remove the fixtures from the pack directory
-- ---------------------------------------------------------------------------

local deleted = pcall(vim.pack.del, { "core-demo", "core-demo-event" }, { force = true })
T.check(deleted, "fixture plugins can be deleted through vim.pack")
T.equal(fs.is_dir(vim.fs.joinpath(pack_dir, "core-demo")), false, "fixture removed from disk")

-- ---------------------------------------------------------------------------
-- Watcher: detects config changes, ignores its own state files
-- ---------------------------------------------------------------------------

local reload = require("core.reload")
local probe = fs.config_path("lua", "core", "__test_watch_probe.lua")
vim.fn.delete(probe)
local events_before = reload.watch_state().events_seen
T.write(probe, { "-- temporary probe written by tests/t06 (deleted immediately)" })
T.wait(1200)
local events_after = reload.watch_state().events_seen
T.check(events_after > events_before, "watcher observed a change in the config tree")
vim.fn.delete(probe)

local notifications = T.capture_notifications()
T.write(fs.config_path("nvim-pack-lock.json"), { '{"plugins":{}}' })
T.wait(900)
T.equal(
    T.notified(notifications, "nvim-pack-lock.json"),
    false,
    "lockfile changes are ignored (no reload loop)"
)
T.check(fs.is_file(probe) == false, "probe file cleaned up")

T.finish()
