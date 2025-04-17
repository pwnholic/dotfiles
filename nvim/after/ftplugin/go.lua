local config = [=[
version: "2"

run:
  skip-dirs:
    - vendor
    - testdata
    - mocks
    - mock
    - internal/mock
    - assets
    - docs
    - scripts
    - third_party
    - generated
  skip-dirs-use-default: false

issues:
  max-same-issues: 50

formatters:
  enable:
    - goimports
    - golines

  settings:
    goimports:
      local-prefixes:
        - github.com/my/project
    golines:
      max-len: 120

linters:
  enable:
    # Essential reliability checks
    - bodyclose
    - errcheck
    - errname
    - errorlint
    - govet
    - ineffassign
    - nilerr
    - noctx
    - rowserrcheck
    - sqlclosecheck
    - staticcheck
    - unused

    # Code quality
    - copyloopvar
    - cyclop
    - exhaustruct
    - exhaustive
    - gocognit
    - gocritic
    - gocyclo
    - iface
    - makezero
    - musttag
    - nestif
    - predeclared
    - revive
    - unconvert
    - unparam

    # Security
    - gosec

    # Modern Go features
    - sloglint
    - usestdlibvars

    # Testing
    - testifylint
    - tparallel

  settings:
    cyclop:
      max-complexity: 20
      package-average: 8.0

    depguard:
      rules:
        "deprecated":
          files: ["$all"]
          deny:
            - pkg: github.com/golang/protobuf
              desc: Use google.golang.org/protobuf instead
            - pkg: github.com/satori/go.uuid
              desc: Use github.com/google/uuid instead
            - pkg: math/rand$
              desc: Use math/rand/v2 instead

    errcheck:
      check-type-assertions: true

    exhaustive:
      check: [switch, map]

    exhaustruct:
      exclude:
        - ^net/http
        - ^os/exec.Cmd$
        - ^reflect.StructField$
        - ^github.com/stretchr/testify/mock.Mock$

    funlen:
      lines: 80
      statements: 50

    gocognit:
      min-complexity: 15

    gocritic:
      settings:
        hugeParam: {min-len: 40}
        rangeValCopy: {sizeThreshold: 32}
        unnamedResult: {checkExported: true}

    govet:
      enable-all: true
      disable:
        - fieldalignment
      settings:
        shadow: {strict: true}

    revive:
      confidence: 0.8
      rules:
        - name: blank-imports
        - name: context-as-argument
        - name: context-keys-type
        - name: dot-imports
        - name: error-return
        - name: error-strings
        - name: exported
          arguments: [["only-typed"]]
        - name: indent-error-flow
        - name: package-comments
        - name: range
        - name: receiver-naming
        - name: time-naming
        - name: var-naming
        - name: var-declaration

    sloglint:
      no-global: "default"
      context: "scope"
      msg-format: "raw"

    staticcheck:
      checks:
        - all
        - -ST1000  # Incorrect or missing package comment
        - -ST1016  # Receiver naming
        - -ST1020  # Comment formatting
        - -ST1021  # Comment formatting
        - -ST1022  # Comment formatting

  exclusions:
    warn-unused: true
    presets:
      - std-error-handling
    rules:
      - path: _test\.go$
        linters:
          - funlen
          - gocognit
          - gocyclo
      - text: "Error return value of .* is not checked"
        linters:
          - errcheck
        path: _test\.go$
      - text: "exported .* should have comment"
        linters:
          - revive
]=]

local filename = ".golangci.yml"
local filepath = vim.fs.joinpath(LazyVim.root(), filename)
if vim.fs.root(LazyVim.root(), { "go.mod", "main.go", ".git" }) ~= nil then
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
end
