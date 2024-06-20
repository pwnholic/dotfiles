require("utils.lsp").start({
	cmd = { "vscode-solidity-server", "--stdio" },
	name = "solidity_ls",
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
})
