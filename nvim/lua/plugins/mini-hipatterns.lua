return {
    "echasnovski/mini.hipatterns",
    opts = {
        highlighters = {
            json = { pattern = [[json%s*:%s*]], group = "MiniHipatternsJson" },
            gorm = { pattern = [[gorm%s*:%s*]], group = "MiniHipatternsGorm" },
            validate = { pattern = [[validate%s*:%s*]], group = "MiniHipatternsValidate" },
            binding = { pattern = [[binding%s*:%s*]], group = "MiniHipatternsBinding" },
        },
    },
}
