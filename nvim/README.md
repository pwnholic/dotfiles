# My Personal Neovim setup

I call my setup is **Remok Dev** dont expect to much with this ~~sh\*it~~

# Requirement

- Neovim nightly (**it a must!!!**)
- fzf
- rg
- fd
- gcc (needed for some plugins e.g treesiter, luasnip...)
- Nerd font (i use **Iosevka Nerd Font**)
- python3
- pip
- node
- npm or yarn
- git

---

# How looks like

- ## **Ducking lightweight as _always_**

This run on my old laptop **Dell Inspiron 14-3462 1.15.0** with this spec :
Disk (/): 270G / 465G (59%)

> WM: i3
>
> Memory: **953MiB / 3731MiB**
>
> CPU: **Intel Celeron N3350 (2) @ 2.400GHz**

![dashboard](https://github.com/lilwigy/nvim/assets/156510600/268867b6-24d1-43ea-8e38-19bc357be0e4)
![[oil](https://github.com/lilwigy/nvim/assets/156510600/e1d54054-eaf7-4a60-87fd-3f9bd093ea57)

- ## Fuzzy finder with fzf-lua
  ![fzf](https://github.com/lilwigy/nvim/assets/156510600/89959324-a41b-4a65-aeff-2ef56ebe62bf)
- ## Language server and Completion
  ![lsp_and_cmp](https://github.com/lilwigy/nvim/assets/156510600/de034837-78d5-471f-b107-e478e1e5b8dc)
- ## Debugger
  ![debugger](https://github.com/lilwigy/nvim/assets/156510600/0f614d62-b777-4645-862a-9ea200fbfdb1)
- ## Tester
  ![testing](https://github.com/lilwigy/nvim/assets/156510600/eccbea75-4c91-4480-9626-5e173a2c774a)
- ## Linter and more...
  ![linter](https://github.com/lilwigy/nvim/assets/156510600/f3a06373-dcdb-4a1d-9e5c-b20853f78285)

---

# CLOC

| Language | files | blank | comment | code |
| -------- | ----- | ----- | ------- | ---- |
| Lua      | 29    | 307   | 186     | 6445 |
| JSON     | 11    | 1     | 0       | 909  |
| Markdown | 1     | 15    | 0       | 48   |
| Scheme   | 4     | 14    | 14      | 23   |
| TOML     | 2     | 2     | 0       | 15   |
| SUM:     | 47    | 339   | 200     | 7440 |

# TODO

- fix code action for range
- fix this `is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)kdiff)?$'"`
