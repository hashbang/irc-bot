return {
	PRIVMSG = function(irc, sender, origin, message, pm) -- luacheck: ignore 212
		if message:match("^!git pull") then
			local stdout, err = assert(io.popen("git pull --ff-only", "r"))
			local output
			if stdout then
				output, err = stdout:read()
				stdout:close()
			end
			local msg = sender[1] .. ": git pull complete: " .. (output or err):gsub("%c", " ")
			irc:PRIVMSG(origin, msg)
		end
	end;
}
