#!/usr/bin/env bash
# Builds the game into build/: yaotl.love, yaotl-windows.zip and yaotl-linux.AppImage
# Needs: curl, zip, unzip, sha256sum and squashfs-tools (unsquashfs, mksquashfs)
set -euo pipefail

LOVE_VERSION="11.5"
LOVE_URL="https://github.com/love2d/love/releases/download/$LOVE_VERSION"
# Pinned so a tampered or replaced download fails the build
WINDOWS_ZIP="love-$LOVE_VERSION-win64.zip"
WINDOWS_SHA256="ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369"
APPIMAGE="love-$LOVE_VERSION-x86_64.AppImage"
APPIMAGE_SHA256="65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00"

# Only what the game needs at runtime
GAME_FILES=(main.lua conf.lua src assets)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
CACHE="$BUILD/cache"
WORK="$BUILD/work"

# Download once into the cache and check the checksum
fetch() {
    local file="$1" sha256="$2"
    if [ ! -f "$CACHE/$file" ]; then
        curl -sSfL -o "$CACHE/$file" "$LOVE_URL/$file"
    fi
    echo "$sha256  $CACHE/$file" | sha256sum --check --quiet
}

build_love() {
    (cd "$ROOT" && zip -9 -q -r -X "$BUILD/yaotl.love" "${GAME_FILES[@]}")
}

# Fused executable: love.exe with the game appended, next to LÖVE's DLLs
# The folder is kept for CI artifacts, which are zipped on upload
build_windows() {
    fetch "$WINDOWS_ZIP" "$WINDOWS_SHA256"
    unzip -q "$CACHE/$WINDOWS_ZIP" -d "$WORK"
    local love="$WORK/love-$LOVE_VERSION-win64" game="$BUILD/yaotl-windows"
    mkdir "$game"
    cat "$love/love.exe" "$BUILD/yaotl.love" >"$game/yaotl.exe"
    cp "$love"/*.dll "$love/license.txt" "$game"
    (cd "$BUILD" && zip -9 -q -r -X yaotl-windows.zip yaotl-windows)
}

# The AppImage is an ELF runtime followed by a squashfs; the squashfs starts where the ELF ends
elf_end() {
    local file="$1"
    local sections_start section_size section_count
    sections_start=$(od -An -t u8 -j 40 -N 8 "$file")
    section_size=$(od -An -t u2 -j 58 -N 2 "$file")
    section_count=$(od -An -t u2 -j 60 -N 2 "$file")
    echo $((sections_start + section_size * section_count))
}

# Same runtime, with the game fused into LÖVE's binary inside the squashfs
build_linux() {
    fetch "$APPIMAGE" "$APPIMAGE_SHA256"
    local offset squashfs="$WORK/squashfs-root"
    offset=$(elf_end "$CACHE/$APPIMAGE")
    unsquashfs -q -no-progress -o "$offset" -d "$squashfs" "$CACHE/$APPIMAGE"
    cat "$squashfs/bin/love" "$BUILD/yaotl.love" >"$WORK/love"
    mv "$WORK/love" "$squashfs/bin/love"
    chmod +x "$squashfs/bin/love"
    mksquashfs "$squashfs" "$WORK/yaotl.squashfs" -comp gzip -root-owned -noappend -quiet
    head -c "$offset" "$CACHE/$APPIMAGE" | cat - "$WORK/yaotl.squashfs" >"$BUILD/yaotl-linux.AppImage"
    chmod +x "$BUILD/yaotl-linux.AppImage"
}

rm -rf "$WORK" "$BUILD"/yaotl*
mkdir -p "$CACHE" "$WORK"

build_love
build_windows
build_linux
rm -rf "$WORK"

ls -lh "$BUILD"/yaotl*
