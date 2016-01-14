-- Shorten URLs
local http_request = require "http.request"
local url_escape = require "http.util".encodeURIComponent

local function shorten(link)
	local h, s = assert(http_request.new_from_uri("http://v.gd/create.php?format=simple&url=" .. url_escape(link)):go())
	if h:get":status" ~= "200" then
		error("Unable to shorten link")
	end
	return assert(s:get_body_as_string())
end

local http_patt = "https?://[%w./%?%%+#_:;[%]%-!~*'()@&=%$,]+"

return {
	PRIVMSG = function(irc, sender, origin, message, pm)
		for url in message:gmatch(http_patt) do
			-- Don't get in a loop with multiple bots
			if #url >= 22 and
				-- Just in case v.gd urls get longer one day
				not url:match("https?://v.gd/")
			then
				local short = shorten(url)
				local msg = string.format("%s: Shortened < %s >", sender[1], short)
				irc:PRIVMSG(origin, msg)
			end
		end
	end;
}
