require("utils.lsp").start({
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/phpactor", "language-server" },
    name = "phpactor",
    filetypes = { "php" },
    root_patterns = { "composer.json", ".phpactor.json", ".phpactor.yml" },
    init_options = {
        ["language_server_worse_reflection.inlay_hints.types"] = true,
        ["language_server_code_transform.import_globals"] = true,
        ["completion_worse.experimantal"] = true,
        ["language_server_worse_reflection.inlay_hints.enable"] = true,
    },
})
