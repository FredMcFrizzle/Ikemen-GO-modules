--[[	   				  PALNUM MODULE
===================================================================
Version: 1.0
Author: Fred McFrizzle
Tested on: 2024-08-14 Nightly Build
Description:
Adds palnum function to select.def, if palnum used then it forces that palette number on the character.
===================================================================
]]

-- HOW TO INSTALL!
-- Drag and drop the palnum.lua file into external\mods\ directory

-- HOW TO USE!
-- in your select.def file under characters, when assigning a character you can now force the character to use a palette (this helps for secret palette characters)
-- Example:
-- kfm, stages/mybg.def, includestage=0  <-- Normal Kung Fu Man
-- kfm, palnum=7, stages/mybg.def, includestage=0  <-- Green Kung Fu Man
-- Currently this does not show the palette you will choose in the character select screen. I wish to implement this in the future but for now im content with this.

-- INFO!
-- if the same palette is selected it will act as normal and the person who selected the palette last will get the next available palette.
-- Using a palette number that doesnt exist will wrap back around. (using palette 13 on a character with 12 palettes goes back to palette 1)

----------------------
-- Palette Function --
----------------------

function start.f_keyPalMap(ref, num, t_assignedPals)
    local t_assignedPals = {}
	local charData = start.f_getCharData(ref)
	local mappedPal
	start.f_setAssignedPal(ref, t_assignedPals)
	if charData.palnum == nil then
		mappedPal = charData.pal_keymap[num] or num
	else
		mappedPal = charData.palnum
	end
    local totalPals = #start.f_getCharData(ref).pal
	-- loop through the palette indices starting from mappedPal
    for i = 0, totalPals - 1 do
        -- calculate the current palette index, wrapping around if it exceeds totalPals
        local currentPal = (mappedPal + i - 1) % totalPals + 1
        -- check if the current palette is not already assigned
        if not t_assignedPals[currentPal] then
            return currentPal
        end
    end
    -- if all palettes are assigned, return the mapped palette
    return mappedPal
end
