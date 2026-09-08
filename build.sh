#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p dist logs
sh ./fetch-sources.sh
docker build --platform linux/amd64 -t tmux-static:3.7c . > logs/build.log 2>&1 || {
    tail -80 logs/build.log; exit 1;
}
docker run --rm -v "$PWD/dist:/dist" tmux-static:3.7c
sh ./test.sh
sh ./package.sh
