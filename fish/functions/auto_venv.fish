function auto_venv --on-variable PWD
    set -l dir $PWD
    set -l project_root ""

    while test "$dir" != /srv
        if test -f "$dir/pyproject.toml"
            set project_root $dir
            break
        end
        set dir (dirname $dir)
    end

    if set -q VIRTUAL_ENV
        if test -z "$project_root" -o "$project_root" != "$AUTO_VENV_ROOT"
            if functions -q deactivate
                deactivate 2>/dev/null
            end
            set -e AUTO_VENV_ROOT
            set -e AUTO_VENV_SYNCED
        end
    end

    if test -z "$project_root"
        return
    end

    if set -q AUTO_VENV_ROOT
        if test "$AUTO_VENV_ROOT" = "$project_root"
            return
        end
    end

    if test -f "$project_root/.python-version"
        set -gx PYTHON_VERSION (cat "$project_root/.python-version")
    end

    if test -f "$project_root/.venv/bin/activate.fish"
        source "$project_root/.venv/bin/activate.fish"
        set -gx AUTO_VENV_ROOT $project_root
        return
    end

    if command -q uv
        if not test -d "$project_root/.venv"
            if not set -q AUTO_VENV_SYNCED
                echo "Creating virtual environment with uv..."
                env -C "$project_root" uv sync
                set -g AUTO_VENV_SYNCED 1
            end
        end
        if test -f "$project_root/.venv/bin/activate.fish"
            source "$project_root/.venv/bin/activate.fish"
            set -gx AUTO_VENV_ROOT $project_root
            return
        end
    end

    if test -f "$project_root/poetry.lock"
        if command -q poetry
            set -l poetry_venv (poetry env info --path 2>/dev/null)
            if test -n "$poetry_venv" -a -f "$poetry_venv/bin/activate.fish"
                source "$poetry_venv/bin/activate.fish"
                set -gx AUTO_VENV_ROOT $project_root
                return
            end
        end
    end

    if test -f "$project_root/venv/bin/activate.fish"
        source "$project_root/venv/bin/activate.fish"
        set -gx AUTO_VENV_ROOT $project_root
        return
    end
end
