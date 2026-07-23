# Python via uv (already on the system PATH).
# Chosen over pyenv/pipx: a single fast Rust tool covering Python installs,
# venvs and packages. uv also manages interpreter versions
# (`uv python install`), so pyenv is unnecessary.

# uv stores caches/data under XDG dirs by default; nothing else to set.
# Uncomment to prefer uv-managed Python over the system interpreter:
# set -gx UV_PYTHON_PREFERENCE managed
