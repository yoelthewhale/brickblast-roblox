local Config = require(script.Parent.Config)

local GameplayRules = {}

function GameplayRules.comboBonusForStreak(comboStreak)
	return math.max(0, comboStreak - 1) * Config.ComboBonusPoints
end

-- Bonus for clearing several lines with a single placement.
--
-- Without this, a simultaneous multi-line clear scored strictly worse than
-- clearing the same lines one at a time: the combo bonus counts clearing
-- *placements*, not lines, so three separate single clears banked 25 + 50 of
-- combo bonus that one triple clear never saw. That made the hardest, most
-- dramatic play the worst-scoring one, and contradicted StageProgression,
-- which already pays extra for multi-line clears.
--
-- The bonus is exactly the combo bonus those clears would have earned as
-- consecutive placements -- 0 + 1 + ... + (n-1) units -- so clearing n lines
-- at once is worth at least as much as clearing them one per placement.
function GameplayRules.multiLineBonusForClear(linesCleared)
	local lines = typeof(linesCleared) == "number" and math.max(0, math.floor(linesCleared)) or 0
	return lines * (lines - 1) / 2 * Config.MultiLineClearBonusPoints
end

function GameplayRules.scoreForPlacement(cellsPlaced, linesCleared, comboStreak)
	local comboBonus = GameplayRules.comboBonusForStreak(comboStreak)
	local multiLineBonus = GameplayRules.multiLineBonusForClear(linesCleared)
	local scoreDelta = cellsPlaced * Config.PointsPerCell
		+ linesCleared * Config.PointsPerLine
		+ comboBonus
		+ multiLineBonus
	return scoreDelta, comboBonus, multiLineBonus
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
