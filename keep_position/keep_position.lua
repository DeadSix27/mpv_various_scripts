local mp = require 'mp'

-- keeps the position when switching files in a playlist, can be useful at times.
-- it's always on, remove the script if you want to disable it.

file_data = {}
function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function on_file_loaded(event)
	new_dur = round(mp.get_property("duration"))
	old_dur = file_data["duration"]
	if old_dur ~= nil and file_data["time-pos"] ~= nil then
		-- if new_dur >= old_dur - 10 and new_dur <= old_dur + 10 then -- use this if u need both files to be close in length
		if file_data["time-pos"] <= new_dur then
			mp.set_property("time-pos", file_data["time-pos"])
		end
		-- end
	end
	file_data["duration"] = new_dur
end

function on_time_changed(name, value)
	if mp.get_property("time-pos") ~= nil then
		file_data["time-pos"] = mp.get_property_number("time-pos")
	end
end

mp.register_event("file-loaded", on_file_loaded)
mp.observe_property("time-pos", "number", on_time_changed);

