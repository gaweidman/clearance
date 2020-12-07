local PLUGIN = PLUGIN

PLUGIN.name = "Clearance"
PLUGIN.author = "QIncarnate"
PLUGIN.description = "An all-encompassing system for ID Cards and clearances for door opening."

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
            return "Door linked."

        end

	end

	ix.command.Add("LinkDoor", COMMAND)
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
                    v:GetNetVar("linkedDoors", {})
                }   
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
            readerEnt:Spawn()
        end
    end

    function PLUGIN:SaveData()
        self:SaveReaders()
    end

    function PLUGIN:LoadData()
        self:LoadReaders()
    end
    
end