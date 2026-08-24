--!strict
-- Fails when a script gets too close to Luau's 200-top-level-local limit.
--
-- Usage: lune run scripts/check-local-registers.luau
--
-- Why this exists: on 2026-08-19 `GameServer.server.luau` crossed that limit
-- and stopped compiling entirely. The server built no hub, created no remotes,
-- and players spawned onto an empty bootstrap floor. Nothing in the pipeline
-- noticed -- Rojo packages source without compiling it, Selene does not model
-- register allocation, StyLua only formats, and the Lune suite cannot load
-- server scripts at all. CI was green the whole time. The only symptom was one
-- line in Studio's Output on a script that silently did nothing.
--
-- The budgets below are a ratchet, deliberately set just above each file's
-- current count. Adding a top-level local to either file fails this check. The
-- fix is to attach the value to an existing table or move the concern into a
-- ModuleScript (which gets its own register budget) -- not to raise the number
-- here. Lowering a budget after a real reduction is always welcome.

local fs = require("@lune/fs")
local process = require("@lune/process")

-- Luau's hard ceiling. Crossing it is a compile failure, not a warning.
local LUAU_TOP_LEVEL_LOCAL_LIMIT = 200

local BUDGETS: { { path: string, budget: number } } = {
	{ path = "src/server/services/GameServer.server.luau", budget = 191 },
	{ path = "src/client/ui/BlockBlastClient.client.luau", budget = 198 },
}

-- Counts declared names, not lines: `local a, b = 1, 2` costs two registers.
-- Only column-zero declarations count, since indented ones are inside a
-- function body and get their own scope.
local function countTopLevelLocals(source: string): number
	local count = 0

	for line in string.gmatch(source, "[^\n]*") do
		local names = string.match(line, "^local%s+([^=]+)")
		if names and not string.match(line, "^local%s+function") then
			-- Strip a type annotation before splitting, so `local a: {number}`
			-- is not miscounted on its comma.
			names = string.gsub(names, ":%s*[^,]*", "")
			for _ in string.gmatch(names, "[^,%s]+") do
				count += 1
			end
		elseif string.match(line, "^local%s+function") then
			count += 1
		end
	end

	return count
end

local failures = 0

print("Checking top-level local budgets (Luau limit: " .. LUAU_TOP_LEVEL_LOCAL_LIMIT .. ")\n")

for _, entry in BUDGETS do
	local source = fs.readFile(entry.path)
	local count = countTopLevelLocals(source)
	local headroom = LUAU_TOP_LEVEL_LOCAL_LIMIT - count

	if count > entry.budget then
		failures += 1
		print(
			string.format(
				"  FAIL  %s\n        %d top-level locals, budget %d (%d from the Luau limit)",
				entry.path,
				count,
				entry.budget,
				headroom
			)
		)
		print("        Attach the value to an existing table, or move the concern into a")
		print("        ModuleScript. Do not raise the budget.")
	else
		print(
			string.format(
				"  ok    %-46s %3d / %3d  (%d from the Luau limit)",
				entry.path,
				count,
				entry.budget,
				headroom
			)
		)
	end
end

print("")

if failures > 0 then
	print(failures .. " file(s) over budget")
	process.exit(1)
end

print("All files within budget")
