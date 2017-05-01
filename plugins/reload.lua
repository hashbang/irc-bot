return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			if message:match("^!reload") then
				if true then
					irc:PRIVMSG(origin, sender[1] .. ": sorry, but reloading is disabled until https://github.com/hashbang/irc-bot/issues/11 is solved")
					return
				end
				irc:PRIVMSG(origin, "Reloading at request of " .. sender[1])
				irc:reload_plugins()
			end
		end;
	};
}
