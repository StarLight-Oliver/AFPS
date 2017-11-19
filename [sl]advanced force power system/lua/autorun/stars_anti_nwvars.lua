
--[[ This is a method of not using the worst form of networked variables. For clarification its NVARS ARE THE WORST!!! Don't use them
This method may take up more space than NVARS but this is like lighting to NVARS. The lighting is MUCH faster

Lets hope some developers learn today

Message from
Star, Dani and The Maw
]]--

local meta = FindMetaTable("Player") // meta is the player its like calling SWEP in weapons
include("sl_config.lua")

if (SERVER) then
	util.AddNetworkString("CoolDown")
	util.AddNetworkString("requestforcepowerupdate")
	util.AddNetworkString("PowerTableUpdate")

	function meta:SetCoolDown(str,int)
		if !int then int = SL.PowerCoolDown[str] end
		if !self.CoolDown then self.CoolDown = {} end
		//print(str)
		self.CoolDown[str] = CurTime() + int // makes a nice table with all the cooldowns in
		
		net.Start("CoolDown")
			net.WriteEntity(self) // The Player you ran it on
			net.WriteString(str) // Force Power
			net.WriteFloat(CurTime() + int) // only sends the float not the table saves time both ends
		net.Send(self) // The Player Getting the Message
	end
	net.Receive("requestforcepowerupdate", function() 
		local wep = net.ReadEntity():GetActiveWeapon()
		wep:MovePowers()
		end)
	function meta:UpdatePowerTable(ent, tbl)
		for x,y in pairs(tbl) do
			tbl[x]["action"] = nil
			tbl[x]["think"] = nil
		end
		//PrintTable(tbl)
		net.Start("PowerTableUpdate")
			net.WriteEntity(ent) // The LightSaber
			net.WriteTable(tbl) // Force Powers
		net.Send(self) // The Player Getting the Message
		
	end
else
	net.Receive("CoolDown",function() 
		local ply = net.ReadEntity()
		local str = net.ReadString()
		local float = net.ReadFloat()
		if !ply.CoolDown then 
			ply.CoolDown = {}
		end
		ply.CoolDown[str] = float
		if !ply.CoolDownr then
			ply.CoolDownr = {}
		end
		local cc = float - CurTime()
		
		//ply:ChatPrint(cc)
		ply.CoolDownr[str] = cc
		//PrintTable(ply.CoolDownr)
		//	ply:ChatPrint(ply.CoolDownr[str])
	end)
	
	net.Receive("PowerTableUpdate", function() net.ReadEntity.ForcePowers = net.ReadTable() end)
end



function requestforcepowerupdate(ply)
	net.Start("requestforcepowerupdate")
		net.WriteEntity(ply)
	net.SendToServer()
end


local ccc = FindMetaTable("Entity")
local doors = {
	 "func_door",
	 "func_door_rotating", 
	 "prop_door_rotating",
	 "prop_dynamic",
}
function ccc:isDoor()
	if table.HasValue(doors, self:GetClass()) then return true end // fight me for the use of HasValue
	return false
end



if SERVER then return end