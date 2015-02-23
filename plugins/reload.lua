return {
	PRIVMSG = function(irc, sender, origin, message, pm)
		if message:match("^!reload") then
			irc:PRIVMSG(origin, "Reloading at request of " .. sender[1])
			irc:reload_plugins()
		end
	end;
}
