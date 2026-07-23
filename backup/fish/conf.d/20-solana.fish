# Solana / Anchor toolchain.
#
# Solana CLI install:
#   sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
#   -> binary lands in ~/.local/share/solana/install/active_release/bin
# Anchor (via AVM):
#   cargo install --git https://github.com/coral-xyz/anchor avm --force
#   then:  avm install <version>  &&  avm use <version>
#   -> the `anchor` shim lands in ~/.avm/bin

# Solana CLI: solana, solana-test-validator, cargo-build-sbf, etc.
fish_add_path --path $HOME/.local/share/solana/install/active_release/bin

# Anchor version manager (avm) shim directory.
fish_add_path --path $HOME/.local/share/avm/bin
