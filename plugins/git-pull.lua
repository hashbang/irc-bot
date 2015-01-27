return {
	OnChat = function(conn, user, channel, message)
		if message:match("^!git pull") then
			local res = os.execute("git pull --ff-only")
			local msg = user.nick .. ": git pull complete: "..tostring(res)
			conn:sendChat(channel, msg)
			return true
		end
	end;
}
