local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

Lighting.ClockTime = 0
Lighting.Brightness = 1.5
Lighting.Ambient = Color3.fromRGB(55, 44, 44)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 25)
Lighting.FogColor = Color3.fromRGB(40, 34, 39)
Lighting.FogStart = 25
Lighting.FogEnd = 125
local grading = Instance.new("ColorCorrectionEffect")
grading.Name = "SymmonnerColorGrade"
grading.Brightness = -0.02
grading.Contrast = 0.12
grading.Saturation = -0.2
grading.TintColor = Color3.fromRGB(255, 225, 200)
grading.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Name = "SymmonnerBloom"
bloom.Intensity = 0.2
bloom.Size = 24
bloom.Threshold = 1.4
bloom.Parent = Lighting
local room = Workspace:WaitForChild("GameRoom")
local board = room:WaitForChild("Board")
local light = Instance.new("PointLight")
light.Name = "BoardGlow"
light.Color = Color3.fromRGB(255, 169, 100)
light.Brightness = 2.4
light.Range = 32
light.Shadows = true
light.Parent = board
local function addLight(name, objectName, color, brightness, range)
	local object = room:WaitForChild(objectName)
	local lamp = Instance.new("PointLight")
	lamp.Name = name
	lamp.Color = color
	lamp.Brightness = brightness
	lamp.Range = range
	lamp.Shadows = true
	lamp.Parent = object
end
addLight("ChandelierGlow", "Chandelier", Color3.fromRGB(255, 192, 122), 3, 38)
addLight("CandleGlowLeft", "CandleLeft", Color3.fromRGB(255, 92, 32), 1.8, 14)
addLight("CandleGlowRight", "CandleRight", Color3.fromRGB(255, 92, 32), 1.8, 14)
local dust = Instance.new("ParticleEmitter")
dust.Name = "FloatingDust"
dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
dust.Color = ColorSequence.new(Color3.fromRGB(255, 216, 160))
dust.LightEmission = 0.25
dust.Rate = 12
dust.Lifetime = NumberRange.new(4, 8)
dust.Speed = NumberRange.new(0.1, 0.4)
dust.SpreadAngle = Vector2.new(180, 180)
dust.Size = NumberSequence.new(0.06)
dust.Parent = room:WaitForChild("Chandelier")
