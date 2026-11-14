local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local status = ReplicatedStorage:WaitForChild("SummonerState"):WaitForChild("Status")

local gui = Instance.new("ScreenGui")
gui.Name = "SummonerHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "Status"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 16)
label.Size = UDim2.new(0.9, 0, 0, 55)
label.BackgroundColor3 = Color3.fromRGB(24, 25, 35)
label.BackgroundTransparency = 0.15
label.TextColor3 = Color3.new(1, 1, 1)
label.TextScaled = true
label.TextWrapped = true
label.Font = Enum.Font.GothamBold
label.Parent = gui

local corner = Instance.new("UICorner")
corner.Parent = label

local function update()
	label.Text = status.Value
end

status.Changed:Connect(update)
update()
