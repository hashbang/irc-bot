return {
	OnChat = function(conn, user, channel, message)
		if message:match("^!reload") then
			for channel in pairs(conn.channels) do
				conn:sendChat(channel, "Reloading at request of " .. user.nick)
			end
			conn:reload_plugins()
			return true
		end
	end;
}
