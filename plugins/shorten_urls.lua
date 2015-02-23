-- Shorten URLs
local http = require "socket.http"
local url = require "socket.url"

local function shorten(link)
	local b, c, h = http.request("http://v.gd/create.php?format=simple&url=" .. url.escape(link))
	if c ~= 200 then
		error("Unable to shorten link")
	end
	return b
end

local http_patt = "https?://[%w./%?%%+#_:;[%]%-!~*'()@&=%$,]+"

return {
	PRIVMSG = function(irc, sender, origin, message, pm)
		local url = message:match(http_patt)
		if not url then return end
		-- Don't get in a loop
		if #url < 22 then return end
		-- Just in case v.gd urls get longer one day
		if url:match("https?://v.gd/") then return end
		local short = shorten(url)
		local msg = string.format("%s: Shortened < %s >", sender[1], short)
		irc:PRIVMSG(origin, msg)
	end;
}
