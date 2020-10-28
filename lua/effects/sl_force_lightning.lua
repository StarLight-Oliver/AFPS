
local function GetRandomPositionInBox( mins, maxs, ang )
	return ang:Up() * math.random( mins.z, maxs.z ) + ang:Right() * math.random( mins.y, maxs.y ) + ang:Forward() * math.random( mins.x, maxs.x )
end

local function GenerateLighting( from, to, deviations, power )
	local start = from
	if ( isentity( start ) ) then start = from:GetPos() end
	local endpos = to:GetPos()

	--render.DrawWireframeBox( start, Angle(0, 0, 0),from:OBBMins(), from:OBBMaxs(), Color(255, 0, 0), true )
	--render.DrawWireframeBox( start, to:GetAngles(),from:OBBMins(), from:OBBMaxs(), Color(0, 255, 0), true )

	--start = start + GetRandomPositionInBox( from:OBBMins(), from:OBBMaxs(), from:GetAngles() )
	endpos = endpos + GetRandomPositionInBox( to:OBBMins(), to:OBBMaxs(), to:GetAngles() )

	local right = (start - endpos):Angle():Right()
	local up = (start - endpos):Angle():Up()
	local segments = {
		{ start, endpos }
	}
	for i = 0, power do
		local newsegs = {}
		for id, seg in pairs( segments ) do
			local mid = Vector( (seg[1].x + seg[2].x) / 2, (seg[1].y + seg[2].y) / 2, (seg[1].z + seg[2].z) / 2 )
			local offsetpos = mid + right * math.random( -deviations, deviations ) + up * math.random( -deviations, deviations )
			table.insert( newsegs, {seg[1], offsetpos} )
			table.insert( newsegs, {offsetpos, seg[2]} )
		end
		segments = newsegs
	end
	return segments
end

local function GenerateLightingSegs( from, to, deviations, segs )
	local start = from
	if ( isentity( start ) ) then start = from:GetPos() end
	local endpos = to:GetPos()

	--render.DrawWireframeBox( start, Angle(0, 0, 0),from:OBBMins(), from:OBBMaxs(), Color(255, 0, 0), true )
	--render.DrawWireframeBox( start, to:GetAngles(),from:OBBMins(), from:OBBMaxs(), Color(0, 255, 0), true )

	--start = start + GetRandomPositionInBox( from:OBBMins(), from:OBBMaxs(), from:GetAngles() )
	endpos = endpos + GetRandomPositionInBox( to:OBBMins(), to:OBBMaxs(), to:GetAngles() )

	local right = (start - endpos):Angle():Right()
	local up = (start - endpos):Angle():Up()
	local fwd = (start - endpos):Angle():Forward()
	local step = (1 / segs) * start:Distance( endpos )

	local lastpos = start
	local segments = {}
	for i = 1, segs do
		local a = lastpos - fwd * step
		table.insert( segments, { lastpos, a } )
		lastpos = a
	end

	for k, v in pairs( segments ) do
		if ( k == 1 || k == #segments ) then continue end

		segments[ k ][ 1 ] = segments[ k ][ 1 ] + right * math.random( -deviations, deviations ) + up * math.random( -deviations, deviations )
		segments[ k - 1 ][ 2 ] = segments[ k ][ 1 ]
	end

	for k, v in pairs( segments ) do
		if ( k == 1 || k == #segments ) then continue end

		if ( math.random( 0, 100 ) > 75 ) then
			local dir = AngleRand():Forward()
			table.insert( segments, { segments[ k ][ 1 ], segments[ k ][ 1 ] + dir * ( step * math.Rand( 0.2, 0.6 ) ) } )
		end
	end

	return segments
end

local mats = {
	(Material( "star/effects/lightning.png" )),
}

local segments = {}
--local n = 0
local tiem = .2

local inner = Material("star/effects/lightning_inner.png")

hook.Add( "PostDrawTranslucentRenderables", "SL.Lighting", function()
	for id, t in pairs( segments ) do
		if ( t.time < CurTime() ) then table.remove( segments, id ) continue end
		
		for id, seg in pairs( t.segs ) do
			
			local size = ( math.max( t.startpos:Distance( t.endpos ) - seg[1]:Distance( t.endpos ), 20) / ( t.startpos:Distance( t.endpos ) ) * t.w ) * ( (t.time - CurTime() ) / tiem )
			render.SetMaterial( t.mat )	
			render.DrawBeam(seg[1], seg[2], size, 0, seg[1]:Distance( seg[2] ) / 25, t.color)
			render.DrawBeam(seg[1], seg[2], size*0.5, 0, seg[1]:Distance( seg[2] ) / 25, color_white)
		end
	end
end )

function EFFECT:Init( data )
	local pos = data:GetOrigin()
	local ent = data:GetEntity()
	local color = data:GetAngles()

	color = Color(color[1], color[2], color[3])

	if ( !IsValid( ent ) ) then return end

	table.insert( segments, {
		color = color,
		segs = GenerateLightingSegs( pos, ent, math.random( 10, 20 ), pos:Distance( ent:GetPos() ) / 48 ), --math.random( 5, 10 ) ),
		mat = table.Random( mats ),
		time = CurTime() + tiem,
		w = math.random( 20, 50 ),
		startpos = pos,
		endpos = ent:GetPos()
	} )
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()

end
