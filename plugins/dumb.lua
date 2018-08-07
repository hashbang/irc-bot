return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			if message:match("^!dumb") then
				irc:NOTICE(origin, "I wasted everyones time by copy-pasting this. - Zelaf")
			end
		end;
	};
}
