#!/usr/bin/env bash
# Packs the loose animation frames from the asset packs into one grid
# spritesheet per animation.
#
# Requires ImageMagick, included in the Nix dev shell. Run it from the project root:
#   nix develop -c ./tools/pack-sprites.sh
set -euo pipefail

SOURCE_DIR="assets_local"
OUTPUT_DIR="assets/sprites"
COLUMNS=5

# "<frames, relative to SOURCE_DIR>:<spritesheet, relative to OUTPUT_DIR>"
ANIMATIONS=(
    "Top_Down_Survivor/flashlight/idle/*.png:player/flashlight_idle"
    "Top_Down_Survivor/flashlight/move/*.png:player/flashlight_move"
    "Top_Down_Survivor/handgun/idle/*.png:player/handgun_idle"
    "Top_Down_Survivor/handgun/move/*.png:player/handgun_move"
    "Top_Down_Survivor/handgun/shoot/*.png:player/handgun_shoot"
    "Top_Down_Survivor/handgun/reload/*.png:player/handgun_reload"
    "Top_Down_Survivor/shotgun/idle/*.png:player/shotgun_idle"
    "Top_Down_Survivor/shotgun/move/*.png:player/shotgun_move"
    "Top_Down_Survivor/shotgun/shoot/*.png:player/shotgun_shoot"
    "Top_Down_Survivor/shotgun/reload/*.png:player/shotgun_reload"
    "Top_Down_Survivor/feet/idle/*.png:player/feet_idle"
    "Top_Down_Survivor/feet/walk/*.png:player/feet_walk"
    "Top_Down_Survivor/feet/strafe_left/*.png:player/feet_strafe_left"
    "Top_Down_Survivor/feet/strafe_right/*.png:player/feet_strafe_right"
    "tds_zombie/export/skeleton-idle_*.png:zombie/idle"
    "tds_zombie/export/skeleton-move_*.png:zombie/move"
    "tds_zombie/export/skeleton-attack_*.png:zombie/attack"
)

if ! command -v montage >/dev/null; then
    echo "ImageMagick not found. Run: nix develop -c $0" >&2
    exit 1
fi

for entry in "${ANIMATIONS[@]}"; do
    pattern="${entry%%:*}"
    name="${entry##*:}"
    output="$OUTPUT_DIR/$name.png"

    # Unquoted so the glob expands; natural sort puts frame_10 after frame_9
    # shellcheck disable=SC2086
    mapfile -t frames < <(printf '%s\n' $SOURCE_DIR/$pattern | sort -V)
    count=${#frames[@]}
    columns=$((count < COLUMNS ? count : COLUMNS))

    mkdir -p "$(dirname "$output")"
    montage "${frames[@]}" -tile "${columns}x" -geometry +0+0 -background none "$output"

    echo "$name: $count frames of $(identify -format '%wx%h' "${frames[0]}"), $columns columns"
done
