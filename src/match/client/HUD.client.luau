local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("SymmonnerMatch")
local inventory = player:WaitForChild("DiceInventory")
local gui = Instance.new("ScreenGui")
gui.Name = "SymmonnerHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.9, 0, 0, 50)
label.Position = UDim2.new(0.05, 0, 0, 10)
label.BackgroundColor3 = Color3.fromRGB(28, 23, 30)
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.TextWrapped = true
label.Parent = gui
local function updateMessage() label.Text = state.Message.Value end
state.Message.Changed:Connect(updateMessage)
updateMessage()
local idol = Instance.new("TextLabel")
idol.Size = UDim2.fromOffset(240, 32)
idol.Position = UDim2.new(1, -250, 0, 70)
idol.BackgroundColor3 = Color3.fromRGB(45, 35, 22)
idol.TextColor3 = Color3.fromRGB(255, 220, 130)
idol.TextScaled = true
idol.Parent = gui
local function updateIdol()
	local amount = player:GetAttribute("CarriedIdol") or 0
	idol.Text = if amount > 0 then "Идол: " .. amount .. " — к доске" else "Идол: нет"
end
player:GetAttributeChangedSignal("CarriedIdol"):Connect(updateIdol)
updateIdol()
local list = Instance.new("Frame")
list.Size = UDim2.new(0, 160, 0, 180)
list.Position = UDim2.new(0, 10, 0.5, -90)
list.BackgroundTransparency = 1
list.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = list
for _, name in {"Heal", "Teleport", "AntiGravity", "Hazard"} do
	local count = inventory:WaitForChild(name)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(55, 45, 60)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Parent = list
	local function update() button.Text = name .. " (" .. count.Value .. ")" end
	count.Changed:Connect(update)
	button.Activated:Connect(function() state.UseDice:FireServer(name) end)
	update()
end
