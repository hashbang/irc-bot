return {
	PRIVMSG = function(irc, sender, origin, message, pm) -- luacheck: ignore 212
		if message:match("^!reload") then
			irc:PRIVMSG(origin, "Reloading at request of " .. sender[1])
			irc:reload_plugins()
		end
	end;
}
