local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- Set this to a published place in this experience before enabling teleports.
local DESTINATION_PLACE_ID = 85770153975326
local CAPACITY = 6
local COUNTDOWN_SECONDS = 10
local TELEPORT_TIMEOUT = 30

local remotes = Instance.new("Folder")
remotes.Name = "LobbyQueue"
remotes.Parent = ReplicatedStorage
local request = Instance.new("RemoteEvent")
request.Name = "Request"
request.Parent = remotes
local update = Instance.new("RemoteEvent")
update.Name = "Update"
update.Parent = remotes

local rooms = {}
local membership = {}
local lastRequest = {}
local nextId = 0

local function broadcast()
	local snapshot = {}
	for _, room in pairs(rooms) do
		local names = {}
		for _, player in ipairs(room.members) do
			table.insert(names, player.DisplayName .. " (@" .. player.Name .. ")")
		end
		table.insert(snapshot, {
			id = room.id, host = room.host.Name, members = names,
			count = #room.members, capacity = CAPACITY,
			status = room.status, remaining = room.remaining,
		})
	end
	table.sort(snapshot, function(a, b) return a.id < b.id end)
	update:FireAllClients("state", snapshot)
end

local function notice(player, text)
	if player.Parent == Players then
		update:FireClient(player, "notice", text)
	end
end

local function cancelCountdown(room)
	if room.status == "countdown" then
		room.generation += 1
		room.status = "open"
		room.remaining = nil
	end
end

local function leave(player)
	local room = membership[player]
	if not room then return end
	membership[player] = nil
	for index, member in ipairs(room.members) do
		if member == player then
			table.remove(room.members, index)
			break
		end
	end
	if #room.members == 0 then
		rooms[room.id] = nil
		room.generation += 1
	else
		if room.host == player then room.host = room.members[1] end
		cancelCountdown(room)
	end
	broadcast()
end

local function start(room)
	if DESTINATION_PLACE_ID <= 0 or DESTINATION_PLACE_ID % 1 ~= 0 then
		notice(room.host, "Destination place ID is not configured.")
		return
	end
	room.status = "countdown"
	room.generation += 1
	local generation = room.generation
	task.spawn(function()
		for seconds = COUNTDOWN_SECONDS, 1, -1 do
			if rooms[room.id] ~= room or room.generation ~= generation then return end
			room.remaining = seconds
			broadcast()
			task.wait(1)
		end
		if rooms[room.id] ~= room or room.generation ~= generation then return end
		room.status = "teleporting"
		room.remaining = nil
		local party = table.clone(room.members)
		room.pending = {}
		for _, player in ipairs(party) do room.pending[player] = true end
		broadcast()
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(DESTINATION_PLACE_ID, party, options)
		end)
		options:Destroy()
		if not ok and rooms[room.id] == room and room.generation == generation then
			room.pending = nil
			room.status = "open"
			for _, player in ipairs(room.members) do notice(player, "Teleport failed. Please try again.") end
			warn("Lobby teleport failed: " .. tostring(err))
			broadcast()
			return
		end
		task.delay(TELEPORT_TIMEOUT, function()
			if rooms[room.id] ~= room or room.generation ~= generation or room.status ~= "teleporting" then return end
			room.pending = nil
			room.status = "open"
			for _, player in ipairs(room.members) do notice(player, "Teleport did not complete. Please try again.") end
			broadcast()
		end)
	end)
end

TeleportService.TeleportInitFailed:Connect(function(player, result, message, placeId)
	local room = membership[player]
	if placeId ~= DESTINATION_PLACE_ID or not room or room.status ~= "teleporting" or not room.pending or not room.pending[player] then return end
	room.pending[player] = nil
	notice(player, "Teleport failed. Wait for the room to reopen and try again.")
	warn("Lobby teleport failed for " .. player.Name .. ": " .. tostring(result) .. " " .. tostring(message))
	local anyPending = false
	for member in pairs(room.pending) do
		if member.Parent == Players and membership[member] == room then anyPending = true break end
	end
	if not anyPending then
		room.pending = nil
		room.status = "open"
		broadcast()
	end
end)

request.OnServerEvent:Connect(function(player, action, id)
	if typeof(action) ~= "string" or #action > 16 then return end
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < 0.3 then return end
	lastRequest[player] = now
	local room = membership[player]
	if action == "sync" then
		broadcast()
	elseif action == "create" then
		if room then notice(player, "Leave your current room first.") return end
		nextId += 1
		room = {id = nextId, host = player, members = {player}, status = "open", generation = 0}
		rooms[room.id] = room
		membership[player] = room
		broadcast()
	elseif action == "join" then
		if room then notice(player, "Leave your current room first.") return end
		if typeof(id) ~= "number" or id ~= id or id % 1 ~= 0 then return end
		room = rooms[id]
		if not room or room.status ~= "open" or #room.members >= CAPACITY then
			notice(player, "Room is unavailable or full.") return
		end
		table.insert(room.members, player)
		membership[player] = room
		broadcast()
	elseif action == "leave" then
		if room and room.status == "teleporting" then notice(player, "Teleport in progress.") return end
		leave(player)
	elseif action == "start" then
		if not room or room.host ~= player or room.status ~= "open" then return end
		start(room)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
	leave(player)
end)
