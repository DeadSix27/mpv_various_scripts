
## mpv_chapter_make

Small tool to create MKV-Chapter files for Anime Episodes.
Based on the idea of https://github.com/shinchiro/mpv-createchapter
But the only thing leftover is format_time.

### Usage:
- Seek to the first frame of the Opening, hit `AddChapterBind`
- If `SeekOped` is `true`, you'll be skipped closely to the end of the Opening
- Find the first frame that's not the Opening anymore, hit `AddChapterBind`
- Repeat for Ending and Epilogue or Preview, see `chapter_names` entry #5. Change to what is appropriate for the current Anime.


### Options:

```lua
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
-- Might not be always accurate, relies on the 1min30s OPED standard and episodes around 20min length
local SeekOped = true
local OpLength = 89 -- 1min29s
local EdLength = 89 -- 1min29s
local EpLength = 1170 -- 19m30s
```

Feel free to change them in the script.
