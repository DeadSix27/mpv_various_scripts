local utils = require("mp.utils")


-- Small tool to create MKV-Chapter files for Anime Episodes.
-- Based on the idea of https://github.com/shinchiro/mpv-createchapter
-- But the only thing leftover is format_time

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
-- Might not be always accurate, relies on the 1min30s OPED standard and episodes around 20min length
local SeekOped = true
local OpLength = 89 -- 1min29s
local EdLength = 89 -- 1min29s
local EpLength = 1170 -- 19m30s

-- -------------------------------------------------------------

local chapter_list = {}
local curr_chapter = 1

function lent(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function has_key(T, K)
    return T[K] ~= nil
end

local function add_chapter()
    local time_pos = mp.get_property_number("time-pos")
    local time_pos_osd = mp.get_property_osd("time-pos/full")
    local chapter_count = mp.get_property_number("chapter-list/count")
    local all_chapters = mp.get_property_native("chapter-list")
	local duration = mp.get_property_native("duration")
	
	local chapter_name = "Chapter " .. curr_chapter
	if has_key(chapter_names, curr_chapter) then
		chapter_name = chapter_names[curr_chapter]
	end
	
	if curr_chapter == 1 then
		table.insert(chapter_list,
			{
				title = chapter_name,
				time = 0,
				end_time = 0
			}
		)
		print(curr_chapter, chapter_name, 0 .. "s")
		curr_chapter = 2
	end
	
	chapter_name = "Chapter " .. curr_chapter
	if has_key(chapter_names, curr_chapter) then
		chapter_name = chapter_names[curr_chapter]
	end
	
	table.insert(chapter_list,
		{
			title = chapter_name,
			time = time_pos,
			end_time = 0
		}
	)
	print(curr_chapter, chapter_name, time_pos)
	
    mp.osd_message("Added \"" .. chapter_name .. "\" Chapter Marker at " .. time_pos_osd, 2)
	
	chapter_list[curr_chapter-1].end_time = time_pos
	
	if curr_chapter == 5 then
		chapter_list[curr_chapter].end_time = duration
	end
	
	mp.set_property_native("chapter-list", chapter_list)
    mp.set_property_number("chapter", curr_chapter)
	
	if SeekOped then
		if chapter_name == "Opening" then
			mp.command("seek " .. OpLength)
			print("Seeking " .. OpLength .. " secs [" .. chapter_name .. "]")
		elseif chapter_name == "Episode" then
			mp.command("seek " .. EpLength)
			print("Seeking " .. EpLength .. " secs [" .. chapter_name .. "]")
		elseif chapter_name == "Ending" then
			mp.command("seek " .. EdLength)
			print("Seeking " .. EdLength .. " secs [" .. chapter_name .. "]")
		end
	end
	
	curr_chapter = curr_chapter + 1
end

local function format_time(seconds)
    local result = ""
    if seconds <= 0 then
        return "00:00:00.000";
    else
        local hours = string.format("%02.f", math.floor(seconds/3600))
        local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
        local secs = string.format("%02.f", math.floor(seconds - hours*60*60 - mins*60))
        local msecs = string.format("%03.f", seconds*1000 - hours*60*60*1000 - mins*60*1000 - secs*1000)
        result = hours..":"..mins..":"..secs.."."..msecs
    end
    return result
end

local function create_chapter_entry(title, time_start, time_end)
		local time_start_str = "00:00:00.000"
		if time_start ~= 0 then
			time_start_str = format_time(time_start)
		end
		local uid = math.random(100000000,999999999) .. math.random(1000000000,9999999999)
		local c = "\t\t<ChapterAtom>\n"
		c = c .. "\t\t\t<ChapterTimeStart>" .. time_start_str .. "</ChapterTimeStart>\n"
		if time_end ~= 0 then
			local time_end_str = format_time(time_end)
			c = c .. "\t\t\t<ChapterTimeEnd>" .. time_end_str .. "</ChapterTimeEnd>\n"
		end
		c = c .. "\t\t\t<ChapterDisplay>\n"
		c = c .. "\t\t\t\t<ChapterString>" .. title .. "</ChapterString>\n"
		c = c .. "\t\t\t\t<ChapterLanguage>eng</ChapterLanguage>\n"
		c = c .. "\t\t\t</ChapterDisplay>\n"
		c = c .. "\t\t\t<ChapterUID>" .. uid .. "</ChapterUID>\n"
		c = c .. "\t\t</ChapterAtom>\n"
		return c
end

local function save_chapter()
	local euid = math.random(100000000,999999999) .. math.random(1000000000,9999999999)
	
	local full_chapter_str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	full_chapter_str = full_chapter_str .. "<!-- <!DOCTYPE Chapters SYSTEM \"matroskachapters.dtd\"> -->\n"
	full_chapter_str = full_chapter_str .. "<Chapters>\n"
	full_chapter_str = full_chapter_str .. "\t<EditionEntry>\n"
	full_chapter_str = full_chapter_str .. "\t\t<EditionUID>" .. euid .. "</EditionUID>\n"	
	for chapter_num, chapter_data in pairs(chapter_list) do
		local chapter_time = chapter_data.time
		local chapter_time_end = chapter_data.end_time
		local chapter_name = chapter_data.title	
		print(chapter_num, chapter_name, chapter_time, chapter_time_end)
		full_chapter_str = full_chapter_str .. create_chapter_entry(chapter_name, chapter_time, chapter_time_end)
	end
	
	full_chapter_str = full_chapter_str .. "\t</EditionEntry>\n"
	full_chapter_str = full_chapter_str .. "</Chapters>"
	
    local path = mp.get_property("path")
    dir, name_ext = utils.split_path(path)
    local name = string.sub(name_ext, 1, (string.len(name_ext)-4))
    local out_path = utils.join_path(dir, name.."_chapter.xml")
    local file = io.open(out_path, "w")
    file:write(full_chapter_str)
    file:close()
    mp.osd_message("Export file to: "..out_path, 3)
	
end

mp.add_key_binding(AddChapterBind, "add_chapter", add_chapter, {repeatable=true})
mp.add_key_binding(SaveChapterBind, "save_chapter", save_chapter, {repeatable=false})
