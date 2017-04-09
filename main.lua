#!/usr/bin/env lua5.2

local lfs = require "lfs"
local irce = require "irce"
local cqueues = require "cqueues"
local cs = require "cqueues.socket"

local function log(...)
	io.stderr:write(string.format(...), "\n")
end

local plugins = {}

local cq = cqueues.new()

local function connect(irc, cd, nick)
	local sock = assert(cs.connect {
		host = cd.host;
		port = cd.port or 6667;
	})
	sock:setmode("t", "bn") -- Binary mode, no output buffering
	if cd.tls then assert(sock:starttls(cd.tls)) end
	irc:set_send_func(function(self, message) -- luacheck: ignore 212
		return sock:write(message)
	end)
	cqueues.running():wrap(function()
		for line in sock:lines() do
			irc:process(line)
		end
		log("Disconnected.")
		sock:shutdown()
		irc:on_disconnect()
	end)

	-- Do connecting
	assert(irc:NICK(nick))
	assert(irc:USER(os.getenv"USER", "hashbang-bot"))
end

local function start(cd, channels, nick)
	local irc = irce.new()
	irc:load_module(require "irce.modules.base")
	irc:load_module(require "irce.modules.message")
	irc:load_module(require "irce.modules.channel")

	local last_connect = os.time()
	function irc:on_disconnect()
		local now = os.time()
		if now < last_connect + (cd.reconnect_timeout or 30) then
			log("Disconnecting too fast.")
		else
			last_connect = now
			log("Reconnecting")
			connect(self, cd, nick)
		end
	end

	-- Print to local console
	irc:set_callback("RAW", function(self, send, message) -- luacheck: ignore 212
		print(("%s %s"):format(send and ">>>" or "<<<", message))
	end)

	-- Handle nick conflict
	irc:set_callback("433", function(self, sender, info)
		local old_nick = info[2]
		local new_nick = "[" .. old_nick .. "]"
		self:NICK(new_nick)
	end)

	-- Once server has sent "welcome" line, join channels
	irc:set_callback("001", function(self)
		for _, v in ipairs(channels) do
			self:JOIN(v)
		end
	end)

	function irc:load_plugins()
		for file in lfs.dir("./plugins") do
			if file:sub(1,1) ~= "." and file:match(".lua$") then
				local func, err = loadfile("./plugins/"..file)
				if func == nil then
					log("Failed to parse plugin %s: %s", file, err)
				else
					local ok, plugin = pcall(func)
					if not ok then
						log("Failed to run plugin %s: %s", file, plugin)
					else
						ok, err = self:load_module(plugin)
						if not ok then
							log("Failed to load plugin %s: %s", file, err)
						else
							log("Successfully loaded plugin %s", file)
							plugins[file] = plugin
						end
					end
				end
			end
		end
	end

	function irc:unload_plugins()
		for k, v in pairs(plugins) do
			self:unload_module(v)
			plugins[k] = nil
		end
	end

	function irc:reload_plugins()
		self:unload_plugins()
		self:load_plugins()
	end

	connect(irc, cd, nick)
	irc:load_plugins()
end
cq:wrap(start, {host="irc.hashbang.sh", port=6697, tls=true}, {
	"#!";
	"#!social";
	"#!plan";
	"#!music";
}, "[]")
assert(cq:loop())
