local SoundService = game:GetService("SoundService")

local ObbyController = {}

function ObbyController.init()
end

function ObbyController.start()
end

function ObbyController.playCheckpointEffect(stageNum: number)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9069609258"
	sound.Volume = 0.6
	sound.Parent = SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return ObbyController
