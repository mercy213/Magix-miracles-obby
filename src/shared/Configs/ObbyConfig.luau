local ObbyConfig = {
	ObbyFolderName = "Obby", -- obby folder
	CheckpointName = "CheckPoint", -- checkpoint name
	DefaultStage = 1, -- default stage 
	KillBrickTag = "KillBrick", -- instead having death part make any part properties add tag and call iit this tag // DeathPart still work
	CheckpointCoolDown = 0.5, 
	Level15BadgeId = 1623073761035482, -- badge
	CompletionBadgeId = 3158809878982794, --badge
	MainGamePlaceId = 82614076557684, -- main game id
	SkipStageDevProductId = 0, -- make this the dev product id 
	PremiumDanceGamepassId = 1234544490, -- dance id from main game

	-- anti cheat
	MaxWalkSpeed = 32, -- max speed
	VoidYThreshold = -150, -- void Y threshold
	MaxCheckpointTouchDistance = 35, -- max checkpoint touch distance
}

return ObbyConfig
