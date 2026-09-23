local hitboxModule = {}
hitboxModule.__index = hitboxModule

-- [[ MADE BY SKYZ ]] [[ VERSION 1.0211 ]] --

-- Services
local runService = game:GetService("RunService")

-- Constructs a new hitbox
function hitboxModule.new(hitboxInfo)
	local self = setmetatable({},hitboxModule)

	self.owner = hitboxInfo.owner or hitboxInfo.lockAt or "undefined"
	self.hitSignal = Instance.new("BindableEvent")
	self.enabled = hitboxInfo.enabled
	self.whitelist = {self.owner}
	self.box = Instance.new("Part",hitboxInfo.lockAt) do
		self.box.Name = hitboxInfo.lockAt.Name.."_HITBOX"
		self.box.Transparency = hitboxInfo.visible and 0.5 or 1
		self.box.BrickColor = BrickColor[self.enabled and "Blue" or "Gray"]()
		self.box.Size = hitboxInfo.size
		self.box.CanCollide = false
		self.box.Massless = true

		local weld = Instance.new("Weld",self.box)
		weld.Part0 = self.box
		weld.Part1 = hitboxInfo.lockAt

		weld.C0 = CFrame.new(hitboxInfo.offset or Vector3.zero)
	end

	self.hitConnection = runService.Heartbeat:Connect(function()
		if not self.enabled then return end

		for i,v in pairs(workspace:GetPartsInPart(self.box)) do
			if not self.enabled then continue end
			self.hitSignal:Fire(v)
		end

	end)

	return self
end

function hitboxModule:UpdateWhitelist(object,value)
	if value and not table.find(self.whitelist,object) then
		table.insert(self.whitelist,object)
	elseif not value and table.find(self.whitelist,object) then
		table.remove(self.whitelist,table.find(self.whitelist,object))
	end
end

function hitboxModule:VerifyWhiteList(object)
	return table.find(self.whitelist,object)
end
function hitboxModule:Fire()
	self.hitSignal.Event:Wait()
end

function hitboxModule:Continue()
	self.enabled = true
	self.box.BrickColor = BrickColor.Blue()
end

function hitboxModule:Pause()
	self.enabled = false
	self.box.BrickColor = BrickColor.Gray()
end

function hitboxModule:Destroy()
	self.enabled = false
	self.hitConnection:Disconnect()
	self.hitSignal:Destroy()
	self.box:Destroy()
end

return hitboxModule
