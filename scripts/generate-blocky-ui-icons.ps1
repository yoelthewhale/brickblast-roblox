Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "assets\ui\icons-blocky-bedwars"
$mockupDir = Join-Path $root "assets\ui\mockups"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $mockupDir | Out-Null

function New-Canvas {
	$bitmap = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
	$graphics.Clear([System.Drawing.Color]::Transparent)
	return @($bitmap, $graphics)
}

function Fill-Rect($g, $x, $y, $w, $h, $color) {
	$brush = [System.Drawing.SolidBrush]::new($color)
	$g.FillRectangle($brush, $x, $y, $w, $h)
	$brush.Dispose()
}

function Stroke-Rect($g, $x, $y, $w, $h, $color, $size) {
	$pen = [System.Drawing.Pen]::new($color, $size)
	$g.DrawRectangle($pen, $x, $y, $w, $h)
	$pen.Dispose()
}

function Draw-Panel($g, $top, $mid, $bottom, $stroke, $shadow) {
	Fill-Rect $g 62 82 388 336 $shadow
	Fill-Rect $g 42 54 388 336 $mid
	Fill-Rect $g 42 54 388 86 $top
	Fill-Rect $g 42 332 388 58 $bottom
	Fill-Rect $g 66 76 340 28 ([System.Drawing.Color]::FromArgb(70, 255, 255, 255))
	Stroke-Rect $g 42 54 388 336 $stroke 18
	Stroke-Rect $g 62 74 348 296 ([System.Drawing.Color]::FromArgb(65, 0, 0, 0)) 4
}

function Draw-Text($g, $text, $y, $size, $fore, $outline) {
	$font = [System.Drawing.Font]::new("Consolas", $size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
	$format = [System.Drawing.StringFormat]::new()
	$format.Alignment = [System.Drawing.StringAlignment]::Center
	$format.LineAlignment = [System.Drawing.StringAlignment]::Center
	$outlineBrush = [System.Drawing.SolidBrush]::new($outline)
	$brush = [System.Drawing.SolidBrush]::new($fore)
	foreach ($offset in @(@(-4, 0), @(4, 0), @(0, -4), @(0, 4))) {
		$g.DrawString($text, $font, $outlineBrush, [System.Drawing.RectangleF]::new($offset[0], $y + $offset[1], 512, $size + 24), $format)
	}
	$g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new(0, $y, 512, $size + 24), $format)
	$brush.Dispose()
	$outlineBrush.Dispose()
	$format.Dispose()
	$font.Dispose()
}

function Draw-Label($g, $text) {
	Draw-Text $g $text 372 42 ([System.Drawing.Color]::White) ([System.Drawing.Color]::FromArgb(120, 20, 35, 55))
}

function Save-Icon($name, $draw) {
	$result = New-Canvas
	$bitmap = $result[0]
	$g = $result[1]
	& $draw $g
	$bitmap.Save((Join-Path $outDir "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
	$g.Dispose()
	$bitmap.Dispose()
}

Save-Icon "play" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(103, 237, 28)) ([System.Drawing.Color]::FromArgb(54, 174, 18)) ([System.Drawing.Color]::FromArgb(37, 121, 16)) ([System.Drawing.Color]::FromArgb(25, 92, 8)) ([System.Drawing.Color]::FromArgb(70, 11, 52, 8))
	Fill-Rect $g 176 152 56 192 ([System.Drawing.Color]::White)
	Fill-Rect $g 232 184 56 128 ([System.Drawing.Color]::White)
	Fill-Rect $g 288 216 56 64 ([System.Drawing.Color]::White)
	Stroke-Rect $g 168 144 72 208 ([System.Drawing.Color]::FromArgb(23, 88, 14)) 10
	Draw-Label $g "PLAY"
}

Save-Icon "shop" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(255, 177, 38)) ([System.Drawing.Color]::FromArgb(224, 104, 10)) ([System.Drawing.Color]::FromArgb(171, 73, 7)) ([System.Drawing.Color]::FromArgb(112, 54, 9)) ([System.Drawing.Color]::FromArgb(70, 83, 37, 4))
	Fill-Rect $g 150 184 212 138 ([System.Drawing.Color]::FromArgb(130, 72, 30))
	Fill-Rect $g 150 164 212 40 ([System.Drawing.Color]::FromArgb(244, 237, 215))
	Fill-Rect $g 150 164 42 40 ([System.Drawing.Color]::FromArgb(237, 54, 48))
	Fill-Rect $g 234 164 42 40 ([System.Drawing.Color]::FromArgb(237, 54, 48))
	Fill-Rect $g 318 164 44 40 ([System.Drawing.Color]::FromArgb(237, 54, 48))
	Fill-Rect $g 210 226 92 96 ([System.Drawing.Color]::FromArgb(255, 211, 87))
	Stroke-Rect $g 150 164 212 158 ([System.Drawing.Color]::FromArgb(79, 47, 20)) 10
	Draw-Label $g "SHOP"
}

Save-Icon "quests" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(44, 166, 255)) ([System.Drawing.Color]::FromArgb(19, 105, 211)) ([System.Drawing.Color]::FromArgb(12, 69, 151)) ([System.Drawing.Color]::FromArgb(7, 50, 116)) ([System.Drawing.Color]::FromArgb(70, 5, 35, 91))
	Fill-Rect $g 158 122 196 232 ([System.Drawing.Color]::FromArgb(237, 250, 255))
	Stroke-Rect $g 158 122 196 232 ([System.Drawing.Color]::FromArgb(18, 77, 139)) 12
	Fill-Rect $g 198 178 114 18 ([System.Drawing.Color]::FromArgb(42, 151, 255))
	Fill-Rect $g 198 232 114 18 ([System.Drawing.Color]::FromArgb(42, 151, 255))
	Fill-Rect $g 178 174 12 12 ([System.Drawing.Color]::FromArgb(255, 205, 61))
	Fill-Rect $g 178 228 12 12 ([System.Drawing.Color]::FromArgb(255, 205, 61))
	Fill-Rect $g 236 292 40 40 ([System.Drawing.Color]::FromArgb(255, 205, 61))
	Fill-Rect $g 220 308 72 12 ([System.Drawing.Color]::FromArgb(255, 205, 61))
	Fill-Rect $g 250 278 12 72 ([System.Drawing.Color]::FromArgb(255, 205, 61))
	Draw-Label $g "QUESTS"
}

Save-Icon "settings" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(113, 130, 148)) ([System.Drawing.Color]::FromArgb(58, 70, 86)) ([System.Drawing.Color]::FromArgb(36, 46, 60)) ([System.Drawing.Color]::FromArgb(20, 29, 41)) ([System.Drawing.Color]::FromArgb(70, 4, 9, 15))
	Fill-Rect $g 224 120 64 264 ([System.Drawing.Color]::White)
	Fill-Rect $g 124 220 264 64 ([System.Drawing.Color]::White)
	Fill-Rect $g 154 150 204 204 ([System.Drawing.Color]::White)
	Fill-Rect $g 198 194 116 116 ([System.Drawing.Color]::FromArgb(62, 76, 95))
	Fill-Rect $g 228 224 56 56 ([System.Drawing.Color]::FromArgb(30, 40, 56))
	Draw-Label $g "SET"
}

Save-Icon "coins" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(255, 218, 45)) ([System.Drawing.Color]::FromArgb(234, 153, 16)) ([System.Drawing.Color]::FromArgb(178, 95, 8)) ([System.Drawing.Color]::FromArgb(112, 66, 10)) ([System.Drawing.Color]::FromArgb(70, 79, 48, 4))
	Fill-Rect $g 160 150 192 192 ([System.Drawing.Color]::FromArgb(255, 224, 68))
	Stroke-Rect $g 160 150 192 192 ([System.Drawing.Color]::FromArgb(130, 82, 13)) 16
	Draw-Text $g "$" 176 120 ([System.Drawing.Color]::White) ([System.Drawing.Color]::FromArgb(126, 78, 8))
	Draw-Label $g "COINS"
}

Save-Icon "wins" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(255, 70, 62)) ([System.Drawing.Color]::FromArgb(204, 38, 32)) ([System.Drawing.Color]::FromArgb(137, 22, 23)) ([System.Drawing.Color]::FromArgb(88, 20, 20)) ([System.Drawing.Color]::FromArgb(70, 72, 7, 7))
	Fill-Rect $g 194 140 124 118 ([System.Drawing.Color]::FromArgb(255, 215, 62))
	Fill-Rect $g 170 172 40 74 ([System.Drawing.Color]::FromArgb(255, 215, 62))
	Fill-Rect $g 302 172 40 74 ([System.Drawing.Color]::FromArgb(255, 215, 62))
	Fill-Rect $g 230 258 52 74 ([System.Drawing.Color]::FromArgb(255, 215, 62))
	Fill-Rect $g 194 324 124 32 ([System.Drawing.Color]::FromArgb(255, 215, 62))
	Stroke-Rect $g 194 140 124 118 ([System.Drawing.Color]::FromArgb(111, 74, 7)) 12
	Draw-Label $g "WINS"
}

Save-Icon "story-stars" {
	param($g)
	Draw-Panel $g ([System.Drawing.Color]::FromArgb(177, 75, 255)) ([System.Drawing.Color]::FromArgb(105, 40, 211)) ([System.Drawing.Color]::FromArgb(69, 29, 146)) ([System.Drawing.Color]::FromArgb(47, 23, 104)) ([System.Drawing.Color]::FromArgb(70, 36, 8, 72))
	Fill-Rect $g 232 124 48 220 ([System.Drawing.Color]::FromArgb(255, 221, 47))
	Fill-Rect $g 148 200 216 48 ([System.Drawing.Color]::FromArgb(255, 221, 47))
	Fill-Rect $g 186 154 140 140 ([System.Drawing.Color]::FromArgb(255, 221, 47))
	Stroke-Rect $g 186 154 140 140 ([System.Drawing.Color]::FromArgb(113, 72, 10)) 12
	Draw-Label $g "STARS"
}

$sheet = [System.Drawing.Bitmap]::new(1540, 760, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$sg.Clear([System.Drawing.Color]::FromArgb(238, 247, 255))
$titleFont = [System.Drawing.Font]::new("Consolas", 38, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$labelFont = [System.Drawing.Font]::new("Consolas", 22, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$ink = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18, 38, 61))
$sg.DrawString("Chosen Direction B - Blocky Competitive HUD Icons", $titleFont, $ink, 42, 28)
$icons = @(
	@("play", "Play"),
	@("shop", "Shop"),
	@("quests", "Quests"),
	@("settings", "Settings"),
	@("coins", "Coins"),
	@("wins", "Wins"),
	@("story-stars", "StoryStars")
)
for ($i = 0; $i -lt $icons.Count; $i++) {
	$name = $icons[$i][0]
	$label = $icons[$i][1]
	$img = [System.Drawing.Image]::FromFile((Join-Path $outDir "$name.png"))
	$x = 52 + ($i % 4) * 360
	$y = 120 + [Math]::Floor($i / 4) * 300
	$sg.DrawImage($img, $x, $y, 220, 220)
	$sg.DrawString($label, $labelFont, $ink, $x + 18, $y + 232)
	$img.Dispose()
}
$previewPath = Join-Path $mockupDir "blocky-bedwars-icon-pack-preview.png"
$sheet.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
$ink.Dispose()
$labelFont.Dispose()
$titleFont.Dispose()
$sg.Dispose()
$sheet.Dispose()

Write-Host "Generated chosen B icon PNGs in $outDir"
Write-Host "Generated preview sheet at $previewPath"
