-- !joke, fetch jokes from icndb

local http_request = require "http.request"
local json = require "dkjson"

return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			if not message:match("^!joke") then
				return
			end
			local first = message:match("^!joke%s+(%g+)")
			if not first then
				first = sender[1]
			end
			local h, s = assert(http_request.new_from_uri(
			        "https://api.icndb.com/jokes/random?limitTo=nerdy&firstName="..first.."&lastName="):go())
			if h:get":status" ~= "200" then return end
			local body = assert(s:get_body_as_string())
			local joke = json.decode(body)
			if not joke or joke.type ~= "success" then return end
			local msg = string.format("%s: %s #%s",
				sender[1], joke.value.joke, joke.value.id)
			irc:PRIVMSG(origin, msg)
		end;
	};
}
