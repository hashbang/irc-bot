return {
	PRIVMSG = function(irc, sender, origin, message, pm) -- luacheck: ignore 212
		if message:match("^!source") then
			irc:PRIVMSG(origin, "See my source at https://github.com/hashbang/irc-bot")
		end
	end;
}
