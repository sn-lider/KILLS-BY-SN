-- SERVICES
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PLACE_ID = game.PlaceId
local startTime = tick()

-------------------------------------------------
-- GUI
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TimerGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 70)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(128, 0, 255)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -10, 0.5, -5)
timeLabel.Position = UDim2.new(0, 5, 0, 5)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.SourceSansBold
timeLabel.Text = "Tiempo: 00m 00s"
timeLabel.Parent = frame

local hopLabel = Instance.new("TextLabel")
hopLabel.Size = UDim2.new(1, -10, 0.5, -5)
hopLabel.Position = UDim2.new(0, 5, 0.5, 0)
hopLabel.BackgroundTransparency = 1
hopLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
hopLabel.TextScaled = true
hopLabel.Font = Enum.Font.SourceSans
hopLabel.Text = "New server 60 seconds"
hopLabel.Parent = frame

-------------------------------------------------
-- TIMER
-------------------------------------------------
task.spawn(function()
	while true do
		local elapsed = math.floor(tick() - startTime)
		local minutes = math.floor(elapsed / 60)
		local seconds = elapsed % 60
		timeLabel.Text = string.format("Tiempo: %02dm %02ds", minutes, seconds)
		task.wait(1)
	end
end)

-------------------------------------------------
-- SERVER HOP
-------------------------------------------------
local function ServerHop()
	local servers = {}
	local success, req = pcall(function()
		return HttpService:JSONDecode(
			game:HttpGet(
				"https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"
			)
		)
	end)

	if not success or not req or not req.data then return end

	for _, server in pairs(req.data) do
		if server.playing < server.maxPlayers then
			table.insert(servers, server.id)
		end
	end

	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(
			PLACE_ID,
			servers[math.random(1, #servers)],
			player
		)
	end
end

task.spawn(function()
	while true do
		for i = 60, 1, -1 do
			hopLabel.Text = "New server " .. i .. " seconds"
			task.wait(1)
		end
		ServerHop()
	end
end)

-------------------------------------------------
-- AUTO KILL / FAST HIT
-------------------------------------------------
local LocalPlayer = player

local autoKill = true
_G.fastHitActive = true

local playerWhitelist = playerWhitelist or {}

task.spawn(function()
	while autoKill do
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local rightHand = character:FindFirstChild("RightHand")
		local leftHand = character:FindFirstChild("LeftHand")

		local punch = LocalPlayer.Backpack:FindFirstChild("Punch")
		if punch and not character:FindFirstChild("Punch") then
			punch.Parent = character
		end

		if rightHand and leftHand then
			for _, target in ipairs(Players:GetPlayers()) do
				if target ~= LocalPlayer and not playerWhitelist[target.Name] then
					local char = target.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if root then
						pcall(function()
							firetouchinterest(rightHand, root, 1)
							firetouchinterest(leftHand, root, 1)
							firetouchinterest(rightHand, root, 0)
							firetouchinterest(leftHand, root, 0)
						end)
					end
				end
			end
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while _G.fastHitActive do
		local punch = LocalPlayer.Backpack:FindFirstChild("Punch")
		if punch then
			punch.Parent = LocalPlayer.Character
			if punch:FindFirstChild("attackTime") then
				punch.attackTime.Value = 0
			end
		end
		task.wait(0.1)
	end
end)

task.spawn(function()
	while _G.fastHitActive do
		local punch = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Punch")
		if punch then
			punch:Activate()
		end
		task.wait(0.1)
	end
end)
