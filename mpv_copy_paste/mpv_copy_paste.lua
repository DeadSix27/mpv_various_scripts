-- -----------------------------------------------------
-- Copyright (C) 2018 DeadSix27 (https://github.com/DeadSix27/mpv_various_scripts/mpv_copy_paste)
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- -----------------------------------------------------

-- Script that allows the user to copy the current path (or URL) in mpv to the clipboard or vise versa.
-- Default keybinds are: Ctrl-c and Ctrl-V
--
-- This script is just for Windows (but can easily be edited to work on Linux probably)

-- Config:
local PasteKeyBind = "Ctrl+v"
local CopyKeyBind  = "Ctrl+c"
--

local utils = require 'mp.utils'

function rtrim(s)
	local n = #s
	while n > 0 and s:find("^%s", n) do n = n - 1 end
	return s:sub(1, n)
end

function handle_clipboard(text)
	local command = nil
	if text ~= nil then
		command = { "powershell", "Set-Clipboard -Value \"" .. text .. "\"" }
	else
		-- Slight modification of rossys function (https://github.com/rossy/mpv-repl/blob/master/repl.lua#L517)
		-- to support copied files.
		command = {
			'powershell', '-NoProfile', '-Command', [[& {
				Trap {
					Write-Error -ErrorRecord $_
					Exit 1
				}

				$clip = ""
				if (Get-Command "Get-Clipboard" -errorAction SilentlyContinue) {
					$clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
				}
			 	else {
					Add-Type -AssemblyName PresentationCore
					$clip = [Windows.Clipboard]::GetText()
				}
				$clip = $clip -Replace "`r",""
				if ($clip.equals("")) {
					Add-Type -AssemblyName PresentationCore
					if ([Windows.Clipboard]::ContainsFileDropList())	{
						$clip = [Windows.Clipboard]::GetFileDropList()
						$clip = $clip[0]
					}
				}
				$u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
				[Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
			}]]
		}
	end
	local ret = utils.subprocess({args = command})
	return rtrim(ret.stdout)
end

function isHttp(s)
	if s:find("https?://") == 1 then
		return true
	end
	return false
end

function paste_path()
	local clipText = handle_clipboard()
	if isHttp(clipText) then
		mp.set_property("options/lavfi-complex", "") -- to work around visualizer.lua doubling up issue.
		mp.osd_message("Ctrl-v: Opening '" .. clipText .. "'")
		mp.command("loadfile ytdl://" .. clipText)
	else
		clipText = string.gsub(clipText, "\\", "/")
		local finfo = utils.file_info(clipText)
		if finfo ~= nil then
			mp.osd_message("Opening '" .. clipText .. "'")
			mp.command("loadfile \"" .. clipText .. "\"")
		else
			mp.osd_message("Ctrl-v: File path in clipboard does not exist: '" .. clipText .. "'")
		end
	end
end

function copy_path()
	local path = mp.get_property_osd("path")
	if path ~= '' then
		path = string.gsub(path, "ytdl://", "")
		handle_clipboard(path)
		mp.osd_message("Ctrl-c: Path '" .. path .. "' has been copied to the clipboard")
	else
		mp.osd_message("Ctrl-c: No file is playing or path is empty.")
	end
end

mp.add_key_binding(PasteKeyBind, "ctrlcv_paste_path", paste_path)

mp.add_key_binding(CopyKeyBind, "ctrlcv_copy_path",  copy_path)
