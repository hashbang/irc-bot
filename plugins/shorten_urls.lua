-- Shorten URLs
local http_request = require "http.request"
local gumbo = require "gumbo" -- lua gumbo
local url_escape = require "http.util".encodeURIComponent
local lpeg = require "lpeg"
local uri_patterns = require "lpeg_patterns.uri"

local function shorten(link)
	local h, s = http_request.new_from_uri("https://is.gd/create.php?format=simple&url=" .. url_escape(link)):go(10)
	if not h then
		print("HTTP ERROR shortening", link, s)
		return
	end
	local b = s:get_body_as_string(10)
	if h:get":status" ~= "200" then
		print("Unable to shorten link", b)
		return
	end
	return b
end

local function gettitle(link)
	local h, s = http_request.new_from_uri(link):go(10)
	if not h then
		print("HTTP ERROR fetching", link, s)
		return
	end
	-- Only read first 16k chars. don't want to download some large file
	local body = s:get_body_chars(16384, 10)
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
					-- Prevent the user's client from triggering a notification,
					-- by including a zero-width space character in their name
					local nick = sender[1]:gsub("^(.)(.*)$", "%1\u{200b}%2")
					msg = nick .. ": " .. msg
					irc:NOTICE(origin, msg)
				end
			end
		end;
	};
}
