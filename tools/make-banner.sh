#!/usr/bin/env bash
# Builds the README banner from the game's tiles and sprites, lit the way the game lights them:
# a lightmap of an almost black ambient, the flashlight's cone and a faint halo, multiplied into the scene.
#
# Requires ImageMagick, included in the Nix dev shell, and two fonts in assets_local/fonts:
#   IMFellEnglishSC.ttf  https://fonts.google.com/specimen/IM+Fell+English+SC (OFL)
#   SpecialElite.ttf     https://fonts.google.com/specimen/Special+Elite (Apache 2.0)
# Run it from the project root:
#   nix develop -c ./tools/make-banner.sh
set -euo pipefail

OUTPUT="docs/images/banner.png"
TITLE_FONT="assets_local/fonts/IMFellEnglishSC.ttf"
SUBTITLE_FONT="assets_local/fonts/SpecialElite.ttf"
SPRITES="assets/sprites"
TILES="assets/maps/sandbox_tiles.png"

WIDTH=1280
HEIGHT=432
TILE=48 # the 32 px tiles at 1.5x
SCALE=0.62 # sprite scale

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$(dirname "$OUTPUT")"

# A corridor: walls along the top and bottom rows, and a pillar
magick "$TILES" -crop 32x32+0+0 +repage -filter point -resize ${TILE}x${TILE} "$TMP/floor.png"
magick "$TILES" -crop 32x32+32+0 +repage -filter point -resize ${TILE}x${TILE} "$TMP/wall.png"
magick -size ${WIDTH}x${TILE} tile:"$TMP/wall.png" "$TMP/wall_row.png"
magick -size ${WIDTH}x${HEIGHT} tile:"$TMP/floor.png" \
    "$TMP/wall_row.png" -geometry +0+0 -composite \
    "$TMP/wall_row.png" -geometry +0+$((HEIGHT - TILE)) -composite \
    \( -size $((TILE * 2))x$((TILE * 2)) tile:"$TMP/wall.png" \) -geometry +$((TILE * 22))+${TILE} -composite \
    "$TMP/scene.png"

# Draws the first frame of a sheet over the scene, with the frame's origin at x, y, turned by angle degrees
place() {
    local sheet="$1" frameWidth="$2" frameHeight="$3" originX="$4" originY="$5" x="$6" y="$7" angle="$8"
    magick "$TMP/scene.png" \
        \( "$sheet" -crop ${frameWidth}x${frameHeight}+0+0 +repage -background none -virtual-pixel transparent \
           -set option:distort:viewport ${WIDTH}x${HEIGHT}+0+0 \
           -distort SRT "$originX,$originY $SCALE $angle $x,$y" \) \
        -composite "$TMP/scene.png"
}

# The player, aiming slightly up; the zombies come from the right. Layouts from src/game/
PLAYER_X=730
PLAYER_Y=228
AIM=-4 # degrees
place "$SPRITES/player/feet_idle.png" 132 155 66 78 $PLAYER_X $PLAYER_Y $AIM
place "$SPRITES/player/flashlight_idle.png" 303 223 95 120 $PLAYER_X $PLAYER_Y $AIM
place "$SPRITES/zombie/move.png" 288 311 120 170 1000 200 172
place "$SPRITES/zombie/move.png" 288 311 120 170 1150 296 196
place "$SPRITES/zombie/move.png" 288 311 120 170 1250 142 182

# The flashlight lens, 200, -16 sprite pixels from the origin, turned with the aim
read -r LENS_X LENS_Y < <(awk -v x=$PLAYER_X -v y=$PLAYER_Y -v a=$AIM -v s=$SCALE 'BEGIN {
    r = a * 3.14159265 / 180; dx = 200 * s; dy = -16 * s
    printf "%.1f %.1f\n", x + dx * cos(r) - dy * sin(r), y + dx * sin(r) + dy * cos(r) }')

# Light intensity: a cone with soft edges, fading with distance, and a faint halo around the player
magick -size ${WIDTH}x${HEIGHT} xc:black -fx "
    vx = i - $LENS_X; vy = j - $LENS_Y; dist = hypot(vx, vy);
    ang = abs(atan2(vy, vx) - ($AIM * pi / 180));
    edg = max(0, min(1, (0.40 - ang) / 0.14));
    fal = pow(max(0, 1 - dist / 820), 1.4);
    gx = i - $PLAYER_X; gy = j - $PLAYER_Y;
    hal = exp(-(gx * gx + gy * gy) / (2 * 75 * 75));
    min(1.3, edg * fal * 1.25 + hal * 0.35)" "$TMP/light.png"

# Warm light plus an almost black ambient with a hint of blue, multiplied into the scene
magick "$TMP/scene.png" \
    \( "$TMP/light.png" \( -size ${WIDTH}x${HEIGHT} xc:"#ffd8a4" \) -compose multiply -composite \
       \( -size ${WIDTH}x${HEIGHT} xc:"#0b0c13" \) -compose plus -composite \) \
    -compose multiply -composite "$TMP/lit.png"

# The title on the dark side, over a faint red glow
magick "$TMP/lit.png" \
    \( -size ${WIDTH}x${HEIGHT} xc:none -font "$TITLE_FONT" -pointsize 132 -kerning 10 \
       -fill "#7a1d17" -annotate +70+238 "YAOTL" -blur 0x14 \) -compose screen -composite \
    -compose over -font "$TITLE_FONT" -pointsize 132 -kerning 10 -fill "#e9e1d2" -annotate +70+238 "YAOTL" \
    -font "$SUBTITLE_FONT" -pointsize 24 -kerning 4 -fill "#9b9385" \
    -annotate +76+284 "A TOP-DOWN HORROR SHOOTER" \
    "$TMP/titled.png"

# A vignette and a little grain; 256 colors keep the file small, and the grain hides the banding
# A fixed seed and no timestamps write the same file on every run
magick "$TMP/titled.png" \
    \( -size ${WIDTH}x${HEIGHT} radial-gradient:white-black -level 0,75% -evaluate pow 0.6 \) \
    -compose multiply -composite \
    -seed 1 -attenuate 0.12 +noise Gaussian \
    +dither -colors 256 \
    -define png:exclude-chunks=date,time \
    "$OUTPUT"

echo "Wrote $OUTPUT"
