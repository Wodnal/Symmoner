local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LOBBY_TIME = 15
local ROUND_TIME = 90
local RESULT_TIME = 8
local TARGET = 5

local state = Instance.new("Folder")
state.Name = "SummonerState"
state.Parent = ReplicatedStorage

local status = Instance.new("StringValue")
status.Name = "Status"
status.Value = "Подготовка..."
status.Parent = state

local world = Instance.new("Folder")
world.Name = "SummonerPrototype"
world.Parent = Workspace

local function part(name, size, position, color, parent)
	local object = Instance.new("Part")
	object.Name = name
	object.Anchored = true
	object.Size = size
	object.Position = position
	object.Color = color
	object.Material = Enum.Material.Slate
	object.TopSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local lobby = part("Lobby", Vector3.new(60, 2, 60), Vector3.new(0, 0, 0), Color3.fromRGB(65, 70, 85), world)
local arena = part("Arena", Vector3.new(100, 2, 100), Vector3.new(150, 0, 0), Color3.fromRGB(55, 74, 61), world)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = lobby.Position + Vector3.new(0, 2, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Parent = world

local function teleportPlayer(player, position)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(position + Vector3.new(math.random(-8, 8), 4, math.random(-8, 8))))
	end
end

local function teleportAll(position)
	for _, player in Players:GetPlayers() do
		teleportPlayer(player, position)
	end
end

local roundActive = false
local collected = 0
local items = Instance.new("Folder")
items.Name = "Items"
items.Parent = world

local positions = {
	Vector3.new(-35, 0, -30), Vector3.new(-15, 0, 25), Vector3.new(0, 0, 0),
	Vector3.new(25, 0, -20), Vector3.new(35, 0, 30), Vector3.new(-30, 0, 5),
	Vector3.new(10, 0, 35), Vector3.new(20, 0, 10),
}

local function createItems()
	items:ClearAllChildren()
	for index, offset in positions do
		local crystal = part("Crystal" .. index, Vector3.new(3, 4, 3), arena.Position + offset + Vector3.new(0, 3, 0), Color3.fromRGB(136, 88, 255), items)
		crystal.Material = Enum.Material.Neon
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Собрать"
		prompt.ObjectText = "Осколок"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.Parent = crystal
		local taken = false
		prompt.Triggered:Connect(function(player)
			if not roundActive or taken or not player.Character then
				return
			end
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - crystal.Position).Magnitude > 12 then
				return
			end
			taken = true
			collected += 1
			crystal:Destroy()
		end)
	end
end

while true do
	roundActive = false
	items:ClearAllChildren()
	teleportAll(lobby.Position)
	for remaining = LOBBY_TIME, 1, -1 do
		status.Value = "Лобби: раунд начнётся через " .. remaining .. " сек."
		task.wait(1)
	end

	if #Players:GetPlayers() > 0 then
		collected = 0
		createItems()
		roundActive = true
		teleportAll(arena.Position)
		for remaining = ROUND_TIME, 1, -1 do
			status.Value = "Соберите осколки: " .. collected .. "/" .. TARGET .. " | Осталось " .. remaining .. " сек."
			if collected >= TARGET or #Players:GetPlayers() == 0 then
				break
			end
			task.wait(1)
		end
		roundActive = false
		status.Value = if collected >= TARGET then "Победа! Команда собрала достаточно осколков." else "Раунд окончен. Попробуйте ещё раз!"
		task.wait(RESULT_TIME)
	else
		status.Value = "Ожидание игроков..."
		task.wait(2)
	end
end
