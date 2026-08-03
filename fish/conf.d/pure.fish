# Shadows /usr/share/fish/vendor_conf.d/pure.fish (package fish-pure-prompt).
#
# The vendor Pure prompt is installed system-wide but we use starship, and
# Pure's conf.d pollutes $fish_user_paths / universal variables with ~70
# `pure_*` entries on every startup. Fish executes only the FIRST conf.d file
# with a given name (user config wins over vendor dirs), so an empty file
# here disables the vendor one without needing sudo to remove the package.
#
# Remove this file (and _pure_init.fish) to re-enable Pure, or
#   sudo pacman -R fish-pure-prompt