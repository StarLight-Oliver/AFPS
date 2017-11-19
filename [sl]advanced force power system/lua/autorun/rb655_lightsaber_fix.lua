
--[[-------------------------------------------------------------------
	Advanced Lightsaber Combat Fixes:
		Fixes Robotboy's hooks so we can use them in our custom lightsabers!
			Powered by
						  _ _ _    ___  ____  
				__      _(_) | |_ / _ \/ ___| 
				\ \ /\ / / | | __| | | \___ \ 
				 \ V  V /| | | |_| |_| |___) |
				  \_/\_/ |_|_|\__|\___/|____/ 
											  
 _____         _                 _             _           
|_   _|__  ___| |__  _ __   ___ | | ___   __ _(_) ___  ___ 
  | |/ _ \/ __| '_ \| '_ \ / _ \| |/ _ \ / _` | |/ _ \/ __|
  | |  __/ (__| | | | | | | (_) | | (_) | (_| | |  __/\__ \
  |_|\___|\___|_| |_|_| |_|\___/|_|\___/ \__, |_|\___||___/
                                         |___/             
----------------------------- Copyright 2017, David "King David" Wiltos ]]--[[
							  
	Lua Developer: King David
	Contact: http://steamcommunity.com/groups/wiltostech
		
-- Copyright 2017, David "King David" Wiltos ]]--
 
AddCSLuaFile()

hook.Add( "InitPostEntity", "wOS.OverwriteRobots", function()

	if ( SERVER ) then
		concommand.Add( "rb655_select_force", function( ply, cmd, args )
			if ( !IsValid( ply ) or !IsValid( ply:GetActiveWeapon() ) or !string.find( ply:GetActiveWeapon():GetClass(), "weapon_lightsaber" ) or !tonumber( args[ 1 ]) ) then return end

			local wep = ply:GetActiveWeapon()
			local ForcePowers = wep:GetActiveForcePowers()
			local typ = math.Clamp( tonumber( args[ 1 ] ), 1, #ForcePowers )
			wep:SetForceType( typ )
		end )
	end

	hook.Add( "EntityTakeDamage", "rb655_sabers_armor", function( victim, dmg )
		local ply = victim
		if ( !ply.GetActiveWeapon or !ply:IsPlayer() ) then return end
		local wep = ply:GetActiveWeapon()
		if ( !IsValid( wep ) or !string.find( wep:GetClass(), "weapon_lightsaber" ) or wep:GetActiveForcePowerType( wep:GetForceType() ).name != "Force Absorb" ) then return end
		if ( !ply:KeyDown( IN_ATTACK2 ) --[[|| !ply:IsOnGround()]] ) then return end

		local damage = dmg:GetDamage() / 5
		local force = wep:GetForce()
		if ( force < damage ) then
			wep:SetForce( 0 )
			dmg:SetDamage( ( damage - force ) * 5 )
			return
		end
		wep:SetForce( force - damage )
		dmg:SetDamage( 0 )
	end )

	hook.Add( "GetFallDamage", "rb655_lightsaber_no_fall_damage", function( ply, speed )
		if ( IsValid( ply ) && IsValid( ply:GetActiveWeapon() ) && string.find( ply:GetActiveWeapon():GetClass(), "weapon_lightsaber" ) ) then
			local wep = ply:GetActiveWeapon()

			if ( ply:KeyDown( IN_DUCK ) ) then
				ply:SetNWFloat( "SWL_FeatherFall", CurTime() ) -- Hate on me for NWVars!
				wep:SetNextAttack( 0.5 )
				ply:ViewPunch( Angle( speed / 32, 0, math.random( -speed, speed ) / 128 ) )
				return 0
			end
		end
	end )

	if SERVER then return end
/*
	hook.Add( "CalcView", "!!!111_rb655_lightsaber_3rdperson_custom", function( ply, pos, ang )
		if ( !IsValid( ply ) or !ply:Alive() or ply:InVehicle() or ply:GetViewEntity() != ply ) then return end
		if ( !LocalPlayer().GetActiveWeapon or !IsValid( LocalPlayer():GetActiveWeapon() ) or !LocalPlayer():GetActiveWeapon().IsLightsaber ) then return end


		local trace = util.TraceHull( {
			start = pos,
			endpos = pos - ang:Forward() * 100,
			filter = { ply:GetActiveWeapon(), ply },
			mins = Vector( -4, -4, -4 ),
			maxs = Vector( 4, 4, 4 ),
		} )

		if ( trace.Hit ) then pos = trace.HitPos else pos = pos - ang:Forward() * 100 end

		return {
			origin = pos,
			angles = ang,
			drawviewer = true
		}
	end )

*/
	hook.Add( "PlayerBindPress", "rb655_sabers_force_custom", function( ply, bind, pressed )
		if ( LocalPlayer():InVehicle() or ply != LocalPlayer() or !LocalPlayer():Alive() or !IsValid( LocalPlayer():GetActiveWeapon() ) or !LocalPlayer():GetActiveWeapon().IsLightsaber ) then return end
		local wep = LocalPlayer():GetActiveWeapon()
		if ( bind == "impulse 100" && pressed ) then
			wep.ForceSelectEnabled = !wep.ForceSelectEnabled
			return true
		end

		if ( !wep.ForceSelectEnabled ) then return end

		if ( bind:StartWith( "slot" ) ) then
			RunConsoleCommand( "rb655_select_force", bind:sub( 5 ) )
			return true
		end
	end )



		hook.Add( "Think", "rb655_lightsaber_ugly_fixes", function()
			for id, ent in pairs( ents.FindByClass( "weapon_lightsaber_*" ) ) do
				if ( !IsValid( ent:GetOwner() ) || ent:GetOwner():GetActiveWeapon() != ent || !ent.GetBladeLength || ent:GetBladeLength() <= 0 ) then continue end

				rb655_ProcessLightsaberEntity( ent )
			end

			for id, ent in pairs( ents.FindByClass( "ent_lightsaber" ) ) do
				if ( !ent.GetBladeLength || ent:GetBladeLength() <= 0 ) then continue end

				rb655_ProcessLightsaberEntity( ent )
			end
		end )
	--[[
		hook.Add( "PostPlayerDraw", "rb655_lightsaber", function( ply )
			if ( !GetGlobalBool( "rb655_lightsaber_hiltonbelt", false ) || !ply:HasWeapon( "weapon_lightsaber" ) ) then return end

			local wep = ply:GetWeapon( "weapon_lightsaber" )
			if ( !IsValid( wep ) || wep == ply:GetActiveWeapon() ) then return end

			if ( !ply.LightsaberMDL ) then
				ply.LightsaberMDL = ClientsideModel( wep.WorldModel, RENDERGROUP_BOTH ) -- wep.WorldModel is nil?
				ply.LightsaberMDL:SetNoDraw( true )
			end
			ply.LightsaberMDL:SetModel( wep.WorldModel )

			local pos, ang = ply:GetBonePosition( 0 )
			ang:RotateAroundAxis( ang:Up(), 80 )

			local len = ply:GetVelocity():Length()
			if ( ply:GetVelocity():Distance( ply:GetForward() * len ) < ply:GetVelocity():Distance( ply:GetForward() * -len ) ) then
				ang:RotateAroundAxis( ang:Right(), math.min( ply:GetVelocity():Length() / 8, 55 ) - 5 ) -- Forward
			else
				ang:RotateAroundAxis( ang:Right(), -math.min( ply:GetVelocity():Length() / 8, 55 ) + 5 )
			end

			if ( ply:GetVelocity():Distance( ply:GetRight() * len ) < ply:GetVelocity():Distance( ply:GetRight() * -len ) ) then
				--ang:RotateAroundAxis( ang:Right(), math.min( ply:GetVelocity():Length() / 8, 55 ) - 5 ) -- Right
			else
				ang:RotateAroundAxis( ang:Up(), -math.min( ply:GetVelocity():Length() / 16, 30 ) + 5 )
			end

			pos = pos - ang:Right() * 8 - ang:Forward() * 8
			if ( wep.WorldModel == "models/weapons/starwars/w_maul_saber_staff_hilt.mdl" ) then
				pos = pos - ang:Forward() * 5
			end
			if ( wep.WorldModel == "models/weapons/starwars/w_kr_hilt.mdl" ) then
				pos = pos + ang:Forward() * 5
			end

			ang:RotateAroundAxis( ang:Forward(), 90 )

			ply.LightsaberMDL:SetPos( pos )
			ply.LightsaberMDL:SetAngles( ang )

			ply.LightsaberMDL:DrawModel()

		end )
	]]--
end )