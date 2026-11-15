local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("SymmonnerMatch")
local inventory = player:WaitForChild("DiceInventory")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local gui = Instance.new("ScreenGui")
gui.Name = "SymmonnerHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function rounded(parent, color, transparency, radius)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = frame
	return frame
end

local function text(parent, value, size, color, font)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextSize = size or 16
	label.Font = font or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local objective = rounded(gui, Color3.fromRGB(17, 13, 12), 0.2, 8)
objective.AnchorPoint = Vector2.new(0.5, 0)
objective.Position = UDim2.new(0.5, 0, 0, 18)
objective.Size = UDim2.new(0.58, 0, 0, 48)
local objectiveText = text(objective, "", 20, Color3.fromRGB(255, 237, 195), Enum.Font.GothamBold)
objectiveText.TextXAlignment = Enum.TextXAlignment.Center
objectiveText.Size = UDim2.fromScale(1, 1)
local objectiveStroke = Instance.new("UIStroke")
objectiveStroke.Color = Color3.fromRGB(126, 85, 44)
objectiveStroke.Transparency = 0.35
objectiveStroke.Parent = objective

local vitals = rounded(gui, Color3.fromRGB(12, 11, 14), 0.12, 8)
vitals.Position = UDim2.fromOffset(22, 22)
vitals.Size = UDim2.fromOffset(250, 82)
local hpText = text(vitals, "♥  100 / 100", 18, Color3.fromRGB(255, 210, 180), Enum.Font.GothamBold)
hpText.Position = UDim2.fromOffset(12, 6)
hpText.Size = UDim2.new(1, -24, 0, 24)
local hpBack = rounded(vitals, Color3.fromRGB(67, 26, 27), 0, 3)
hpBack.Position = UDim2.fromOffset(12, 36)
hpBack.Size = UDim2.new(1, -24, 0, 9)
local hpFill = rounded(hpBack, Color3.fromRGB(190, 57, 51), 0, 3)
hpFill.Size = UDim2.fromScale(1, 1)
local staminaText = text(vitals, "STAMINA", 10, Color3.fromRGB(190, 190, 202), Enum.Font.GothamBold)
staminaText.Position = UDim2.fromOffset(12, 51)
staminaText.Size = UDim2.fromOffset(58, 20)
local staminaBack = rounded(vitals, Color3.fromRGB(35, 38, 55), 0, 3)
staminaBack.Position = UDim2.fromOffset(75, 57)
staminaBack.Size = UDim2.new(1, -87, 0, 7)
local staminaFill = rounded(staminaBack, Color3.fromRGB(92, 139, 215), 0, 3)
staminaFill.Size = UDim2.fromScale(1, 1)

local score = rounded(gui, Color3.fromRGB(15, 13, 12), 0.12, 8)
score.AnchorPoint = Vector2.new(1, 0)
score.Position = UDim2.new(1, -22, 0, 22)
score.Size = UDim2.fromOffset(130, 44)
local scoreText = text(score, "◉  0", 21, Color3.fromRGB(255, 218, 125), Enum.Font.GothamBold)
scoreText.TextXAlignment = Enum.TextXAlignment.Center
scoreText.Size = UDim2.fromScale(1, 1)

local carried = rounded(gui, Color3.fromRGB(35, 24, 15), 0.08, 6)
carried.AnchorPoint = Vector2.new(1, 0)
carried.Position = UDim2.new(1, -22, 0, 74)
carried.Size = UDim2.fromOffset(180, 30)
local carriedText = text(carried, "ИДОЛ: НЕТ", 13, Color3.fromRGB(255, 220, 145), Enum.Font.GothamBold)
carriedText.TextXAlignment = Enum.TextXAlignment.Center
carriedText.Size = UDim2.fromScale(1, 1)

local slots = rounded(gui, Color3.fromRGB(10, 9, 12), 0.3, 10)
slots.AnchorPoint = Vector2.new(0.5, 1)
slots.Position = UDim2.new(0.5, 0, 1, -24)
slots.Size = UDim2.fromOffset(330, 76)
local slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection = Enum.FillDirection.Horizontal
slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
slotLayout.Padding = UDim.new(0, 8)
slotLayout.Parent = slots

local diceNames = {"Heal", "Teleport", "AntiGravity", "Hazard"}
local diceLabels = {Heal = "HEAL", Teleport = "TELEPORT", AntiGravity = "FLOAT", Hazard = "HAZARD"}
local diceColors = {Heal = Color3.fromRGB(50, 158, 91), Teleport = Color3.fromRGB(102, 67, 185), AntiGravity = Color3.fromRGB(61, 132, 183), Hazard = Color3.fromRGB(177, 72, 44)}
local slotButtons = {}
for slotNumber = 1, 3 do
	local slot = Instance.new("TextButton")
	slot.Text = ""
	slot.AutoButtonColor = true
	slot.BackgroundColor3 = Color3.fromRGB(35, 32, 37)
	slot.BorderSizePixel = 0
	slot.Parent = slots
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot
	slot.Size = UDim2.fromOffset(96, 62)
	local key = text(slot, "[" .. slotNumber .. "]", 11, Color3.fromRGB(190, 184, 176), Enum.Font.GothamBold)
	key.Position = UDim2.fromOffset(7, 4)
	key.Size = UDim2.fromOffset(28, 16)
	local name = text(slot, "EMPTY", 12, Color3.fromRGB(235, 230, 220), Enum.Font.GothamBold)
	name.Position = UDim2.fromOffset(4, 25)
	name.Size = UDim2.new(1, -8, 0, 18)
	name.TextXAlignment = Enum.TextXAlignment.Center
	local count = text(slot, "×0", 11, Color3.fromRGB(210, 200, 180), Enum.Font.GothamMedium)
	count.Position = UDim2.fromOffset(4, 43)
	count.Size = UDim2.new(1, -8, 0, 16)
	count.TextXAlignment = Enum.TextXAlignment.Center
	local slotData = {frame = slot, name = name, count = count, action = nil}
	slot.Activated:Connect(function()
		if slotData.action then state.UseDice:FireServer(slotData.action) end
	end)
	slotButtons[slotNumber] = slotData
end

local function updateVitals()
	local health = humanoid.Health
	local maxHealth = math.max(1, humanoid.MaxHealth)
	hpText.Text = string.format("♥  %d / %d", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
	hpFill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
	local color = health <= maxHealth * 0.25 and Color3.fromRGB(244, 60, 47) or Color3.fromRGB(190, 57, 51)
	hpFill.BackgroundColor3 = color
end
humanoid.HealthChanged:Connect(updateVitals)
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(updateVitals)
	updateVitals()
end)

local function updateMessage()
	objectiveText.Text = state.Message.Value
end
state.Message.Changed:Connect(updateMessage)
updateMessage()

local function updateIdol()
	local amount = player:GetAttribute("CarriedIdol") or 0
	carriedText.Text = if amount > 0 then "ИДОЛ: " .. amount .. " PTS" else "ИДОЛ: НЕТ"
end
player:GetAttributeChangedSignal("CarriedIdol"):Connect(updateIdol)
updateIdol()

local function refreshSlots()
	local index = 1
	for _, name in diceNames do
		local amount = inventory:FindFirstChild(name)
		if amount and amount.Value > 0 and index <= 3 then
			local slot = slotButtons[index]
			slot.name.Text = diceLabels[name]
			slot.count.Text = "×" .. amount.Value
			slot.frame.BackgroundColor3 = diceColors[name]
			slot.action = name
			index += 1
		end
	end
	while index <= 3 do
		local slot = slotButtons[index]
		slot.name.Text = "EMPTY"
		slot.count.Text = "×0"
		slot.frame.BackgroundColor3 = Color3.fromRGB(35, 32, 37)
		slot.action = nil
		index += 1
	end
end
for _, value in inventory:GetChildren() do value.Changed:Connect(refreshSlots) end
inventory.ChildAdded:Connect(function(value) value.Changed:Connect(refreshSlots); refreshSlots() end)
refreshSlots()
updateVitals()
