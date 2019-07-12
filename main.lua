#!/usr/bin/env lua5.2

local lfs = require "lfs"
local irce = require "irce"
local cqueues = require "cqueues"
local onerror = require "http.connection_common".onerror
local ca = require "cqueues.auxlib"
local cc = require "cqueues.condition"
local cs = require "cqueues.socket"

local function log(...)
	io.stderr:write(string.format(...), "\n")
end

local plugins = {}

local cq = cqueues.new()

local function connect(irc, config)
	local sock
	do
		local err, errno
		sock, err, errno = ca.fileresult(cs.connect {
			host = config.host;
			port = config.port or 6667;
		})
		if not sock then
			return nil, err, errno
		end
	end
	sock:onerror(onerror)
	sock:setmode("t", "bn") -- Binary mode, no output buffering
	if config.tls then
		local ok, err, errno = sock:starttls(config.tls)
		if not ok then
			return nil, err, errno
		end
	end
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

	return true
end

local function start(config)
	if options == nil then
		options = {}
	end

	local irc = irce.new()
	irc:load_module(require "irce.modules.base")
	irc:load_module(require "irce.modules.channel")
	irc:load_module(require "irce.modules.message")
	irc:load_module(require "irce.modules.motd")

	local last_connect = 0
	local function try_connect(self)
		local now = os.time()
		local since_last = now - last_connect
		local timeout = config.reconnect_timeout or 30
		if since_last < timeout then
			log("Disconnecting too fast from %s:%d", config.host, config.port or 6667)
			cqueues.sleep(timeout - since_last)
		end
		log("Reconnecting to %s:%d", config.host, config.port or 6667)
		last_connect = now
		local ok, err = connect(self, config)
		if not ok then
			log(err)
			return try_connect(self)
		end
	end
	function irc:on_disconnect()
		try_connect(self)
	end

	-- Print to local console
	irc:set_callback(irce.RAW, function(self, send, message) -- luacheck: ignore 212
		print(("%s %s"):format(send and ">>>" or "<<<", message))
	end)

	-- Handle nick conflict
	irc:set_callback("433", function(self, sender, info) -- luacheck: ignore 212
		local old_nick = info[2]
		local new_nick = "[" .. old_nick .. "]"
		self:NICK(new_nick)
	end)

	local nickserv_identified = false
	local nickserv_cond = cc.new()
	-- When nickserv identify succeeds
	irc:load_module({
		hooks = {
			NOTICE = function(self, state, sender, origin, message, pm)
				if not pm or
					not sender[1]:match("[Nn]ickserv") or
					not message:match("ou are now identified")
				then
					return
				end
				nickserv_identified = true
				nickserv_cond:signal()
			end;
		}
	})

	local has_welcome = false
	local welcome_cond = cc.new()
	irc:set_callback("001", function(self)
		has_welcome = true
		welcome_cond:signal()
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
			local ok, err = self:unload_module(v)
			if not ok then
				io.stderr:write(string.format("Failed to unload %s: %s\n", k, err))
			end
			plugins[k] = nil
		end
	end

	function irc:reload_plugins()
		self:unload_plugins()
		self:load_plugins()
	end

	try_connect(irc, config)
	irc:load_plugins()

	-- Do connecting
	assert(irc:NICK(config.nick))
	assert(irc:USER(config.user or os.getenv"USER", "hashbang-bot"))

	-- Once server has sent "welcome" line
	cq:wrap(function()
		while not has_welcome do
			welcome_cond:wait()
		end

		local nickserv = config.nickserv
		if nickserv then
			-- identify with nickserv
			local msg = nickserv.password
			if nickserv.username then
				msg = nickserv.username .. " " .. msg
			end
			irc:PRIVMSG("nickserv", "id " .. msg)
		end
		-- join channels
		for c, channel_config in pairs(config.channels) do
			if channel_config.needs_registration then
				cq:wrap(function()
					while not nickserv_identified do
						-- wait for nickserv
						nickserv_cond:wait()
					end

					irc:JOIN(c)
				end)
			else
				irc:JOIN(c)
			end
		end
	end)

	-- Send a PING every minute
	cqueues.running():wrap(function()
		local ping_counter = 0
		while true do
			cqueues.sleep(60)
			ping_counter = ping_counter + 1
			irc:PING(string.format("%d", ping_counter))
		end
	end)
end

local config = dofile "config.lua"
for _, conf in pairs(config) do
	cq:wrap(start, conf)
end

local ok, err, _, thd = cq:loop()
if not ok then
	err = debug.traceback(thd, err)
	error(err)
end
