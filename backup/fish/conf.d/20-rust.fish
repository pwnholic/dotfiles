# Rust toolchain (rustup + cargo).

# Defaults made explicit so the config is self-contained even when the
# rustup profile.d snippet (used by bash/zsh, not sourced by fish) is absent.
set -gx RUSTUP_HOME $HOME/.local/share/rustup
set -gx CARGO_HOME $HOME/.local/share/cargo

# Cargo binaries: cargo, rustc, rustup, rust-gdb, and any `cargo install` bin.
fish_add_path --path $CARGO_HOME/bin
