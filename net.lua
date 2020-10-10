/*
Net op-code idea
Made by Sirro
*/
AddCSLuaFile()
local net = net
local net_table = net_table || {}

local net_name = "net_table_main"
local netReferences = {
	["Angle"] = 0,
	["Bit"] = 0,
	["Bool"] = 0,
	["Color"] = 0,
	["Data"] = 2,
	["Double"] = 0,
	["Entity"] = 0,
	["Float"] = 0,
	["Int"] = 1,
	["Matrix"] = 0,
	["Normal"] = 0,
	["String"] = 0,
	["Table"] = 0, -- don't use this, that defeats the whole purpose
	["Type"] = 0,
	["UInt"] = 1,
	["Vector"] = 0
}

local function countBits(num)
	return math.ceil ( math.log(  math.abs( num ), 2) + 1 )
end


if SERVER then
	util.AddNetworkString(net_name)
end
net.Receive(net_name, function(len, ply)
	local opCode = net.ReadUInt(8) -- 255 should be enough, right?
	local netTab = net_table[opCode]
	if netTab then
		local payload = {}

		if netTab.payload then
			for k, v in ipairs(netTab.payload) do
				-- read requires argument, e.x: WriteUInt (8)
				local hasSize = net.ReadBool()
				if hasSize then
					local size = net.ReadUInt(6)
					payload[#payload + 1] = net["Read" .. v](size)
					continue
				end
				payload[#payload + 1] = net["Read" .. v]()
			end
			netTab.func(ply, unpack(payload))
		end
	end
end)


-- can use the opcode or the name, opcode is faster though
function net.FireOPVar(uid, ...)
	local netTab

	local vars = {...}

	local opcode
	local plyTab
	-- search for opcode/name
	-- person is using opcode
	if isnumber(uid) then
		netTab = net_table[uid]
		opcode = uid
	else -- person is using name
		for k, v in ipairs(net_table) do
			if v.name == uid then
				netTab = v
				opcode = k
				break
			end
		end
	end
	if !netTab then return end -- didn't find anything

	-- server will vore the first variable in the varargs as the player targets
	if SERVER then
		plyTab = vars[1]
		table.remove(vars, 1)
	end
	-- verifying; these should match/have an identical variable count
	for k, v in ipairs(netTab.payload) do
		assert(netReferences[v], "Var " .. v .. " in pos " .. k .. " is not valid type!")
	end
	net.Start(net_name)
	net.WriteUInt(opcode, 8) -- opcode

	for k, v in ipairs(netTab.payload) do
		if netReferences[ v ] >= 1 then
			local size = countBits( netReferences[ v ] == 2 && #vars[k] || vars[k] )
			net.WriteBool(true)
			net.WriteUInt( size, 6 )
			net["Write" .. v](vars[k], size)
			continue
		end
		net.WriteBool(false)
		net["Write" .. v](vars[k])
	end

	if SERVER then
		net.Send(plyTab)
	else
		net.SendToServer()
	end
end

function net.AddOPVar(tab)
	if !tab || !tab.name then return end
	-- lua refersh support
	for k, v in ipairs(net_table) do
		if v.name == tab.name then
			net_table[k] = tab
			return k
		end
	end

	-- insert
	local opCode = #net_table + 1
	net_table[opCode] = tab

	return opCode
end
