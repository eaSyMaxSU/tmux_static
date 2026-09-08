#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p logs
rocky=rockylinux:9@sha256:d7be1c094cc5845ee815d4632fe377514ee6ebcf8efaed6892889657e5ddaaa6
# Exercise the untouched Rocky 9 userland without installing any packages.
docker run --rm --platform linux/amd64 --network none --user 65534:65534 \
    -e HOME=/tmp -v "$PWD/dist:/artifacts:ro" -v "$PWD/test-rocky.py:/test.py:ro" \
    "$rocky" python3 /test.py > logs/test-rocky-stock.log 2>&1 || {
    cat logs/test-rocky-stock.log; exit 1;
}
cat logs/test-rocky-stock.log
# Hide every compiled-in system terminfo directory, and the per-user directory.
# The container has no /opt/static or /opt/ncurses-tools build-time paths.
docker run --rm --platform linux/amd64 --network none --user 65534:65534 \
    --tmpfs /usr/share/terminfo --tmpfs /etc/terminfo --tmpfs /usr/lib/terminfo \
    -e HOME=/tmp -e TERMINFO=/nonexistent -e TERMINFO_DIRS=/nonexistent \
    -v "$PWD/dist:/artifacts:ro" -v "$PWD/test-rocky.py:/test.py:ro" \
    "$rocky" python3 /test.py > logs/test-rocky-no-terminfo.log 2>&1 || {
    cat logs/test-rocky-no-terminfo.log; exit 1;
}
cat logs/test-rocky-no-terminfo.log
cp logs/test-rocky-stock.log logs/test-rocky-no-terminfo.log dist/
