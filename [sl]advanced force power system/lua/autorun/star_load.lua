SL = {}
SL.ForcePowers = {
	{
		name = "Force Leap",
		icon = "L",
		material = "star/icon/leap",
		description = "Jump longer and higher.\nAim higher to jump higher/further.\nHold CTRL to negate fall damage, but stop moving for 1 sec",
		action = function( self )
			if ( self:GetForce() < 10 or !self.Owner:IsOnGround() or CLIENT ) then return end
			self:SetForce( self:GetForce() - 10 )

			self:SetNextAttack( 0.5 )

			self.Owner:SetVelocity( self.Owner:GetAimVector() * 512 + Vector( 0, 0, 512 ) )
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 10)
			self:PlayWeaponSound( "lightsaber/force_leap.wav" )

			-- Trigger the jump animation, yay
			self:CallOnClient( "ForceJumpAnim", "" )
		end
	}, {
		name = "Force Repulse",
		icon = "R",
		material = "star/icon/repulse",
		description = "Hold to charge for greater distance/damage.\nKill everybody close to you.\nPush back everybody who is a bit farther away but still close enough.",
		action = function( self )
			if ( self:GetNextSecondaryFire() > CurTime() ) then return end
			if ( self:GetForce() < 1 or CLIENT ) then return end
			if ( !self.Owner:KeyDown( IN_ATTACK2 ) && !self.Owner:KeyReleased( IN_ATTACK2 ) ) then return end
			if ( !self._ForceRepulse && self:GetForce() < 16 ) then return end

			if ( !self.Owner:KeyReleased( IN_ATTACK2 ) ) then
				if ( !self._ForceRepulse ) then self:SetForce( self:GetForce() - 16 ) self._ForceRepulse = 1 end

				if ( !self.NextForceEffect or self.NextForceEffect < CurTime() ) then
					local ed = EffectData()
					ed:SetOrigin( self.Owner:GetPos() + Vector( 0, 0, 36 ) )
					ed:SetRadius( 128 * self._ForceRepulse )
					util.Effect( "rb655_force_repulse_in", ed, true, true )

					self.NextForceEffect = CurTime() + math.Clamp( self._ForceRepulse / 20, 0.1, 0.5 )
				end

				self._ForceRepulse = self._ForceRepulse + 0.025
				self:SetForce( self:GetForce() - 0.5 )
				if ( self:GetForce() > 0.99 ) then return end
			else
				if ( !self._ForceRepulse ) then return end
			end

			local maxdist = 128 * self._ForceRepulse

			for i, e in pairs( ents.FindInSphere( self.Owner:GetPos(), maxdist ) ) do
				if ( e == self.Owner ) then continue end

				local dist = self.Owner:GetPos():Distance( e:GetPos() )
				local mul = ( maxdist - dist ) / 256

				local v = ( self.Owner:GetPos() - e:GetPos() ):GetNormalized()
				v.z = 0

				if ( e:IsNPC() && util.IsValidRagdoll( e:GetModel() or "" ) ) then

					local dmg = DamageInfo()
					dmg:SetDamagePosition( e:GetPos() + e:OBBCenter() )
					dmg:SetDamage( 48 * mul )
					dmg:SetDamageType( DMG_GENERIC )
					if ( ( 1 - dist / maxdist ) > 0.8 ) then
						dmg:SetDamageType( DMG_DISSOLVE )
						dmg:SetDamage( e:Health() * 3 )
					end
					dmg:SetDamageForce( -v * math.min( mul * 40000, 80000 ) )
					dmg:SetInflictor( self.Owner )
					dmg:SetAttacker( self.Owner )
					e:TakeDamageInfo( dmg )

					if ( e:IsOnGround() ) then
						e:SetVelocity( v * mul * -2048 + Vector( 0, 0, 64 ) )
					elseif ( !e:IsOnGround() ) then
						e:SetVelocity( v * mul * -1024 + Vector( 0, 0, 64 ) )
					end

				elseif ( e:IsPlayer() && e:IsOnGround() ) then
					e:SetVelocity( v * mul * -2048 + Vector( 0, 0, 64 ) )
				elseif ( e:IsPlayer() && !e:IsOnGround() ) then
					e:SetVelocity( v * mul * -384 + Vector( 0, 0, 64 ) )
				elseif ( e:GetPhysicsObjectCount() > 0 ) then
					for i = 0, e:GetPhysicsObjectCount() - 1 do
						e:GetPhysicsObjectNum( i ):ApplyForceCenter( v * mul * -512 * math.min( e:GetPhysicsObject():GetMass(), 256 ) + Vector( 0, 0, 64 ) )
					end
				end
			end

			local ed = EffectData()
			ed:SetOrigin( self.Owner:GetPos() + Vector( 0, 0, 36 ) )
			ed:SetRadius( maxdist )
			util.Effect( "rb655_force_repulse_out", ed, true, true )

			self._ForceRepulse = nil

			self:SetNextAttack( 1 )

			self:PlayWeaponSound( "lightsaber/force_repulse.wav" )
		end
	}, {
		name = "Force Deflect",
		icon = "D",
		material = "star/icon/reflect",
		description = "Hold Mouse 2 to deflect damage.",
		action = function( self )
			if ( self:GetForce() < 1/* || !self.Owner:IsOnGround()*/ || CLIENT ) then return end
			self:SetForce( self:GetForce() - 0.1 )
			local ed = EffectData()
			ed:SetOrigin( self.Owner:GetPos() )
			util.Effect( "rb655_force_absorb", ed, true, true )

			self:SetNextAttack( 0.3 )
		end
	}, {
		name = "Force Absorb",
		icon = "A",
		material = "star/icon/absorb",
		description = "Hold Mouse 2 to deflect damage.",
		action = function(self)
		if CLIENT then return end
		end
	}, {
		name = "Force Combust",
		icon = "C",
		target = 1,
		material = "star/icon/combust",
		description = "Ignite stuff infront of you.",
		action = function( self )
			if ( CLIENT ) then return end

			local ent = self:SelectTargets( 1 )[ 1 ]

			if ( !IsValid( ent ) || ent:IsOnFire() ) then self:SetNextAttack( 0.2 ) return end

			local time = math.Clamp( 512 / self.Owner:GetPos():Distance( ent:GetPos() ), 1, 16 )
			local neededForce = math.ceil( math.Clamp( time * 2, 10, 32 ) )

			if ( self:GetForce() < neededForce ) then self:SetNextAttack( 0.2 ) return end

			ent:Ignite( time, 0 )
			self:SetForce( self:GetForce() - neededForce )

			self:SetNextAttack( 1 )
		end
	}, {
	name = "Force Freeze",
		icon = "F",
		target = 3,
		material = "star/icon/freeze.png",
		description = "What have you done to my muscles",
		action = function( self )
		
			if ( self:GetForce() < 3 || CLIENT ) then return end

			local foundents = 0
			for id, ent in pairs( self:SelectTargets( 3 ) ) do
				if ( !IsValid( ent ) ) then continue end

				foundents = foundents + 5				
				local edc = EffectData()
				edc:SetOrigin( ent:GetPos() )
				edc:SetEntity( ent )
				util.Effect( "effect_force_freeze_ent", edc, true, true )
				
				ent:Freeze(true)
				ent:Lock(true)
				timer.Create( "Freeze Timer" .. ent:EntIndex(), 10, 1, function() 	 ent:Freeze(false) ent:UnLock() end )

			end

			if ( foundents > 0 ) then
				self:SetForce( self:GetForce() - foundents )
			end
			self:SetNextAttack( 0.1)
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name)
			
		end }, {
	name = "Force UnFreeze",
		icon = "UF",
		target = 3,
		material = "star/icon/force_break.png",
		description = "Let Your Muscles Move",
		action = function( self )
			if ( self:GetForce() < 3 || CLIENT ) then return end

			local foundents = 1
			for id, ent in pairs( self:SelectTargets( 3 ) ) do
				if ( !IsValid( ent ) ) then continue end

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
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name)
		end }, {
		name = "Force Lightning",
		icon = "L",
		target = 3,
		material = "star/icon/lightning",
		description = "Torture people ( and monsters ) at will.",
		action = function( self )
			if ( self:GetForce() < 3 || CLIENT ) then return end
			local ply = self.Owner
			local foundents = 0
			for id, ent in pairs( self:SelectTargets( 3 ) ) do
				if ( !IsValid( ent ) ) then continue end

				foundents = foundents + 1
				local ed = EffectData()
				ed:SetOrigin( self:GetSaberPosAng() )
				ed:SetEntity( ent )			
				ed:SetAngles(Angle(ply:GetInfo( "star_lightning_red" ), ply:GetInfo( "star_lightning_green" ), ply:GetInfo("star_lightning_blue")))
				util.Effect( "sl_force_lighting", ed, true, true )

				local wep = ent.GetActiveWeapon and ent:GetActiveWeapon()
				if IsValid( wep ) and wep.IsLightsaber and (wep.ForcePowers[ wep:GetForceType() ].name == "Force Deflect" or wep.ForcePowers[ wep:GetForceType() ].name == "Force Deflect (Greater)" ) and ent:KeyDown(IN_ATTACK2) then
					local ed = EffectData()
					ed:SetOrigin( ent:GetPos() + Vector(0,0,44) )
					ed:SetEntity( self )
					ed:SetAngles(Angle(ply:GetInfo( "star_lightning_red" ), ply:GetInfo( "star_lightning_green" ), ply:GetInfo("star_lightning_blue")))
					util.Effect( "sl_force_lighting", ed, true, true )

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
				self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name)
				end )
			end
			self:SetNextAttack( 0.1 )
		end
	}, {
		name = "Force Pull",
		icon = "P",
		target = 1,
		material = "star/icon/pull",
		description = "Pulls people towards you.",
		action = function( self )
			if ( self:GetForce() < 10 || CLIENT ) then return end
			local foundents = 0
			for id, ent in pairs( self:SelectTargets( 1 ) ) do
				if ( !IsValid( ent ) ) then continue end
				foundents = foundents + 1
				ent:SetPos(ent:GetPos() + Vector(0,0,10))
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
	},{
		name = "Force Push",
		icon = "P",
		target = 1,
		material = "star/icon/push",
		description = "Pushes people away from you.",
		action = function( self )
			if ( self:GetForce() < 10 || CLIENT ) then return end
			local foundents = 0
			for id, ent in pairs( self:SelectTargets( 1 ) ) do
				if ( !IsValid( ent ) ) then continue end
				foundents = foundents + 1
				ent:SetPos(ent:GetPos() - Vector(0,0,-10))
				//self.Owner:ChatPrint("Yeah")
				if ent.loco then
					ent.loco:SetVelocity((self.Owner:GetPos() - ent:GetPos()):GetNormal() * -2048 + Vector( 0, 0, 128 ))
				else
					ent:SetVelocity((self.Owner:GetPos() - ent:GetPos()):GetNormal() * -2048 + Vector( 0, 0, 128 ))
				end
			end
			self:PlayWeaponSound( "lightsaber/force_leap.wav" )
			if ( foundents > 0 ) then
				self:SetForce( self:GetForce() - 10 )
			end
			self:SetNextAttack( 0.25 )
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 10)
		end
	}, {
		name = "Force Choke",
		icon = "CH",
		target = 1,
		material = "star/icon/choke.png",
		description = "Vader it up!",
		action = function( self )
			if ( self:GetForce() < 30 || CLIENT ) then return end

			for id, ent in pairs( self:SelectTargets( 1 ) ) do
				if ( !IsValid( ent ) || ent.Chocked ) then continue end
				ent.Chocked = true
				ent:Freeze(true)
				//print( ent, ent:LookupSequence("Choked_Barnacle") )
				//PrintTable( ent:GetSequenceList() )
				ent:ResetSequence( ent:LookupSequence("Choked_Barnacle") )
				//ent:ResetSequence( ent:LookupAttachment("") )
				local elev = 150
				local time = 1
				local entcur = ent:GetPos()
				for x = 1, 10 do
					timer.Simple( x / 10, function() if ( !IsValid( ent ) ) then return end
						ent:Lock()
						ent:SetPos( Lerp(x / 10, ent:GetPos(), entcur + Vector(0,0,elev)))
					end )
				end
				timer.Create( "star_choke_"..ent:EntIndex(), time + 3, 1, function() if ( !IsValid( ent ) ) then return end
					ent:UnLock()
					local dmg = DamageInfo()
					ent:Freeze(false) // SEE Robotboy655, one method of fixing choke now if you can be bothered / me run an animtion over it
					dmg:SetAttacker( self.Owner || self )
					dmg:SetInflictor( self.Owner || self )
					ent.Chocked = false
					dmg:SetDamage( 250 )
					ent:TakeDamageInfo( dmg )
					
				end )
				self:SetForce( self:GetForce() - 30)
			end

			self:SetNextAttack( 0.1 )
		end
	}, {
		name = "Force Aura Heal",
		icon = "H",
		description = "Hold Mouse 2 to slowly heal you.",
		material = "star/icon/heal",
		action = function( self )
		
			local pl = self.Owner;
			if pl:Health() >= pl:GetMaxHealth() then pl:Health(pl:GetMaxHealth())  return end
			self.Owner:SetHealth( self.Owner:Health() + (pl:GetMaxHealth() / 100) ) 
			local ed = EffectData()
			ed:SetOrigin( self.Owner:GetPos() )
			util.Effect( "effect_sithmeditate", ed, true, true )
			self:SetNextAttack(0.2)

		end
	}, {
		name = "Ground Slam",
		icon = "GS",
		material = "star/icon/ground_slam.png",
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
			for i, e in pairs( ents.FindInSphere( self.Owner:GetPos(), maxdist ) ) do
				if (e.Team and e:Team() == self.Owner:Team()) or (e.PlayerTeam and e.PlayerTeam == self.Owner:Team()) then continue end

				local dist = self.Owner:GetPos():Distance( e:GetPos() )
				local mul = ( maxdist - dist ) / 256
				local v = ( self.Owner:GetPos() - e:GetPos() ):GetNormalized()
				v.z = 0

				local dmg = DamageInfo()
				dmg:SetDamagePosition( e:GetPos() + e:OBBCenter() )
				dmg:SetDamage( 30 * mul )
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
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 30)
			self:PlayWeaponSound( "lightsaber/force_repulse.wav" )
		end
	}, {
		name = "Shadow Strike",
		icon = "SS",
		material = "star/icon/shadowstrike",
		target = 4,
		description = "Strike Up to 4 Enemys\n Cost: 80",
		action = function(self)
			if CLIENT then return end
			if self:GetForce() < 80 then return end
			local ent = self:SelectTargets( 1 )[1]
              
            if (!IsValid(ent)) then return end
			if !ent:IsNPC() and !ent:IsPlayer() then return end
                --Setup damageinfo
            local dmg = DamageInfo()
            dmg:SetDamage( 75 )
            dmg:SetDamageType( DMG_DIRECT )
            dmg:SetInflictor( self.Owner )
            dmg:SetAttacker( self.Owner )
               
            local Hit = {[ent:EntIndex()] = ent}
            local count = 0
            for x = 1,4 do
				local org = ent:GetPos()
				local sound = CreateSound( ent, Sound( self.SwingSound ) )
				ent:TakeDamageInfo( dmg )
				sound:Play()
				timer.Simple(0.75, function()
					sound:Stop()
				end)
					//sound:ChangeVolume( 0, 0 )
                   // ent = nil
                   
                for x,y in pairs(ents.FindInSphere(org, 512) ) do
                    if (y:IsPlayer() or y:IsNPC()) and y != self.Owner and !Hit[y:EntIndex()] then
                        Hit[y:EntIndex()]   = y
                        ent                 = y
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
               
            self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 30)
        end
		}, {
		name = "Heal (Others)",
		icon = "HO",
		material = "star/icon/groupheal",
		description = "Heal those around you",
		heal = 512,
		action = function( sel )
			if sel:GetForce() < 5 then return end
			local ent = sel:SelectTargets( 1 )[1]
 
			
			if !IsValid(ent) then return end
			//	local ent = trace.Entity
		
				if ent:GetMaxHealth() <= ent:Health() then
					ent:SetHealth(ent:GetMaxHealth())
				else 
					ent:SetHealth(ent:Health() + (ent:GetMaxLength() / 100))
					sel:SetForce(sel:GetForce() - 2)
					sel:SetNextAttack(0.1)
					
					local ed = EffectData()
					ed:SetOrigin( ent:GetPos() )
					util.Effect( "effect_jedimeditate", ed, true, true )
				
					local ed = EffectData()
					ed:SetOrigin( sel.Owner:GetPos() )
					util.Effect( "effect_jedimeditate", ed, true, true )
					
				end 
			self:SetNextAttack(0.2)
		end,
	}, {
		name = "Force Use",
		icon = "U",
		description = "Use Objects from far away",
		material = "star/icon/mind_trick_2.png",
		action = function(self) 
		    local trace = self:GetOwner():GetEyeTrace()
			if ( self:GetForce() < 10 || CLIENT ) then return end
			self:SetForce( self:GetForce() - 10 )
			self:SetNextAttack( 0.2 )
			//local ed = EffectData()
			//ed:SetOrigin( trace.Entity:GetPos() )
		//	util.Effect( "force_unlock", ed, true, true ) -- Might make an effect at some point
            trace.Entity:Use(self.Owner, self.Owner, USE_ON, 1)
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name)			
		end
	}, {
	name = "Force Storm",
	icon = "FS",
	material = "star/icon/storm.png",
	description = "Shoot Bolts of Lightning down from the sky",
	action = function( self )
		if CLIENT then return end
		if self:GetForce() < 70 then return end
		local pi = math.pi
		posv = {
		pi*2/5,
		pi*4/5,
		pi*6/5,
		pi*8/5,
		2*pi,
		}
		 // Yeah I know not nice 
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
		self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 45)
	
	end
	}, {
		name = "Charge",
		icon = "CH",
		material = "star/icon/leap",
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
			self.Owner:SetCoolDown(self:GetActiveForcePowerType( self:GetForceType() ).name, 20)
		end
		},  {
		name = "Force Meteor",
		icon = "C",
		target = 1,
		material = "star/icon/meteor.png",
		description = "Shoot Meteors down from the sky ",
		action = function( sel )
			if ( CLIENT ) then return end
			local ply = sel.Owner
			local ent = sel:SelectTargets( 1 )[ 1 ]

			if ( !IsValid( ent )) then sel:SetNextAttack( 0.2 ) return end

			if sel:GetForce() < 70 then return end
			for x = 1,5 do
				local meteor = ents.Create("star_metor")
				meteor.nodupe = true
				meteor:Spawn()
				meteor:SetMeteorTarget(ent)
			end
			sel:SetForce( sel:GetForce() - 70 )
			local metor = CreateSound( sel.Owner,( "star/metor/thunder_close" .. 1 ..".mp3" ))
			metor:Play()
			sel:SetNextAttack( 2 )
			sel.Owner:SetCoolDown(sel:GetActiveForcePowerType( sel:GetForceType() ).name, 60)
			
		end
	}, {
		name = "Force Light (Sith)",
		description = "Create Red Glowing Light\n Around The Player",
		icon = "FL",
		material = "star/icon/light.png", -- Will need to change
		action = function( sel )
			if SERVER then return end
			if sel:GetForce() < 10 then return end
			local ForceLight = DynamicLight( eid )
			if ( ForceLight ) then
				for x = 1,120 do
					timer.Simple(x/4 ,function()
						if sel.Owner:GetActiveWeapon() != sel then return end
						ForceLight.Pos = sel:GetPos() + Vector(0,0,50)
						ForceLight.r = 255
						ForceLight.g = 0
						ForceLight.b = 0
						ForceLight.Brightness = 0.5
						ForceLight.Size = 4024
						ForceLight.Decay = 0
						ForceLight.DieTime = CurTime() + 0.5
					end)
				end
			end
		end
	}, {
		name = "Force Light (Jedi)",
		description = "Create Light from force",
		icon = "FL",
		material = "star/icon/light.png", -- Will need to change
		action = function( sel )
			if SERVER then return end
			if sel:GetForce() < 10 then return end
			local ForceLight = DynamicLight( eid )
			if ( ForceLight ) then
				for x = 1,120 do
					timer.Simple(x/4 ,function()
						if sel.Owner:GetActiveWeapon() != sel then return end
						ForceLight.Pos = sel:GetPos() + Vector(0,0,50)
						ForceLight.r = 0
						ForceLight.g = 0
						ForceLight.b = 255
						ForceLight.Brightness = 0.5
						ForceLight.Size = 4024
						ForceLight.Decay = 0
						ForceLight.DieTime = CurTime() + 0.5
					end)
				end
			end
		end
	},
}

function StormLightning(wep, pos, pos2)
	local ply = wep.Owner
	local clr = ply:GetInfo( "star_lightning_red" ) .. " " .. ply:GetInfo( "star_lightning_green" ) .. " " .. ply:GetInfo("star_lightning_blue") // Yeah that does not look nice
	
	if !clr then clr = "255 0 0" end
	clr = tostring(clr)
	
	local LA = ents.Create("env_laser")
	LA:SetKeyValue("lasertarget", "forcestorm")
	LA:SetKeyValue("renderamt", "255")
	LA:SetKeyValue("renderfx", "15")
	LA:SetKeyValue("rendercolor", clr)
	LA:SetKeyValue("material", "sprites/laserbeam.spr")
	LA:SetKeyValue("materialscroll", "3")
	LA:SetKeyValue("dissolvetype", "-1")
	LA:SetKeyValue("spawnflags", "0")
	LA:SetKeyValue("width", "30")
	LA:SetKeyValue("damage", "100")
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
			for x,y in pairs(ents.FindInSphere(pos2, 50)) do
				if y:IsPlayer() or y:IsNPC() then
					y:TakeDamageInfo(dmg)
				end
			end
		end)
	end
end

function SL:GetSLForcePower( power )
	for x,y in pairs (self.ForcePowers) do
		if self.ForcePowers[x].name == power then
			return self.ForcePowers[x]
		end
	end
	return nil
end

function SL:DamageTrace(self, blade)
	local isTrace1Hit = false
	local pos, ang = self:GetSaberPosAng(blade)
	local trace = util.TraceLine( {
		start = pos,
		endpos = pos + ang * self:GetBladeLength(),
		filter = { self, self.Owner },
		--mins = Vector( -1, -1, -1 ) * self:GetBladeWidth() / 8,
		--maxs = Vector( 1, 1, 1 ) * self:GetBladeWidth() / 8
	} )
	local traceBack = util.TraceLine( {
		start = pos + ang * self:GetBladeLength(blade),
		endpos = pos,
		filter = { self, self.Owner },
		--mins = Vector( -1, -1, -1 ) * self:GetBladeWidth() / 8,
		--maxs = Vector( 1, 1, 1 ) * self:GetBladeWidth() / 8
	} )
	// uncomment the mins and maxs will make a box happen, This "LORD TYLER" is how you do it not with your complicated function
	
	--if ( SERVER ) then debugoverlay.Line( trace.StartPos, trace.HitPos, .1, Color( 255, 0, 0 ), false ) end

	-- When the blade is outside of the world
	if ( trace.HitSky or ( trace.StartSolid && trace.HitWorld ) ) then trace.Hit = false end
	if ( traceBack.HitSky or ( traceBack.StartSolid && traceBack.HitWorld ) ) then traceBack.Hit = false end

	self:DrawHitEffects( trace, traceBack )
	isTrace1Hit = trace.Hit or traceBack.Hit

	-- Don't deal the damage twice to the same entity
	if ( traceBack.Entity == trace.Entity && IsValid( trace.Entity ) ) then traceBack.Hit = false end

	if ( trace.Hit ) then rb655_LS_DoDamage( trace, self ) end
	if ( traceBack.Hit ) then rb655_LS_DoDamage( traceBack, self ) end

	return isTrace1Hit
end

hook.Add("Think", "SL_FIXREUPULSE", function()
	if CLIENT then return end
	for x,y in pairs(player.GetAll()) do
		if y:GetActiveWeapon().IsLightsaber then
			local wep = y:GetActiveWeapon()
			if wep._ForceRepulse && !y:KeyDown(IN_ATTACK2) then
				local maxdist = 1024
				local ed = EffectData()
				ed:SetOrigin( y:GetPos() + Vector( 0, 0, 36 ) )
				ed:SetRadius( 1024 )
				util.Effect( "rb655_force_repulse_out", ed, true, true )
				wep._ForceRepulse = nil
				wep:SetNextAttack( 1 )
				wep:PlayWeaponSound( "lightsaber/force_repulse.wav" )
				for i, e in pairs( ents.FindInSphere( y:GetPos(), maxdist ) ) do
					if ( e == y) then continue end

					local dist = y:GetPos():Distance( e:GetPos() )
					local mul = ( maxdist - dist ) / 256

					local v = ( y:GetPos() - e:GetPos() ):GetNormalized()
					v.z = 0
	
					if ( e:IsNPC() && util.IsValidRagdoll( e:GetModel() or "" ) ) then
						local dmg = DamageInfo()
						dmg:SetDamagePosition( e:GetPos() + e:OBBCenter() )
						dmg:SetDamage( 48 * mul )
						dmg:SetDamageType( DMG_GENERIC )
						if ( ( 1 - dist / maxdist ) > 0.8 ) then
							dmg:SetDamageType( DMG_DISSOLVE )
							dmg:SetDamage( e:Health() * 3 )
						end
						dmg:SetDamageForce( -v * math.min( mul * 40000, 80000 ) )
						dmg:SetInflictor(wep.Owner )
						dmg:SetAttacker( wep.Owner )
						e:TakeDamageInfo( dmg )

						if ( e:IsOnGround() ) then
							e:SetVelocity( v * mul * -2048 + Vector( 0, 0, 64 ) )
						elseif ( !e:IsOnGround() ) then
							e:SetVelocity( v * mul * -1024 + Vector( 0, 0, 64 ) )
						end

					elseif ( e:IsPlayer() && e:IsOnGround() ) then
						e:SetVelocity( v * mul * -2048 + Vector( 0, 0, 64 ) )
					elseif ( e:IsPlayer() && !e:IsOnGround() ) then
						e:SetVelocity( v * mul * -384 + Vector( 0, 0, 64 ) )
					elseif ( e:GetPhysicsObjectCount() > 0 ) then
						for i = 0, e:GetPhysicsObjectCount() - 1 do
							e:GetPhysicsObjectNum( i ):ApplyForceCenter( v * mul * -512 * math.min( e:GetPhysicsObject():GetMass(), 256 ) + Vector( 0, 0, 64 ) )
						end
					end
				end
			end
		end
	end
end)