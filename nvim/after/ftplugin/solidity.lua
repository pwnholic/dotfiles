require("utils.lsp").start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/vscode-solidity-server", "--stdio" },
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
})