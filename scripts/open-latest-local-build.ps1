param(
	[string]$ExpectedAccount = "CAPTINNINJATACO"
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$latestBuild = Get-ChildItem -LiteralPath $projectRoot -Filter "BlockBlastBattle-Day*.rbxl" |
	Sort-Object LastWriteTime -Descending |
	Select-Object -First 1

if (-not $latestBuild) {
	Write-Error "No BlockBlastBattle-Day*.rbxl build was found in $projectRoot."
	exit 1
}

$studioCandidates = @(
	"$env:LOCALAPPDATA\Roblox\Versions\*\RobloxStudioBeta.exe",
	"$env:ProgramFiles\Roblox\Versions\*\RobloxStudioBeta.exe",
	"${env:ProgramFiles(x86)}\Roblox\Versions\*\RobloxStudioBeta.exe"
)

$studio = $null
foreach ($candidate in $studioCandidates) {
	$studio = Get-ChildItem -Path $candidate -ErrorAction SilentlyContinue |
		Sort-Object LastWriteTime -Descending |
		Select-Object -First 1
	if ($studio) {
		break
	}
}

if (-not $studio) {
	Write-Error "RobloxStudioBeta.exe was not found. Open Roblox Studio manually and load $($latestBuild.FullName)."
	exit 1
}

Write-Host "Opening local build:"
Write-Host "  $($latestBuild.FullName)"
Write-Host ""
Write-Host "Before pressing Play or publishing, confirm Roblox Studio's top-right account is:"
Write-Host "  $ExpectedAccount"
Write-Host ""
Write-Host "If Studio opens under another account, sign out inside Studio and sign back in as $ExpectedAccount."

Start-Process -FilePath $studio.FullName -ArgumentList "`"$($latestBuild.FullName)`""
