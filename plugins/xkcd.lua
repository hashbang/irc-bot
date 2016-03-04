-- !xkcd, created with cooperation of GeekDude (GitHub @G33kDude)

local http_request = require "http.request"
local json = require "dkjson"

return {
	PRIVMSG = function(irc, sender, origin, message, pm) -- luacheck: ignore 212
		local xkcd_num = message:match("^!xkcd%s+(%d+)")
		if not xkcd_num then
			xkcd_num = message:match("https?://xkcd.com/(%d+)")
			if not xkcd_num then return end
		end
		local h, s = assert(http_request.new_from_uri("http://xkcd.com/"..xkcd_num.."/info.0.json"):go())
		if h:get":status" ~= "200" then return end
		local body = assert(s:get_body_as_string())
		local metadata = json.decode(body)
		if not metadata then return end
		local msg = string.format("%s: XKCD #%s '%s' https://xkcd.com/%s Alt: %s",
			sender[1], xkcd_num, metadata.title, xkcd_num, metadata.alt)
		irc:PRIVMSG(origin, msg)
	end;
}
