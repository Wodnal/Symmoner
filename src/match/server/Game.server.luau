local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

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
local throwStage = Instance.new("RemoteEvent")
throwStage.Name = "ThrowStage"
throwStage.Parent = state

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
local function addDieFaces(part, numbers, color)
	local order = {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom}
	for index, faceId in order do
		local surface = Instance.new("SurfaceGui")
		surface.Name = "Face" .. index
		surface.Face = faceId
		surface.AlwaysOnTop = false
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 64
		surface.Parent = part
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = color or Color3.fromRGB(46, 26, 70)
		frame.BorderSizePixel = 0
		frame.Parent = surface
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.12, 0)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(216, 170, 84)
		stroke.Thickness = 3
		stroke.Transparency = 0.2
		stroke.Parent = frame
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = numbers[index]
		label.TextColor3 = Color3.fromRGB(255, 232, 176)
		label.TextStrokeColor3 = Color3.fromRGB(58, 28, 8)
		label.TextStrokeTransparency = 0.35
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.Parent = frame
	end
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
local function updateIdolVisual(player)
	local character = player.Character
	if not character then return end
	local old = character:FindFirstChild("CarriedIdolVisual")
	if old then old:Destroy() end
	local value = player:GetAttribute("CarriedIdol") or 0
	local root = character:FindFirstChild("HumanoidRootPart")
	if value <= 0 or not root then return end
	local idol = Instance.new("Part")
	idol.Name = "CarriedIdolVisual"
	idol.Size = Vector3.new(1.2, 1.7, 1.2)
	idol.Color = Color3.fromRGB(218, 164, 49)
	idol.Material = Enum.Material.Metal
	idol.Massless = true
	idol.CanCollide = false
	idol.CFrame = root.CFrame * CFrame.new(1.4, 0, -1.3)
	idol.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = idol
	weld.Parent = idol
end
local clearHeldStageDie
local function setupPlayer(player)
	player:SetAttribute("CarriedIdol", 0)
	player:SetAttribute("HoldingStageDie", false)
	player:GetAttributeChangedSignal("CarriedIdol"):Connect(function() updateIdolVisual(player) end)
	local function onCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			player:SetAttribute("CarriedIdol", 0)
			player:SetAttribute("HoldingStageDie", false)
			if clearHeldStageDie then clearHeldStageDie(player) end
		end)
		task.defer(function() updateIdolVisual(player) end)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then task.spawn(onCharacter, player.Character) end
	local folder = Instance.new("Folder")
	folder.Name = "DiceInventory"
	folder.Parent = player
	inventories[player] = folder
	for _, name in names do
		local count = Instance.new("IntValue")
		count.Name = name
		count.Parent = folder
	end
	folder.Heal.Value = 2
	folder.Teleport.Value = 1
	folder.AntiGravity.Value = 1
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
local TARGET_POINTS = 300
local stage = 0
local points = 0
local totalPoints = 0
local phase = "READY"
local stageDie
local dieResolved = false
local createStageDie
local boardPrompt = promptOn(board, "Бросить кубик этапа", "Проклятая доска")
boardPrompt.Enabled = false
local depositPrompt = promptOn(board, "Сдать идола", "Доска")
depositPrompt.Enabled = false
local boardInfo = Instance.new("BillboardGui")
boardInfo.Name = "BoardInfo"
boardInfo.Size = UDim2.fromOffset(300, 70)
boardInfo.StudsOffset = Vector3.new(0, 4, 0)
boardInfo.AlwaysOnTop = true
boardInfo.Parent = board
local boardLabel = Instance.new("TextLabel")
boardLabel.Size = UDim2.fromScale(1, 1)
boardLabel.BackgroundTransparency = 1
boardLabel.TextColor3 = Color3.fromRGB(255, 220, 143)
boardLabel.TextStrokeTransparency = 0
boardLabel.TextScaled = true
boardLabel.Font = Enum.Font.GothamBold
boardLabel.Parent = boardInfo
local function updateBoard()
	if phase ~= "READY" then
		for _, participant in Players:GetPlayers() do
			if participant:GetAttribute("HoldingStageDie") then
				participant:SetAttribute("HoldingStageDie", false)
				if clearHeldStageDie then clearHeldStageDie(participant) end
			end
		end
	end
	if phase == "READY" and (not stageDie or dieResolved) then
		dieResolved = false
		createStageDie()
	end
	if phase == "READY" then
		boardLabel.Text = "КУБИК ГОТОВ\nВернитесь в безопасную зону!"
	elseif phase == "EXPLORE" then
		boardLabel.Text = "ДО СЛЕДУЮЩЕГО КУБИКА: " .. math.max(0, TARGET_POINTS - points)
	else
		boardLabel.Text = "ПОБЕДА!"
	end
	boardPrompt.Enabled = false
	depositPrompt.Enabled = phase == "EXPLORE"
end
local function insideSafeZone(root)
	local offset = root.Position - board.Position
	return math.abs(offset.X) <= 17 and math.abs(offset.Z) <= 17 and math.abs(offset.Y) <= 12
end
local resetIdols
local stagePrompt
local rollStage = Instance.new("BindableEvent")
clearHeldStageDie = function(player)
	local character = player.Character
	local held = character and character:FindFirstChild("HeldStageDie")
	if held then held:Destroy() end
end
local function createHeldStageDie(player)
	clearHeldStageDie(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local held = Instance.new("Part")
	held.Name = "HeldStageDie"
	held.Size = Vector3.new(1.25, 1.25, 1.25)
	held.Color = Color3.fromRGB(116, 60, 165)
	held.Material = Enum.Material.Neon
	held.CanCollide = false
	held.CanTouch = false
	held.Massless = true
	held.CFrame = root.CFrame * CFrame.new(0.95, 0.25, -1.7) * CFrame.Angles(math.rad(-14), math.rad(32), math.rad(6))
	held.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = held
	weld.Parent = held
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(190, 90, 255)
	glow.Brightness = 1.5
	glow.Range = 8
	glow.Parent = held
	addDieFaces(held, {"1", "6", "3", "4", "2", "5"})
end
createStageDie = function()
	if stageDie then stageDie:Destroy() end
	stageDie = Instance.new("Part")
	stageDie.Name = "StageDie"
	stageDie.Size = Vector3.new(2.2, 2.2, 2.2)
	stageDie.Position = board.Position + Vector3.new(0, 2.1, 0)
	stageDie.Color = Color3.fromRGB(82, 48, 112)
	stageDie.Material = Enum.Material.Neon
	stageDie.Anchored = true
	stageDie.CanCollide = true
	stageDie.Parent = world
	local glow = Instance.new("PointLight")
	glow.Name = "StageDieGlow"
	glow.Color = Color3.fromRGB(190, 90, 255)
	glow.Brightness = 2
	glow.Range = 14
	glow.Parent = stageDie
	addDieFaces(stageDie, {"1", "6", "3", "4", "2", "5"})
	stagePrompt = promptOn(stageDie, "Поднять", "Кубик этапа")
	stagePrompt.Triggered:Connect(function(player)
		if phase == "READY" and near(player, board) and not player:GetAttribute("HoldingStageDie") then
			player:SetAttribute("HoldingStageDie", true)
			createHeldStageDie(player)
			stagePrompt.Enabled = false
			stageDie.Transparency = 1
			stageDie.CanCollide = false
			local dieGlow = stageDie:FindFirstChild("StageDieGlow")
			if dieGlow then dieGlow.Enabled = false end
			message.Value = player.DisplayName .. " поднял кубик. Удерживайте ЛКМ и отпустите, чтобы бросить."
			task.delay(15, function()
				if player.Parent and player:GetAttribute("HoldingStageDie") and phase == "READY" and stageDie and stageDie.Parent then
					player:SetAttribute("HoldingStageDie", false)
					clearHeldStageDie(player)
					stageDie.Transparency = 0
					stageDie.CanCollide = true
					local dieGlow = stageDie:FindFirstChild("StageDieGlow")
					if dieGlow then dieGlow.Enabled = true end
					stagePrompt.Enabled = true
					message.Value = "Кубик вернулся на доску. Подойдите и поднимите снова."
				end
			end)
		end
	end)
end
local function addPrompt(part, action, object)
	local prompt = promptOn(part, action, object)
	return prompt
end
local function createIdolVisual(player, value)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root then return end
	local old = character:FindFirstChild("CarriedIdolVisual")
	if old then old:Destroy() end
	local idol = Instance.new("Part")
	idol.Name = "CarriedIdolVisual"
	idol.Shape = Enum.PartType.Ball
	idol.Size = Vector3.new(1.1, 1.4, 1.1)
	idol.Color = value >= 200 and Color3.fromRGB(170, 60, 255) or Color3.fromRGB(255, 181, 35)
	idol.Material = Enum.Material.Neon
	idol.CanCollide = false
	idol.Massless = true
	idol.CFrame = root.CFrame * CFrame.new(1.3, 0.1, -1.1)
	idol.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, idol
	weld.Parent = idol
	local glow = Instance.new("PointLight")
	glow.Color = idol.Color
	glow.Range = 8
	glow.Brightness = 1.4
	glow.Parent = idol
end
local function clearIdolVisual(player)
	local character = player.Character
	local idol = character and character:FindFirstChild("CarriedIdolVisual")
	if idol then idol:Destroy() end
end
local performRoll
throwStage.OnServerEvent:Connect(function(player, direction, power)
	if phase ~= "READY" or not player:GetAttribute("HoldingStageDie") then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not near(player, board) or typeof(direction) ~= "Vector3" then return end
	player:SetAttribute("HoldingStageDie", false)
	clearHeldStageDie(player)
	local die = stageDie
	if not die then return end
	die.Transparency = 0
	die.CanCollide = true
	local dieGlow = die:FindFirstChild("StageDieGlow")
	if dieGlow then dieGlow.Enabled = true end
	die.CFrame = root.CFrame * CFrame.new(0, 1, -4) * CFrame.Angles(math.rad(random:NextInteger(0, 360)), math.rad(random:NextInteger(0, 360)), 0)
	die.Anchored = false
	die:SetNetworkOwner(nil)
	die.AssemblyLinearVelocity = direction.Unit * math.clamp(tonumber(power) or 28, 18, 45) + Vector3.new(0, 14, 0)
	die.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-14, 14), random:NextNumber(-14, 14), random:NextNumber(-14, 14))
	stagePrompt.Enabled = false
	task.spawn(function()
		local deadline = os.clock() + 5
		while os.clock() < deadline do
			task.wait(0.12)
			if not die.Parent then return end
			if die.AssemblyLinearVelocity.Magnitude < 1.6 then break end
		end
		if die.Parent and phase == "READY" then
			die.Anchored = true
			die.AssemblyLinearVelocity = Vector3.zero
			die.AssemblyAngularVelocity = Vector3.zero
			local target = CFrame.new(board.Position + Vector3.new(0, 2.1, 0)) * CFrame.Angles(math.rad(random:NextInteger(0, 359)), math.rad(random:NextInteger(0, 359)), 0)
			TweenService:Create(die, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = target}):Play()
			task.wait(0.4)
			rollStage:Fire(player)
		end
	end)
end)
boardPrompt.Triggered:Connect(function(player)
	if phase ~= "READY" or not near(player, board) then return end
	performRoll(player)
end)
performRoll = function(player)
	phase = "TRANSITION"
	boardPrompt.Enabled = false
	local casualties = 0
	if stage > 0 then
		for _, participant in Players:GetPlayers() do
			local character = participant.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and not insideSafeZone(root) then
				humanoid.Health = 0
				casualties += 1
			end
		end
	end
	local roll = random:NextInteger(1, 6)
	if stageDie then
		local up = {
			[1] = CFrame.Angles(math.rad(90), 0, 0),
			[2] = CFrame.new(),
			[3] = CFrame.Angles(0, 0, math.rad(-90)),
			[4] = CFrame.Angles(0, 0, math.rad(90)),
			[5] = CFrame.Angles(math.rad(180), 0, 0),
			[6] = CFrame.Angles(math.rad(-90), 0, 0),
		}
		dieResolved = true
		if stagePrompt then stagePrompt.Enabled = false end
		stageDie.Anchored = true
		stageDie.AssemblyLinearVelocity = Vector3.zero
		stageDie.AssemblyAngularVelocity = Vector3.zero
		local target = CFrame.new(stageDie.Position) * up[roll]
		TweenService:Create(stageDie, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = target}):Play()
		stageDie.Color = Color3.fromRGB(210, 140, 48)
	end
	stage += 1
	progress = math.min(BOARD_END, progress + roll)
	if progress >= BOARD_END then
		phase = "FINISHED"
		message.Value = "Победа! Доска пройдена. Общие очки: " .. totalPoints
	else
		points = 0
		phase = "EXPLORE"
		if resetIdols then resetIdols() end
		message.Value = "Этап " .. stage .. ": выпало " .. roll .. ", путь " .. progress .. "/" .. BOARD_END .. ". Найдите идолов!" .. (if casualties > 0 then " Вне хаба погибло: " .. casualties else "")
	end
	updateBoard()
end
rollStage.Event:Connect(performRoll)
depositPrompt.Triggered:Connect(function(player)
	if phase ~= "EXPLORE" or not near(player, board) then return end
	local value = player:GetAttribute("CarriedIdol") or 0
	if value <= 0 then return end
	player:SetAttribute("CarriedIdol", 0)
	clearIdolVisual(player)
	points += value
	totalPoints += value
	if points >= TARGET_POINTS then
		phase = "READY"
		message.Value = "Следующий кубик готов! Все игроки должны вернуться к доске."
	else
		message.Value = player.DisplayName .. " сдаёт идола: +" .. value .. ". Осталось " .. (TARGET_POINTS - points)
	end
	updateBoard()
end)
updateBoard()

local searches = {}
resetIdols = function()
	for _, search in searches do
		search.available = true
		search.prompt.Enabled = true
	end
end
for index = 1, 4 do
	local container = world:WaitForChild("Search" .. index)
	local prompt = promptOn(container, "Обыскать", "Старый ящик")
	local search = {available = true, prompt = prompt}
	table.insert(searches, search)
	prompt.Triggered:Connect(function(player)
		local inventory = inventories[player]
		if phase ~= "EXPLORE" or not search.available or not inventory or not near(player, container) then return end
		if (player:GetAttribute("CarriedIdol") or 0) > 0 then
			message.Value = "Сначала отнесите найденного идола к доске."
			return
		end
		search.available = false
		prompt.Enabled = false
		task.delay(45, function()
			search.available = true
			prompt.Enabled = true
		end)
		local total = 0
		for _, die in inventory:GetChildren() do total += die.Value end
		if random:NextInteger(1, 4) == 1 and total < 3 then
			local die = inventory:FindFirstChild(names[random:NextInteger(1, #names)])
			die.Value += 1
			message.Value = player.DisplayName .. " находит кубик: " .. die.Name
			return
		end
		local values = {100, 150, 200}
		local value = values[random:NextInteger(1, #values)]
		player:SetAttribute("CarriedIdol", value)
		createIdolVisual(player, value)
		message.Value = player.DisplayName .. " нашёл идола на " .. value .. " очков. Верните его к доске."
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
	local projectile = Instance.new("Part")
	projectile.Name = "ThrownDie"
	projectile.Size = Vector3.new(1.2, 1.2, 1.2)
	projectile.Material = Enum.Material.Neon
	local colors = {Heal = Color3.fromRGB(80, 220, 120), Teleport = Color3.fromRGB(130, 90, 230), AntiGravity = Color3.fromRGB(120, 200, 255), Hazard = Color3.fromRGB(255, 100, 50)}
	projectile.Color = colors[name]
	projectile.CFrame = root.CFrame * CFrame.new(0, 1, -4)
	projectile.Parent = Workspace
	projectile:SetNetworkOwner(nil)
	projectile.AssemblyLinearVelocity = root.CFrame.LookVector * 30 + Vector3.new(0, 17, 0)
	projectile.AssemblyAngularVelocity = Vector3.new(8, 12, 7)
	message.Value = player.DisplayName .. " бросает кубик: " .. name
	task.delay(2, function()
		if not projectile.Parent then return end
		local position = projectile.Position
		projectile.Anchored = true
		projectile.CanCollide = false
		projectile.Transparency = 0.6
		local effect = Instance.new("PointLight")
		effect.Color = colors[name]
		effect.Brightness = 5
		effect.Range = 16
		effect.Parent = projectile
		if name == "Heal" or name == "Hazard" then
			for _, target in Players:GetPlayers() do
				local targetCharacter = target.Character
				local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and (targetRoot.Position - position).Magnitude <= 12 then
					if name == "Heal" then targetHumanoid.Health = math.min(targetHumanoid.MaxHealth, targetHumanoid.Health + 25) else targetHumanoid:TakeDamage(20) end
				end
			end
		elseif name == "Teleport" and player.Character == character and humanoid.Health > 0 then
			character:PivotTo(CFrame.new(0, 5, 15))
		elseif name == "AntiGravity" and root.Parent and humanoid.Health > 0 then
			local attachment = Instance.new("Attachment")
			attachment.Parent = root
			local force = Instance.new("VectorForce")
			force.Attachment0 = attachment
			force.Force = Vector3.new(0, root.AssemblyMass * Workspace.Gravity * 0.65, 0)
			force.Parent = root
			task.delay(5, function() force:Destroy(); attachment:Destroy() end)
		end
		task.delay(1, function() projectile:Destroy() end)
	end)
end)
