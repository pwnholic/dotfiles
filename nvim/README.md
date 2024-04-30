# Todo

<!--toc:start-->

- fix obsidian
- Yang teliti bro

<!--toc:end-->

```lua
local sname = entry.source.name

if sname == "rg" then
    item.kind = "RipGrep"
elseif sname == "cmp_yanky" then
    item.kind = "Yanky"
elseif sname == "calc" then
    item.kind = "Calc"
elseif sname = "obsidian" then
    item.kind = "Obs"
elseif sname = "obsidian_new" then
    item.kind = "ObsNew"
elseif sname = "obsidian_tags" then
    item.kind = "ObsTags"
end



```
