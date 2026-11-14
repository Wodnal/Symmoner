local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LobbyQueue")
local request = remotes:WaitForChild("Request")
local update = remotes:WaitForChild("Update")

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyQueueUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(360, 420)
panel.Position = UDim2.new(0, 12, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
panel.Parent = gui

local function label(text, position, size, parent)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 1
	item.TextColor3 = Color3.new(1, 1, 1)
	item.Font = Enum.Font.Gotham
	item.TextSize = 14
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Position = position
	item.Size = size
	item.Text = text
	item.Parent = parent
	return item
end

local function button(text, position, size, parent, callback)
	local item = Instance.new("TextButton")
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = Color3.fromRGB(70, 75, 120)
	item.TextColor3 = Color3.new(1, 1, 1)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 14
	item.Text = text
	item.Parent = parent
	item.Activated:Connect(callback)
	return item
end

label("LOBBY QUEUE", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 28), panel)
local message = label("Create or join a room.", UDim2.fromOffset(12, 38), UDim2.new(1, -24, 0, 36), panel)
button("Create", UDim2.fromOffset(12, 80), UDim2.fromOffset(100, 32), panel, function() request:FireServer("create") end)
button("Leave", UDim2.fromOffset(122, 80), UDim2.fromOffset(100, 32), panel, function() request:FireServer("leave") end)
button("Start", UDim2.fromOffset(232, 80), UDim2.fromOffset(100, 32), panel, function() request:FireServer("start") end)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 122)
list.Size = UDim2.new(1, -24, 1, -134)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = list

update.OnClientEvent:Connect(function(kind, data)
	if kind == "notice" then
		message.Text = data
	elseif kind == "state" then
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		for _, room in ipairs(data) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 100)
			row.BackgroundColor3 = Color3.fromRGB(43, 46, 63)
			row.Parent = list
			local status = room.status == "countdown" and ("Starting in " .. tostring(room.remaining)) or room.status
			label("#" .. room.id .. "  Host: " .. room.host .. "  " .. room.count .. "/" .. room.capacity .. "  " .. status,
				UDim2.fromOffset(6, 3), UDim2.new(1, -12, 0, 24), row)
			label(table.concat(room.members, ", "), UDim2.fromOffset(6, 27), UDim2.new(1, -90, 0, 68), row)
			button("Join", UDim2.new(1, -76, 0, 45), UDim2.fromOffset(70, 32), row, function()
				request:FireServer("join", room.id)
			end)
		end
	end
end)
request:FireServer("sync")
