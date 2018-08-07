--- Weather Plugin for IRC bot.
-- Written by stinethebean and daurnimator
-- Uses Yahoo's YQL to fetch the weather for a given location
-- triggered by !w <location> or !weather <location>

local unpack = table.unpack or unpack
local http_request = require "http.request"
local url_encode = require "http.util".encodeURIComponent
local json = require "dkjson"

-- YQL = yahoo query language

-- this function makes it so the string it's given is safe to put into a YQL string
-- seems that if you use single quotes, you only have to escape single quotes
-- in the given string (s), it is replacing singlequotes (') with (\')
local function yql_encode_string(s)
	-- gsub is a global substitution of matches in the string
	-- we have to double escape the \', as it means something special to lua too
	return "'" .. s:gsub("'", "\\'") .. "'"
end

-- Perform a YQL query
local function yql_query(q)
	local url = "http://query.yahooapis.com/v1/public/yql?q="
		.. url_encode(q) .. "&format=json"
	local r = http_request.new_from_uri(url)
	local h, s = assert(r:go())
	local b, err = s:get_body_as_string()
	if not b then
		return nil, err
	end
	if h:get":status" ~= "200" then -- in lua, ~= is not equal to
		return nil, b
	end
	local response = json.decode(b)
	local query = response.query
	if query.count <= 1 then
		return query.results
	else
		return unpack(query.results)
	end
end

local function farenheit_to_celsius(f)
	return (f - 32) * (5/9)
end

return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			local location = message:match("^!w%s+(.+)")
			if not location then
				location = message:match("^!weather%s+(.+)")
				if not location then return end
			end
			local weather, err = yql_query("select * from weather.forecast where woeid in ("
				.. "select woeid from geo.places(1) where text=" .. yql_encode_string(location)
				.. ") and u='f'")
			local msg
			if weather then
				-- weather is a table; we need to retrieve portions of it's content

				-- %s is filled in with what we want
				msg = string.format("%s: %s: %s %s°F (%d°C)",
					sender[1],
					weather.channel.item.title,
					weather.channel.item.condition.text,
					-- this temp comes in to us as a string,
					-- so we don't bother converting it to a number just to convert it back again
					weather.channel.item.condition.temp,
					-- we use %d for this instead of %s as it's a number
					farenheit_to_celsius(tonumber(weather.channel.item.condition.temp))
					-- we're converting the temp in farenheit (held in weather.channel.item.condition.temp)
					-- to a number, then going to pass it to the conversion function
				)
			elseif err == nil then
				msg = string.format("%s: weather seems to be unavailable", sender[1])
			else
				msg = string.format("error fetching weather: %q", err)
			end
			irc:NOTICE(origin, msg)
		end;
	};
}
