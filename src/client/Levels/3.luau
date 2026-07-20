local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Level3 = {}
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local connections = {}
local isFirstPerson = false
local isInMaze = false
local bobbingTime = 0
local isBound = false

local crosshairGui: ScreenGui?
local currentBobOffset = Vector3.zero

local origAmbient: Color3
local origOutdoor: Color3
local origFogColor: Color3
local origFogStart: number
local origFogEnd: number

function Level3.onEnter()
	Level3.bindMaze()
end

function Level3.bindMaze()
	if isBound then return end
	isBound = true

	origAmbient = Lighting.Ambient
	origOutdoor = Lighting.OutdoorAmbient
	origFogColor = Lighting.FogColor
	origFogStart = Lighting.FogStart
	origFogEnd = Lighting.FogEnd

	task.spawn(function()
		local obby = Workspace:WaitForChild("Obby", 15)
		if not obby then return end

		local level3Folder = obby:WaitForChild("Level3", 15)
		if not level3Folder then return end

		local mazeStart = level3Folder:WaitForChild("MazeStart", 15)
		local mazeEnd = level3Folder:WaitForChild("MazeEnd", 15)

		local function bindTouch(instance: Instance, callback: () -> ())
			local function bindPart(part: BasePart)
				local conn = part.Touched:Connect(function(hit)
					local char = localPlayer.Character
					if char and hit:IsDescendantOf(char) then
						callback()
					end
				end)
				table.insert(connections, conn)
			end

			if instance:IsA("BasePart") then
				bindPart(instance)
			end

			for _, descendant in ipairs(instance:GetDescendants()) do
				if descendant:IsA("BasePart") then
					bindPart(descendant)
				end
			end

			local childConn = instance.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("BasePart") then
					bindPart(descendant)
				end
			end)
			table.insert(connections, childConn)
		end

		if mazeStart then
			bindTouch(mazeStart, function()
				if not isInMaze then
					isInMaze = true
					Level3.enableFirstPerson()
				end
			end)
		end

		if mazeEnd then
			bindTouch(mazeEnd, function()
				if isInMaze then
					isInMaze = false
					Level3.disableFirstPerson()
				end
			end)
		end
	end)
end

function Level3.createCrosshair()
	if crosshairGui then
		crosshairGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MazeCrosshair"
	gui.ResetOnSpawn = false

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(0.5, -3, 0.5, -3)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = dot

	gui.Parent = playerGui
	crosshairGui = gui
end

function Level3.removeCrosshair()
	if crosshairGui then
		crosshairGui:Destroy()
		crosshairGui = nil
	end
end

function Level3.enableFirstPerson()
	if isFirstPerson then return end
	isFirstPerson = true

	local char = localPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	local savedWalkSpeed = 16
	if humanoid then
		savedWalkSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
	end

	if head then
		local targetCF = head.CFrame + Vector3.new(0, 0.5, 0)
		camera.CameraType = Enum.CameraType.Scriptable

		local tween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCF
		})
		tween:Play()

		tween.Completed:Connect(function()
			if isFirstPerson then
				localPlayer.CameraMinZoomDistance = 0.5
				localPlayer.CameraMaxZoomDistance = 0.5
				camera.CameraType = Enum.CameraType.Custom
				if humanoid then
					humanoid.WalkSpeed = savedWalkSpeed
				end
			end
		end)
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	Level3.createCrosshair()

	TweenService:Create(Lighting, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Ambient = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(0, 0, 0),
		FogColor = Color3.fromRGB(0, 0, 0),
		FogStart = 0,
		FogEnd = 18
	}):Play()

	local renderConn = RunService.RenderStepped:Connect(function(dt)
		Level3.updateHeadBobbing(dt)
	end)
	table.insert(connections, renderConn)
end

function Level3.disableFirstPerson()
	if not isFirstPerson then return end
	isFirstPerson = false

	local char = localPlayer.Character
	local humanoid = if char then char:FindFirstChildOfClass("Humanoid") else nil

	local savedWalkSpeed = 16
	if humanoid then
		savedWalkSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		humanoid.CameraOffset = Vector3.zero
	end

	local startCF = camera.CFrame
	local backCF = startCF - (startCF.LookVector * 8)
	camera.CameraType = Enum.CameraType.Scriptable

	local exitTween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = backCF
	})
	exitTween:Play()

	exitTween.Completed:Connect(function()
		localPlayer.CameraMinZoomDistance = 0.5
		localPlayer.CameraMaxZoomDistance = 128
		camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if humanoid then
			humanoid.WalkSpeed = savedWalkSpeed
		end
	end)

	Level3.removeCrosshair()

	TweenService:Create(Lighting, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Ambient = origAmbient or Color3.fromRGB(128, 128, 128),
		OutdoorAmbient = origOutdoor or Color3.fromRGB(128, 128, 128),
		FogColor = origFogColor or Color3.fromRGB(192, 192, 192),
		FogStart = origFogStart or 0,
		FogEnd = origFogEnd or 100000
	}):Play()
end

function Level3.updateHeadBobbing(dt: number)
	if not isFirstPerson then return end

	local char = localPlayer.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local isWalking = humanoid.MoveDirection.Magnitude > 0.1 and humanoid.FloorMaterial ~= Enum.Material.Air

	local targetBob = Vector3.zero

	if isWalking then
		bobbingTime += dt * 14
		local bobX = math.cos(bobbingTime * 0.5) * 0.28
		local bobY = math.abs(math.sin(bobbingTime)) * 0.38

		targetBob = Vector3.new(bobX, bobY, 0)
	else
		bobbingTime = 0
	end

	currentBobOffset = currentBobOffset:Lerp(targetBob, dt * 16)
	humanoid.CameraOffset = currentBobOffset
end

function Level3.onLeave()
	Level3.disableFirstPerson()
end

return Level3
