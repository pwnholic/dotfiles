-- nvim-lint: async linters via `vim.diagnostic`, CURRENT BUFFER ONLY.
--
-- OVERRIDE CONTRACT (replaces LazyVim `plugins/linting.lua` behavior):
--   - Only the buffer that fired the autocmd is ever linted. No workspace
--     sweep, no quickfix list, no cross-buffer diagnostics touch.
--   - No `["*"]` global linters, no `["_"]` fallback linters. Resolution is
--     strictly `linters_by_ft[vim.bo[bufnr].filetype]` for the event buffer.
--   - `try_lint(names)` is always called with an explicit name list so it
--     can never re-resolve from whatever buffer happens to be current.
--   - The event buffer is pinned via `nvim_buf_call` so even if you switch
--     windows during the debounce, the right buffer gets the diagnostics.
--
-- LINT RULES (user spec):
--   1. Missing binaries are AUTO-INSTALLED via mason (`:MasonInstall`),
--      async in the background. Buffer gets linted once install finishes.
--   2. A linter runs ONLY when its project config file exists, searched
--      upward from the buffer (config-gated, see CONFIG_MARKERS below).
--   3. Lint triggers on SAVE only (`BufWritePost`). No lint on open,
--      no lint on InsertLeave.
--
-- HARDENING (error handling / deadlock / perf):
--   - Every linter is checked with `vim.fn.executable` before it runs; a
--     missing binary triggers a one-shot mason install, never spawns
--     a dead process, never spams notifications.
--   - Linters skip non-normal buffers (`buftype ~= ""`), unnamed buffers,
--     unloaded buffers (`nvim_buf_is_loaded`), and huge buffers
--     (>1MB by default) so oil/preview/terminal/paste dumps stay cheap.
--   - Fault isolation: each linter invocation is wrapped in a `pcall`
--     equivalent (`lint.lint` + `try_lint` both pcall internally, and
--     `try_lint` cancels the previous same-name proc via
--     `LintProc:cancel()` -> SIGINT, escalating to SIGKILL after 10s).
--   - Watchdog: any proc still listed by `lint.get_running(bufnr)` after
--     `timeout_ms` gets `try_lint`ed-cancelled so a hung binary can never
--     wedge the per-buffer proc slot. Interval is `timeout_ms + 5000`
--     (upstream needs up to 10s for its own SIGINT->SIGKILL escalation).
--   - BufWipeout clears diagnostics + dead timers/handles so we never
--     leak uv handles on a long-running session.
--
-- PERFORMANCE:
--   - ONE global 100ms debounce timer shared by all buffers. Stale pending
--     requests are superseded (pending set), never queued — so a fast
--     save burst collapses to a single lint of the newest buffer.
local DEBOUNCE_MS = 100
local TIMEOUT_MS = 15000
local MAX_BYTES = 1024 * 1024

--- Project config markers per linter. A linter runs only when one of its
--- markers is found upward from the buffer file. `true` = always run
--- (the tool is self-configuring; e.g. fish --no-execute needs no config).
local CONFIG_MARKERS = {
    selene = { "selene.toml", ".selene.toml" },
    ruff = { "pyproject.toml", "ruff.toml", ".ruff.toml" },
    golangcilint = { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" },
    shellcheck = { ".shellcheckrc", "shellcheckrc", ".shellcheckrc.json" },
    fish = true,
    oxlint = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts", "package.json" },
}

--- mason package name per linter (differs from the nvim-lint name).
local MASON_PKG = {
    selene = "selene",
    ruff = "ruff",
    golangcilint = "golangci-lint",
    shellcheck = "shellcheck",
    oxlint = "oxlint",
    -- fish: system shell, not a mason package on purpose.
}

return {
    {
        "mfussenegger/nvim-lint",
        opts = function(_, opts)
            opts.linters = opts.linters or {}
            opts.linters_by_ft = {
                lua = { "selene" },
                python = { "ruff" },
                go = { "golangcilint" },
                sh = { "shellcheck" },
                fish = { "fish" },
                javascript = { "oxlint" },
                javascriptreact = { "oxlint" },
                typescript = { "oxlint" },
                typescriptreact = { "oxlint" },
                -- NOTE: no ["*"], no ["_"] on purpose. See header.
            }
        end,
        config = function(_, opts)
            local lint = require("lint")

            vim.iter(opts.linters or {}):each(function(name, linter)
                if type(linter) == "table" and type(lint.linters[name]) == "table" then
                    lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
                else
                    lint.linters[name] = linter
                end
            end)
            lint.linters_by_ft = opts.linters_by_ft or {}
            lint.linters_by_ft["*"] = nil
            lint.linters_by_ft["_"] = nil

            local installing = {} ---@type table<string, boolean>
            local timer = assert(vim.uv.new_timer(), "nvim-lint: failed to create debounce timer")
            local pending = {} ---@type table<integer, boolean>

            local function has_config(name, filename)
                local markers = CONFIG_MARKERS[name]
                if markers == true then
                    return true
                end
                if type(markers) ~= "table" or filename == "" then
                    return false
                end
                local dir = vim.fn.fnamemodify(filename, ":p:h")
                return vim.fs.find(markers, { path = dir, upward = true })[1] ~= nil
            end

            --- Ensure the linter binary exists, auto-installing via mason.
            --- Returns true when the binary is ready to run now.
            local function binary_ready(name, cmd)
                if vim.fn.executable(cmd) == 1 then
                    return true
                end
                local pkg = MASON_PKG[name]
                if not pkg or installing[pkg] then
                    return false
                end
                local ok, mr = pcall(require, "mason-registry")
                if not ok then
                    return false
                end
                local ok_pkg, package = pcall(mr.get_package, pkg)
                if not ok_pkg or package:is_installed() then
                    return false
                end
                -- One-shot async install; the `package:install:success`
                -- handler below re-lints the buffer once it lands.
                installing[pkg] = true
                LazyVim.info(("Installing linter `%s` via mason..."):format(pkg), { title = "nvim-lint" })
                package:install(nil, function(success, _)
                    installing[pkg] = nil
                    if success then
                        LazyVim.info(("Linter `%s` installed."):format(pkg), { title = "nvim-lint" })
                    else
                        LazyVim.error(("Failed to install linter `%s`."):format(pkg), { title = "nvim-lint" })
                    end
                end)
                return false
            end

            local function should_skip(bufnr)
                -- Non-normal buffers (terminal, prompt, nofile like oil/
                -- scratch), unlisted, unloaded, unnamed, or huge: never lint.
                if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
                    return true
                end
                if not vim.bo[bufnr].buflisted or vim.bo[bufnr].buftype ~= "" then
                    return true
                end
                local name = vim.api.nvim_buf_get_name(bufnr)
                if name == "" then
                    return true
                end
                local ok, stat = pcall(vim.uv.fs_stat, name)
                if ok and stat and stat.size and stat.size > MAX_BYTES then
                    return true
                end
                if vim.bo[bufnr].filetype == "" then
                    return true
                end
                return false
            end

            local function lint_buffer(bufnr)
                bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
                if should_skip(bufnr) then
                    return
                end
                local ft = vim.bo[bufnr].filetype
                local filename = vim.api.nvim_buf_get_name(bufnr)
                local ctx = { filename = filename }
                ctx.dirname = vim.fn.fnamemodify(filename, ":h")
                local names = vim.iter(lint._resolve_linter_by_ft(ft))
                    :filter(function(name)
                        local linter = lint.linters[name]
                        if not linter then
                            LazyVim.warn("Linter not found: " .. name, { title = "nvim-lint" })
                            return false
                        end
                        if type(linter) == "table" and linter.condition and not linter.condition(ctx) then
                            return false
                        end
                        -- Rule 2: config-gated. Skip silently when the project
                        -- has no config file for this linter.
                        if not has_config(name, filename) then
                            return false
                        end
                        -- Rule 1: auto-install missing binaries via mason.
                        local cmd = type(linter.cmd) == "string" and linter.cmd or name
                        -- oxlint def uses a cmd FUNCTION (prefers local
                        -- node_modules/.bin); resolve to a plain binary check.
                        if type(cmd) ~= "string" then
                            cmd = "oxlint"
                        end
                        return binary_ready(name, cmd)
                    end)
                    :totable()
                if #names == 0 then
                    return
                end
                -- Pin execution to the EVENT buffer, not "current" at fire time.
                -- try_lint cancels the previous same-name proc for this buffer
                -- (SIGINT -> SIGKILL escalation lives upstream in LintProc).
                local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
                    lint.try_lint(names, { ignore_errors = true })
                end)
                if not ok then
                    LazyVim.error(("nvim-lint failed for buffer %d: %s"):format(bufnr, err), { title = "nvim-lint" })
                    return
                end
                -- Watchdog: free the per-buffer proc slot if a linter hangs
                -- past TIMEOUT_MS so the next event can never deadlock on it.
                vim.defer_fn(function()
                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        return
                    end
                    local running = lint.get_running(bufnr)
                    if #running > 0 then
                        pcall(vim.api.nvim_buf_call, bufnr, function()
                            lint.try_lint(running, { ignore_errors = true })
                        end)
                    end
                end, TIMEOUT_MS + 5000)
            end

            local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
            -- Rule 3: on SAVE only. BufWritePost fires after the file hits
            -- disk, so file-mode linters (golangcilint, oxlint, shellcheck
            -- on saved files) always see fresh content.
            vim.api.nvim_create_autocmd("BufWritePost", {
                group = group,
                callback = function(args)
                    pending[args.buf] = true
                    timer:start(DEBOUNCE_MS, 0, function()
                        timer:stop()
                        vim.schedule(function()
                            for bufnr in pairs(pending) do
                                pending[bufnr] = nil
                                lint_buffer(bufnr)
                            end
                        end)
                    end)
                end,
            })
            -- Re-lint buffers whose linter just finished installing.
            local ok_mr, mr = pcall(require, "mason-registry")
            if ok_mr then
                mr:on("package:install:success", function(pkg)
                    vim.schedule(function()
                        vim.iter(vim.api.nvim_list_bufs())
                            :filter(function(bufnr)
                                return vim.api.nvim_buf_is_valid(bufnr)
                                    and vim.bo[bufnr].buflisted
                                    and vim.bo[bufnr].filetype ~= ""
                            end)
                            :filter(function(bufnr)
                                return vim.iter(lint._resolve_linter_by_ft(vim.bo[bufnr].filetype)):any(function(name)
                                    return MASON_PKG[name] == pkg.name
                                end)
                            end)
                            :each(lint_buffer)
                    end)
                end)
            end
            -- Housekeeping: clear diagnostics of wiped buffers so stale
            -- signs never linger, and drop any pending flag for them.
            vim.api.nvim_create_autocmd("BufWipeout", {
                group = group,
                callback = function(args)
                    pending[args.buf] = nil
                    vim.diagnostic.reset(nil, args.buf)
                end,
            })
        end,
    },
}
