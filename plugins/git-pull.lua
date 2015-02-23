return {
	PRIVMSG = function(irc, sender, origin, message, pm)
		if message:match("^!git pull") then
			local res = os.execute("git pull --ff-only")
			local msg = sender[1] .. ": git pull complete: " .. tostring(res)
			irc:PRIVMSG(origin, msg)
		end
	end;
}
