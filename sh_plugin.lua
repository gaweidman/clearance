local PLUGIN = PLUGIN

PLUGIN.name = "Clearance"
PLUGIN.author = "QIncarnate"
PLUGIN.description = "An all-encompassing system for ID Cards and clearances for door opening."

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

        if (!IsValid(entity) or entity:GetClass() != "ix_reader") then
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

        -- Now that we know the entity is a door, we can set the creation ID variable.
        entCreationID = door:GetCreationID()
        
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

            if (door:GetNetVar("mode", MODE_UNDEFINED) == MODE_SWIPE_CARD) then
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
        elseif (mode == "OPEN") then
            entity:SetLockMode(MODE_OPEN)
        elseif (mode == "LOCKDOWN") then
            entity:SetLockMode(MODE_LOCKDOWN)
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

if (CLIENT) then
    hook.Add( "PreDrawHalos", "AddPropHalos", function()
        if (LocalPlayer():GetNetVar("selectedReaderID", nil) != nil) then
            for k, v in ipairs(ents.FindByClass("ix_reader")) do
                if (v:EntIndex() == LocalPlayer():GetNetVar("selectedReaderID", nil)) then
                    local entities = {v}
                    halo.Add( entities, Color(0, 255, 0), 5, 5, 2 )
                end
            end
        end
    end)
end

if (SERVER) then
    
    function PLUGIN:SaveReaders()
        local readers = {}

        for k, v in ipairs(ents.FindByClass("ix_reader")) do
            if (IsValid(v)) then
                readers[#readers + 1] = {
                    v:GetPos(),
                    v:GetAngles(),
                    v:GetNetVar("linkedDoors", {}),
                    v:GetNetVar("mode", MODE_UNDEFINED)
                }

                if (v:GetNetVar("mode", MODE_UNDEFINED) == MODE_ACCESS_DENIED or v:GetNetVar("mode", MODE_UNDEFINED) == MODE_ACCESS_GRANTED) then
                    v[4] = MODE_SWIPE_CARD
                end
            end
        end

        ix.data.Set("readers", readers)
    end

    function PLUGIN:LoadReaders()
        local readers = ix.data.Get("readers", {})

        for k, v in ipairs(readers) do
            local readerEnt = ents.Create("ix_reader")
            
            readerEnt:SetPos(v[1])
            readerEnt:SetAngles(v[2])
            readerEnt:SetNetVar("linkedDoors", v[3])
            readerEnt:SetNetVar("mode", v[4])

            if (v[4] == MODE_SWIPE_CARD) then
                for k, v in ipairs(ents.GetAll()) do
                    for k2, v2 in pairs(self:GetNetVar("linkedDoors")) do
                        if (v:MapCreationID() == v2) then
                            v:Fire("Lock")
                        end
                    end
                end
            end

            readerEnt:Spawn()
            readerEnt:GetPhysicsObject():EnableMotion(false) -- Doesn't do an IsValid check for simplicity reasons. If something is broken, add an IsValid check.
        end
    end

    function PLUGIN:SaveData()
        self:SaveReaders()
    end

    function PLUGIN:LoadData()
        self:LoadReaders()
    end

    netstream.Hook("PrintIDCard", function(client, data)
        local name = data[1]
        local org = data[2]
        local role = data[3]
        local printerID = data[4]

        local printer = nil
        
        for k, v in ipairs(ents.FindByClass("ix_idprinter")) do
            if (v:GetCreationID() == printerID and IsValid(v)) then
                printer = v
            end
        end
        

        local isbClearance = 0
        local techClearance = 0
        local controlClearance = 0

        if (org == "Imperial Security Bureau") then
            isbClearance = 1
        elseif (org == "Navy" and role == "Crewman") then
            controlClearance = 1
        elseif (org == "Navy" and role == "Technician") then
            techClearance = 1
        end

        if (role == "Stormtrooper") then
            role = "394th Stormtrooper Legion"
        elseif (role == "Shock Trooper") then
            role = "73rd Shock Trooper Batallion"
        elseif (role == "Shadow Trooper") then
            role = "26th Shadow Ops Battalion"
        elseif (role == "Scout Trooper") then
            role = "26th Scout Division"
        elseif (role == "Range Trooper") then
            role = "26th Range Trooper Battalion"
        end

        ix.item.Spawn("idcard", printer:GetPos() + Vector(0, 10, 0), function() end, Angle(0, 0, 0), {
            ["charName"] = name,
            ["org"] = org,
            ["role"] = role,
            ["rank"] = 1,
            ["clearance"] = {
                ["control"] = 0,
                ["systems"] = 0,
                ["isb"] = 0
            }
        })
    end)
    
end

if (CLIENT) then
    netstream.Hook("OpenIDCreate", function(data)
        vgui.Create("ixCreateID"):Populate(data)
    end)
end