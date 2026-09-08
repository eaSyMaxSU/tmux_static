#!/bin/sh
set -eu
export CFLAGS='-O2 -march=x86-64 -mtune=generic'
export SOURCE_DATE_EPOCH=1786968000
jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN)}
[ "$jobs" -le 16 ] || jobs=16
mkdir -p /build /out/licenses
cd /build
for archive in /sources/*.tar.gz; do tar -xzf "$archive"; done
# ncurses names these entries kitty/ghostty; accept their commonly exported TERM names.
cat >> /build/ncurses-6.6/misc/terminfo.src <<'EOF'

xterm-kitty|Kitty alias for the ncurses kitty entry,
    use=kitty,
xterm-ghostty|Ghostty alias for the ncurses ghostty entry,
    use=ghostty,
EOF

# Build matching tic/infocmp first, for ncurses' compiled fallback database.
mkdir ncurses-tools
cd ncurses-tools
../ncurses-6.6/configure --prefix=/opt/ncurses-tools --enable-widec \
    --without-shared --without-debug --without-ada --without-cxx \
    --without-cxx-binding --without-tests --without-manpages
make -j"$jobs"
make install
export PATH="/opt/ncurses-tools/bin:$PATH"
cd /build
mkdir ncurses-static
cd ncurses-static
../ncurses-6.6/configure --prefix=/opt/static --enable-widec \
    --without-shared --without-debug --without-ada --without-cxx \
    --without-cxx-binding --without-tests --without-manpages \
    --enable-pc-files --with-pkg-config-libdir=/opt/static/lib/pkgconfig \
    --with-default-terminfo-dir=/usr/share/terminfo \
    --with-terminfo-dirs=/etc/terminfo:/lib/terminfo:/usr/share/terminfo \
    --with-fallbacks=xterm,xterm-256color,xterm-direct,screen,screen-256color,tmux,tmux-256color,linux,vt100,vt220,rxvt,rxvt-256color,putty,putty-256color,alacritty,alacritty-direct,foot,foot-direct,xterm-kitty,xterm-ghostty,ghostty,wezterm,ms-terminal,ms-terminal-direct
make -j"$jobs"
make install

cd /build/libevent-2.1.12-stable
./configure --prefix=/opt/static --disable-shared --enable-static \
    --disable-openssl --disable-samples --disable-libevent-regress
make -j"$jobs"
make install

cd /build/tmux-3.7c
export PKG_CONFIG_PATH=/opt/static/lib/pkgconfig
export CPPFLAGS='-I/opt/static/include -I/opt/static/include/ncursesw'
export LDFLAGS='-static -L/opt/static/lib'
./configure --prefix=/usr/local --enable-static
make -j"$jobs"
strip tmux
cp tmux /out/tmux-3.7c-linux-x86_64-static
cp tmux.1 /out/tmux.1
cp COPYING /out/licenses/tmux-COPYING
cp /build/ncurses-6.6/COPYING /out/licenses/ncurses-COPYING
cp /build/libevent-2.1.12-stable/LICENSE /out/licenses/libevent-LICENSE
# Include musl's notice for the statically linked C runtime.
cp /build/musl-1.2.5/COPYRIGHT /out/licenses/musl-COPYRIGHT
cp /sources.sha256 /out/sources.sha256
{
    /out/tmux-3.7c-linux-x86_64-static -V
    file /out/tmux-3.7c-linux-x86_64-static
    readelf -l /out/tmux-3.7c-linux-x86_64-static
    readelf -d /out/tmux-3.7c-linux-x86_64-static
    cc --version
    apk info -v
} > /out/BUILD-INFO.txt
if readelf -l /out/tmux-3.7c-linux-x86_64-static | grep -q INTERP; then
    echo 'Unexpected ELF interpreter' >&2; exit 1
fi
if readelf -d /out/tmux-3.7c-linux-x86_64-static | grep -q NEEDED; then
    echo 'Unexpected dynamic dependency' >&2; exit 1
fi
