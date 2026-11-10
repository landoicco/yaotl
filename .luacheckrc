-- LÖVE runs on LuaJIT and exposes the love global
std = "luajit+love"

-- Matches StyLua's column_width
max_line_length = 120

-- Local asset packs, not part of the game; maps are written by Tiled
exclude_files = { "assets_local/", "assets/maps/" }

-- Callbacks and state interfaces take arguments they may not use
unused_args = false
