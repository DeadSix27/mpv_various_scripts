
## mpv_chapter_make

Small tool to create MKV-Chapter files for Anime Episodes.
Based on the idea of https://github.com/shinchiro/mpv-createchapter
But the only thing leftover is format_time.

### Usage:
- Seek to the first frame of the Opening, hit the key defined via `AddChapterBind` (Default: Shift-c)
- If `SeekOped` is set to `true` in the options, you'll be skipped closely to the end of the Opening (configureable, see: `OpLength`)
- Find the first frame that's not the Opening anymore, hit the `AddChapterBind` key again (Default: Shift-c) and you'll be skipped approx. to the end of the Episode/start of the Ending (configureable, see: `EpLength`)
- Repeat for Ending and Epilogue or Preview, see `chapter_names` entry #5. Change to what is appropriate for the current Anime, e.g if it has no Prologue, remove the Prologue entry (for example).


### Options:

```lua
-- Config ------------------------------------------------------

local chapter_names = { -- Change to whatever you want. Every chapter past the amount of entries in this table, will be named "Chapter (num)"
	[1] = "Prologue",
	[2] = "Opening",
	[3] = "Episode",
	[4] = "Ending",
	[5] = "Preview", -- "Epilogue"
}
-- Keybinds
local AddChapterBind = "C" -- Add current position as chapter with above naming scheme
local SaveChapterBind  = "B" -- Save chapter to xml file

-- For convinience, it seeks the aprox. OP/ED and Episode length ahead to save some time.
-- Might not be always accurate, relies on the 1min30s OPED standard and episodes around 20min length,
-- so for anime-shorts you have to change this or turn off 'SeekOped'.
local SeekOped = true
local OpSeekId = 2 -- Specify the number of the "Opening" chapter after which you want to seek (see chapter_names table)
local EpSeekId = 3 -- Same as above, but for the "Episode" Seek
local EdSeekId = 4 -- Same as above, but for the "Ending" Seek
local OpLength = 89 -- How far to seek after Openings (89 (1min29s) is the default)
local EpLength = 1170 -- How far to seek after Episode (1170 (19m30s) is the default)
local EdLength = 89 -- How far to seek after Endings (89 (1min29s) is the default)


-- [Optional] Show chapters in OSC while creating them: --
--
-- The OSC won't display the chapter markers until it's reloaded,
-- to do this we have to actually edit the OSC, you'll have to download it from here (unless you use a custom OSC, then the same code edit below may or may not work for you):
-- https://raw.githubusercontent.com/mpv-player/mpv/master/player/lua/osc.lua
-- and place it into your scripts folder, then add "osc=no" into your mpv.conf and add the following line of code (without end/start single quote):
-- 'mp.register_script_message("osc-request-init", request_init)'
-- above this line (without end/start single quote), it should only exist once, if not, then good luck:
-- 'mp.observe_property("fullscreen", "bool",'
-- then set the below value to 'true' instead of 'false'
--
local reInitOSC = false
```

Feel free to change them in the script.
