local knowledge_base = {
	hb = "The IRC client we use is weechat ( https://weechat.org/files/doc/stable/weechat_quickstart.en.html ), running in the tmux terminal multiplexer ( https://www.tmuxcheatsheet.com/ )";
}

return {
	hooks = {
		PRIVMSG = function(irc, state, sender, origin, message, pm) -- luacheck: ignore 212
			local topic = message:match("^!explain%s+(%S+)")
			if not topic then return end
			local answer = knowledge_base[topic]
			if answer == nil then
				answer = "I don't know about that topic. Submit a pull request!"
			end
			irc:NOTICE(origin, answer)
		end;
	}
}
