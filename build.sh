#!/usr/bin/env bash

set -e

BASEDIR="$(dirname "${BASH_SOURCE[0]}")"
WORKDIR="$BASEDIR/work"
STAGEDIR="$BASEDIR/staging"

IMAGE="qaac:latest"

QAAC_VER='2.85'

[ -d "$WORKDIR" ] || mkdir -p "$WORKDIR"
[ -d "$STAGEDIR" ] || mkdir -p "$STAGEDIR"

die() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

dl_file() {
    local url="$1"
    local fname="${2:-$(basename "$url")}"
    # Don't redownload
    if [ -r "$WORKDIR/$fname" ] ; then
        return 0
    fi
    printf '>> Downloading "%s"...\n' "$fname" >&2

    curl -sSLo "$WORKDIR/$fname" "$url" || die "Failed to download '$fname'"
    echo -n "$WORKDIR/$fname"
}

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

require_cmd() {
    if ! command -v "$1" >/dev/null ; then
        die "Required command '$1' not in PATH"
    fi
}

# Ensure we have the commands we need
require_cmd 7z
require_cmd curl
detect_docker

itunes_setup="$(dl_file 'https://secure-appldnld.apple.com/itunes12/041-02279-20180912-24D8EE3A-AC7A-11E8-BE19-C36F1B1141A5/iTunesSetup.exe')"
qaac_zip="$(dl_file "https://github.com/nu774/qaac/releases/download/v${QAAC_VER}/qaac_${QAAC_VER}.zip")"

7z e -y -i"!qaac_${QAAC_VER}/x86/*" -o"$STAGEDIR" "$qaac_zip"
# Credit to https://www.andrews-corner.org/qaac.html
extra_dlls="$(dl_file 'http://www.andrews-corner.org/downloads/x32DLLs_20250625.zip')"
7z e -o"$WORKDIR" -y "$itunes_setup" 'AppleApplicationSupport.msi'
7z e -o"$STAGEDIR" \
     -y "$WORKDIR/AppleApplicationSupport.msi" \
     -i'!*AppleApplicationSupport_ASL.dll' \
     -i'!*AppleApplicationSupport_CoreAudioToolbox.dll' \
     -i'!*AppleApplicationSupport_CoreFoundation.dll' \
     -i'!*AppleApplicationSupport_icudt*.dll' \
     -i'!*AppleApplicationSupport_libdispatch.dll' \
     -i'!*AppleApplicationSupport_libicu*.dll' \
     -i'!*AppleApplicationSupport_objc.dll' \
     -i'!F_CENTRAL_msvc?100*'

for j in "$STAGEDIR/"*.dll ; do mv -v "$j" "${j/AppleApplicationSupport_}" ; done
for j in "$STAGEDIR/F_CENTRAL_msvcr100"* ; do mv -v "$j" "$STAGEDIR/msvcr100.dll" ; done
for j in "$STAGEDIR/F_CENTRAL_msvcp100"* ; do mv -v "$j" "$STAGEDIR/msvcp100.dll" ; done

unzip -d "$STAGEDIR" -j "$extra_dlls"

[ -z "$CI_MODE" ] && "$DOCKER" build -t "$IMAGE" "$BASEDIR"
exit 0
