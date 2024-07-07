
--[[

Editing the Lightsabers.

Once you unpack the lightsaber addon, you are voided of any support as to why it doesn't work.
I can't possibly provide support for all the edits and I can't know what your edits broke or whatever.

-------------------------------- DO NOT REUPLOAD THIS ADDON IN ANY SHAPE OF FORM --------------------------------
-------------------------------- DO NOT REUPLOAD THIS ADDON IN ANY SHAPE OF FORM --------------------------------
-------------------------------- DO NOT REUPLOAD THIS ADDON IN ANY SHAPE OF FORM --------------------------------
-------------------------------- DO NOT REUPLOAD THIS ADDON IN ANY SHAPE OF FORM --------------------------------
-------------------------------- DO NOT REUPLOAD THIS ADDON IN ANY SHAPE OF FORM --------------------------------

-------------------------- DO NOT EDIT ANYTHING DOWN BELOW OR YOU LOSE SUPPORT FROM ME --------------------------
-------------------------- DO NOT EDIT ANYTHING DOWN BELOW OR YOU LOSE SUPPORT FROM ME --------------------------
-------------------------- DO NOT EDIT ANYTHING DOWN BELOW OR YOU LOSE SUPPORT FROM ME --------------------------
-------------------------- DO NOT EDIT ANYTHING DOWN BELOW OR YOU LOSE SUPPORT FROM ME --------------------------
-------------------------- DO NOT EDIT ANYTHING DOWN BELOW OR YOU LOSE SUPPORT FROM ME --------------------------
-------------------------- DO NOT EDIT ANYTHING DOWN BELOW OR YOU LOSE SUPPORT FROM ME --------------------------

]]

TOOL.Category = "AFPS"
TOOL.Name = "#tool.star_lightning"

TOOL.ClientConVar["red"] = "100"
TOOL.ClientConVar["green"] = "100"
TOOL.ClientConVar["blue"] = "255"

function TOOL:LeftClick( trace )

	return false
end

function TOOL:RightClick( trace )

	return false
end


if ( SERVER ) then return end

language.Add( "tool.star_lightning", "Lightning" )
language.Add( "tool.star_lightning.name", "Lightning" )
language.Add( "tool.star_lightning.desc", "Edit the Colour of your Lightning" )
language.Add( "tool.star_lightning.0", "" )
language.Add( "tool.star_lightning.left", "" )
language.Add( "tool.star_lightning.right", "" )


language.Add( "tool.star_lightning.color", "Lighting Color" )


language.Add( "tool.star_lightning.preset1", "Blue Lighting" )
language.Add( "tool.star_lightning.preset2", "Red Lighting" )
language.Add( "tool.star_lightning.preset3", "Green Lighting" )
language.Add( "tool.star_lightning.preset4", "Dark Blue Lighting" )

local ConVarsDefault = TOOL:BuildConVarList()

local PresetPresets = {
	[ "#preset.default" ] = ConVarsDefault,
	[ "#tool.star_lightning.preset1" ] = {
		star_lightning_red = "100",
		star_lightning_green = "100",
		star_lightning_blue = "255",
	},
	[ "#tool.star_lightning.preset2" ] = {
		star_lightning_red = "255",
		star_lightning_green = "0",
		star_lightning_blue = "0",
	},
	[ "#tool.star_lightning.preset3" ] = {
		star_lightning_red = "0",
		star_lightning_green = "255",
		star_lightning_blue = "0",
	},
	[ "#tool.star_lightning.preset4" ] = {
		star_lightning_red = "0",
		star_lightning_green = "0",
		star_lightning_blue = "255",
	},

}

function TOOL.BuildCPanel( panel )
	panel:AddControl( "ComboBox", { MenuButton = 1, Folder = "star_lightning", Options = PresetPresets, CVars = table.GetKeys( ConVarsDefault ) } )

	panel:AddControl( "Color", { Label = "#tool.star_lightning.color", Red = "star_lightning_red", Green = "star_lightning_green", Blue = "star_lightning_blue", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )

end
