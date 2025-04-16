local config = [[
BasedOnStyle: LLVM
AccessModifierOffset: -4
AlignAfterOpenBracket: Align
AlignConsecutiveMacros: true
AlignConsecutiveAssignments: true
AlignConsecutiveDeclarations: true
AlignEscapedNewlines: Right
AlignOperands: true
AlignTrailingComments: true
AllowAllArgumentsOnNextLine: false
AllowAllConstructorInitializersOnNextLine: false
AllowAllParametersOfDeclarationOnNextLine: false
AllowShortBlocksOnASingleLine: Never
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: None
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false
AlwaysBreakAfterReturnType: None
AlwaysBreakBeforeMultilineStrings: false
AlwaysBreakTemplateDeclarations: Yes
BinPackArguments: false
BinPackParameters: false
BraceWrapping:
  AfterCaseLabel: false
  AfterClass: true
  AfterControlStatement: Never
  AfterEnum: true
  AfterFunction: true
  AfterNamespace: true
  AfterObjCDeclaration: true
  AfterStruct: false
  AfterUnion: true
  BeforeCatch: true
  BeforeElse: true
  IndentBraces: false
  SplitEmptyFunction: true
  SplitEmptyRecord: true
  SplitEmptyNamespace: true
BreakBeforeBinaryOperators: NonAssignment
BreakBeforeBraces: Custom
BreakBeforeTernaryOperators: true
BreakConstructorInitializers: BeforeComma
BreakInheritanceList: BeforeComma
BreakStringLiterals: true
ColumnLimit: 80
CompactNamespaces: false
ConstructorInitializerIndentWidth: 4
ContinuationIndentWidth: 4
Cpp11BracedListStyle: true
DerivePointerAlignment: false
FixNamespaceComments: true
IncludeBlocks: Regroup
IncludeCategories:
  - Regex: '^<.*\.h>'
    Priority: 1
  - Regex: "^<.*"
    Priority: 2
  - Regex: ".*"
    Priority: 3
IndentCaseLabels: true
IndentPPDirectives: AfterHash
IndentWidth: 4
KeepEmptyLinesAtTheStartOfBlocks: false
MaxEmptyLinesToKeep: 1
NamespaceIndentation: All
PointerAlignment: Right
ReflowComments: true
SortIncludes: true
SortUsingDeclarations: true
SpaceAfterCStyleCast: true
SpaceAfterLogicalNot: false
SpaceAfterTemplateKeyword: true
SpaceBeforeAssignmentOperators: true
SpaceBeforeCpp11BracedList: true
SpaceBeforeCtorInitializerColon: true
SpaceBeforeInheritanceColon: true
SpaceBeforeParens: ControlStatements
SpaceBeforeRangeBasedForLoopColon: true
SpaceInEmptyParentheses: false
SpacesBeforeTrailingComments: 1
SpacesInAngles: false
SpacesInContainerLiterals: false
SpacesInCStyleCastParentheses: false
SpacesInParentheses: false
SpacesInSquareBrackets: false
Standard: Latest
TabWidth: 4
UseTab: Never
]]

local filename = ".clang-format"
local filepath = vim.fs.joinpath(vim.uv.cwd(), filename)

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
