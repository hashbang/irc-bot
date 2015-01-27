#!/usr/bin/env lua5.1

local lfs = require "lfs"
local cqueues = require "cqueues"

-- LuaIRC.
-- Docs: https://jakobovrum.github.io/LuaIRC/doc/modules/irc.html
local irc = require "irc"

local function log(...)
	io.stderr:write(string.format(...), "\n")
end

local plugins = {}
local function clear_plugins()
	for k,v in pairs(plugins) do
		plugins[k] = nil
	end
end
local function load_plugins()
	for file in lfs.dir("./plugins") do
		if file:sub(1,1) ~= "." and file:match(".lua$") then
			local func, err = loadfile("./plugins/"..file)
			if func == nil then
				log("Failed to load plugin %s: %s", file, err)
			else
				local ok, plugin = pcall(func)
				if not ok then
					log("Failed to run plugin %s: %s", file, err)
				else
					log("Successfully loaded plugin %s", file)
					plugins[file] = plugin
				end
			end
		end
	end
end
load_plugins()

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

	function hb:reload_plugins()
		clear_plugins()
		load_plugins()
	end

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

	hb:hook("OnChat", function(user, channel, message)
		-- We do everything in a single hook, as hooks are not called in a reliable order
		-- https://github.com/JakobOvrum/LuaIRC/issues/33

		-- If not from channel, reply to nick
		if not channel:match("^#") then
			channel = user.nick
		end
		for name, plugin in pairs(plugins) do
			if plugin.OnChat then
				local ok, err = pcall(plugin.OnChat, hb, user, channel, message)
				if not ok then
					log("Plugin %s failed: %s", name, tostring(err))
				end
			end
		end
	end)

	while cqueues.poll(hb) do
		hb:think()
	end
end)
assert(cq:loop())
