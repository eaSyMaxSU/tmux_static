# Static tmux for Rocky Linux 9 (x86_64)

tmux **3.7c**, built from upstream source with **ncurses 6.6**,
**libevent 2.1.12**, and Alpine's **musl 1.2.5** C runtime statically linked.
No ncurses, libevent, musl, or glibc shared libraries need to be installed for
this binary. Targets baseline x86_64 CPUs (no `-march=native`).

## Install without root

Download the tarball and `SHA256SUMS` from
[GitHub Releases](https://github.com/eaSyMaxSU/tmux_static/releases).
On the Rocky Linux server:

```sh
sha256sum --ignore-missing -c SHA256SUMS
tar -xzf tmux-3.7c-linux-x86_64-static.tar.gz
mkdir -p "$HOME/.local/bin"
install -m 755 tmux "$HOME/.local/bin/tmux"
export PATH="$HOME/.local/bin:$PATH"
tmux -V
tmux new -s work
```

Add the `export PATH=...` line to `~/.bashrc` to keep it across logins.
Detach with **Ctrl-b**, then **d**; return with `tmux attach -t work`.
Alternatively download the standalone `tmux-3.7c-linux-x86_64-static` asset,
make it executable, and run it directly. The tarball includes dependency
license notices, the manual page, build metadata, and test reports.

## Terminal support

Common terminal descriptions are compiled into ncurses, so tmux can start
without the server's terminfo database. Embedded terminal names:

```text
xterm xterm-256color xterm-direct
screen screen-256color tmux tmux-256color
linux vt100 vt220 rxvt rxvt-256color putty putty-256color
alacritty alacritty-direct foot foot-direct
xterm-kitty xterm-ghostty ghostty wezterm ms-terminal ms-terminal-direct
```

`xterm-kitty` and `xterm-ghostty` are aliases for ncurses' `kitty` and `ghostty`
entries. Normal system/user terminfo entries take precedence over fallbacks.
For an unsupported `$TERM`, install its terminfo entry or, if your terminal
supports xterm sequences, launch with `TERM=xterm-256color tmux`.

The embedded database is available to this tmux binary. Programs launched
inside tmux still use their own libraries and terminfo. If an application
reports an unknown `tmux-256color` terminal, use an installed description in
`~/.tmux.conf`, for example `set -g default-terminal "screen-256color"`, then
create a new window. External commands such as `vlock` and clipboard tools
are separate programs and are not bundled.

## Build in Arch Linux WSL

Requires Docker, curl, tar, and standard shell utilities. From this directory
in PowerShell:

```powershell
wsl -d archlinux -u root -- sh ./build.sh
```

Or on Linux with Docker access: `sh ./build.sh`.
The Alpine build runs inside Docker; it does not install build dependencies
into Arch. Downloads are pinned by SHA-256 in `sources.sha256`, and container
base images are pinned by digest. Alpine package versions are recorded in
`BUILD-INFO.txt`; APK repositories are not snapshotted, so future rebuilds are
not guaranteed to be byte-identical.

Artifacts are written to `dist/`; the full build log is in `logs/build.log`.
`test.sh` reruns validation and `package.sh` creates the release tarball.

## Validation

The build rejects ELF files with a program interpreter or dynamic `NEEDED`
entries. Interactive tests run as UID 65534 without network access against
the pinned `rockylinux:9` image (Rocky 9.3 userland), without installing any
packages. Each of the 24 embedded terminal types is tested for startup,
rendering, UTF-8 output, pane splitting, terminal resize, keyboard detach,
and reattach. The suite runs against both the stock image and with all
standard terminfo directories hidden and terminfo environment paths absent.

Docker uses the host WSL Linux kernel; this validates Rocky 9 userland
compatibility, not a booted Rocky 9 kernel. The server needs normal Linux
PTY support, a shell, and a writable temporary directory.

## Upstream sources

- [tmux 3.7c](https://github.com/tmux/tmux/releases/tag/3.7c)
- [ncurses 6.6](https://invisible-island.net/ncurses/announce.html)
- [libevent 2.1.12](https://github.com/libevent/libevent/releases/tag/release-2.1.12-stable)
- [musl 1.2.5](https://musl.libc.org/releases.html) (source archive used for its license notice; runtime supplied by Alpine)

This is a community build, not an official tmux release artifact.

## License

The build scripts, Dockerfile, tests, and documentation in this repository
are released under the [ISC License](LICENSE).

The tmux binary produced by this build combines upstream works. Their notices
are copied into `licenses/` in the release tarball: tmux (ISC), ncurses,
libevent (BSD-3-Clause), and musl (MIT). Those terms govern the binary.
