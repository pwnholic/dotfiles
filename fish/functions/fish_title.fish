# Overrides the vendor fish_title (part of fish-pure-prompt) which references
# Pure-specific variables and breaks once those universals are removed. This
# user function wins because ~/.config/fish/functions is first in
# $fish_function_path.
function fish_title
    set -l current_folder (prompt_pwd)
    set -l current_command (status current-command 2>/dev/null; or echo $_)[1]
    if test -n "$argv[1]"
        echo "$current_folder: $argv[1]"
    else
        echo "$current_folder: $current_command"
    end
end