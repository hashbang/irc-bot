-- Shorten URLs
local http_request = require "http.request"
local gumbo = require "gumbo" -- lua gumbo
local url_escape = require "http.util".encodeURIComponent
local lpeg = require "lpeg"
local uri_patterns = require "lpeg_patterns.uri"

local function shorten(link)
	local h, s = http_request.new_from_uri("https://is.gd/create.php?format=simple&url=" .. url_escape(link)):go()
	if not h then
		print("HTTP ERROR shortening", link, s)
		return
	end
	local b = s:get_body_as_string()
	if h:get":status" ~= "200" then
		print("Unable to shorten link", b)
		return
	end
	return b
end

local function gettitle(link)
	local h, s = http_request.new_from_uri(link):go()
	if not h then
		print("HTTP ERROR fetching", link, s)
		return
	end
	-- Only read first 16k chars. don't want to download some large file
	local body = s:get_body_chars(16384)
	s:shutdown()
	if not body then return end
	local document = gumbo.parse(body)
	local title = document.title
	if title == "" then return end
	title = title:gsub("[\r\n]+", " ")
	title = string.format("%q", title) -- escape control characters and surround with quotes
	return title
end

-- LPEG pattern that searches for URIs
local patt = lpeg.P { lpeg.C(uri_patterns.sane_uri) * lpeg.Cp() + 1 * lpeg.V(1) }
-- Iterator for urls in a string
local function urls(s)
	local i = 1
	return function()
		local m, n, j = lpeg.match(patt, s, i)
		if m then
			i = j + 1
		end
		return m, n
	end
end

return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			for url, parsed in urls(message) do
				local msg = ""
				local title
				if parsed.scheme == "http" or parsed.scheme == "https" then
					title = gettitle(url)
					if title then
						msg = msg .. "Title " .. title .. " "
					end
				end
				-- Don't get in a loop with multiple bots
				if #url >= 23 and
					-- Just in case is.gd urls get longer one day
					not url:match("https?://is.gd/")
				then
					local short = shorten(url)
					if short then
						msg = msg .. "Shortened < " .. short .. " >"
					end
				end
				if #msg > 0 then
					msg = sender[1] .. ": " .. msg
					irc:PRIVMSG(origin, msg)
				end
			end
		end;
	};
}
