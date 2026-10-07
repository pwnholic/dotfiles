--- t02: root detection engine (strategies, caching, invalidation, inspector).
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local root = require("core.root")

-- Two different project roots plus a nested one (for the invalidation check).
local base = T.tmpdir("root")
local proj_a = vim.fs.joinpath(base, "project-a")
local proj_b = vim.fs.joinpath(base, "project-b", "nested", "deep")
vim.fn.mkdir(proj_a, "p")
vim.fn.mkdir(proj_b, "p")
T.write(vim.fs.joinpath(base, "project-b", "go.mod"), { "module example.com/b" })
T.write(
    vim.fs.joinpath(base, "project-b", "nested", "deep", "go.mod"),
    { "module example.com/deep" }
)
T.write(vim.fs.joinpath(proj_a, ".git", "HEAD"), { "ref: refs/heads/main" })
T.write(vim.fs.joinpath(proj_a, "main.py"), { "print(1)" })
T.write(vim.fs.joinpath(proj_b, "main.py"), { "print(2)" })

--- @param file string
--- @return integer bufnr
local function open(file)
    vim.cmd.edit({ args = { vim.fn.fnameescape(file) }, mods = { keepalt = true } })
    return vim.api.nvim_get_current_buf()
end

local buf_a = open(vim.fs.joinpath(proj_a, "main.py"))
local detail_a = root.detail(buf_a)
T.equal(detail_a.root, proj_a, "marker strategy resolves project A root (via .git)")
T.equal(detail_a.strategy, "git", "selected strategy is the highest-priority marker match")
T.equal(detail_a.marker, ".git", "matching marker reported")
-- Buffer-enter already resolved this buffer's context, so `detail()` may be a
-- hit here; the *uncached* path is `resolve()`, and cache behaviour is asserted
-- explicitly below via `invalidate()`.
T.equal(root.resolve(buf_a).strategy, "git", "resolve() is the uncached path")
root.invalidate(buf_a)
T.equal(root.detail(buf_a).cache.hit, false, "after invalidate() the entry is recomputed")
T.equal(root.detail(buf_a).cache.hit, true, "the recomputed entry is cached again")
T.equal(root.get(buf_a), proj_a, "root.get() returns the same cached result")

local buf_b = open(vim.fs.joinpath(proj_b, "main.py"))
T.equal(
    root.get(buf_b),
    vim.fs.joinpath(base, "project-b", "nested", "deep"),
    "closest marker wins (nested project B)"
)

-- cwd strategy: a file inside cwd without markers further up.
local loose = vim.fs.joinpath(base, "loose")
vim.fn.mkdir(loose, "p")
T.write(vim.fs.joinpath(loose, "notes.txt"), { "hello" })
vim.cmd.cd(vim.fn.fnameescape(loose))
local buf_loose = open(vim.fs.joinpath(loose, "notes.txt"))
T.equal(root.get(buf_loose), loose, "cwd strategy covers files without markers")

-- Outside cwd without markers: the dirname fallback applies (documented).
local fresh = vim.fs.joinpath(base, "fresh")
local fresh_deep = vim.fs.joinpath(fresh, "nested", "deep")
vim.fn.mkdir(fresh_deep, "p")
T.write(vim.fs.joinpath(fresh_deep, "code.lua"), { "return 1" })
local buf_fresh = open(vim.fs.joinpath(fresh_deep, "code.lua"))
T.equal(root.get(buf_fresh), fresh_deep, "dirname fallback: the buffer's directory")
T.equal(root.detail(buf_fresh).strategy, "file", "fallback strategy reported")

-- Invalidation: adding a marker higher up must change the resolved root, which
-- is only possible when the cache entry was invalidated by the write.
T.write(vim.fs.joinpath(fresh, "package.json"), { "{}" })
vim.api.nvim_buf_call(buf_fresh, function()
    vim.cmd.write()
end)
T.equal(root.get(buf_fresh), fresh, "creating a marker invalidates the cache and re-resolves")
T.equal(root.detail(buf_fresh).strategy, "project", "the new marker strategy now matches")
T.equal(root.detail(buf_fresh).marker, "package.json", "the matching marker is reported")

-- Custom strategy registration (extension point) without touching core.
local registered = root.register_strategy({
    id = "test-marker",
    kind = "marker",
    markers = { "custom-root-marker" },
    priority = 200,
})
T.check(registered, "custom strategy registered")
local custom = vim.fs.joinpath(base, "custom")
vim.fn.mkdir(custom, "p")
T.write(vim.fs.joinpath(custom, "custom-root-marker"), { "" })
T.write(vim.fs.joinpath(custom, "file.txt"), { "x" })
local buf_custom = open(vim.fs.joinpath(custom, "file.txt"))
T.equal(root.get(buf_custom), custom, "custom strategy participates")
T.equal(root.detail(buf_custom).strategy, "test-marker", "custom strategy wins by priority")

-- Function strategies are supported and receive the buffer context.
local fn_ok = root.register_strategy({
    id = "test-fn",
    kind = "fn",
    priority = 300,
    fn = function(ctx)
        if ctx.filetype == "lua" then
            return ctx.dir, "fn strategy matched a lua buffer"
        end
        return nil, "fn strategy: not a lua buffer"
    end,
})
T.check(fn_ok, "function strategy registered")
local lua_dir = vim.fs.joinpath(base, "fn")
vim.fn.mkdir(lua_dir, "p")
T.write(vim.fs.joinpath(lua_dir, "f.lua"), { "return 1" })
local buf_fn = open(vim.fs.joinpath(lua_dir, "f.lua"))
T.equal(root.get(buf_fn), lua_dir, "function strategy resolved the root")
T.equal(root.detail(buf_fn).strategy, "test-fn", "function strategy selected")

-- Unknown kind is rejected with a clear error.
local ok_bad, bad_err = root.register_strategy({ id = "bad", kind = "not-a-kind" })
T.equal(ok_bad, false, "unknown strategy kind rejected")
T.check(
    tostring(bad_err):find("unknown strategy kind", 1, true) ~= nil,
    "rejection explains the reason"
)

-- `vim.g.root_spec` is the documented data-driven override point.
local spec_before = root.list_strategies()
vim.g.root_spec = { { id = "cwd-only", kind = "cwd" } }
root.setup(require("core.defaults").get("root", {}))
T.equal(#root.list_strategies(), 1, "vim.g.root_spec replaces the strategy list")
T.equal(root.list_strategies()[1].id, "cwd-only", "declared strategy is the only one")
vim.g.root_spec = nil
root.setup(require("core.defaults").get("root", {}))
-- `setup()` rebuilds the strategy list from configuration (documented), so the
-- ad-hoc test strategies registered above are gone and the defaults are back.
T.equal(#root.list_strategies(), 5, "setup() rebuilds the strategy list from the defaults")
T.check(#spec_before > 5, "test strategies had been registered before")

-- Inspector + command.
local lines = root.report_lines(buf_a)
local text = table.concat(lines, "\n")
T.check(text:find("Project root", 1, true) ~= nil, "inspector reports the resolved root")
T.check(
    text:find("Strategies (in priority order)", 1, true) ~= nil,
    "inspector lists evaluated strategies"
)
T.check(text:find("Cache", 1, true) ~= nil, "inspector reports cache state")
T.check(text:find("lsp", 1, true) ~= nil, "inspector reports failed strategies (lsp)")
local ok_cmd, cmd_err = pcall(vim.cmd, "Root " .. buf_a)
T.check(ok_cmd, ":Root runs for a buffer number: " .. tostring(cmd_err))
local report_buf = vim.fn.bufnr("core://root")
T.check(report_buf ~= -1, ":Root opens the inspector buffer")
T.check(#vim.api.nvim_buf_get_lines(report_buf, 0, -1, false) > 5, ":Root buffer has content")

-- Clearing the cache is observable: the next lookup is a miss again. (The
-- cache is immediately repopulated with the *current* buffer's context, which
-- is by design -- `clear()` also re-emits the project context.)
root.get(buf_a)
root.clear()
T.equal(root.detail(buf_a).cache.hit, false, "after clear() the entry is resolved again")

-- Invalid input is rejected, not guessed.
local ok_bad_root = pcall(vim.cmd, "Root not-a-number")
T.check(ok_bad_root, ":Root with a non-numeric argument is handled without raising a Lua error")

T.finish()
