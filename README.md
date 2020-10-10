# opcodes-lua
### Helper functions to improve net-library usage

Example:
```lua

net.AddOPVar{
	name = "print",
	payload = {"String", "Int"}, -- refer to the net.Write/Readx in the gmod wiki, eg: net.Read**String**
	func = function(ply, str, int)
		if CLIENT then
			print("Recieved broadcast 1 from Server!")
			print(str)
			print(int)
		end
	end
}
-- net.AddOPVar will also return a unique ID for it, you can use it when firing for a faster call.
local opcode2 = net.AddOPVar{
	name = "print2",
	payload = {"UInt", "Vector"},
	func = function(ply, uint, vec)
		if CLIENT then
			print("Recieved broadcast 2 from Server!")
			print(uint)
			print(vec)
		end
	end
}


if SERVER then
	net.FireOPVar("print", player.GetAll(), 
		"Hello world!", 
		-19999
	)
	net.FireOPVar(opcode2, player.GetByID(1), 
		3399944, 
		Vector(23, 23, 44)
	)
end

```
