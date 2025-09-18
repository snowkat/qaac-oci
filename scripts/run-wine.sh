#!/bin/sh

# Basic anti-footgun heuristic
if [ ! -f "/app/run-wine.sh" ] ; then
    echo "WARNING: This should only be run within the container!" >&2
    exit 1
fi

cleanup() {
    # Kill Xvfb pid, iff:
    #  - $xvfb_pid exists (and thus Xvfb has been spawned)
    #  - /proc/$xvfb_pid/exe exists (and thus the PID still exists)
    #  - /proc/$xvfb_pid/exe points to /usr/bin/Xvfb (and thus the PID is still Xvfb)
    if [ -n "$xvfb_pid" -a -e "/proc/$xvfb_pid/exe" ] && \
        [ "$(realpath "/proc/$xvfb_pid/exe")" = "/usr/bin/Xvfb" ] ; then
        kill "$xvfb_pid"
    fi
}

trap 'cleanup' EXIT

# Spawn our pseudo-X
Xvfb :0 -screen 0 1024x768x16 &
xvfb_pid=$!

DISPLAY=:0.0 wine "$@"
