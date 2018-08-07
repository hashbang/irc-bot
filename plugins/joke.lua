-- !joke, fetch jokes from icndb

local http_request = require "http.request"
local http_util = require "http.util"
local json = require "dkjson"

local url_format =
	"https://api.icndb.com/jokes/random?limitTo=nerdy&firstName=%s&lastName="

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
			local h, s = http_request.new_from_uri(url_format:format(
				http_util.encodeURI(first))):go()
			if not h or h:get":status" ~= "200" then
				print("Unable to fetch joke", h)
				return
			end
			local body = s:get_body_as_string()
			local joke = json.decode(body)
			if not joke or joke.type ~= "success" then
				print("Unable to fetch joke", body)
				return
			end
			local msg = string.format("%s: %s #%s",
				sender[1], joke.value.joke:gsub("  ", " "), joke.value.id)
			irc:NOTICE(origin, msg)
		end;
	};
}
