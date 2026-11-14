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

local world = Workspace:WaitForChild("GameRoom")
local board = world:WaitForChild("Board")
local spawn = world:WaitForChild("MatchSpawn")
for _, object in Workspace:GetDescendants() do
	if object:IsA("SpawnLocation") and object ~= spawn then
		object.Enabled = false
	end
end
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

local BOARD_END = 30
local boardPrompt = promptOn(board, "Бросить", "Проклятая доска")
local boardReady = true
local finished = false
boardPrompt.Triggered:Connect(function(player)
	if finished or not boardReady or not near(player, board) then return end
	boardReady = false
	boardPrompt.Enabled = false
	local roll = random:NextInteger(1, 6)
	progress = math.min(BOARD_END, progress + roll)
	if progress >= BOARD_END then
		finished = true
		message.Value = "Победа! Команда достигла конца доски: " .. progress .. "/" .. BOARD_END
		return
	end
	local event = random:NextInteger(1, 3)
	local description
	if event == 1 then
		description = "Проклятие ранит всех!"
		for _, participant in Players:GetPlayers() do
			local humanoid = participant.Character and participant.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then humanoid:TakeDamage(10) end
		end
	elseif event == 2 then
		description = "Доска исцеляет команду."
		for _, participant in Players:GetPlayers() do
			local humanoid = participant.Character and participant.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 10) end
		end
	else
		description = "В доме тихо... пока что."
	end
	message.Value = player.DisplayName .. " бросает " .. roll .. " | " .. progress .. "/" .. BOARD_END .. " | " .. description
	task.delay(4, function() boardReady = true; boardPrompt.Enabled = true end)
end)

for index = 1, 4 do
	local container = world:WaitForChild("Search" .. index)
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
