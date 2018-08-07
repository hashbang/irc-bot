return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			if message:match("^!source") then
				irc:NOTICE(origin, "See my source at https://github.com/hashbang/irc-bot")
			end
		end;
	};
}
