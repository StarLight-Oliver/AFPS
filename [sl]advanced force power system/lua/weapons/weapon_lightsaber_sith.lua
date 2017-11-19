AddCSLuaFile()

SWEP.Base = "weapon_lightsaber_star"

SWEP.PrintName = "Sith Saber"
SWEP.Author = "StarLight"
SWEP.Category = "AFPS"
SWEP.Contact = "http://steamcommunity.com/id/no1stargeorge"
SWEP.Purpose = "To slice off each others limbs and heads."
SWEP.Instructions = "Use the force, Luke."
SWEP.RenderGroup = RENDERGROUP_BOTH

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawWeaponInfoBox = false

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/sgg/starwars/weapons/w_anakin_ep2_saber_hilt.mdl"
SWEP.ViewModelFOV = 55

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.IsLightsaber = true
SWEP.ForceSelectEnabled = false

local powers = {
	"Force Lightning",
	"Force Light (Sith)",
	"Force Leap",
	"Force Use",
}

hook.Add( "CanUseLightsaberForcePower", "Sith_Force_Powers", function( ply, power )
	if ply:GetActiveWeapon():GetClass() == "weapon_lightsaber_sith" then
		local c = false
		for x,y in pairs(powers) do
			if power == y then
				c = true
			end
		end
		return c
	end
end )