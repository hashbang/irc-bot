-- Shorten URLs
local http_request = require "http.request"
local url_escape = require "http.util".encodeURIComponent

local function shorten(link)
	local h, s = http_request.new_from_uri("http://v.gd/create.php?format=simple&url=" .. url_escape(link)):go()
	if not h then
		print("HTTP ERROR shortening", s)
		return
	end
	local b = s:get_body_as_string()
	if h:get":status" ~= "200" then
		print("Unable to shorten link", b)
		return
	end
	return b
end


-- adapted from http://stackoverflow.com/a/14899740/282536
local unescape_map = {
	amp = "&",
	lt = "<",
	gt = ">",
	quot = "\"",
	apos = "'",
}
local function unescape(text)
	text = text:gsub("(&(#?x?)([%d%a]+);)", function(orig, n, s)
		return n == "" and unescape_map[s] or n=="#" and string.char(s) or n == "#x" and string.char(tonumber(s,16)) or orig
	end)
	return text
end
local function gettitle(link)
	local h, s = http_request.new_from_uri(link):go()
	if not h then
		print("HTTP ERROR fetching", link, s)
		return
	end
	-- Only read first 4096 chars. don't want to download some large file
	local body = s:get_body_chars(4096)
	s:shutdown()
	if not body then return end
	-- Approximate match; could have false posititves, but it'll do
	local title = body:match("<title>(.-)<")
	if not title then return end
	title = unescape(title)
	title = title:gsub("[\r\n]+", " ")
	title = string.format("%q", title) -- escape control characters
	return title
end

local http_patt = "https?://[%w./%?%%+#_:;[%]%-!~*'()@&=%$,]+"

return {
	PRIVMSG = function(irc, sender, origin, message, pm) -- luacheck: ignore 212
		for url in message:gmatch(http_patt) do
			local msg = sender[1] .. ": "
			local title = gettitle(url)
			if title then
				msg = msg .. "Title " .. title .. " "
			end
			-- Don't get in a loop with multiple bots
			if #url >= 22 and
				-- Just in case v.gd urls get longer one day
				not url:match("https?://v.gd/")
			then
				local short = shorten(url)
				if short then
					msg = msg .. "Shortened < " .. short .. " >"
				end
			end
			irc:PRIVMSG(origin, msg)
		end
	end;
}
