# User-local executables. `fish_add_path --path` prepends to PATH for this
# session only (no universal-variable drift), deduplicates, and silently
# skips directories that do not exist yet -- so tools not installed yet are
# picked up automatically once their install directory appears.

# General user-local binaries (standalone CLIs, manual installs, etc.).
fish_add_path --path $HOME/.local/bin

# pi coding agent.
fish_add_path --path $HOME/.pi/agent/bin

# Neovim LSP servers / DAP / formatters installed via mason.
fish_add_path --path $HOME/.local/share/nvim/mason/bin

# Foundry (Ethereum dev toolchain).
fish_add_path --path $HOME/.foundry/bin

# pdtm (ProjectDiscovery tool manager) Go binaries.
fish_add_path --path $HOME/.pdtm/go/bin

fish_add_path --path $HOME/.local/share/solana/install/active_release/bin
