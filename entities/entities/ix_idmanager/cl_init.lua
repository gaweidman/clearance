-- Called when the entity initializes.
function ENT:Initialize()
end

-- Called when the entity should draw.
function ENT:Draw()
	self.Entity:DrawModel()

	cam.Start3D2D(self:GetPos() + Vector(-25, 0, 10), self:GetAngles() + Angle(90, 0, 0), 0.1)
		surface.SetDrawColor(Color(255, 255, 255))
		surface.DrawRect(0, 0, 400, 400)
	cam.End3D2D()
end
