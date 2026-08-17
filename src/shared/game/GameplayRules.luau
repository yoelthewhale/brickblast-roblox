local Config = require(script.Parent.Config)

local GameplayRules = {}

function GameplayRules.comboBonusForStreak(comboStreak)
	return math.max(0, comboStreak - 1) * Config.ComboBonusPoints
end

function GameplayRules.scoreForPlacement(cellsPlaced, linesCleared, comboStreak)
	local comboBonus = GameplayRules.comboBonusForStreak(comboStreak)
	local scoreDelta = cellsPlaced * Config.PointsPerCell
		+ linesCleared * Config.PointsPerLine
		+ comboBonus
	return scoreDelta, comboBonus
end

function GameplayRules.assistanceRestoreAmount(comboStreak, stageResult)
	local amount = 0
	local triggers = {
		stageAdvanced = false,
		comboMilestone = false,
		perfectClear = false,
	}

	if stageResult and stageResult.stagesAdvanced > 0 then
		amount += Config.HandGeneration.StageAdvanceRestore * stageResult.stagesAdvanced
		triggers.stageAdvanced = true
	end
	if comboStreak > 0 and comboStreak % Config.HandGeneration.ComboRestoreMilestone == 0 then
		amount += Config.HandGeneration.ComboRestore
		triggers.comboMilestone = true
	end
	if stageResult and stageResult.perfectClear then
		amount += Config.HandGeneration.PerfectClearRestore
		triggers.perfectClear = true
	end

	return amount, triggers
end

function GameplayRules.describeAssistanceTriggers(triggers)
	local reasons = {}

	if triggers.stageAdvanced then
		table.insert(reasons, "stage advanced")
	end
	if triggers.comboMilestone then
		table.insert(reasons, "combo milestone")
	end
	if triggers.perfectClear then
		table.insert(reasons, "perfect clear")
	end

	if #reasons == 0 then
		return "none"
	end

	return table.concat(reasons, ", ")
end

return GameplayRules
