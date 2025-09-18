#!/usr/bin/env bash

set -e

# TODO: fix once we push to ghcr
IMAGE="qaac:latest"

unset aactmp

detect_docker() {
    if [ -n "$DOCKER" ] ; then
        return
    elif DOCKER="$(command -v docker)" ; then
        return
    elif DOCKER="$(command -v podman)" ; then
        return
    else
        die "Can't find a container manager (docker/podman)"
    fi
}

cleanup() {
    # Remove the temporary AAC storage
    if [ -n "$aactmp" -a -d "$aactmp" ] ; then
        rm -r "$aactmp"
    fi
}

trap 'cleanup' EXIT

usage() {
    printf 'usage: %s INPUT OUTPUT [--] [QAAC OPTIONS]\n' "$0" >&2
    printf "To see qaac help, use \`%s --help'.\n" "$0" >&2
    exit 2
}

die() {
    printf 'error: %s\n' "$0" >&2
    exit 1
}

detect_docker

case "$1" in
-h|--help)
    # passthrough to qaac.exe
    $DOCKER run "$IMAGE" qaac --help
    exit
    ;;
'')
    usage
    ;;
--)
    # Passthru for e.g. --check
    shift
    $DOCKER run -i "$IMAGE" qaac "$@" 
    exit
    ;;
*)
    [ "$#" -ge 2 ] || usage
    infile="$(realpath "$1")"
    ;;
esac

outfile="$(realpath "$2")"
shift 2
# -- is optional, but I like it for separating arguments
[ "$1" == "--" ] && shift

outdir="$(dirname "$outfile")"
outname="$(basename "$outname")"

[ -f "$infile" -a -r "$infile" ] || die "Input file '$infile' not found"
[ -d "$outdir" ] || die "Output file directory '$outdir' not found"

$DOCKER run --rm -v "$outdir:/app/winepfx/drive_c/out" -i "$IMAGE" "$@" -o "c:\\out\\$outname" - < "$infile"
