--!strict
-- Headless test runner for src/shared/game/*Tests.luau.
-- Usage: lune run scripts/run-tests.luau
--
-- These test modules were written to run inside Roblox Studio, using
-- Roblox-style `require(script.Parent.X)` and datatypes like Vector2,
-- Color3, and Random. This runner makes that work under Lune (a
-- standalone Luau runtime, no Roblox client/DataModel involved) by:
--   1. Pulling Vector2/Color3/Enum/etc. from @lune/roblox as globals.
--   2. Polyfilling Random.new, which @lune/roblox does not provide.
--   3. Faking `script` as a path-encoding proxy table, and swapping the
--      global `require`/`script` to resolve `script.Parent.X` through
--      Lune's real file-based require. The swap happens around every
--      nested require so deeply-nested modules each see their own
--      correct location, not the outermost caller's.

local roblox = require("@lune/roblox")
local process = require("@lune/process")

local robloxGlobals = { "Vector2", "Vector3", "Color3", "Enum", "UDim", "UDim2", "CFrame" }
for _, name in robloxGlobals do
	(_G :: any)[name] = (roblox :: any)[name];
	(getfenv() :: any)[name] = (roblox :: any)[name]
end

local RandomPolyfill = {}
RandomPolyfill.__index = RandomPolyfill

function RandomPolyfill.new(seed: number?)
	local self = setmetatable({}, RandomPolyfill)
	local state = (seed or 0) % 2147483647
	self._state = state <= 0 and state + 2147483646 or state
	return self
end

function RandomPolyfill:_nextRaw(): number
	self._state = (self._state * 16807) % 2147483647
	return self._state
end

function RandomPolyfill:NextNumber(min: number?, max: number?): number
	local fraction = (self:_nextRaw() - 1) / 2147483646
	if min == nil then
		return fraction
	end
	return min + fraction * ((max :: number) - min)
end

function RandomPolyfill:NextInteger(min: number, max: number): number
	local fraction = (self:_nextRaw() - 1) / 2147483646
	return math.floor(min + fraction * (max - min + 1))
end
(_G :: any).Random = RandomPolyfill;
(getfenv() :: any).Random = RandomPolyfill

type ScriptProxy = { __path: string }

local ScriptProxyMeta = {}
ScriptProxyMeta.__index = function(self: ScriptProxy, key: string)
	if key == "Parent" then
		local dir = self.__path:match("(.*)/[^/]+$") or "."
		return setmetatable({ __path = dir }, ScriptProxyMeta)
	end
	return setmetatable({ __path = self.__path .. "/" .. key }, ScriptProxyMeta)
end

local function makeScriptProxy(path: string): ScriptProxy
	return setmetatable({ __path = path }, ScriptProxyMeta) :: any
end

local realRequire = require

local function shimRequire(target: any): any
	if type(target) ~= "table" or not target.__path then
		return realRequire(target)
	end

	local previousScript = (_G :: any).script
	local nextScript = makeScriptProxy(target.__path);
	(_G :: any).script = nextScript;
	(getfenv() :: any).script = nextScript
	local ok, result = pcall(realRequire, target.__path);
	(_G :: any).script = previousScript;
	(getfenv() :: any).script = previousScript
	if not ok then
		error(result, 0)
	end
	return result
end
(_G :: any).require = shimRequire;
(getfenv() :: any).require = shimRequire

local TEST_MODULES = {
	"AchievementsTests",
	"CosmeticProgressionTests",
	"DeveloperToolsTests",
	"GameplayRulesTests",
	"HandGeneratorTests",
	"OneMoreChanceTests",
	"ProfilePersistenceTests",
	"SimulationHarnessTests",
	"SoloLayoutTests",
	"StageProgressionTests",
	"TelemetryTests",
	"StageVisualsTests",
	"VisualTokensTests",
	"UIControlRulesTests",
	"VisualQualityTests",
	"ClearPraiseTests",
}

local GAME_DIR = "../src/shared/game"

local totalModules = 0
local failedModules = 0
local totalTests = 0

print("Running BrickBlast shared/game test suites via Lune...\n")

for _, moduleName in TEST_MODULES do
	totalModules += 1
	local modulePath = `{GAME_DIR}/{moduleName}`

	local ok, testsOrError = pcall(function()
		local testModule = shimRequire(makeScriptProxy(modulePath))
		return testModule.run()
	end)

	if ok then
		local count = #(testsOrError :: { string })
		totalTests += count
		print(`  PASS  {moduleName} ({count} tests)`)
	else
		failedModules += 1
		print(`  FAIL  {moduleName}`)
		print(`        {tostring(testsOrError)}`)
	end
end

print("")
print(
	`{totalModules - failedModules}/{totalModules} modules passed, {totalTests} individual tests ran`
)

if failedModules > 0 then
	process.exit(1)
end
