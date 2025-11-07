return {
    "yetone/avante.nvim",
    opts = {
        provider = "claude-code",
        auto_suggestions_provider = "glm",
        providers = {
            glm = {
                __inherited_from = "openai",
                endpoint = "https://api.z.ai/api/anthropic",
                model = "glm-4.6",
                timeout = 30000,
                api_key_name = os.getenv("ANTHROPIC_AUTH_TOKEN"),
                extra_request_body = {
                    temperature = 0.7,
                    max_tokens = 20480,
                },
            },
        },
        acp_providers = {
            ["claude-code"] = {
                command = "claude-code-acp",
                args = {},
                env = {
                    NODE_NO_WARNINGS = "1",
                    ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic",
                    ANTHROPIC_AUTH_TOKEN = os.getenv("ANTHROPIC_AUTH_TOKEN"),
                },
                timeout = 20000,
            },
        },
        session_recovery = {
            enabled = true,
            max_history_messages = 20,
            max_message_length = 1000,
            include_history_count = 15,
            truncate_history = true,
        },
        debug = false,
        behaviour = {
            auto_suggestions = false,
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = false,
            support_paste_from_clipboard = false,
            minimize_diff = true,
        },
        windows = {
            position = "right",
            wrap = true,
            width = 30,
            sidebar_header = {
                enabled = true,
                align = "center",
                rounded = true,
            },
            input = {
                prefix = "",
                height = 8,
            },
            edit = {
                border = "rounded",
                start_insert = true,
            },
            ask = {
                floating = false,
                start_insert = true,
                border = "rounded",
                focus_on_apply = "ours",
            },
        },
        selection = {
            enabled = true,
            hint_display = "delayed",
        },
        instructions_file = "AGENTS.md",
        input = {
            provider = "snacks",
            provider_opts = {},
        },
        selector = {
            provider = "snacks",
            provider_opts = {},
        },
    },
}
