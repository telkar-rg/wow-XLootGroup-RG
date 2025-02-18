local ADDON_NAME, ADDON_TABLE = ...

local XLootGroup = _G["XLootGroup"]
if not XLootGroup then return end

local TMT = _G["TransmogTracker"]
if not TMT then return end

-- XLootGroup.AA = AA

local ADDON_NAME_SHORT = "TMT_XLG"
local function DPrint(...)
	DEFAULT_CHAT_FRAME:AddMessage( "|cff66bbff"..ADDON_NAME_SHORT.."|r: " .. strjoin("|r; ", tostringall(...) ) )
	ChatFrame3:AddMessage( "|cff66bbff"..ADDON_NAME_SHORT.."|r: " .. strjoin("|r; ", tostringall(...) ) )
end
local print=DPrint



local TMT_AddGroupLoot

local PlayerClassLocal, PlayerClassEN
local tmog_itemSubClasses = {}
local magic_1, magic_2, magic_3, magic_4, magic_5, magic_6, magic_7 = 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875
local ttClasses = gsub(ITEM_CLASSES_ALLOWED, "%%s", "")
local ttClassesLen = strlen(ttClasses)
local pattern_item = "(\124c%x+\124Hitem:(%d+):[-:%d]+\124h%[(.-)%]\124h\124r)"
local tmog_allowed = {
	["ALL"] = {
		["INVTYPE_HEAD"] 		= 1,
		["INVTYPE_SHOULDER"] 	= 1,
		["INVTYPE_BODY"] 		= 1,
		["INVTYPE_CHEST"] 		= 1,
		["INVTYPE_ROBE"] 		= 1,
		["INVTYPE_WAIST"] 		= 1,
		["INVTYPE_LEGS"] 		= 1,
		["INVTYPE_FEET"] 		= 1,
		["INVTYPE_WRIST"] 		= 1,
		["INVTYPE_HAND"] 		= 1,
		["INVTYPE_CLOAK"] 		= 1,
		["INVTYPE_WEAPON"] 		= 1,
		["INVTYPE_2HWEAPON"] 	= 1,
		["INVTYPE_WEAPONMAINHAND"] 	= 1,
	},
	["WARRIOR"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] 	= 1, -- needs 2nd check
		["INVTYPE_SHIELD"] 	= 1,
		["INVTYPE_RANGED"] 	= 1,
		["INVTYPE_THROWN"] 	= 1,
	},
	["DEATHKNIGHT"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
	},
	["PALADIN"] = {
		["INVTYPE_SHIELD"] 	= 1,
	},
	["PRIEST"] = {
		["INVTYPE_HOLDABLE"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1, -- needs 2nd check
	},
	["SHAMAN"] = {
		["INVTYPE_SHIELD"] 	= 1,
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
	},
	["DRUID"] = {
		["INVTYPE_HOLDABLE"] 	= 1
	},
	["ROGUE"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
		["INVTYPE_RANGED"] 	= 1,
		["INVTYPE_THROWN"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1, -- needs 2nd check
	},
	["MAGE"] = {
		["INVTYPE_HOLDABLE"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1,
	},
	["WARLOCK"] = {
		["INVTYPE_HOLDABLE"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] = 1, -- needs 2nd check
	},
	["HUNTER"] = {
		["INVTYPE_WEAPONOFFHAND"] 	= 1,
		["INVTYPE_RANGED"] 	= 1,
		["INVTYPE_THROWN"] 	= 1,
		["INVTYPE_RANGEDRIGHT"] 	= 1, -- needs 2nd check
	},
	["GUNS_CROSSBOWS"] = {
		["HUNTER"] 	= 1,
		["ROGUE"] 	= 1,
		["WARRIOR"] = 1,
	},
	["WANDS"] = {
		["PRIEST"] 	= 1,
		["MAGE"] 	= 1,
		["WARLOCK"] = 1,
	},
}


function ADDON_TABLE.OnReady()
	-- called when "ADDON_LOADED" event fired
	print("-- OnReady, ADDON_LOADED")
	
	PlayerClassLocal, PlayerClassEN = UnitClass("player")
	tmog_itemSubClasses = { GetAuctionItemSubClasses(1) }
end


function ADDON_TABLE.OnLoad()
	-- called when addon file is fully executed
	print("-- OnLoad")
	
	PlayerClassLocal, PlayerClassEN = UnitClass("player") 		-- get EN PlayerClass
	tmog_itemSubClasses = { GetAuctionItemSubClasses(1) }
	hooksecurefunc(XLootGroup, "AddGroupLoot", TMT_AddGroupLoot);
end


function ADDON_TABLE.OnEvent(frame, event, ...)
	if (event == 'ADDON_LOADED') then
		local name = ...;
		if name == ADDON_NAME then
			ADDON_TABLE.Frame:UnregisterEvent("ADDON_LOADED")
			ADDON_TABLE.OnReady();
		end
	end
end


function TMT_AddGroupLoot(self, item, time)
	local stack = XLootGroup.AA.stacks.roll
	
	print("stack.rows", #stack.rows)
	print("-- TMT_AddGroupLoot", item)
	
	local row
	for idx = 1, #stack.rows do
		row = stack.rows[idx]
		if row.rollID == item then break end
		row = nil
	end
	if not row then return end
	
	local tmtIcon = row.tmtIcon
	if not tmtIcon then
		tmtIcon = CreateFrame("Frame", row:GetName().."tmtIcon", row)
		tmtIcon.tex = tmtIcon:CreateTexture()
		tmtIcon.tex:SetTexture("Interface\\Minimap\\TRACKING\\OBJECTICONS")
		tmtIcon.tex:SetTexCoord(0, 0.125, 0, 0.5)
		tmtIcon.tex:SetPoint("CENTER", row, "TOPLEFT", 0, -3)
		
		tmtIcon.tex:SetWidth(row.bneed:GetWidth())
		tmtIcon.tex:SetHeight(row.bneed:GetHeight())
		tmtIcon:SetFrameLevel(row.bneed:GetFrameLevel()+1)
		
		row.tmtIcon = tmtIcon
		
	end
	tmtIcon.tex:Hide()
	
	
	local tmogState, itemLevel, itemType, itemSubType, itemEquipLoc, itemId
	_, itemId, _ = strmatch( row.link, pattern_item )
	if not itemId then return end
	itemId = tonumber(itemId)
	if not itemId then return end
	
	_, _, _, itemLevel, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemId)
	
	if not itemEquipLoc or itemEquipLoc == "" then return end
	if itemLevel > 2400 then  -- ignore pdk25 and above item levels
		return
	end
	
	if TMT:checkItemId(itemId) then
		tmogState = 1 -- we know it
	elseif TMT:checkUniqueId(itemId) then
		tmogState = 2 -- we know it through others
	else
		tmogState = 3 -- we dont know it
	end
	
	-- check if we even want to track this
	if tmogState == 3 then
		if not (tmog_allowed.ALL[itemEquipLoc] or tmog_allowed[PlayerClassEN][itemEquipLoc]) then
			-- print("this class", PlayerClassEN, "cannot tmog", itemEquipLoc)
			return
		end
		
		if itemEquipLoc == "INVTYPE_RANGEDRIGHT" then
			if ( itemSubType == tmog_itemSubClasses[16] ) then -- if WAND
				if not tmog_allowed.WANDS[PlayerClassEN] then
					-- print("this class", PlayerClassEN, "cannot tmog", itemSubType)
					return
				end
			else -- if GUNS CROSSBOWS
				if not tmog_allowed.GUNS_CROSSBOWS[PlayerClassEN] then
					-- print("this class", PlayerClassEN, "cannot tmog", itemSubType)
					return
				end
			end
		end
	end
	if tmogState ~= 1 then
		
		TMT_XLG_TooltipHidden:SetOwner(UIParent, "ANCHOR_NONE")
		TMT_XLG_TooltipHidden:ClearLines()
		TMT_XLG_TooltipHidden:SetHyperlink(row.link) -- check tooltip of our item
		
		local outClasses
		-- check all lines of our tooltip
		for i=1,TMT_XLG_TooltipHidden:NumLines() do 
			local txtL = getglobal("TMT_XLG_TooltipHidden".."TextLeft" ..i):GetText()
			-- local txtR = getglobal("TMT_XLG_TooltipHidden".."TextRight"..i):GetText()
			if not txtL or txtL=="" or txtL==" " then break end
			
			if strsub(txtL,1,ttClassesLen) == ttClasses then
				
				local tc = { strsplit(",", strsub(txtL,ttClassesLen+1)) }
				-- print("this item is for classes:", unpack(tc))
				outClasses = {}
				
				if #tc > 0 then
					for _, cName in pairs(tc) do
						cName = strtrim(cName)
						outClasses[cName] = 1
					end
				end
				if not outClasses[PlayerClassLocal] then 
					return
				end
				break
			end
		end
		TMT_XLG_TooltipHidden:Hide()
	end
	if tmogState then
		if tmogState == 1 then
			row.tmtIcon.tex:SetTexCoord(magic_4, magic_5, 0, 0.5)
		elseif tmogState == 2 then
			row.tmtIcon.tex:SetTexCoord(magic_3, magic_4, 0, 0.5)
		else
			row.tmtIcon.tex:SetTexCoord(magic_2, magic_3, 0, 0.5)
		end
		row.tmtIcon.tex:Show()
	else
		row.tmtIcon.tex:Hide()
	end
	print("tmogState", tmogState)
end



ADDON_TABLE.Frame = CreateFrame("Frame")
ADDON_TABLE.Frame:SetScript("OnEvent", ADDON_TABLE.OnEvent)
ADDON_TABLE.Frame:RegisterEvent("ADDON_LOADED")

ADDON_TABLE.OnLoad()

