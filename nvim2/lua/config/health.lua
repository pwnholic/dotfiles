--- `:checkhealth config` entry point.
---
--- `:checkhealth <name>` resolves `lua/**/<name>/health.lua`, so this file must
--- exist at `lua/config/health.lua`. The implementation lives in `core.health`.
return require("core.health")
