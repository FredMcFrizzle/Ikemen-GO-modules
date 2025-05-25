--[[	   				  PALNUM MODULE
===================================================================
Version: 1.1
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

--;===========================================================
--; CONFIG
--;===========================================================
-- Change these how you like!

--These are based off the position of the character name in motif
--Default: 0
local palnameX = 0
--Default: 10
local palnameY = 10

--;===========================================================
--; PALETTE KEYMAP
--;===========================================================

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

--;===========================================================
--; SELECT SCREEN
--;===========================================================
local t_recordText = {}
local txt_recordSelect = main.f_createTextImg(motif.select_info, 'record')
local txt_timerSelect = main.f_createTextImg(motif.select_info, 'timer')
local txt_selStage = main.f_createTextImg(motif.select_info, 'stage_active')
local t_txt_name = {}
for i = 1, 2 do
	table.insert(t_txt_name, main.f_createTextImg(motif.select_info, 'p' .. i .. '_name'))
end

if main.t_sort.select_info.teammenu == nil then
	main.t_sort.select_info.teammenu = {'single', 'simul', 'turns'}
end

function start.f_selectScreen()
	if (not main.selectMenu[1] and not main.selectMenu[2]) or selScreenEnd then
		return true
	end
	main.f_bgReset(motif.selectbgdef.bg)
	main.f_fadeReset('fadein', motif.select_info)
	main.f_playBGM(false, motif.music.select_bgm, motif.music.select_bgm_loop, motif.music.select_bgm_volume, motif.music.select_bgm_loopstart, motif.music.select_bgm_loopend)
	start.f_resetTempData(motif.select_info, '_face')
	local stageActiveCount = 0
	local stageActiveType = 'stage_active'
	timerSelect = 0
	local escFlag = false
	local t_teamMenu = {{}, {}}
	local blinkCount = 0
	local counter = 0 - motif.select_info.fadein_time
	-- generate team mode items table
	for side = 1, 2 do
		-- start with all default teammode entires
		local str = 'teammenu_itemname_' .. gamemode() .. '_'
		local t = {
			{data = text:create({}), itemname = 'single', displayname = (motif.select_info[str .. 'single'] or motif.select_info.teammenu_itemname_single), mode = 0, insert = true},
			{data = text:create({}), itemname = 'simul', displayname = (motif.select_info[str .. 'simul'] or motif.select_info.teammenu_itemname_simul), mode = 1, insert = true},
			{data = text:create({}), itemname = 'turns', displayname = (motif.select_info[str .. 'turns'] or motif.select_info.teammenu_itemname_turns), mode = 2, insert = true},
			{data = text:create({}), itemname = 'tag', displayname = (motif.select_info[str .. 'tag'] or motif.select_info.teammenu_itemname_tag), mode = 3, insert = true},
			{data = text:create({}), itemname = 'ratio', displayname = (motif.select_info[str .. 'ratio'] or motif.select_info.teammenu_itemname_ratio), mode = 2, insert = true},
		}
		local activeNum = #t
		-- keep team mode allowed by game mode declaration, but only if it hasn't been disabled by screenpack parameter
		for i = #t, 1, -1 do
			local itemname = t[i].itemname
			if not main.teamMenu[side][itemname]
				or (motif.select_info[str .. itemname] ~= nil and motif.select_info[str .. itemname] == '')
				or (motif.select_info[str .. itemname] == nil and motif.select_info['teammenu_itemname_' .. itemname] == '') then
				t[i].insert = false
				activeNum = activeNum - 1 --track disabled items
			end
		end
		-- first we insert all entries existing in screenpack file in correct order
		for _, name in ipairs(main.f_tableExists(main.t_sort.select_info).teammenu) do
			for k, v in ipairs(t) do
				if v.insert and (name == v.itemname or name == gamemode() .. '_' .. v.itemname) then
					table.insert(t_teamMenu[side], v)
					v.insert = false
					break
				end
			end
		end
		-- then we insert remaining default entries
		for k, v in ipairs(t) do
			if v.insert or (activeNum == 0 and main.teamMenu[side][v.itemname]) then
				table.insert(t_teamMenu[side], v)
				-- if all items are disabled by screenpack add only first default item
				if activeNum == 0 then
					break
				end
			end
		end
	end
	while not selScreenEnd do
		counter = counter + 1
		--credits
		if main.credits ~= -1 and getKey(motif.attract_mode.credits_key) then
			sndPlay(motif.files.snd_data, motif.attract_mode.credits_snd[1], motif.attract_mode.credits_snd[2])
			main.credits = main.credits + 1
			resetKey()
		end
		--draw clearcolor
		clearColor(motif.selectbgdef.bgclearcolor[1], motif.selectbgdef.bgclearcolor[2], motif.selectbgdef.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(motif.selectbgdef.bg, 0)
		--draw title
		main.txt_mainSelect:draw()
		--draw portraits
		for side = 1, 2 do
			if #start.p[side].t_selTemp > 0 then
				start.f_drawPortraits(start.p[side].t_selTemp, side, motif.select_info, '_face', true)
			end
		end
		--draw cell art
		for row = 1, motif.select_info.rows do
			for col = 1, motif.select_info.columns do
				local t = start.t_grid[row][col]
				if t.skip ~= 1 then
					--draw cell background
					if (t.char ~= nil and (t.hidden == 0 or t.hidden == 3)) or motif.select_info.showemptyboxes == 1 then
						main.f_animPosDraw(
							motif.select_info.cell_bg_data,
							motif.select_info.pos[1] + t.x,
							motif.select_info.pos[2] + t.y,
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
						)
					end
					--draw random cell
					if t.char == 'randomselect' or t.hidden == 3 then
						main.f_animPosDraw(
							motif.select_info.cell_random_data,
							motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
							motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_random_facing)
						)
					--draw face cell
					elseif t.char ~= nil and t.hidden == 0 then
						main.f_animPosDraw(
							start.f_getCharData(t.char_ref).cell_data,
							motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
							motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
							(motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.portrait_facing)
						)
					end
				end
			end
		end
		--draw done cursors
		for side = 1, 2 do
			for _, v in pairs(start.p[side].t_selected) do
				if v.cursor ~= nil then
					--get cell coordinates
					local x = v.cursor[1]
					local y = v.cursor[2]
					local t = start.t_grid[y + 1][x + 1]
					--retrieve proper cell coordinates in case of random selection
					--TODO: doesn't work with slot feature
					--if (t.char == 'randomselect' or t.hidden == 3) --[[and not gameOption('Options.Team.Duplicates')]] then
					--	x = start.f_getCharData(v.ref).col - 1
					--	y = start.f_getCharData(v.ref).row - 1
					--	t = start.t_grid[y + 1][x + 1]
					--end
					--render only if cell is not hidden
					if t.hidden ~= 1 and t.hidden ~= 2 then
						start.f_drawCursor(v.pn, x, y, '_cursor_done')
					end
				end
			end
		end
		--team and select menu
		if blinkCount < motif.select_info.p2_cursor_switchtime then
			blinkCount = blinkCount + 1
		else
			blinkCount = 0
		end
		for side = 1, 2 do
			if not start.p[side].teamEnd then
				start.f_teamMenu(side, t_teamMenu[side])
			elseif not start.p[side].selEnd then
				--for each player with active controls
				for k, v in ipairs(start.p[side].t_selCmd) do
					local member = main.f_tableLength(start.p[side].t_selected) + k
					if main.coop and (side == 1 or gamemode('versuscoop')) then
						member = k
					end
					--member selection
					v.selectState = start.f_selectMenu(side, v.cmd, v.player, member, v.selectState)
					--draw active cursor
					if side == 2 and motif.select_info.p2_cursor_blink == 1 then
						local sameCell = false
						for _, v2 in ipairs(start.p[1].t_selCmd) do							
							if start.c[v.player].cell == start.c[v2.player].cell and v.selectState == 0 and v2.selectState == 0 then
								if blinkCount == 0 then
									start.c[v.player].blink = not start.c[v.player].blink
								end
								sameCell = true
								break
							end
						end
						if not sameCell then
							start.c[v.player].blink = false
						end
					end
					if v.selectState < 4 and start.f_selGrid(start.c[v.player].cell + 1).hidden ~= 1 and not start.c[v.player].blink then
						start.f_drawCursor(v.player, start.c[v.player].selX, start.c[v.player].selY, '_cursor_active')
					end
				end
			end
			--delayed screen transition for the duration of face_done_anim or selection sound
			if start.p[side].screenDelay > 0 then
				if main.f_input(main.t_players, {'pal', 's'}) then
					start.p[side].screenDelay = 0
				else
					start.p[side].screenDelay = start.p[side].screenDelay - 1
				end
			end
		end
		--exit select screen
		if not escFlag and (esc() or main.f_input(main.t_players, {'m'})) then
			main.f_fadeReset('fadeout', motif.select_info)
			escFlag = true
		end
		--draw names
		for side = 1, 2 do
			if #start.p[side].t_selTemp > 0 then
				for i = 1, #start.p[side].t_selTemp do
					if i <= motif.select_info['p' .. side .. '_name_num'] or main.coop then
						local name = ''
						local pal = ''
						if motif.select_info['p' .. side .. '_name_num'] == 1 then
							name = start.f_getName(start.p[side].t_selTemp[#start.p[side].t_selTemp].ref, side)
							if start.f_getCharData(start.p[side].t_selTemp[i].ref, side) ~= nil then
							pal = 'color ' .. tostring(start.f_getCharData(start.p[side].t_selTemp[#start.p[side].t_selTemp].ref, side).palname)
							end
						else
							name = start.f_getName(start.p[side].t_selTemp[i].ref, side)
							if start.p[side].t_selTemp[i].ref ~= nil then
							pal = 'color ' .. tostring(start.f_getCharData(start.p[side].t_selTemp[i].ref, side).palname)
							end
						end
						t_txt_name[side]:update({
							font =   motif.select_info['p' .. side .. '_name_font'][1],
							bank =   motif.select_info['p' .. side .. '_name_font'][2],
							align =  motif.select_info['p' .. side .. '_name_font'][3],
							text =   name,
							x =      motif.select_info['p' .. side .. '_name_offset'][1] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][1],
							y =      motif.select_info['p' .. side .. '_name_offset'][2] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][2],
							scaleX = motif.select_info['p' .. side .. '_name_scale'][1],
							scaleY = motif.select_info['p' .. side .. '_name_scale'][2],
							r =      motif.select_info['p' .. side .. '_name_font'][4],
							g =      motif.select_info['p' .. side .. '_name_font'][5],
							b =      motif.select_info['p' .. side .. '_name_font'][6],
							height = motif.select_info['p' .. side .. '_name_font'][7],
						})
						t_txt_name[side]:draw()
						--draw palette name
						if start.p[side].t_selTemp[#start.p[side].t_selTemp].ref ~= nil then
							if start.f_getCharData(start.p[side].t_selTemp[#start.p[side].t_selTemp].ref, side).palname ~= nil then
								t_txt_name[side]:update({
									text =   pal,
									x =		 motif.select_info['p' .. side .. '_name_offset'][1] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][1] + palnameX,
									y =      motif.select_info['p' .. side .. '_name_offset'][2] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][2] + palnameY,
								})
								t_txt_name[side]:draw()
							end
						end
						if start.p[side].t_selTemp[i].ref ~= nil then
							if start.f_getCharData(start.p[side].t_selTemp[i].ref, side).palname ~= nil then
								t_txt_name[side]:update({
									text =   pal,
									x =		 motif.select_info['p' .. side .. '_name_offset'][1] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][1] + palnameX,
									y =      motif.select_info['p' .. side .. '_name_offset'][2] + (i - 1) * motif.select_info['p' .. side .. '_name_spacing'][2] + palnameY,
								})
								t_txt_name[side]:draw()
							end
						end
					end
				end
			end
		end
		--team and character selection complete
		if start.p[1].selEnd and start.p[2].selEnd and start.p[1].teamEnd and start.p[2].teamEnd then
			restoreCursor = true
			if main.stageMenu and not stageEnd then --Stage select
				start.f_stageMenu()
			elseif start.p[1].screenDelay <= 0 and start.p[2].screenDelay <= 0 and main.fadeType == 'fadein' then
				main.f_fadeReset('fadeout', motif.select_info)
			end
			--draw stage portrait
			if main.stageMenu then
				--draw stage portrait background
				main.f_animPosDraw(motif.select_info.stage_portrait_bg_data)
				--draw stage portrait (random)
				if stageListNo == 0 then
					main.f_animPosDraw(motif.select_info.stage_portrait_random_data)
				--draw stage portrait loaded from stage SFF
				else
					main.f_animPosDraw(
						main.t_selStages[main.t_selectableStages[stageListNo]].anim_data,
						motif.select_info.stage_pos[1] + motif.select_info.stage_portrait_offset[1],
						motif.select_info.stage_pos[2] + motif.select_info.stage_portrait_offset[2]
					)
				end
				if not stageEnd then
					if main.f_input(main.t_players, {'pal', 's'}) or timerSelect == -1 then
						sndPlay(motif.files.snd_data, motif.select_info.stage_done_snd[1], motif.select_info.stage_done_snd[2])
						stageActiveType = 'stage_done'
						stageEnd = true
					elseif stageActiveCount < motif.select_info.stage_active_switchtime then --delay change
						stageActiveCount = stageActiveCount + 1
					else
						if stageActiveType == 'stage_active' then
							stageActiveType = 'stage_active2'
						else
							stageActiveType = 'stage_active'
						end
						stageActiveCount = 0
					end
				end
				--draw stage name
				local t_txt = {}
				if stageListNo == 0 then
					t_txt[1] = motif.select_info.stage_random_text
				else
					t = motif.select_info.stage_text:gsub('%%i', tostring(stageListNo))
					t = t:gsub('\n', '\\n')
					t = t:gsub('%%s', main.t_selStages[main.t_selectableStages[stageListNo]].name)
					for i, c in ipairs(main.f_strsplit('\\n', t)) do --split string using "\n" delimiter
						t_txt[i] = c
					end
				end
				for i = 1, #t_txt do
					txt_selStage:update({
						font =   motif.select_info[stageActiveType .. '_font'][1],
						bank =   motif.select_info[stageActiveType .. '_font'][2],
						align =  motif.select_info[stageActiveType .. '_font'][3],
						text =   t_txt[i],
						x =      motif.select_info.stage_pos[1] + motif.select_info[stageActiveType .. '_offset'][1],
						y =      motif.select_info.stage_pos[2] + motif.select_info[stageActiveType .. '_offset'][2] + main.f_ySpacing(motif.select_info, stageActiveType) * (i - 1),
						scaleX = motif.select_info[stageActiveType .. '_scale'][1],
						scaleY = motif.select_info[stageActiveType .. '_scale'][2],
						r =      motif.select_info[stageActiveType .. '_font'][4],
						g =      motif.select_info[stageActiveType .. '_font'][5],
						b =      motif.select_info[stageActiveType .. '_font'][6],
						height = motif.select_info[stageActiveType .. '_font'][7],
					})
					txt_selStage:draw()
				end
			end
		end
		--draw timer
		if motif.select_info.timer_count ~= -1 and (not start.p[1].teamEnd or not start.p[2].teamEnd or not start.p[1].selEnd or not start.p[2].selEnd or (main.stageMenu and not stageEnd)) and counter >= 0 then
			timerSelect = main.f_drawTimer(timerSelect, motif.select_info, 'timer_', txt_timerSelect)
		end
		--draw record text
		for i = 1, #t_recordText do
			txt_recordSelect:update({
				text = t_recordText[i],
				y = motif.select_info.record_offset[2] + main.f_ySpacing(motif.select_info, 'record') * (i - 1),
			})
			txt_recordSelect:draw()
		end
		-- hook
		hook.run("start.f_selectScreen")
		--draw layerno = 1 backgrounds
		bgDraw(motif.selectbgdef.bg, 1)
		--draw fadein / fadeout
		main.f_fadeAnim(motif.select_info)
		--frame transition
		if not main.f_frameChange() then
			selScreenEnd = true
			break --skip last frame rendering
		end
		main.f_refresh()
	end
	return not escFlag
end

--resets various data
function start.f_selectReset(hardReset)
	esc(false)
	setMatchNo(1)
	setConsecutiveWins(1, 0)
	setConsecutiveWins(2, 0)
	setContinue(false)
	main.f_cmdInput()
	local col = 1
	local row = 1
	for i = 1, #main.t_selGrid do
		if i > motif.select_info.columns * row then
			row = row + 1
			col = 1
		end
		if main.t_selGrid[i].slot ~= 1 then
			main.t_selGrid[i].slot = 1
			start.t_grid[row][col].char = start.f_selGrid(i).char
			start.t_grid[row][col].char_ref = start.f_selGrid(i).char_ref
			start.t_grid[row][col].hidden = start.f_selGrid(i).hidden
			start.t_grid[row][col].skip = start.f_selGrid(i).skip
		end
		col = col + 1
	end
	if hardReset then
		stageListNo = 0
		restoreCursor = false
		--cursor start cell
		for i = 1, gameOption('Config.Players') do
			if start.f_getCursorData(i, '_cursor_startcell')[1] < motif.select_info.rows then
				start.c[i].selY = start.f_getCursorData(i, '_cursor_startcell')[1]
			else
				start.c[i].selY = 0
			end
			if start.f_getCursorData(i, '_cursor_startcell')[2] < motif.select_info.columns then
				start.c[i].selX = start.f_getCursorData(i, '_cursor_startcell')[2]
			else
				start.c[i].selX = 0
			end
			start.c[i].cell = -1
			start.c[i].randCnt = 0
			start.c[i].randRef = nil
		end
	end
	if stageRandom then
		stageListNo = 0
		stageRandom = false
	end
	for side = 1, 2 do
		if hardReset then
			start.p[side].numSimul = math.max(2, gameOption('Options.Simul.Min'))
			start.p[side].numTag = math.max(2, gameOption('Options.Tag.Min'))
			start.p[side].numTurns = math.max(2, gameOption('Options.Turns.Min'))
			start.p[side].numRatio = 1
			start.p[side].teamMenu = 1
			start.p[side].t_cursor = {}
			start.p[side].teamMode = 0
		end
		start.p[side].numSimul = math.min(start.p[side].numSimul, gameOption('Options.Simul.Max'))
		start.p[side].numTag = math.min(start.p[side].numTag, gameOption('Options.Tag.Max'))
		start.p[side].numTurns = math.min(start.p[side].numTurns, gameOption('Options.Turns.Max'))
		start.p[side].numChars = 1
		start.p[side].teamEnd = main.cpuSide[side] and (side == 2 or not main.cpuSide[1]) and main.forceChar[side] == nil
		start.p[side].selEnd = not main.selectMenu[side]
		start.p[side].ratio = false
		start.p[side].t_selected = {}
		start.p[side].t_selTemp = {}
		start.p[side].t_selCmd = {}
	end
	for _, v in ipairs(start.c) do
		v.cell = -1
	end
	selScreenEnd = false
	stageEnd = false
	t_reservedChars = {{}, {}}
	start.winCnt = 0
	start.loseCnt = 0
	if start.challenger == 0 then
		start.t_savedData = {
			win = {0, 0},
			lose = {0, 0},
			time = {total = 0, matches = {}},
			score = {total = {0, 0}, matches = {}},
			consecutive = {0, 0},
			debugflag = {false, false},
		}
		start.t_roster = {}
		start.reset = true
	end
	t_recordText = start.f_getRecordText()
	menu.movelistChar = 1
	hook.run("start.f_selectReset")
end