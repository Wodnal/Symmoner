local Lighting = game:GetService("Lighting")

Lighting.ClockTime = 0
Lighting.Brightness = 1.2
Lighting.Ambient = Color3.fromRGB(32, 35, 52)
Lighting.OutdoorAmbient = Color3.fromRGB(12, 14, 22)
Lighting.FogColor = Color3.fromRGB(18, 20, 32)
Lighting.FogStart = 35
Lighting.FogEnd = 180

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.38
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(105, 112, 150)
atmosphere.Decay = Color3.fromRGB(25, 28, 48)
atmosphere.Glare = 0.08
atmosphere.Haze = 1.4
atmosphere.Parent = Lighting

local function lamp(name, color)
	local object = workspace:WaitForChild("LobbyHub"):WaitForChild(name)
	local light = Instance.new("PointLight")
	light.Name = "AmbientLamp"
	light.Color = color
	light.Brightness = 2.5
	light.Range = 28
	light.Shadows = true
	light.Parent = object
end

lamp("LeftLamp", Color3.fromRGB(112, 75, 255))
lamp("RightLamp", Color3.fromRGB(255, 86, 156))
