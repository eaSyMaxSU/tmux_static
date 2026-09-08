tmux 3.7c for Linux x86_64, built from source in Docker through Arch Linux WSL and tested against stock Rocky Linux 9.3 userland.

- Fully static PIE: includes musl, libevent 2.1.12, and ncurses 6.6. No dynamic loader or shared-library dependencies.
- Embeds 24 common terminal descriptions, including xterm-256color, tmux-256color, Kitty, Ghostty, and Windows Terminal aliases.
- Baseline x86_64 CPU target; no root access or package installation required on the server.
- Passed interactive startup, UTF-8 output, split panes, resize, keyboard detach, and reattach for all 24 terminal names, both with stock terminfo and with system terminfo directories hidden. Tests ran as UID 65534 in Docker on the WSL host kernel.

Download the `.tar.gz` and `SHA256SUMS`, then:

```sh
sha256sum --ignore-missing -c SHA256SUMS
tar -xzf tmux-3.7c-linux-x86_64-static.tar.gz
mkdir -p "$HOME/.local/bin"
install -m 755 tmux "$HOME/.local/bin/tmux"
export PATH="$HOME/.local/bin:$PATH"
tmux new -s work
```

The tarball includes the binary, dependency license notices, manual page, build metadata, and test reports. The standalone binary is also attached; use `chmod +x tmux-3.7c-linux-x86_64-static` before running it.

Programs launched inside tmux still need their own runtime dependencies and terminal descriptions. See the README for terminal configuration and build instructions. This is a community build, not an official upstream tmux artifact.
