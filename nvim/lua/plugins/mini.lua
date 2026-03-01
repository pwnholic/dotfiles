return {
    {
        "nvim-mini/mini-git",
        version = false,
        cmd = "Git",
        config = function()
            require("mini.git").setup({
                job = { git_executable = "git", timeout = 30000 },
                command = { split = "auto" },
            })
        end,
    },
    {
        "nvim-mini/mini.hipatterns",
        opts = function()
            local hi = require("mini.hipatterns")

            return {
                highlighters = {
                    url = {
                        pattern = "()https?://[%w_%-%.~:/?#%[%]@!$&'%(%)%*%+,;=%%]+()",
                        group = "@markup.link.url",
                    },
                    env_var = {
                        pattern = function(buf_id)
                            local ft = vim.bo[buf_id].filetype
                            if not vim.tbl_contains({ "sh", "bash", "zsh", "dockerfile", "makefile" }, ft) then
                                return nil
                            end
                            return "%$%{?()[%w_]+()%}?"
                        end,
                        group = "@constant",
                    },
                    trailing_whitespace = {
                        pattern = "%S+()%s+()$",
                        group = "MiniHipatternsFixme",
                    },
                    -- Tag key: json, gorm, db, validate, xml, yaml, mapstructure, etc.
                    go_tag_key = {
                        pattern = function(buf_id)
                            if vim.bo[buf_id].filetype ~= "go" then
                                return nil
                            end
                            return "()[%w_%.%-]+():"
                        end,
                        group = function(_, match)
                            local found = vim.iter({
                                "json",
                                "yaml",
                                "xml",
                                "toml",
                                "csv",
                                "db",
                                "gorm",
                                "sql",
                                "sqlx",
                                "bun",
                                "validate",
                                "binding",
                                "mapstructure",
                                "envconfig",
                                "env",
                                "bson",
                                "dynamodb",
                                "firestore",
                                "form",
                                "query",
                                "param",
                                "header",
                                "uri",
                                "msgpack",
                                "protobuf",
                                "avro",
                                "redis",
                                "cache",
                                "comment",
                                "example",
                                "doc",
                                "default",
                                "required",
                                "swaggertype",
                                "enums",
                                "extensions",
                            }):any(function(tag)
                                return tag == match
                            end)
                            return found and "@attribute" or nil
                        end,
                    },
                    hex_color = hi.gen_highlighter.hex_color(),
                },
            }
        end,
    },
}
