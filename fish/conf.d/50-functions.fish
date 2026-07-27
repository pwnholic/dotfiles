# Convenience commands, defined as plain fish functions (NO `alias`, NO `abbr`).
# Interactive only, so non-interactive fish scripts keep using the real
# binaries. Edit or remove freely.

if status is-interactive
    # --- Listing (eza, with fallback to system ls) ------------------------
    # eza is the preferred lister; if it is ever unavailable the wrappers
    # fall back to the system `ls` so the core command never breaks.
    if type -q eza
        function ls -d "List with eza (dirs first, auto icons)"
            eza --group-directories-first --icons=auto $argv
        end
        function ll -d "Long listing with eza"
            eza -l --group-directories-first --icons=auto --git $argv
        end
        function la -d "All entries, long, with eza"
            eza -la --group-directories-first --icons=auto --git $argv
        end
        function lt -d "Tree listing (depth 2) with eza"
            eza --tree --level=2 --group-directories-first --icons=auto $argv
        end
    else
        function ls -d "List directory contents"
            command ls --color=auto $argv
        end
        function ll -d "Long listing"
            command ls -l --color=auto $argv
        end
        function la -d "All entries, long"
            command ls -la --color=auto $argv
        end
        function lt -d "Recursive listing"
            command ls -R --color=auto $argv
        end
    end

    # --- Navigation --------------------------------------------------------
    function .. -d "cd up one directory"
        builtin cd ..
    end
    function ... -d "cd up two directories"
        builtin cd ../..
    end
    function .... -d "cd up three directories"
        builtin cd ../../..
    end

    # --- Misc --------------------------------------------------------------
    function mkcd -d "mkdir -p <dir> and cd into it"
        if test (count $argv) -ne 1
            echo "usage: mkcd <dir>" >&2
            return 1
        end
        mkdir -p $argv[1]; and builtin cd $argv[1]
    end
end
