#!/bin/sh
set -eu
cd "$(dirname "$0")"
test -f dist/test-rocky-stock.log
test -f dist/test-rocky-no-terminfo.log
cp README.md dist/README.md
cd dist
package=tmux-3.7c-linux-x86_64-static
chmod 755 "$package"
tar -czf "$package.tar.gz" --transform="s/^$package\$/tmux/" \
    "$package" README.md tmux.1 licenses BUILD-INFO.txt sources.sha256 \
    test-rocky-stock.log test-rocky-no-terminfo.log
sha256sum "$package" "$package.tar.gz" > SHA256SUMS
