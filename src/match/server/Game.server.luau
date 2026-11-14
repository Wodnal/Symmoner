local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local state = Instance.new("Folder")
state.Name = "SymmonnerMatch"
state.Parent = ReplicatedStorage
local message = Instance.new("StringValue")
message.Name = "Message"
message.Value = "Исследуйте комнату и бросайте кубик на доске."
message.Parent = state
local useDice = Instance.new("RemoteEvent")
useDice.Name = "UseDice"
useDice.Parent = state

local world = Instance.new("Folder")
world.Name = "SymmonnerPrototype"
world.Parent = Workspace
local function makePart(name, size, position, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Parent = world
	return p
end
makePart("Floor", Vector3.new(90, 2, 90), Vector3.new(0, 0, 0), Color3.fromRGB(55, 45, 40))
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Position = Vector3.new(0, 2, 15)
spawn.Parent = world
local board = makePart("Board", Vector3.new(10, 1, 10), Vector3.new(0, 4, 0), Color3.fromRGB(105, 65, 40))
makePart("Table", Vector3.new(12, 3, 12), Vector3.new(0, 2, 0), Color3.fromRGB(68, 43, 30))
local function promptOn(part, action, object)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = part
	return prompt
end
local inventories = {}
local cooldowns = {}
local progress = 0
local random = Random.new()
local names = {"Heal", "Teleport", "AntiGravity", "Hazard"}
local function near(player, object)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root and humanoid and humanoid.Health > 0 and (root.Position - object.Position).Magnitude <= 12
end
local function setupPlayer(player)
	local folder = Instance.new("Folder")
	folder.Name = "DiceInventory"
	folder.Parent = player
	inventories[player] = folder
	for _, name in names do
		local count = Instance.new("IntValue")
		count.Name = name
		count.Parent = folder
	end
end
Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	inventories[player] = nil
	cooldowns[player] = nil
end)

local boardPrompt = promptOn(board, "Бросить", "Проклятая доска")
local boardReady = true
boardPrompt.Triggered:Connect(function(player)
	if not boardReady or not near(player, board) then return end
	boardReady = false
	local roll = random:NextInteger(1, 6)
	progress += roll
	message.Value = player.DisplayName .. " бросает " .. roll .. ". Путь: " .. progress .. "."
	task.delay(3, function() boardReady = true end)
end)

for index, position in {Vector3.new(-25, 2, -25), Vector3.new(25, 2, -25), Vector3.new(-25, 2, 25), Vector3.new(25, 2, 25)} do
	local container = makePart("Search" .. index, Vector3.new(4, 3, 4), position, Color3.fromRGB(90, 80, 55))
	local prompt = promptOn(container, "Обыскать", "Старый ящик")
	local available = true
	prompt.Triggered:Connect(function(player)
		local inventory = inventories[player]
		if not available or not inventory or not near(player, container) then return end
		local total = 0
		for _, value in inventory:GetChildren() do total += value.Value end
		if total >= 5 then return end
		available = false
		prompt.Enabled = false
		local die = inventory:FindFirstChild(names[random:NextInteger(1, #names)])
		die.Value += 1
		message.Value = player.DisplayName .. " находит кубик: " .. die.Name
		task.delay(30, function() available = true; prompt.Enabled = true end)
	end)
end

useDice.OnServerEvent:Connect(function(player, name)
	if typeof(name) ~= "string" or not table.find(names, name) then return end
	local now = os.clock()
	if cooldowns[player] and now - cooldowns[player] < 1 then return end
	cooldowns[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local inventory = inventories[player]
	local die = inventory and inventory:FindFirstChild(name)
	if not root or not humanoid or humanoid.Health <= 0 or not die or die.Value < 1 then return end
	die.Value -= 1
	local roll = random:NextInteger(1, 6)
	if name == "Heal" then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + roll * 5)
	elseif name == "Teleport" then
		character:PivotTo(CFrame.new(0, 5, 15))
	elseif name == "AntiGravity" then
		local attachment = Instance.new("Attachment")
		attachment.Parent = root
		local force = Instance.new("VectorForce")
		force.Attachment0 = attachment
		force.Force = Vector3.new(0, root.AssemblyMass * Workspace.Gravity * 0.65, 0)
		force.Parent = root
		task.delay(5, function() force:Destroy(); attachment:Destroy() end)
	elseif name == "Hazard" then
		humanoid:TakeDamage(roll * 3)
	end
	message.Value = player.DisplayName .. " использует " .. name .. ": " .. roll
end)
