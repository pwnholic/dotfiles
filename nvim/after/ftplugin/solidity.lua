require("utils.lsp").start({
	cmd = { "vscode-solidity-server", "--stdio" },
	root_patterns = {
		"hardhat.config.js",
		"hardhat.config.ts",
		"foundry.toml",
		"remappings.txt",
		"truffle.js",
		"truffle-config.js",
		"ape-config.yaml",
		".git",
		"package.json",
	},
	filetypes = { "solidity" },
	settings = {
		solidity = {
			compileUsingRemoteVersion = "latest",
			packageDefaultDependenciesContractsDirectory = "",
			enabledAsYouTypeCompilationErrorCheck = true,
			validationDelay = 1500,
			packageDefaultDependenciesDirectory = { "node_modules", "lib" },
			-- remappings = {
			-- 	"@chainlink/=/Users/patrick/.brownie/packages/smartcontractkit/chainlink-brownie-contracts@0.2.2",
			-- 	"@openzeppelin/=/Users/patrick/.brownie/packages/OpenZeppelin/openzeppelin-contracts@4.3.2",
			-- },
			linter = "solhint",
			solhintRules = {
				["avoid-sha3"] = "warn",
			},
		},
	},
})
