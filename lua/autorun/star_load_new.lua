local ccc = FindMetaTable("Entity")
local doors = {
	["func_door"] = true,
	["func_door_rotating"] = true, 
	["prop_door_rotating"] = true,
	["prop_dynamic"] = true,
}
function ccc:IsDoor()
	if doors[self:GetClass()] then return true end
	return false
end


rb655_AddForcePower({
	name = "Force Deflect",
	icon = "D",
	texture = "star/icon/reflect",
	description = "Hold Mouse 2 to deflect damage.",
	action = function( self )
		if ( self:GetForce() < 1 || CLIENT ) then return end
		self:SetForce( self:GetForce() - 0.1 )
		local ed = EffectData()
		ed:SetOrigin( self.Owner:GetPos() )
		ed:SetAngles(Angle(100,100,100))
		util.Effect( "sl_force_hit", ed, true, true )

		self:SetNextAttack( 0.3 )
	end
})

rb655_AddForcePower({
	name = "Force Freeze",
	icon = "F",
	target = 3,
	texture = "star/icon/freeze.png",
	description = "What have you done to my muscles",
	action = function( self )
		if ( self:GetForce() < 3 || CLIENT ) then return end

		local foundents = 0
		for id, ent in pairs( self:SelectTargets( 3 ) ) do
			if ( !IsValid( ent ) ) then continue end
			if !ent:IsPlayer() then continue end
			foundents = foundents + 5				

			local edc = EffectData()
			edc:SetOrigin( ent:GetPos() )
			edc:SetEntity( ent )
			util.Effect( "effect_force_freeze_ent", edc, true, true )
				
			ent:Freeze(true)
			timer.Create( "Freeze Timer" .. ent:EntIndex(), 10, 1, function() if IsValid(ent) then ent:Freeze(false) end end )
		end

		if ( foundents > 0 ) then
			self:SetForce( self:GetForce() - foundents )
		end
		self:SetNextAttack( 0.1)
		if self.Owner.SetCoolDown then
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 30)
		end
	end
})

rb655_AddForcePower({
	name = "Force UnFreeze",
	icon = "UF",
	target = 3,
	texture = "star/icon/force_break.png",
	description = "Let Your Muscles Move",
	action = function( self )
		if ( self:GetForce() < 3 || CLIENT ) then return end

		local foundents = 1
		for id, ent in pairs( self:SelectTargets( 3 ) ) do
			if ( !IsValid( ent ) ) then continue end
			if !ent:IsPlayer() then return end
			foundents = foundents + 1
			local ed = EffectData()
			ed:SetOrigin( self:GetSaberPosAng() )
			ed:SetEntity( ent )
			util.Effect( "effect_heal", ed, true, true )
			ent:Freeze(false)
		end

		if ( foundents > 0 ) then
			self:SetForce( self:GetForce() - foundents )
		end
		self:SetNextAttack( 0.1 )
		if self.Owner.SetCoolDown then
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 30)
		end
	end 
}) 
		
rb655_AddForcePower({
	name = "Force Beam",
	icon = "B",
	target = 3,
	texture = "star/icon/lightning",
	description = "Torture people ( and monsters ) at will.",
	action = function(self)
		if ( self:GetForce() < 3 || CLIENT ) then return end
		local ply = self.Owner
		local foundents = 0

		local pos = self:GetSaberPosAng() 
		local color = Angle(ply:GetInfo( "star_lightning_red" ), ply:GetInfo( "star_lightning_green" ), ply:GetInfo("star_lightning_blue"))

		for id, ent in pairs( self:SelectTargets( 3 ) ) do
			if ( !IsValid( ent ) ) then continue end

			foundents = foundents + 1
			local ed = EffectData()
			ed:SetOrigin( pos )
			ed:SetEntity( ent )			
			ed:SetAngles( color )
			util.Effect( "sl_force_lightning", ed, true, true )

			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon()
			if IsValid( wep ) and wep.IsLightsaber and (wep.ForcePowers[ wep:GetForceType() ].name == "Force Deflect" or wep.ForcePowers[ wep:GetForceType() ].name == "Force Deflect (Greater)" ) and ent:KeyDown(IN_ATTACK2) then
				local ed = EffectData()
				ed:SetOrigin( ent:GetPos() + Vector(0,0,44) )
				ed:SetEntity( self )
				ed:SetAngles( color )
				util.Effect( "sl_force_lightning", ed, true, true )

				local dmg = DamageInfo()
				dmg:SetAttacker( ent )
				dmg:SetInflictor( wep )

				dmg:SetDamage( math.Clamp( 512 / ent:GetPos():Distance( self.Owner:GetPos() ), 1, 10 ) )
				self.Owner:TakeDamageInfo( dmg )
				continue --no damage lol
			end

			local dmg = DamageInfo()
			dmg:SetAttacker( self.Owner || self )
			dmg:SetInflictor( self.Owner || self )

			dmg:SetDamage( math.Clamp( 2048 / self.Owner:GetPos():Distance( ent:GetPos() ), 1, 10 ) )
			if ( ent:IsNPC() ) then dmg:SetDamage( 4 ) end
			ent:TakeDamageInfo( dmg )
		end

		if ( foundents > 0 ) then
			self:SetForce( self:GetForce() - foundents )
		
			if ( !self.SoundLightning ) then
				self.SoundLightning = CreateSound( self.Owner, "lightsaber/force_lightning" .. math.random( 1, 2 ) .. ".wav" )
				self.SoundLightning:Play()
			else
				self.SoundLightning:Play()
			end

			timer.Create( "test", 0.2, 1, function()
				if ( self.SoundLightning ) then
					self.SoundLightning:Stop() 
					self.SoundLightning = nil 
				end
				if self.SetCoolDown then
					self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name)
				end
			end )
		end
		
		self:SetNextAttack( 0.1 )
	end
})

rb655_AddForcePower({
	name = "Force Pull",
	icon = "PU",
	target = 1,
	texture = "star/icon/pull",
	description = "Pulls people towards you.",
	action = function( self )
		if ( self:GetForce() < 10 || CLIENT ) then return end
		local foundents = 0
		for id, ent in pairs( self:SelectTargets( 1 ) ) do
			if ( !IsValid( ent ) ) then continue end
			foundents = foundents + 1
			//ent:SetPos(ent:GetPos() + Vector(0,0,10))
			if ent.loco then
				ent.loco:SetVelocity((self.Owner:GetPos() - ent:GetPos()):GetNormal() * 2048 - Vector( 0, 0, 128 ))
			else
				ent:SetVelocity((self.Owner:GetPos() - ent:GetPos()):GetNormal() * 2048 - Vector( 0, 0, 128 ))
			end
		end
	
		if ( foundents > 0 ) then
			self:SetForce( self:GetForce() - 5 )
		end
		self:SetNextAttack( 0.25 )
	end
})

rb655_AddForcePower({
	name = "Force Push",
	icon = "PS",
	target = 1,
	texture = "star/icon/push",
	description = "Pushes people away from you.",
	action = function( self )
		if ( self:GetForce() < 10 || CLIENT ) then return end
		local foundents = 0
		for id, ent in pairs( self:SelectTargets( 1 ) ) do
			if ( !IsValid( ent ) ) then continue end
			foundents = foundents + 1
			ent:SetPos(ent:GetPos() - Vector(0,0,-10))

			if ent.loco then
				ent.loco:SetVelocity((self.Owner:GetPos() - ent:GetPos()):GetNormal() * -2048 + Vector( 0, 0, 128 ))
			else
				ent:SetVelocity((self.Owner:GetPos() - ent:GetPos()):GetNormal() * -2048 + Vector( 0, 0, 128 ))
			end
		end
		
		if ( foundents > 0 ) then
			self:PlayWeaponSound( "lightsaber/force_leap.wav" )
			self:SetForce( self:GetForce() - 10 )
		end
		self:SetNextAttack( 0.25 )
	end
})

rb655_AddForcePower({
	name = "Force Choke",
	icon = "CH",
	target = 1,
	texture = "star/icon/choke.png",
	description = "Vader it up!",
	action = function( self )
		if ( self:GetForce() < 30 || CLIENT ) then return end

		for id, ent in pairs( self:SelectTargets( 1 ) ) do
			if ( !IsValid( ent ) || ent.Chocked ) then continue end
			if !ent:IsPlayer() then continue end
			ent.Chocked = true
			ent:Freeze(true)
			local elev = 100
			local time = 1
			timer.Simple( 0.1, function() if ( !IsValid( ent ) ) then return end
				ent:SetPos( ent:GetPos() + Vector( 0, 0, elev / 3 * 1 ) )
				ent:Freeze(true)
			end )
	
			timer.Simple( 0.2, function() if ( !IsValid( ent ) ) then return end
				ent:SetPos( ent:GetPos() + Vector( 0, 0, elev / 3 * 1 ) )
				ent:Freeze(true)
			end )
			timer.Simple( 0.3, function() if ( !IsValid( ent ) ) then return end
				ent:SetPos( ent:GetPos() + Vector( 0, 0, elev / 3 * 1 ) )
				ent:Freeze(true)
			end )

			timer.Create( "star_choke_"..ent:EntIndex(), time + 3, 1, function() if ( !IsValid( ent ) ) then return end
				local dmg = DamageInfo()
				ent:Freeze(false)
				dmg:SetAttacker( self.Owner || self )
				dmg:SetInflictor( self.Owner || self )
				ent.Chocked = false
				dmg:SetDamage( 250 )
				ent:TakeDamageInfo( dmg )
				self:SetForce( self:GetForce() - 30)
			end )

		end
		self:SetNextAttack( 0.1 )
	end
})

rb655_AddForcePower({
	name = "Force Aura Heal",
	icon = "AH",
	description = "Hold Mouse 2 to slowly heal you.",
	texture = "star/icon/heal",
	action = function( self )
		if self:GetForce() <= 1 then return end

		local foundEnts = false

		for index, ent in ipairs(ents.FindInSphere(self.Owner:GetPos(), 256)) do
			if !IsValid(ent) then continue end
			if !ent:IsPlayer() then continue end
			if self:GetForce() <= 1 then break end
			if ent:Health() != ent:GetMaxHealth() then
				ent:SetHealth(math.min(ent:Health() + ent:GetMaxHealth()/100, ent:GetMaxHealth()))

				local ed = EffectData()
				ed:SetOrigin( ent:GetPos() )
				util.Effect( "rb655_force_heal", ed, true, true )

				self:SetForce(self:GetForce() - 1)
				foundEnts = true
			end
		end

		if foundEnts then
			local ed = EffectData()
			ed:SetOrigin( self.Owner:GetPos() )
			ed:SetAngles(Angle(100,255,100))
			util.Effect( "sl_force_hit", ed, true, true )
		end
		self:SetNextAttack(0.1)

	end
})

rb655_AddForcePower({
	name = "Ground Slam",
	icon = "GS",
	texture = "star/icon/ground_slam.png",
	description = "Shocks and destroys everything around you.",
	action = function( self )
		if ( self:GetForce() < 60 || CLIENT || !self.Owner:IsOnGround() ) then return end
	
		local elev = 400
		local time = 1
		ent = self.Owner
			
		self:SetForce(self:GetForce() - 60)
		self:SetNextAttack( 1 )

		for j = 0,6 do
			for i = 0, 24 do
				local ed = EffectData()
				ed:SetOrigin( self.Owner:GetPos() + Vector(0,0,0) )
				ed:SetStart( self.Owner:GetPos() + Vector(0,0,0) + Angle(0 , i * 15, 0):Forward() * 512)
				util.Effect( "force_groundslam", ed, true, true )
			end
		end

		local maxdist = 128 * 4

		local ed = EffectData()
		ed:SetOrigin( self.Owner:GetPos() + Vector( 0, 0, 36 ) )
		ed:SetRadius( maxdist )
		util.Effect( "rb655_force_repulse_out", ed, true, true )
	
		for i, e in ipairs( ents.FindInSphere( self.Owner:GetPos(), maxdist ) ) do
			if e:IsPlayer() and e == self.Owner then continue end

			local dist = self.Owner:GetPos():Distance( e:GetPos() )
			local mul = ( maxdist - dist ) / 256

			local v = ( self.Owner:GetPos() - e:GetPos() ):GetNormalized()
			v.z = 0

			local dmg = DamageInfo()
			dmg:SetDamagePosition( e:GetPos() + e:OBBCenter() )
			dmg:SetDamage( 700 * mul )
			dmg:SetDamageType( DMG_DISSOLVE )
			dmg:SetDamageForce( -v * math.min( mul * 40000, 80000 ) )
			dmg:SetInflictor( self.Owner )
			dmg:SetAttacker( self.Owner )
			e:TakeDamageInfo( dmg )

			if ( e:IsOnGround() ) then
				e:SetVelocity( v * mul * -2048 + Vector( 0, 0, 64 ) )
			elseif ( !e:IsOnGround() ) then
				e:SetVelocity( v * mul * -1024 + Vector( 0, 0, 64 ) )
			end
		end

		if ( !self.SoundLightning ) then
			self.SoundLightning = CreateSound( self.Owner, "lightsaber/force_lightning" .. math.random( 1, 2 ) .. ".wav" )
			self.SoundLightning:Play()
			self.SoundLightning:ChangeVolume(0,0.3)
		else
			self.SoundLightning:Play()
		end

		timer.Create( "test", 0.6, 1, function() if ( self.SoundLightning ) then self.SoundLightning:Stop() self.SoundLightning = nil end end )

		self:PlayWeaponSound( "lightsaber/force_repulse.wav" )
	end
})

rb655_AddForcePower({
	name = "Shadow Step",
	icon = "SS",
	texture = "star/icon/shadowstrike",
	target = 4,
	description = "Strike Up to 4 Enemys\n Cost: 80",
	action = function(self)
		if CLIENT then return end
		if self:GetForce() < 80 then return end
				
		local ent = self:SelectTargets( 1 )[1]
			   
		if (!IsValid(ent)) then return end
		if !ent:IsNPC() and !ent:IsPlayer() then return end

		local dmg = DamageInfo()
		dmg:SetDamage( 75 )
		dmg:SetDamageType( DMG_DIRECT )
		dmg:SetInflictor( self.Owner )
		dmg:SetAttacker( self.Owner )
			   
		local Hit = {[ent:EntIndex()] = ent}
		local count = 0
		for x = 1,4 do
			local org = ent:GetPos()
			
			if !Hit[ent:EntIndex()] then
				local sound = CreateSound( ent, Sound( self.SwingSound ) )
					
				sound:Play()
				timer.Simple(0.75, function()
					sound:Stop()
				end)

			end
			ent:TakeDamageInfo( dmg )

			for x,y in pairs(ents.FindInSphere(org, 512) ) do
				if (y:IsPlayer() or y:IsNPC()) and y != self.Owner and !Hit[y:EntIndex()] then
					Hit[y:EntIndex()] = y
					ent	= y
				end
			end
				   
			ent = ent or table.Random(Hit)
			if x == 4 then
				pos1 = self.Owner:GetPos()
				pos2 = ent:GetPos()
				self.Owner:SetPos(pos2)
				ent:SetPos(pos1)
			end
		end
			   
		if self.Owner.SetCoolDown then
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 30)
		end
	end
})

rb655_AddForcePower({
	name = "Heal (Others)",
	icon = "HO",
	texture = "star/icon/groupheal",
	description = "Heal those around you",
	action = function( self )
		if self:GetForce() < 5 then return end

		local ent = self:SelectTargets( 1 )[1]
			
		if !IsValid(ent) then return end
		
		if ent:GetMaxHealth() <= ent:Health() then
			ent:SetHealth(ent:GetMaxHealth())
		else 
			ent:SetHealth(ent:Health() + (ent:GetMaxHealth() / 100))
			self:SetForce(self:GetForce() - 2)
			self:SetNextAttack(0.1)
					
			local ed = EffectData()
			ed:SetOrigin( ent:GetPos() )
			ed:SetAngles(Angle(100,200,100))
			util.Effect( "sl_force_hit", ed, true, true )			
		end 
	end
})

rb655_AddForcePower({
	name = "Force Breach",
	icon = "FB",
	description = "Hold Mouse 2 to open doors yourself",
	texture = "star/icon/mind_trick_2.png",
	action = function( self )
		local trace = self:GetOwner():GetEyeTrace()
	
		if ( self:GetForce() < 10 ||  !trace.Entity:IsDoor() || CLIENT ) then return end
		self:SetForce( self:GetForce() - 10 )

		self:SetNextAttack( 1 )

		trace.Entity:EmitSound("doors/door_latch3.wav")
		trace.Entity:Fire( "Open" , 0)

		self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 1)
	end
})

local pi = math.pi
local posv = { // DON"T TOUCH
	pi*2/5,
	pi*4/5,
	pi*6/5,
	pi*8/5,
	2*pi,
}


local function StormLightning(wep, pos, pos2)
	local ply = wep.Owner
	local clr = ply:GetInfo( "star_lightning_red" ) .. " " .. ply:GetInfo( "star_lightning_green" ) .. " " .. ply:GetInfo("star_lightning_blue") // Yeah that does not look nice
	
	if !clr then clr = "255 0 0" end
	clr = tostring(clr)
	
	local LA = ents.Create("env_laser")
	LA:SetKeyValue("lasertarget", "forcestorm")
	LA:SetKeyValue("renderamt", "255")
	LA:SetKeyValue("renderfx", "15")
	LA:SetKeyValue("rendercolor", clr)
	LA:SetKeyValue("texture", "sprites/laserbeam.spr")
	LA:SetKeyValue("texturescroll", "3")
	LA:SetKeyValue("dissolvetype", "-1")
	LA:SetKeyValue("spawnflags", "0")
	LA:SetKeyValue("width", "30")
	LA:SetKeyValue("damage", "15")
	LA:SetKeyValue("noiseamplitude", "10")
	LA:Spawn()
	LA:Fire("Kill","",7)
	LA:Fire("turnon","",7)
	LA:SetPos(pos)
	
	local LT = ents.Create("info_target")
	LT:SetKeyValue("targetname", "forcestorm")
	LT:SetPos(pos2)
	LT:Fire("kill","",7)
	LT:Spawn()

	local dmg = DamageInfo()
    dmg:SetDamage( 10 )
    dmg:SetDamageType( DMG_DIRECT )
    dmg:SetInflictor( ply )
    dmg:SetAttacker( ply )
	for c = 1, 28 do
		timer.Simple(c / 4, function()
			for _, ent in pairs(ents.FindInSphere(pos2, 50)) do
				if ent:IsPlayer() or ent:IsNPC() then
					ent:TakeDamageInfo(dmg)
				end
			end
		end)
	end
end


rb655_AddForcePower({
	name = "Force Storm",
	icon = "FS",
	texture = "star/icon/storm.png",
	description = "Shoot Bolts of Lightning down from the sky",
	action = function( self )
		if self:GetForce() < 70 then return end
		if CLIENT then return end
		local tr = util.TraceLine( util.GetPlayerTrace( self.Owner ) )
		if tr.HitPos:Distance( self.Owner:GetPos()) > 2048 then return end 
		local pos = tr.HitPos + Vector( 0, 0, 600 )		
		self.Owner:EmitSound( Sound( "npc/strider/charging.wav" ) )	
		timer.Simple(0.5, function()
			self.Owner:EmitSound( Sound( "ambient/atmosphere/thunder1.wav" ) )
			self.Owner:EmitSound( Sound( "npc/strider/fire.wav" ) )	
			for x = 1,5 do
				local pos1 = pos + Vector( 65*math.sin( posv[x] ), 65*math.cos( posv[x] ), 0 )
				local pos2 = pos1 - Vector(0,0,600)
				StormLightning(self, pos1, pos2)
			end
		end)
	
		self:SetForce(self:GetForce() - 70)
		if self.Owner.SetCoolDown then
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 45)	
		end
	end
})

rb655_AddForcePower({
	name = "Charge",
	icon = "CH",
	texture = "star/icon/leap",
	target = 1,
	description = "Lunge at your enemy",
	action = function( self )
		local ent = self:SelectTargets( 1 )[ 1 ]
		if !IsValid( ent ) then self:SetNextAttack( 0.2 ) return end
		if ( self:GetForce() < 20 ) then self:SetNextAttack( 0.2 ) return end
		local newpos = ( ent:GetPos() - self.Owner:GetPos() )
		newpos = newpos / newpos:Length()
		self.Owner:SetLocalVelocity( newpos*700 + Vector( 0, 0, 300 ) )
		self:SetForce( self:GetForce() - 20 )
		self:PlayWeaponSound( "lightsaber/force_leap.wav" )
		self:SetNextAttack( 1 )

		if self.Owner.SetCoolDown then
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 20)
		end
	end
})

rb655_AddForcePower({
	name = "Force Meteor",
	icon = "M",
	target = 1,
	texture = "star/icon/meteor.png",
	description = "Shoot Meteors down from the sky ",
	action = function( self)
		if ( CLIENT ) then return end
		local ply = self.Owner
		local ent = self:SelectTargets( 1 )[ 1 ]

		if ( !IsValid( ent )) then self:SetNextAttack( 0.2 ) return end

		if self:GetForce() < 70 then return end
		for x = 1,5 do
			local meteor = ents.Create("star_metor")
			meteor.nodupe = true
			meteor:Spawn()
			meteor:SetMeteorTarget(ent)
		end
	
		self:SetForce( self:GetForce() - 70 )
		local metor = CreateSound( self.Owner,( "star/metor/thunder_close" .. 1 ..".mp3" ))
		metor:Play()
		self:SetNextAttack( 2 )
		if self.Owner.SetCoolDown then
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 60)
		end
	end
})
