AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

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

ISB_CLEARANCES = {
    [1] = 1,
    [2] = 2
}

function ENT:Initialize()
	self:SetModel("models/props_c17/door01_left.mdl") 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
	local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:Wake() end
    
    self:SetNetVar("statusWaitEnd", -1)
end

-- Called when the entity is spawned.
function ENT:SpawnFunction( ply, tr )
    if ( !tr.Hit ) then return end
    local ent = ents.Create("ix_reader")
    ent:SetPos( tr.HitPos + tr.HitNormal * 16 )
    ent:Spawn()
    ent:Activate()
    ent:SetUseType(SIMPLE_USE)

    ent:SetNetVar("mode", MODE_SWIPE_CARD)

    return ent
end

function ENT:OnRemove()
end

function ENT:Think()
    if (CurTime() >= self:GetNetVar("statusWaitEnd", -1) and self:GetNetVar("statusWaitEnd", -1) != -1 and self:GetLockMode() == MODE_ACCESS_GRANTED) then
        self:SetLockMode(MODE_SWIPE_CARD)
        for k, v in ipairs(ents.GetAll()) do
            for k2, v2 in pairs(self:GetNetVar("linkedDoors")) do
                if (v:MapCreationID() == v2) then
                    v:Fire("Lock")
                    self:SetNetVar("statusWaitEnd", -1)
                end
            end
        end
    elseif (CurTime() >= self:GetNetVar("statusWaitEnd", -1) and self:GetNetVar("statusWaitEnd", -1) != -1 and self:GetLockMode() == MODE_ACCESS_DENIED) then
        self:SetLockMode(MODE_SWIPE_CARD)
        self:SetNetVar("statusWaitEnd", -1)
    end
end

function ENT:Use()
    
end

function ENT:SetLockMode(mode)
    self:SetNetVar("mode", mode)
end

function ENT:GetLockMode()
    self:GetNetVar("mode", MODE_UNDEFINED)
end

function ENT:AccessGranted()
    self:SetLockMode(MODE_ACCESS_GRANTED)
    for k, v in ipairs(ents.GetAll()) do
        for k2, v2 in pairs(self:GetNetVar("linkedDoors")) do
            if (v:MapCreationID() == v2) then
                v:Fire("Unlock")
                self:SetNetVar("statusWaitEnd", CurTime() + ix.config.Get("Card Swipe Cooldown", 3))
            end
        end
    end
end

function ENT:AccessDenied()
    self:SetLockMode(MODE_ACCESS_DENIED)
    self:SetNetVar("statusWaitEnd", CurTime() + ix.config.Get("Card Swipe Cooldown", 3))
end