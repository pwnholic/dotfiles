# General environment: XDG base dirs, editor, pager, and sane defaults.

# XDG Base Directory
# Pin the base dirs explicitly so every tool keeps its config/cache/data
# under ~/.config, ~/.cache, ~/.local/share, ~/.local/state.
# XDG_RUNTIME_DIR is owned by systemd -- never override it here.
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state

# Editor / pager
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT "-c"
end
set -gx LESS "-R"          # allow ANSI color escape codes in less
set -gx LESSHISTFILE "-"   # do not write a ~/.lesshst file
set -gx BAT_THEME "TwoDark"

# Neovim runtime
# nvim locates its own runtime by default; pin VIMRUNTIME when the bundled
# runtime exists so tools that read it see a stable path.
if test -d /usr/share/nvim/runtime; and not set -q VIMRUNTIME
    set -gx VIMRUNTIME /usr/share/nvim/runtime
end

# npm
set -gx NPM_CONFIG_FUND false
set -gx npm_config_cache $XDG_CACHE_HOME/npm

set -gx CLINE_API_KEY sk_344098fac355dfa667a5e56f8f1ffda19c7bb9e9a7c22160f8fade476127b5d6

set -gx CRG_EMBEDDING_MODEL Alibaba-NLP/UEmbed-2B
set -gx CRG_RECURSE_SUBMODULES true
set -gx CRG_TOOLS build_or_update_graph_tool,run_postprocess_tool,get_minimal_context_tool,get_impact_radius_tool,get_review_context_tool,query_graph_tool,traverse_graph_tool,semantic_search_nodes_tool,embed_graph_tool,list_graph_stats_tool,get_docs_section_tool,find_large_functions_tool,list_flows_tool,get_flow_tool,get_affected_flows_tool,list_communities_tool,get_community_tool,get_architecture_overview_tool,detect_changes_tool,get_hub_nodes_tool,get_bridge_nodes_tool,get_knowledge_gaps_tool,get_surprising_connections_tool,get_suggested_questions_tool,refactor_tool,apply_refactor_tool,generate_wiki_tool,get_wiki_page_tool,list_repos_tool,cross_repo_search_tool
