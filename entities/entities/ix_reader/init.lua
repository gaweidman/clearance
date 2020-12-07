AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWIPE_CARD = {
    ["enum"] = 1, 
    ["msg"] = "Swipe\nCard", 
    ["color"] = Color(255, 255, 255)
}

ACCESS_GRANTED = {
    ["enum"] = 2, 
    ["msg"] = "Access\nGranted", 
    ["color"] = Color(40, 255, 40)
}

ACCESS_DENIED = {
    ["enum"] = 3, 
    ["msg"] = "Access\nDenied", 
    ["color"] = Color(255, 40, 40)
}

OPEN = {
    ["enum"] = 4, 
    ["msg"] = "Open", 
    ["color"] = Color(40, 255, 40)
}

LOCKDOWN = {
    ["enum"] = 5, 
    ["msg"] = "Locked\nDown", 
    ["color"] = Color(255, 40, 40)
}

function ENT:Initialize()
	self:SetModel("models/props_c17/door01_left.mdl") 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then phys:Wake() end
end

-- Called when the entity is spawned.
function ENT:SpawnFunction( ply, tr )
    if ( !tr.Hit ) then return end
    local ent = ents.Create("ix_reader")
    ent:SetPos( tr.HitPos + tr.HitNormal * 16 )
    ent:Spawn()
    ent:Activate()
    ent:SetUseType(SIMPLE_USE)

    return ent
end
ents.Create("prop_physics")

function ENT:OnRemove()
end

function ENT:Think()
end

function ENT:Use()
    local mode = self:GetNetVar("mode", ACCESS_GRANTED)

    if (mode == SWIPE_CARD) then
        self:SetNetVar("mode", ACCESS_GRANTED)
    elseif (mode == ACCESS_GRANTED) then
        self:SetNetVar("mode", ACCESS_DENIED)
    elseif (mode == ACCESS_DENIED) then
        self:SetNetVar("mode", OPEN)
    elseif (mode == OPEN) then
        self:SetNetVar("mode", LOCKDOWN)
    elseif (mode == LOCKDOWN) then
        self:SetNetVar("mode", SWIPE_CARD)
    end
end