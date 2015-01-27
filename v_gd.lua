local http = require "socket.http"
local url = require "socket.url"

local function shorten(link)
	local b, c, h = http.request("http://v.gd/create.php?format=simple&url=" .. url.escape(link))
	if c ~= 200 then
		error("Unable to shorten link")
	end
	return b
end

return {
	shorten = shorten;
}
