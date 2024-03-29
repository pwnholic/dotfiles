local map = vim.keymap.set

map("n", "<leader>jm", "<cmd>PhpMethod<cr>", { desc = "Generate Undefined Method" })
map("n", "<leader>jc", "<cmd>PhpClass<cr>", { desc = "Generate Undefined `class, trait, interface, enums`" })
map("n", "<leader>js", "<cmd>PhpScripts<cr>", { desc = "Run Composer Script" })
map("n", "<leader>jn", "<cmd>PhpNamespace<cr>", { desc = "Generates Namespace for the File" })
map("n", "<leader>jg", "<cmd>PhpGetSet<cr>", { desc = "Generates Getter Setter or Both on Cursor" })
map("n", "<leader>jf", "<cmd>PhpCreate<cr>", { desc = "Create Class, Interface, Enum, or Trait" })
map("v", "<leader>jr", "<cmd>PhpArtisan<cr>", { desc = "Inline Selected Text to function/method" })
