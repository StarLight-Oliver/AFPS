AddCSLuaFile()

SWEP.Base = "weapon_lightsaber"

SWEP.PrintName = "Standard Saber"
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
local sl = SL.ForcePowers
//timer.Simple(0.1,function()
//end)

function SWEP:GetActiveForcePowers()
	local ForcePowers = {}
	for id, t in pairs( SL.ForcePowers ) do
		local ret = hook.Run( "CanUseLightsaberForcePower", self:GetOwner(), t.name )
		if ( ret == false ) then continue end

		table.insert( ForcePowers, t )
	end
	return ForcePowers
end


hook.Add( "ScalePlayerDamage", "Deflect Bullets", function( ent, hitgroup, dmginfo )
	if not ent:IsPlayer() then return end
	if ( IsValid( ent ) && IsValid( ent:GetActiveWeapon() ) && ent:GetActiveWeapon().IsLightsaber ) then // Makes sure the weapon is a lightsaber so you do not deflect things when we have something else equipped
		local self = ent:GetActiveWeapon()
		if self:GetBladeLength() > 1 then
			if ent:GetActiveWeapon():GetActiveForcePowerType( self:GetForceType() ).name == "Force Deflect" && ent:KeyDown(IN_ATTACK2) && ent:GetActiveWeapon():GetForce() > 1 then
				if dmginfo:IsDamageType( DMG_BULLET ) || dmginfo:IsDamageType( DMG_SHOCK ) then // gets the damage type of the damage dealt so that we do not defelect things like prop damage (That would be very strange)
					local angle = ( dmginfo:GetAttacker():GetPos() - ent:GetPos() ):Angle() // Gets the angle differences
					if ( math.AngleDifference( angle.y, ent:EyeAngles().y ) <= 35 ) and ( math.AngleDifference( angle.y, ent:EyeAngles().y ) >= -35 ) then // are the players basically facing each other
						local bullet = {}
						bullet.Num 		= 1
						bullet.Src 		= ent:EyePos()			
						bullet.Dir 		= ent:GetAimVector()
						bullet.Spread 	= 0		
						bullet.Tracer	= 1
						bullet.Force	= 0						
						bullet.Damage	= dmginfo:GetDamage()
						if bullet.Damage < 0 then bullet.Damage = bullet.Damage*-1 end // inverts the damage 
						bullet.AmmoType = "Pistol" // ammo type does not really matter
						bullet.TracerName = dmginfo:GetAttacker():GetActiveWeapon().TracerName or "Ar2Tracer" // gets a custom trace this will cause issues with TFA right now
						ent:FireBullets( bullet ) // fires one bullet
						ent:EmitSound( "lightsaber/saber_hit_laser" .. math.random( 1, 4 ) .. ".wav" ) // plays a sound like the person has deflected it with their weapon
						dmginfo:SetDamage( 0 ) // Sets the damage which we get to nothing so we do not feel the damage
						ent:GetActiveWeapon():SetForce( ent:GetActiveWeapon():GetForce() - 1 ) // minuses one force for bullet we get shot at us
					end
				end
			end
		end
	end
end )

function SWEP:SecondaryAttack()
	if ( !IsValid( self.Owner ) or !self:GetActiveForcePowerType( self:GetForceType() ) ) then return end
	if ( game.SinglePlayer() && SERVER ) then self:CallOnClient( "SecondaryAttack", "" ) end

	local selectedForcePower = self:GetActiveForcePowerType( self:GetForceType() )
	if ( !selectedForcePower ) then return end

	local ret = hook.Run( "CanUseLightsaberForcePower", self.Owner, selectedForcePower.name )
	if ( ret == false ) then return end
	
	if ( selectedForcePower.action) then
		if self.Owner.CoolDown && self.Owner.CoolDown[selectedForcePower.name] then
			if self.Owner.CoolDown[selectedForcePower.name] > CurTime() then return end
		end
		selectedForcePower.action( self )
		if ( GetConVarNumber( "rb655_lightsaber_infinite" ) != 0 ) then self:SetForce( 100 ) end	
	end
end

function SWEP:Think()

	self.WorldModel = self:GetWorldModel()
	self:SetModel( self:GetWorldModel() )

	local selectedForcePower = self:GetActiveForcePowerType( self:GetForceType() )
	if ( selectedForcePower && selectedForcePower.think && !self.Owner:KeyDown( IN_USE ) ) then
		local ret = hook.Run( "CanUseLightsaberForcePower", self.Owner, selectedForcePower.name )
		if ( ret != false && selectedForcePower.think ) then
			selectedForcePower.think( self )
		end
	end

	if ( CLIENT ) then return true end

	if ( ( self.NextForce or 0 ) < CurTime() ) then
		self:SetForce( math.min( self:GetForce() + 0.5, 100 ) )
	end

	if ( !self:GetEnabled() && self:GetBladeLength() != 0 ) then
		self:SetBladeLength( math.Approach( self:GetBladeLength(), 0, 2 ) )
	elseif ( self:GetEnabled() && self:GetBladeLength() != self:GetMaxLength() ) then
		self:SetBladeLength( math.Approach( self:GetBladeLength(), self:GetMaxLength(), 8 ) )
	end

	if ( self:GetEnabled() && !self:GetWorksUnderwater() && self.Owner:WaterLevel() > 2 ) then
		self:SetEnabled( false )
		--self:EmitSound( self:GetOffSound() )
	end

	if ( self:GetBladeLength() <= 0 ) then return end

	-- ------------------------------------------------- DAMAGE ------------------------------------------------- --

	-- This whole system was needed to be reworked, There you go Robotboy655 reworked

	local blades = 0
	local hit = false
	for id, t in pairs( self:GetAttachments() ) do
		if  !string.match( t.name, "blade(%d+)" ) then continue end

		local bladeNum = string.match( t.name, "blade(%d+)" )

		if ( bladeNum && self:LookupAttachment( "blade" .. bladeNum ) > 0 ) then
			if SL:DamageTrace(self, bladeNum) && !hit then
				hit = true
			end
		end
	end
	if blades == 0 then
		if SL:DamageTrace(self, 1) && !hit then
			hit = true
		end
	end
	if ( ( hit ) && self.SoundHit ) then
		self.SoundHit:ChangeVolume( math.Rand( 0.1, 0.5 ), 0 )
	elseif ( self.SoundHit ) then
		self.SoundHit:ChangeVolume( 0, 0 )
	end

	-- ------------------------------------------------- SOUNDS ------------------------------------------------- --
	local pos, ang = self:GetSaberPosAng()
	if ( self.SoundSwing ) then

		if ( self.LastAng != ang ) then
			self.LastAng = self.LastAng or ang
			self.SoundSwing:ChangeVolume( math.Clamp( ang:Distance( self.LastAng ) / 2, 0, 1 ), 0 )
		end

		self.LastAng = ang
	end

	if ( self.SoundLoop ) then
		pos = pos + ang * self:GetBladeLength()

		if ( self.LastPos != pos ) then
			self.LastPos = self.LastPos or pos
			self.SoundLoop:ChangeVolume( 0.1 + math.Clamp( pos:Distance( self.LastPos ) / 128, 0, 0.2 ), 0 )
		end
		self.LastPos = pos
	end
end

if SERVER then return end
/*
local grad = Material( "gui/gradient_up" )
local function DrawHUDBox( x, y, w, h, t, b, c)
// c is the texture argument
	x = math.floor( x )
	y = math.floor( y )
	w = math.floor( w )
	h = math.floor( h )
	
	
	
	if c then
		local texture = Material(t)
		surface.SetMaterial( texture )
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( x, y, w, h )
	
	else
		surface.SetDrawColor( 255, 255, 255, 255 )
		draw.NoTexture()
		surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
		surface.DrawTexturedRect( x, y, w, h )

		surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
		surface.DrawRect( x, y, w, h )
	end
	if ( b ) then
		surface.SetMaterial( grad )
		surface.SetDrawColor( Color( 0, 128, 255, 4 ) )
		surface.DrawTexturedRect( x, y, w, h )
	end

end


local ForceBar = 100
function SWEP:DrawHUD()
	if ( !IsValid( self.Owner ) || self.Owner:GetViewEntity() != self.Owner || self.Owner:InVehicle() ) then return end

	-----------------------------------
	self.ForcePowers = self:GetActiveForcePowers()
	local icon = 52
	local gap = 5

	local bar = 4
	local bar2 = 16

	if ( self.ForceSelectEnabled ) then
		icon = 54
		bar = 6
		bar2 = 18
	end

	----------------------------------- Force Bar -----------------------------------

	ForceBar = math.min( 100, Lerp( 0.1, ForceBar, math.floor( self:GetForce() ) ) )
	local w = #self.ForcePowers * icon + ( #self.ForcePowers - 1 ) * gap
	if #self.ForcePowers > 10 then
	w = 10 * icon + (9)* gap
	end
	
	local h = bar2
	local x = math.floor( ScrW() / 2 - w / 2 )
	local y = ScrH() - gap - bar2

	DrawHUDBox( x, y, w, h )

	local barW = math.ceil( w * ( ForceBar / 100 ) )
	if ( self:GetForce() <= 1 && barW <= 1 ) then barW = 0 end
	draw.RoundedBox( 0, x, y, barW, h, Color( 0, 128, 255, 255 ) )

	draw.SimpleText( math.floor( self:GetForce() ) .. "%", "SelectedForceHUD", x + w / 2, y + h / 2, Color( 255, 255, 255 ), 1, 1 )

	----------------------------------- Force Icons -----------------------------------

	local y = y - icon - gap
	local h = icon
	local cy = y
	if #self.ForcePowers < 10 then
	for id, name in pairs( self.ForcePowers ) do
		//print(self.ForcePowers[id].name)
		local x = x + ( id - 1 ) * ( h + gap )
		local x2 = math.floor( x + icon / 2 )
		if hook.Run( "CanUseLightsaberForcePower", self.Owner, self.ForcePowers[ id ].name ) then continue end
		if self.ForcePowers[ id ].texture and self.ForcePowers[ id ].texture != "" then
			DrawHUDBox( x, y, h, h, self.ForcePowers[ id ].texture, self:GetForceType() == id, true)
		else
			DrawHUDBox( x, y, h, h, "naruto/basic/Icon", self:GetForceType() == id, false)
		end
		draw.SimpleText( self.ForcePowers[ id ].icon || "", "SelectedForceType", x2, math.floor( y + icon / 2 ), Color( 255, 255, 255 ), 1, 1 )
		if ( self.ForceSelectEnabled ) then
			draw.SimpleText( ( input.LookupBinding( "slot" .. id ) || "<NOT BOUND>" ):upper(), "SelectedForceHUD", x + gap, y + gap, Color( 255, 255, 255 ) )
		end
		if ( self:GetForceType() == id ) then
			local y = y + ( icon - bar )
			surface.SetDrawColor( 0, 128, 255, 255 )
			draw.NoTexture()
			surface.DrawPoly( {
				{ x = x2 - bar, y = y },
				{ x = x2, y = y - bar },
				{ x = x2 + bar, y = y }
			} )
			draw.RoundedBox( 0, x, y, h, bar, Color( 0, 128, 255, 255 ) )
		end
	end
	else
		cy = y
		local count = 0
		for id, name in pairs( self.ForcePowers ) do
		//print(self.ForcePowers[id].name)
		if !self.ForcePowers[id].name then continue end
		if hook.Run( "CanUseLightsaberForcePower", self.Owner, self.ForcePowers[ id ].name ) then continue end
		local pow = self.ForcePowers[id].name
		if count == 10 then
		cy = y - gap - icon
		count = 0
		end
		count = count + 1  
		local x = x + ( count - 1 ) * ( h + gap )
		local x2 = math.floor( x + icon / 2 )
		if self.Owner.CoolDown && self.Owner.CoolDown[pow] && self.Owner.CoolDown[pow] > CurTime() then
			if self.ForcePowers[ id ].texture and self.ForcePowers[ id ].texture != "" then
				DrawHUDBox( x, cy, h, h, self.ForcePowers[ id ].texture, self:GetForceType() == id, true)
			else
				DrawHUDBox( x, cy, h, h, "naruto/basic/Icon", self:GetForceType() == id, false)
			end
			local va = tonumber(self.Owner.CoolDownr[pow])
			local cva = h / va
			//print(va) 
			DrawHUDBox( x, cy, h, h, "naruto/basic/Icon", self:GetForceType() == id, false)
			local strinc = tostring(tonumber(self.Owner.CoolDown[pow]) - CurTime())
			local length = 1
			for c = 1,#strinc do
				if strinc[c] == "." then
					length = c - 1
					break
				end
			end
			draw.SimpleText( string.sub(strinc, 1, length)|| "", "SelectedForceType", x2, math.floor( cy + icon / 2 ), Color( 255, 255, 255 ), 1, 1 )
		
		else
			if self.ForcePowers[ id ].texture and self.ForcePowers[ id ].texture != "" then
				DrawHUDBox( x, cy, h, h, self.ForcePowers[ id ].texture, self:GetForceType() == id, true)
			else
				DrawHUDBox( x, cy, h, h, "naruto/basic/Icon", self:GetForceType() == id, false)
			end
			draw.SimpleText( self.ForcePowers[ id ].icon || "", "SelectedForceType", x2, math.floor( cy + icon / 2 ), Color( 255, 255, 255 ), 1, 1 )
		end
		if ( self.ForceSelectEnabled ) then
			if cy != y then
				draw.SimpleText( "Press " .. (input.LookupBinding("+zoom") || "+zoom"):upper(), "SelectedForceHUD", x + gap, cy + gap, Color( 255, 255, 255 ) )
			else
				draw.SimpleText( ( input.LookupBinding( "slot" .. id ) || "<NOT BOUND>" ):upper(), "SelectedForceHUD", x + gap, cy + gap, Color( 255, 255, 255 ) )
			end
		end
		if ( self:GetForceType() == id ) then
			local bb = cy + ( icon - bar )
			surface.SetDrawColor( 0, 128, 255, 255 )
			draw.NoTexture()
			surface.DrawPoly( {
				{ x = x2 - bar, y = bb },
				{ x = x2, y = bb - bar },
				{ x = x2 + bar, y = bb }
			} )
			draw.RoundedBox( 0, x, bb, h, bar, Color( 0, 128, 255, 255 ) )
		end
	end
	end
	----------------------------------- Force Description -----------------------------------
	if cy != y then
		y = cy
	end
	if ( self.ForceSelectEnabled ) then

		surface.SetFont( "SelectedForceHUD" )
		local tW, tH = surface.GetTextSize( self.ForcePowers[ self:GetForceType() ].description || "" )

		/*local x = x + w + gap
		local y = y
		local x = ScrW() / 2 + gap// - tW / 2
		local y = y - tH - gap * 3

		DrawHUDBox( x, y, tW + gap * 2, tH + gap * 2 )

		for id, txt in pairs( string.Explode( "\n", self.ForcePowers[ self:GetForceType() ].description || "" ) ) do
			draw.SimpleText( txt, "SelectedForceHUD", x + gap, y + ( id - 1 ) * ScreenScale( 6 ) + gap, Color( 255, 255, 255 ) )
		end

	end

	----------------------------------- Force Label -----------------------------------

	if ( !self.ForceSelectEnabled ) then
		surface.SetFont( "SelectedForceHUD" )
		local txt = "Press " .. ( input.LookupBinding( "impulse 100" ) || "<NOT BOUND>" ):upper() .. " to toggle Force selection"
		local tW, tH = surface.GetTextSize( txt )

		local x = x + w / 2
		local y = y - tH - gap

		DrawHUDBox( x - tW / 2 - 5, y, tW + 10, tH )
		draw.SimpleText( txt, "SelectedForceHUD", x, y, Color( 255, 255, 255 ), 1 )

		local isGood = hook.Call( "PlayerBindPress", nil, LocalPlayer(), "this_bind_doesnt_exist", true )
		if ( isGood == true ) then
			local txt = "Some addon is breaking the PlayerBindPress hook. Send a screenshot of this error to the mod page!"
			for name, func in pairs( hook.GetTable()[ "PlayerBindPress" ] ) do txt = txt .. "\n" .. tostring( name ) end
			local tW, tH = surface.GetTextSize( txt )

			y = y - tH - gap

			local id = 1
			DrawHUDBox( x - tW / 2 - 5, y, tW + 10, tH )
			draw.SimpleText( string.Explode( "\n", txt )[ 1 ], "SelectedForceHUD", x, y + 0, Color( 255, 230, 230 ), 1 )

			for str, func in pairs( hook.GetTable()[ "PlayerBindPress" ] ) do
				local clr = Color( 255, 255, 128 )
				if ( ( isstring( str ) && func( LocalPlayer(), "this_bind_doesnt_exist", true ) == true ) || ( !isstring( str ) && func( str, LocalPlayer(), "this_bind_doesnt_exist", true ) == true ) ) then
					clr = Color( 255, 128, 128 )
				end
				if ( !isstring( str ) ) then str = tostring( str ) end
				if ( str == "" ) then str = "<empty string hook>" end
				local _, lineH = surface.GetTextSize( str )
				draw.SimpleText( str, "SelectedForceHUD", x, y + id * lineH, clr, 1 )
				id = id + 1
			end
		end

	end	
	if ( self.ForceSelectEnabled ) then
		surface.SetFont( "SelectedForceType" )
		local txt = self.ForcePowers[ self:GetForceType() ].name or ""
		local tW2, tH2 = surface.GetTextSize( txt )

		local x = x + w / 2 - tW2 - gap * 2//+ w / 2
		local y = y + gap - tH2 - gap * 2

		DrawHUDBox( x, y, tW2 + 10, tH2 )
		draw.SimpleText( txt, "SelectedForceType", x + gap, y, Color( 255, 255, 255 ) )
	end

	----------------------------------- Force Target -----------------------------------

	local isTarget = self.ForcePowers[ self:GetForceType() ].target

	if ( isTarget ) then
		for id, ent in pairs( self:SelectTargets( isTarget ) ) do
			if ( !IsValid( ent ) ) then continue end
			local maxs = ent:OBBMaxs()
			local p = ent:GetPos()
			p.z = p.z + maxs.z

			local pos = p:ToScreen()
			local x, y = pos.x, pos.y
			local size = 16
			
			local clr = self:GetCrystalColor()
		
			surface.SetDrawColor( clr.x,clr.y,clr.z, 255 )
			draw.NoTexture()
			surface.DrawPoly( {
				{ x = x - size, y = y - size },
				{ x = x + size, y = y - size },
				{ x = x, y = y }
			} )
		end
	end

end
*/

local grad = Material( "gui/gradient_up" )
local function DrawHUDBox( x, y, w, h, t, b, c)
// c is the texture argument
	x = math.floor( x )
	y = math.floor( y )
	w = math.floor( w )
	h = math.floor( h )
	
	
	
	if c then
		local texture = t
		if type(t) == "string" then
			texture = Material(t)
		end
		surface.SetMaterial( texture )
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( x, y, w, h )
	
	else
		surface.SetDrawColor( 255, 255, 255, 255 )
		draw.NoTexture()
		surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
		surface.DrawTexturedRect( x, y, w, h )

		surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
		surface.DrawRect( x, y, w, h )
	end
	if ( b ) then
		surface.SetMaterial( grad )
		surface.SetDrawColor( Color( 0, 128, 255, 4 ) )
		surface.DrawTexturedRect( x, y, w, h )
	end

end


local ForceBar = 100
hook.Add( "LightsaberDrawHUD", "stars_saber_hook", function( meh, Force, MaxForce, SelectedPower, ForcePowers  )
	local icon = 52
	local gap = 5

	local bar = 4
	local bar2 = 16
	
	local wep = LocalPlayer():GetActiveWeapon()
	local ForceSelectEnabled = wep.ForceSelectEnabled
	if ( ForceSelectEnabled ) then
		icon = 54
		bar = 6
		bar2 = 18
	end
	
	




	ForceBar = math.min( 100, Lerp( 0.1, ForceBar, math.floor( Force ) ) )
	local w = #ForcePowers * icon + ( #ForcePowers - 1 ) * gap
		
	local h = bar2
	local x = math.floor( ScrW() / 2 - w / 2 )
	local y = ScrH() - gap - bar2

	DrawHUDBox( x, y, w, h )

	local barW = math.ceil( w * ( ForceBar / 100 ) )
	if ( Force <= 1 && barW <= 1 ) then barW = 0 end
	draw.RoundedBox( 0, x, y, barW, h, Color( 0, 128, 255, 255 ) )

	draw.SimpleText( math.floor(Force ) .. "%", "SelectedForceHUD", x + w / 2, y + h / 2, Color( 255, 255, 255 ), 1, 1 )
	/*
	
		Icons
	
	*/
	local y = y - icon - gap
	local h = icon
	
	for id, name in pairs( ForcePowers ) do
		local x = x + ( id - 1 ) * ( h + gap )
		local x2 = math.floor( x + icon / 2 )
		local pow = ForcePowers[ id ].name
		if wep.Owner.CoolDown && wep.Owner.CoolDown[pow] && wep.Owner.CoolDown[pow] > CurTime() then
			if ForcePowers[ id ].material and ForcePowers[ id ].material != "" then
				DrawHUDBox( x, y, h, h, ForcePowers[ id ].material, SelectedPower == id, true)
			else
				DrawHUDBox( x, y, h, h, "", SelectedPower == id, false)
			end
			local va = tonumber(wep.Owner.CoolDownr[pow])
			local cva = h / va
			DrawHUDBox( x, y, h, h, "naruto/basic/Icon", SelectedPower == id, false)
			local strinc = tostring(tonumber(wep.Owner.CoolDown[pow]) - CurTime())
			local length = 1
			for c = 1,#strinc do
				if strinc[c] == "." then
					length = c - 1
					break
				end
			end
			draw.SimpleText( string.sub(strinc, 1, length)|| "", "SelectedForceType", x2, math.floor( y + icon / 2 ), Color( 255, 255, 255 ), 1, 1 )
		
		else
			if ForcePowers[ id ].material and ForcePowers[ id ].material != "" then
				DrawHUDBox( x, y, h, h, ForcePowers[ id ].material, SelectedPower == id, true)
			else
				DrawHUDBox( x, y, h, h, "", SelectedPower == id, false)
			end
			draw.SimpleText( ForcePowers[ id ].icon || "", "SelectedForceType", x2, math.floor( y + icon / 2 ), Color( 255, 255, 255 ), 1, 1 )
		end
		
		if ( ForceSelectEnabled ) then
			draw.SimpleText( ( input.LookupBinding( "slot" .. id ) || "<NOT BOUND>" ):upper(), "SelectedForceHUD", x + gap, y + gap, Color( 255, 255, 255 ) )
		end
		if ( SelectedPower == id ) then
			local y = y + ( icon - bar )
			surface.SetDrawColor( 0, 128, 255, 255 )
			draw.NoTexture()
			surface.DrawPoly( {
				{ x = x2 - bar, y = y },
				{ x = x2, y = y - bar },
				{ x = x2 + bar, y = y }
			} )
			draw.RoundedBox( 0, x, y, h, bar, Color( 0, 128, 255, 255 ) )
		end
	end
	
	if ( ForceSelectEnabled ) then

		surface.SetFont( "SelectedForceHUD" )
		local tW, tH = surface.GetTextSize( ForcePowers[ SelectedPower ].description || "" )

		local x = x + w + gap
		local y = y
		local x = ScrW() / 2 + gap// - tW / 2
		local y = y - tH - gap * 3

		DrawHUDBox( x, y, tW + gap * 2, tH + gap * 2 )

		for id, txt in pairs( string.Explode( "\n", ForcePowers[ SelectedPower ].description || "" ) ) do
			draw.SimpleText( txt, "SelectedForceHUD", x + gap, y + ( id - 1 ) * ScreenScale( 6 ) + gap, Color( 255, 255, 255 ) )
		end

	end

	----------------------------------- Force Label -----------------------------------

	if ( !ForceSelectEnabled ) then
		surface.SetFont( "SelectedForceHUD" )
		local txt = "Press " .. ( input.LookupBinding( "impulse 100" ) || "<NOT BOUND>" ):upper() .. " to toggle Force selection"
		local tW, tH = surface.GetTextSize( txt )

		local x = x + w / 2
		local y = y - tH - gap

		DrawHUDBox( x - tW / 2 - 5, y, tW + 10, tH ) 
		draw.SimpleText( txt, "SelectedForceHUD", x, y, Color( 255, 255, 255 ), 1 )
	end	
	
	if ( ForceSelectEnabled ) then
		surface.SetFont( "SelectedForceType" )
		local txt = ForcePowers[ SelectedPower ].name or ""
		local tW2, tH2 = surface.GetTextSize( txt )

		local x = x + w / 2 - tW2 - gap * 2//+ w / 2
		local y = y + gap - tH2 - gap * 2

		DrawHUDBox( x, y, tW2 + 10, tH2 )
		draw.SimpleText( txt, "SelectedForceType", x + gap, y, Color( 255, 255, 255 ) )
	end 
	
	return ScrH() + 100000 -- Hides any errors off screen we don't need them
end )


