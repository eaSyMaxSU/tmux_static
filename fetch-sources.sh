#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p sources
cd sources
curl -fL --retry 3 --retry-all-errors -o tmux-3.7c.tar.gz https://github.com/tmux/tmux/releases/download/3.7c/tmux-3.7c.tar.gz
curl -fL --retry 3 --retry-all-errors -o ncurses-6.6.tar.gz https://invisible-island.net/archives/ncurses/ncurses-6.6.tar.gz
curl -fL --retry 3 --retry-all-errors -o libevent-2.1.12-stable.tar.gz https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
curl -fL --retry 3 --retry-all-errors -o musl-1.2.5.tar.gz https://musl.libc.org/releases/musl-1.2.5.tar.gz
sha256sum -c ../sources.sha256
