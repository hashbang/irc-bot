return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			if message:match("^!reload") then
				irc:NOTICE(origin, "Reloading at request of " .. sender[1])
				irc:reload_plugins()
			end
		end;
	};
}
