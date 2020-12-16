MODE_SWIPE_CARD = {
    ["enum"] = 1, 
    ["msg"] = "Swipe\nCard", 
    ["color"] = Color(255, 255, 255)
}

MODE_ACCESS_GRANTED = {
    ["enum"] = 2, 
    ["msg"] = "Access\nGranted", 
    ["color"] = Color(40, 255, 40)
}

MODE_ACCESS_DENIED = {
    ["enum"] = 3, 
    ["msg"] = "Access\nDenied", 
    ["color"] = Color(255, 40, 40)
}

MODE_OPEN = {
    ["enum"] = 4, 
    ["msg"] = "Open", 
    ["color"] = Color(40, 255, 40)
}

MODE_LOCKDOWN = {
    ["enum"] = 5, 
    ["msg"] = "Locked\nDown", 
    ["color"] = Color(255, 40, 40)
}

MODE_UNDEFINED = {
    ["enum"] = 6, 
    ["msg"] = "UNDEFINED", 
    ["color"] = Color(255, 40, 255)
}

do
	local COMMAND = {}

    function COMMAND:OnRun(client, message)
        local entity = client:GetEyeTrace().Entity

        if (!IsValid(entity) or !entity:IsReader()) then
            client:SetNetVar("selectedReaderID", nil)
            return "That is not a valid entity!"
        else
            client:SetNetVar("selectedReaderID", entity:EntIndex())
            return "Reader selected."
        end

	end

	ix.command.Add("SelectReader", COMMAND)
end

do
	local COMMAND = {}

    function COMMAND:OnRun(client, message)
        local door = client:GetEyeTrace().Entity -- The entity the player is looking at, suppose to be a door.

        local entCreationID -- The creation ID of the door. 
        -- We can't set this on initialization because if the entity in question isn't a door, it could possibly not have a creation ID.

        local scannerID = client:GetNetVar("selectedReaderID", nil) -- The ID of the reader the player selected, they have selected one. 
        -- If they haven't selected a reader, the value is nil.

        -- Makes sure the entity in question is in fact both valid and a door.
        if (!IsValid(door) or !door:IsDoor()) then
            client:SetNetVar("selectedReaderID", nil)
            return "That is not a valid entity!"
        end

        -- Now that we know the entity is a door, we can set the map creation ID variable.
        entCreationID = door:MapCreationID()
        
        -- Checks if the player has selected a reader.
        -- If they haven't, reset the player's reader and tell them they haven't selected one.
        if (client:GetNetVar("selectedReaderID", nil) == nil) then
            client:SetNetVar("selectedReaderID", nil)
            return "You haven't selected a reader!"
        else -- Runs if the player HAS selected a reader.

            local readerEnt
            for k, v in pairs(ents.FindByClass("ix_reader")) do -- Gets the entity of the reader with the ID the player has selected.
                if (v:EntIndex() == scannerID) then
                    readerEnt = v
                end
            end

            -- Gets the linked doors of the reader, adds the new door, and resubmits
            local linkedDoors = readerEnt:GetNetVar("linkedDoors", {})  
            linkedDoors[#linkedDoors + 1] = entCreationID
            readerEnt:SetNetVar("linkedDoors", linkedDoors)

            client:SetNetVar("selectedReaderID", nil)

            if (readerEnt:GetNetVar("mode", MODE_UNDEFINED).enum == MODE_SWIPE_CARD.enum) then
                door:Fire("Lock")
            end

            return "Door linked."

        end

	end

	ix.command.Add("LinkDoor", COMMAND)
end

do
    local COMMAND = {}

    COMMAND.arguments = ix.type.text

    function COMMAND:OnRun(client, mode)
        local entity = client:GetEyeTrace().Entity

        if (!IsValid(entity) or entity:GetClass() != "ix_reader") then
            client:SetNetVar("selectedReaderID", nil)
            return "That is not a valid entity!"
        end

        mode = string.upper(mode)

        if (mode == "RESTRICTED") then
            entity:SetLockMode(MODE_SWIPE_CARD)
            for k, v in pairs(readerEnt:GetNetVar("linkedDoors", {})) do
                for k2, v2 in ipairs(ents.GetAll()) do
                    if (v2:MapCreationID() == v) then
                        v2:Fire("Lock")
                    end
                end
            end
        elseif (mode == "OPEN") then

            entity:SetLockMode(MODE_OPEN)
            for k, v in pairs(readerEnt:GetNetVar("linkedDoors", {})) do
                for k2, v2 in ipairs(ents.GetAll()) do
                    if (v2:MapCreationID() == v) then
                        v2:Fire("Unlock")
                    end
                end
            end

        elseif (mode == "LOCKDOWN") then

            entity:SetLockMode(MODE_LOCKDOWN)
            for k, v in pairs(readerEnt:GetNetVar("linkedDoors", {})) do
                for k2, v2 in ipairs(ents.GetAll()) do
                    if (v2:MapCreationID() == v) then
                        v2:Fire("Lock")
                    end
                end
            end

        else
            return "Invalid reader mode!"
        end

	end

	ix.command.Add("SetReaderMode", COMMAND) -- TODO: Add rank and clearance checking.
end

do
    local COMMAND = {}

    COMMAND.arguments = ix.type.text

    function COMMAND:OnRun(client, mode)
        local entity = client:GetEyeTrace().Entity
        entity:Fire("Lock")
	end

	ix.command.Add("LockDoor", COMMAND) -- TODO: Add rank and clearance checking.
end

do
    local COMMAND = {}

    COMMAND.arguments = ix.type.text

    function COMMAND:OnRun(client, mode)
        local entity = client:GetEyeTrace().Entity
        entity:Fire("Unlock")
	end

    ix.command.Add("UnlockDoor", COMMAND) -- TODO: Add rank and clearance checking.
end

do
    local COMMAND = {}

    COMMAND.arguments = {
        ix.type.string,
        ix.type.number
    }

    function COMMAND:OnRun(client, clrType, level)
        local entity = client:GetEyeTrace().Entity
        clrType = string.lower(clrType)

        if (!IsValid(entity) or !entity:IsReader()) then
            return "That is not a valid entity!"
        elseif (clrType != "control" and clrType != "systems" and clrType != "isb") then
            return "That is not a valid clearance type!"
        else
            entity:SetNetVar("reqClr", {
                ["type"] = clrType,
                ["level"] = level
                
            })
            clrType = clrType:gsub("^%l", string.upper)
            if (clrType == "Isb") then clrType = "ISB" end
            return "Required clearance set to "..clrType.." "..level.."."
        end
	end

    ix.command.Add("SetClearance", COMMAND) -- TODO: Add rank and clearance checking.
end

do
    local COMMAND = {}

    function COMMAND:OnRun(client)
        for k, v in ipairs(ents.FindByClass("ix_reader")) do
            v:Remove()
        end
	end

    ix.command.Add("RemoveReaders", COMMAND) -- TODO: Add rank and clearance checking.
end

do
    local COMMAND = {}

    function COMMAND:OnRun(client)
        local entity = client:GetEyeTrace().Entity

        if (!IsValid(entity)) then
            return "That is not a valid entity!"
        else
            client:ChatPrint(entity:MapCreationID())
        end
	end

    ix.command.Add("GetCreationID", COMMAND) -- TODO: Add rank and clearance checking.
end