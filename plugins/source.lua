return {
	OnChat = function(conn, user, channel, message)
		if message:match("^!source") then
			conn:sendChat(channel, "See my source at https://github.com/hashbang/irc-bot")
			return true
		end
	end;
}
