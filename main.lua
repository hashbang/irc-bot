#!/usr/bin/env lua5.1

local cqueues = require "cqueues"

-- LuaIRC.
-- Docs: https://jakobovrum.github.io/LuaIRC/doc/modules/irc.html
local irc = require "irc"

local http_patt = "https?://[%w./%?%%+#_:;[%]%-!~*'()@&=%$,]+"

local cq = cqueues.new()
cq:wrap(function()
	local hb = irc.new {
		nick = "[]";
		username = "xmpp";
		realname = "hashbang-bot";
	}
	-- Set up for cqueues
	hb.events = "r"
	function hb:pollfd() return self.socket:getfd() end

	hb:connect {
		host = "irc.hashbang.sh";
		port = 6697;
		secure = true;
	}
	hb:join("#!") -- We should join automatically; but just in case.
	hb:join("#!social")
	hb:join("#!plan")

	-- Print to local console
	hb:hook("OnJoin", function(user, channel)
		print(user.nick, "-->", channel)
	end)
	hb:hook("OnPart", function(user, channel)
		print(user.nick, "<--", channel)
	end)
	hb:hook("OnChat", function(user, channel, message)
		print(channel, user.nick, message)
	end)

	local v_gd = require "v_gd"
	local http_request = require "socket.http".request
	local json = require "dkjson"
	hb:hook("OnChat", function(user, channel, message)
		-- We do everything in a single hook, as hooks are not called in a reliable order
		-- https://github.com/JakobOvrum/LuaIRC/issues/33

		-- If not from channel, reply to nick
		if not channel:match("^#") then
			channel = user.nick
		end

		if (function() -- !xkcd, created with cooperation of GeekDude (GitHub @G33kDude)
			local xkcd_num = message:match("^!xkcd%s+(%d+)")
			if not xkcd_num then
				xkcd_num = message:match("https?://xkcd.com/(%d+)")
				if not xkcd_num then return end
			end
			-- we can take the cheap/crap way out and use socket.http.request
			local body, code = http_request("http://xkcd.com/"..xkcd_num.."/info.0.json")
			if code ~= 200 then return end
			local metadata = json.decode(body)
			if not metadata then return end
			local msg = string.format("%s: XKCD #%s '%s' https://xkcd.com/%s Alt: %s",
				user.nick, metadata.title, xkcd_num, xkcd_num, metadata.alt)
			hb:sendChat(channel, msg)
			return true
		end)() then return end

		if (function() -- Shorten URLs
			local url = message:match(http_patt)
			if not url then return end
			-- Don't get in a loop
			if #url < 22 then return end
			-- Just in case v.gd urls get longer one day
			if url:match("https?://v.gd/") then return end
			local short = v_gd.shorten(url)
			local msg = string.format("%s: Shortened < %s >", user.nick, short)
			hb:sendChat(channel, msg)
			return true
		end)() then return end
	end)

	while cqueues.poll(hb) do
		hb:think()
	end
end)
assert(cq:loop())
