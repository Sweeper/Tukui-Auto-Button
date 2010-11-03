local Items = {
	39213, -- Massive Seaforium Charge (Strand of the Ancients)
	47030, -- Huge Seaforium Bombs (Isle of Conquest)
	42986, -- The RP-GG (Wintergrasp)
	37860, -- Ruby Drake (Occulus)
	37815, -- Emerald Drake (Occulus)
	37859, -- Amber Essence (Occulus)
	46029, -- Mimiron's Core (Ulduar)
	50851, -- Pulsing Life Crystal (ICC weekly raid quest)
--[[
	34722, -- Frostweave Bandage (Test)
	46376, -- Flask of the Frost Wyrm
	46379, -- Flask of Stoneblood
	46377, -- Flask of Endless Rage
	47499, -- Flask of the North
	40211, -- Potion of Speed
	40093, -- Indestructible Potion
]]	
}
 
local EquipedItems = {
	49278, -- Goblin Rocket Pack (ICC)
--	50356, -- Corroded Skeleton Key (Test)
}

local icon_size = ((TukuiMinimap:GetWidth() + 4) / 2) -- same size as datatext panel below minimap
--local icon_size = 29 -- size if used as an shapeshift extension
local anchor = "MINIMAP" -- "MINIMAP" | "SHAPESHIFT" | "FREE"
local direction = "DOWN" -- "RIGHT" | "LEFT" | "UP" | "DOWN"

local minimap_gap = 24

local free_anchor = UIParent
local free_anchor_position = "CENTER"
local free_offset_x = 100
local free_offset_y = 100

local function createButton(id)
	--Create our Button
	local AutoButton = CreateFrame("Button", "TukzAutoButton"..id, UIParent, "SecureActionButtonTemplate")
	AutoButton:SetWidth(TukuiDB.Scale(icon_size))
	AutoButton:SetHeight(TukuiDB.Scale(icon_size))
	TukuiDB.SetTemplate(AutoButton)
	TukuiDB.StyleButton(AutoButton, false)
	AutoButton:SetAttribute("type", "item")
	AutoButton:SetAlpha(0)
	AutoButton:EnableMouse(false)
	 
	--Texture for our button
	AutoButton.t = AutoButton:CreateTexture(nil,"OVERLAY",nil)
	AutoButton.t:SetPoint("TOPLEFT", AutoButton, "TOPLEFT", TukuiDB.Scale(2), TukuiDB.Scale(-2))
	AutoButton.t:SetPoint("BOTTOMRIGHT", AutoButton, "BOTTOMRIGHT", TukuiDB.Scale(-2), TukuiDB.Scale(2))
	AutoButton.t:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	 
	--Count text for our button
	AutoButton.c = AutoButton:CreateFontString(nil,"OVERLAY",f)
	AutoButton.c:SetFont(TukuiCF.media.font,12,"OUTLINE")
	AutoButton.c:SetTextColor(0.8, 0.8, 0.8, 1)
	AutoButton.c:SetPoint("BOTTOMRIGHT", TukuiDB.Scale(-2), TukuiDB.Scale(2))
	AutoButton.c:SetJustifyH("CENTER")	
	 
	--Cooldown
	AutoButton.Cooldown = CreateFrame("Cooldown",nil,AutoButton)
	AutoButton.Cooldown:SetPoint("TOPLEFT", AutoButton, "TOPLEFT", TukuiDB.Scale(2), TukuiDB.Scale(-2))
	AutoButton.Cooldown:SetPoint("BOTTOMRIGHT", AutoButton, "BOTTOMRIGHT", TukuiDB.Scale(-2), TukuiDB.Scale(2))	
	
	AutoButton.visible = true
	
	return AutoButton
end

local buttons = { }	

local function OnEvent()
	for i, b in pairs(buttons) do
		b.visible = false
		b:SetAlpha(0)
		if not InCombatLockdown() then
			b:EnableMouse(false)
		end
	end

	--Scan inventory for Equipment matches
	for w = 1, 19 do
		for e, EquipedItem in pairs(EquipedItems) do
			if GetInventoryItemID("player", w) == EquipedItem then
				local button = buttons[EquipedItem]
				if not button then
					if not InCombatLockdown() then
						local itemName = GetItemInfo(EquipedItem)
						local itemIcon = GetInventoryItemTexture("player", w)				
						
						button = createButton(EquipedItem)
						
						--Set our texture to the item found in bags
						button.t:SetTexture(itemIcon)
						button.c:SetText("")				

						--Make button use the set item when clicked
						button:SetAttribute("item", itemName)

						button:SetScript("OnUpdate", function(self, elapsed)
							local cd_start, cd_finish, cd_enable = GetInventoryItemCooldown("player",w)
							CooldownFrame_SetTimer(button.Cooldown, cd_start, cd_finish, cd_enable)
						end)
						
						buttons[EquipedItem] = button
					end 
				end 
				
				if button then
					button.visible = true
					button:SetAlpha(1)
					if not InCombatLockdown() then
						button:EnableMouse(true)
					end
				end 
			end
		end
	end	

	--Scan bags for Item matchs
	for b = 0, NUM_BAG_SLOTS do
		for s = 1, GetContainerNumSlots(b) do
			local itemID = GetContainerItemID(b, s)
			itemID = tonumber(itemID)
			for i, Item in pairs(Items) do
				local button = buttons[Item]
				if not button then
					if not InCombatLockdown() then
						if itemID == Item then
							button = createButton(Item)

							--Set our texture to the item found in bags
							local itemIcon = GetItemIcon(Item)
							button.t:SetTexture(itemIcon)
		 
							--Make button use the set item when clicked
							local itemName, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(Item)
							button:SetAttribute("item", itemName)
		 
							button:SetScript("OnUpdate", function(self, elapsed)
								local cd_start, cd_finish, cd_enable = GetContainerItemCooldown(b, s)
								CooldownFrame_SetTimer(button.Cooldown, cd_start, cd_finish, cd_enable)
							end)
							
							buttons[Item] = button
						end
					end 
				end 
				
				if button then
					local count = GetItemCount(Item)
					--Get the count if there is one
					if count and count ~= 1 then
						button.c:SetText(count)
					else
						button.c:SetText("")
					end
					
					if count > 0 then
						button.visible = true
						button:SetAlpha(1)
						if not InCombatLockdown() then
							button:EnableMouse(true)
						end
					end
				end
			end
		end
	end 

	if not InCombatLockdown() then
		local prev = nil
		-- Display the buttons
		for i, b in pairs(buttons) do
			b:ClearAllPoints()
			if not prev and b.visible then			
				if anchor == "MINIMAP" then
					b:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", TukuiDB.Scale(-2), TukuiDB.Scale(-(2+minimap_gap)))
				elseif anchor == "SHAPESHIFT" then
					for j = 1, NUM_SHAPESHIFT_SLOTS do
						if _G["ShapeshiftButton"..j]:IsVisible() then
							b:SetPoint("BOTTOMLEFT", _G["ShapeshiftButton"..j], "BOTTOMRIGHT", TukuiDB.Scale(4), 0)
						end 
					end				
					
					if b:GetNumPoints() == 0 then
						b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", TukuiDB.Scale(2), TukuiDB.Scale(-2))
					end 
				else
					b:SetPoint("TOPLEFT", free_anchor, free_anchor_position, TukuiDB.Scale(free_offset_x), TukuiDB.Scale(free_offset_y))
				end 
			elseif b.visible then
				if direction == "LEFT" then
					b:SetPoint("BOTTOMRIGHT", prev, "BOTTOMLEFT", TukuiDB.Scale(-4), 0)
				elseif direction == "DOWN" then
					b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, TukuiDB.Scale(-4))
				elseif direction == "UP" then
					b:SetPoint("BOTTOMLEFT", prev, "TOPLEFT", 0, TukuiDB.Scale(4))
				else
					b:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", TukuiDB.Scale(4), 0)
				end
			end
			
			if b.visible then
				prev = b
			end
		end
	end 
end

local Scanner = CreateFrame("Frame")
Scanner:RegisterEvent("BAG_UPDATE")
Scanner:RegisterEvent("UNIT_INVENTORY_CHANGED")
Scanner:RegisterEvent("PLAYER_REGEN_ENABLED")
Scanner:SetScript("OnEvent", OnEvent)