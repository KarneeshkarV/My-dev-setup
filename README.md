# myDev-setup

Personal Linux bootstrap and GNU Stow dotfiles.

Works on Arch (Omarchy included) and Debian/Ubuntu.

## Install tools

`runs/` holds one installer per tool.
`run.sh` runs every executable in that directory, or only paths that match a filter.

```bash
./run.sh --dry          # print, do not run
./run.sh                # run all
./run.sh docker         # run only scripts whose path contains "docker"
```

`aafirst.sh` updates the system.
Its name sorts first so a full run starts there.

A full `./run.sh` also runs `porn-block.sh` (pins DNS to Cloudflare for Families) and `neovim.sh` (deletes `~/.config/nvim` then builds Neovim from source).
Filter if you do not want those.

## Stow configs

`dev.sh` links packages from `stow/` into `$HOME`.
Install GNU Stow first with `./runs/stow.sh`.

```bash
./dev.sh -l             # list packages
./dev.sh --dry          # preview
./dev.sh                # stow all
./dev.sh zsh git        # stow named packages
./dev.sh -r zsh         # restow
./dev.sh -u tmux        # unstow
```

## Layout

| Path | What it is |
| --- | --- |
| `runs/` | Installers: zsh, tmux, neovim, docker, node, python, rust, go, CLI tools, agent CLIs (claude, codex, opencode, pi, grok) |
| `stow/` | Packages: agents, ghostty, git, i3, polybar, rofi, tmux, zsh, scripts |
| `lib/distro-utils.sh` | pacman/yay vs apt |
| `backup/` | Exported package lists from `runs/backup.sh` |
| `non_essential/` | CUDA and Zephyr, not part of `run.sh` |
