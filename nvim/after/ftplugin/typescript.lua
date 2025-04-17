local config = [[
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "quoteProps": "consistent",
  "jsxSingleQuote": false,
  "trailingComma": "all",
  "bracketSpacing": true,
  "bracketSameLine": false,
  "arrowParens": "always",
  "proseWrap": "always",
  "htmlWhitespaceSensitivity": "css", 
  "endOfLine": "lf",
  "singleAttributePerLine": true,  
  "overrides": [
    {
      "files": ["*.ts", "*.tsx"],
      "options": {
        "parser": "typescript"
      }
    }
  ]
}
]]

local filename = ".prettierrc"
local filepath = vim.fs.joinpath(LazyVim.root(), filename)

if not vim.uv.fs_stat(filepath) then
    local fd = assert(vim.uv.fs_open(filepath, "w", 438)) -- 'w' = write mode, 438 = permission 0666
    assert(vim.uv.fs_write(fd, config))
    vim.notify(
        string.format("Missing file [%s] and the new one has been generated", filename),
        2,
        { title = "New File" }
    )
    vim.uv.fs_close(fd)
end
