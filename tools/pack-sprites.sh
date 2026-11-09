#!/usr/bin/env bash
# Packs the loose animation frames from the asset pack into one grid
# spritesheet per animation.
#
# Requires ImageMagick. Run it from the project root without installing it:
#   nix shell nixpkgs#imagemagick -c ./tools/pack-sprites.sh
set -euo pipefail

SOURCE_DIR="assets_local/Top_Down_Survivor"
OUTPUT_DIR="assets/sprites/player"
COLUMNS=5

# "<folder in the pack>:<spritesheet name in the game>"
ANIMATIONS=(
    "flashlight/idle:flashlight_idle"
    "flashlight/move:flashlight_move"
    "feet/idle:feet_idle"
    "feet/walk:feet_walk"
    "feet/strafe_left:feet_strafe_left"
    "feet/strafe_right:feet_strafe_right"
)

if ! command -v montage >/dev/null; then
    echo "ImageMagick not found. Run: nix shell nixpkgs#imagemagick -c $0" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

for entry in "${ANIMATIONS[@]}"; do
    source="${entry%%:*}"
    name="${entry##*:}"

    # Natural sort, so frame_10 comes after frame_9
    mapfile -t frames < <(printf '%s\n' "$SOURCE_DIR/$source"/*.png | sort -V)
    count=${#frames[@]}
    columns=$((count < COLUMNS ? count : COLUMNS))

    montage "${frames[@]}" -tile "${columns}x" -geometry +0+0 -background none \
        "$OUTPUT_DIR/$name.png"

    echo "$name: $count frames of $(identify -format '%wx%h' "${frames[0]}"), $columns columns"
done
