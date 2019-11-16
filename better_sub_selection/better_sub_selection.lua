local mp = require 'mp'
local op = require 'mp.options'
local inspect = require 'inspect'

-- This script makes mpv re-use "--slang=[lang],[lanmg],..." even when switching files in playlist. (seems to not do that by default for some reason?)
-- Additionally you can specify "--script-opts=bss-list="[title1]|[title2]|.." to select subtitles in order by title, title can be a str or lua pattern (e.g "GroupName.+ENG.+")
-- If you specify just a string it will only check wether that string is in the title, it does not do full comparison.

-- Example:
-- mpv --script-opts=bss-list="Hi I am|foobar" file.mkv 
-- If the mkv file had 2 subs one named "Hi i am a subtitle, title.." it would select that regardless of its track position/id/lang and also ignoring --slang
-- Additionally that option can be set in the file "script-opts/bss.conf" like:
-- # bss config
-- list=Hi I am|foobar

-- Note that this is obviously flawed when titles contain "|", but I hate lua pattern's so yeah you can however turn this into lua code and make us both happy: ((?:\\\||[^\|])+)

local options = {
    list = "",
}
op.read_options(options, "bss")

local title_list = {}

for i in string.gmatch(options.list, "([^|]+)") do
   title_list[#title_list + 1] = i
end

function get_tracks()
    local tracktable = mp.get_property_native("track-list", {})
    local tracks_osc = {}
    tracks_osc.video, tracks_osc.audio, tracks_osc.sub = {}, {}, {}
    for n = 1, #tracktable do
        if not (tracktable[n].type == "unknown") then
            local ttype = tracktable[n].type
            table.insert(tracks_osc[ttype], tracktable[n])
        end
    end
	return tracks_osc
end

function in_arr(item, arr)
    for index, value in ipairs(arr) do
        if value == item then
            return true
        end
    end
    return false
end

function title_match(subtitle)
	ret = false
    for index, pattern in ipairs(title_list) do
		ret = string.match(subtitle, pattern)
		if ret ~= nil then
			ret = true
		else
			ret = false
		end
    end
    return ret
end


function on_file_loaded(event)
	local sublangs = mp.get_property_native("slang")
	if #title_list <= 0 and #sublangs <= 0 then
		return
	end
	local subs = get_tracks()["sub"]
    if #subs > 0 then
		-- local sid = nil
		for n = 1, #subs do
			if #title_list >= 1 then
				if title_match(subs[n].title) then
					mp.set_property("sid", subs[n].id)
					break
				end
			end
			if #sublangs >= 1 then
				if in_arr(subs[n].lang, sublangs) then
					mp.set_property("sid", subs[n].id)
					break
				end
			end
		end
	end
end

mp.register_event("file-loaded", on_file_loaded)