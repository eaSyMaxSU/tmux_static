#!/usr/bin/env python3
"""Exercise the actual TUI on Rocky 9, including compiled terminfo fallbacks."""
import fcntl
import os
import pty
import select
import struct
import subprocess
import termios
import time

BIN = "/artifacts/tmux-3.7c-linux-x86_64-static"
TERMS = "xterm xterm-256color xterm-direct screen screen-256color tmux tmux-256color linux vt100 vt220 rxvt rxvt-256color putty putty-256color alacritty alacritty-direct foot foot-direct xterm-kitty xterm-ghostty ghostty wezterm ms-terminal ms-terminal-direct".split()


def test_terminal(term, index):
    socket = "static-test-%d-%d" % (os.getpid(), index)
    env = dict(os.environ, TERM=term, LANG="C.UTF-8", LC_ALL="C.UTF-8", HOME="/tmp", SHELL="/bin/bash")
    base = [BIN, "-L", socket, "-f", "/dev/null"]
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))

    def child_setup():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    def attach(args):
        return subprocess.Popen(base + args, stdin=slave, stdout=slave, stderr=slave,
                                env=env, preexec_fn=child_setup)

    def command(*args):
        return subprocess.run(base + list(args), env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, encoding="utf-8", timeout=10)

    screen = bytearray()

    def drain():
        while select.select([master], [], [], 0)[0]:
            screen.extend(os.read(master, 65536))

    def until(predicate, label):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            drain()
            if predicate():
                return
            time.sleep(0.05)
        raise AssertionError("%s: %s; terminal output=%r" % (term, label, screen[-2000:]))

    client = attach(["new-session", "-s", "smoke", "/bin/bash --noprofile --norc"])
    try:
        until(lambda: command("has-session", "-t", "smoke").returncode == 0, "start session")
        # Clear the echoed command so capture-pane must observe shell output.
        result = command("send-keys", "-t", "smoke:0.0", "printf '\\033[2J\\033[HSTATIC_OK_中文_✓\\n'", "Enter")
        assert result.returncode == 0, result.stderr
        until(lambda: "STATIC_OK_中文_✓" in command("capture-pane", "-p", "-t", "smoke:0.0").stdout,
              "UTF-8 pane output")
        until(lambda: b"STATIC_OK_" in screen and b"\x1b[" in screen, "interactive rendering")
        result = command("split-window", "-h", "-t", "smoke:0", "/bin/bash --noprofile --norc")
        assert result.returncode == 0, result.stderr
        panes = command("list-panes", "-t", "smoke:0", "-F", "#{pane_id}").stdout.splitlines()
        assert len(panes) == 2, panes
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
        until(lambda: command("display-message", "-p", "-t", "smoke:0", "#{window_width}x#{window_height}").stdout.strip() == "120x39",
              "resize to 120x40 including status line")
        os.write(master, b"\x02d")
        until(lambda: client.poll() is not None, "detach with Ctrl-b d")
        assert client.returncode == 0, screen[-2000:]
        assert command("has-session", "-t", "smoke").returncode == 0
        client = attach(["attach-session", "-t", "smoke"])
        until(lambda: command("list-clients", "-F", "#{client_session}").stdout.strip() == "smoke", "reattach")
        os.write(master, b"\x02d")
        until(lambda: client.poll() is not None, "detach after reattach")
        assert client.returncode == 0
        print("PASS %s: TUI, UTF-8, split, resize, detach, reattach" % term, flush=True)
    finally:
        command("kill-server")
        if client.poll() is None:
            client.terminate()
            client.wait(timeout=5)
        os.close(master)
        os.close(slave)


print(open("/etc/rocky-release").read().strip(), flush=True)
print("uid=%s; TERMINFO=%s; TERMINFO_DIRS=%s" %
      (os.getuid(), os.environ.get("TERMINFO"), os.environ.get("TERMINFO_DIRS")), flush=True)
print(subprocess.check_output([BIN, "-V"], universal_newlines=True).strip(), flush=True)
for idx, terminal in enumerate(TERMS):
    test_terminal(terminal, idx)
print("All %d terminal types passed." % len(TERMS), flush=True)
