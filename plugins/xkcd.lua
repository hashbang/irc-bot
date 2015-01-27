-- !xkcd, created with cooperation of GeekDude (GitHub @G33kDude)

local http_request = require "socket.http".request
local json = require "dkjson"

return {
	OnChat = function(conn, user, channel, message)
		local xkcd_num = message:match("^!xkcd%s+(%d+)")
		if not xkcd_num then
			xkcd_num = message:match("https?://xkcd.com/(%d+)")
			if not xkcd_num then return end
		end
		-- we can take the cheap/crap way out and use socket.http.request
		local body, code = http_request("http://xkcd.com/"..xkcd_num.."/info.0.json")
		if code ~= 200 then return end
		local metadata = json.decode(body)
		if not metadata then return end
		local msg = string.format("%s: XKCD #%s '%s' https://xkcd.com/%s Alt: %s",
			user.nick, xkcd_num, metadata.title, xkcd_num, metadata.alt)
		conn:sendChat(channel, msg)
		return true
	end;
}
