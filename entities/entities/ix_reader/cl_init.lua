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


-- Called when the entity initializes.
function ENT:Initialize()
end

-- Called when the entity should draw.
function ENT:Draw()
	self.Entity:DrawModel()
	local mode = self:GetNetVar("mode", SWIPE_CARD)

	cam.Start3D2D(self:GetPos() + Vector(-10, 0, 0), self:GetAngles() + Angle(0, 90, 90), 0.1)
		draw.DrawText(mode.msg, "ScoreboardDefaultTitle", 200, 0, mode.color, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end