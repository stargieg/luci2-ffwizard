#!/usr/bin/env lua

local json = require "luci.jsonc"
local fs   = require "nixio.fs"
local utl = require "luci.util"

local methods = {
	getVersion = {
		call = function()
			local telnet_port = 2009
			local req_json
			req_json = utl.exec("(echo '/systeminfo json version /quit' | nc ::1 %d) 2>/dev/null" % telnet_port)
			return { result = req_json }
		end
	},
	
	getLan = {
		call = function()
			local telnet_port = 2009
			local req_json
			req_json = utl.exec("(echo '/olsrv2info json lan /quit' | nc ::1 %d) 2>/dev/null" % telnet_port)
			return { result = req_json }
		end
	},
	
	getNode = {
		call = function()
			local telnet_port = 2009
			local req_json
			req_json = utl.exec("(echo '/olsrv2info json node /quit' | nc ::1 %d) 2>/dev/null" % telnet_port)
			return { result = req_json }
		end
	},
	
	getNeighbors = {
		call = function()
			local ipc = require "luci.ip"
			local uci = require "luci.model.uci".cursor()
			local ntm = require "luci.model.network".init()
			local devices  = ntm:get_wifidevs()
			local assoclist = {}
			local data = {}
			local req_json
			local telnet_port = 2009
			local resolve = uci:get("luci_olsr2", "general", "resolve")
		
			for _, dev in ipairs(devices) do
				for _, net in ipairs(dev:get_wifinets()) do
						local radio = net:get_device()
						assoclist[#assoclist+1] = {}
						assoclist[#assoclist]['ifname'] = net:ifname()
						assoclist[#assoclist]['network'] = net:network()[1]
						assoclist[#assoclist]['device'] = radio and radio:name() or nil
						assoclist[#assoclist]['list'] = net:assoclist()
				end
			end
		
			req_json = json.parse(utl.exec("(echo '/nhdpinfo json neighbor /quit' | nc ::1 %d) 2>/dev/null" % telnet_port))
			if not (type(req_json) == "table") then
				return
			end
		
			for _, neighbors in pairs(req_json) do
				for nidx, neighbor in pairs(neighbors) do
					if not neighbor then
						return
					end
					neighbors[nidx].proto = 6
					local rt = ipc.route(neighbor["neighbor_originator"])
					if not rt then
						return
					end
					local localIP=rt.src:string()
					neighbors[nidx].localIP=localIP
					neighbors[nidx].interface = ntm:get_status_by_address(localIP) or "?"
					utl.exec("ping6 -q -c1 %s" % rt.gw:string().."%"..rt.dev)
					ipc.neighbors({ dest = rt.gw:string() }, function(ipn)
						neighbors[nidx].mac = ipn.mac
						for _, val in ipairs(assoclist) do
							if val.network == neighbors[nidx].interface and val.list then
								local assocmac, assot
								for assocmac, assot in pairs(val.list) do
									if ipn.mac == luci.ip.new(assocmac) then
										neighbors[nidx].signal = tonumber(assot.signal) or 0
										neighbors[nidx].noise = tonumber(assot.noise) or 0
										neighbors[nidx].snr = (neighbors[nidx].noise*-1) - (neighbors[nidx].signal*-1)
									end
								end
							end
						end
					end)
					if resolve == "1" then
						local hostname = nixio.getnameinfo(neighbor["neighbor_originator"])
						if hostname then
							neighbors[nidx].hostname = hostname
						end
					end
				end
				data = neighbors
			end
			return { result = data }
		end
	},
	
	getAttached_network = {
		call = function()
			local telnet_port = 2009
			local req_json
			req_json = utl.exec("(echo '/olsrv2info json attached_network /quit' | nc ::1 %d) 2>/dev/null" % telnet_port)
			return { result = req_json }
		end
	}
}
local function parseInput()
	local parse = json.new()
	local done, err

	while true do
		local chunk = io.read(4096)
		if not chunk then
			break
		elseif not done and not err then
			done, err = parse:parse(chunk)
		end
	end

	if not done then
		print(json.stringify({ error = err or "Incomplete input" }))
		os.exit(1)
	end

	return parse:get()
end

local function validateArgs(func, uargs)
	local method = methods[func]
	if not method then
		print(json.stringify({ error = "Method not found" }))
		os.exit(1)
	end

	if type(uargs) ~= "table" then
		print(json.stringify({ error = "Invalid arguments" }))
		os.exit(1)
	end

	uargs.ubus_rpc_session = nil

	local k, v
	local margs = method.args or {}
	for k, v in pairs(uargs) do
		if margs[k] == nil or
		   (v ~= nil and type(v) ~= type(margs[k]))
		then
			print(json.stringify({ error = "Invalid arguments" }))
			os.exit(1)
		end
	end

	return method
end

if arg[1] == "list" then
	local _, method, rv = nil, nil, {}
	for _, method in pairs(methods) do rv[_] = method.args or {} end
	print((json.stringify(rv):gsub(":%[%]", ":{}")))
elseif arg[1] == "call" then
	local args = parseInput()
	local method = validateArgs(arg[2], args)
	local result, code = method.call(args)
	print((json.stringify(result):gsub("^%[%]$", "{}")))
	os.exit(code or 0)
end
