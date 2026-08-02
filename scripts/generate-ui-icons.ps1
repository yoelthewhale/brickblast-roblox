Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "assets\ui\icons"
$mockupDir = Join-Path $root "assets\ui\mockups"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $mockupDir | Out-Null

function New-Bitmap($width, $height) {
	$bitmap = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
	$graphics.Clear([System.Drawing.Color]::Transparent)
	return @($bitmap, $graphics)
}

function New-RoundRectPath($x, $y, $w, $h, $r) {
	$path = [System.Drawing.Drawing2D.GraphicsPath]::new()
	$d = $r * 2
	$path.AddArc($x, $y, $d, $d, 180, 90)
	$path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
	$path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
	$path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
	$path.CloseFigure()
	return $path
}

function Draw-Badge($g, $top, $bottom, $stroke) {
	$shadowPath = New-RoundRectPath 52 68 408 384 74
	$shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(72, 0, 41, 86))
	$g.FillPath($shadowBrush, $shadowPath)
	$shadowBrush.Dispose()
	$shadowPath.Dispose()

	$path = New-RoundRectPath 42 46 428 390 78
	$brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
		[System.Drawing.Rectangle]::new(42, 46, 428, 390),
		$top,
		$bottom,
		[System.Drawing.Drawing2D.LinearGradientMode]::Vertical
	)
	$g.FillPath($brush, $path)
	$brush.Dispose()

	$pen = [System.Drawing.Pen]::new($stroke, 16)
	$g.DrawPath($pen, $path)
	$pen.Dispose()

	$shine = New-RoundRectPath 78 72 356 96 42
	$shineBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(78, 255, 255, 255))
	$g.FillPath($shineBrush, $shine)
	$shineBrush.Dispose()
	$shine.Dispose()
	$path.Dispose()
}

function Draw-CenteredText($g, $text, $y, $size, $color) {
	$font = [System.Drawing.Font]::new("Arial", $size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
	$format = [System.Drawing.StringFormat]::new()
	$format.Alignment = [System.Drawing.StringAlignment]::Center
	$format.LineAlignment = [System.Drawing.StringAlignment]::Center
	$outline = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(160, 0, 50, 92))
	$brush = [System.Drawing.SolidBrush]::new($color)
	$rect = [System.Drawing.RectangleF]::new(0, $y, 512, $size + 32)
	foreach ($offset in @(@(-3,0), @(3,0), @(0,-3), @(0,3))) {
		$g.DrawString($text, $font, $outline, [System.Drawing.RectangleF]::new($offset[0], $y + $offset[1], 512, $size + 32), $format)
	}
	$g.DrawString($text, $font, $brush, $rect, $format)
	$brush.Dispose()
	$outline.Dispose()
	$format.Dispose()
	$font.Dispose()
}

function Draw-Star($g, $cx, $cy, $outer, $inner, $brush, $pen) {
	$points = [System.Drawing.PointF[]]::new(10)
	for ($i = 0; $i -lt 10; $i++) {
		$angle = (-90 + $i * 36) * [Math]::PI / 180
		$r = if ($i % 2 -eq 0) { $outer } else { $inner }
		$points[$i] = [System.Drawing.PointF]::new($cx + [Math]::Cos($angle) * $r, $cy + [Math]::Sin($angle) * $r)
	}
	$g.FillPolygon($brush, $points)
	$g.DrawPolygon($pen, $points)
}

function Save-Icon($name, $draw) {
	$result = New-Bitmap 512 512
	$bitmap = $result[0]
	$g = $result[1]
	& $draw $g
	$path = Join-Path $outDir "$name.png"
	$bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
	$g.Dispose()
	$bitmap.Dispose()
}

Save-Icon "play" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(112, 255, 119)) ([System.Drawing.Color]::FromArgb(27, 188, 67)) ([System.Drawing.Color]::FromArgb(18, 129, 48))
	$tri = [System.Drawing.PointF[]]@(
		[System.Drawing.PointF]::new(210, 152),
		[System.Drawing.PointF]::new(210, 344),
		[System.Drawing.PointF]::new(356, 248)
	)
	$white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
	$outline = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(38, 126, 43), 18)
	$g.FillPolygon($white, $tri)
	$g.DrawPolygon($outline, $tri)
	$white.Dispose()
	$outline.Dispose()
	Draw-CenteredText $g "PLAY" 352 56 ([System.Drawing.Color]::White)
}

Save-Icon "shop" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(255, 226, 83)) ([System.Drawing.Color]::FromArgb(245, 143, 28)) ([System.Drawing.Color]::FromArgb(157, 90, 12))
	$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(97, 56, 17), 18)
	$brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 247, 178))
	$g.FillRectangle($brush, 142, 192, 228, 130)
	$g.DrawRectangle($pen, 142, 192, 228, 130)
	$g.DrawArc($pen, 176, 122, 160, 140, 200, 140)
	$g.FillEllipse([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(87, 204, 255)), 216, 222, 80, 80)
	$brush.Dispose()
	$pen.Dispose()
	Draw-CenteredText $g "SHOP" 344 48 ([System.Drawing.Color]::White)
}

Save-Icon "quests" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(90, 210, 255)) ([System.Drawing.Color]::FromArgb(36, 116, 238)) ([System.Drawing.Color]::FromArgb(14, 73, 162))
	$paper = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235, 250, 255))
	$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(17, 84, 156), 14)
	$g.FillRectangle($paper, 150, 112, 212, 250)
	$g.DrawRectangle($pen, 150, 112, 212, 250)
	$linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(49, 144, 255), 12)
	$g.DrawLine($linePen, 190, 190, 322, 190)
	$g.DrawLine($linePen, 190, 246, 322, 246)
	$starBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 221, 75))
	$starPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(181, 110, 16), 8)
	Draw-Star $g 256 330 54 24 $starBrush $starPen
	$paper.Dispose()
	$pen.Dispose()
	$linePen.Dispose()
	$starBrush.Dispose()
	$starPen.Dispose()
	Draw-CenteredText $g "QUESTS" 372 38 ([System.Drawing.Color]::White)
}

Save-Icon "settings" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(188, 200, 214)) ([System.Drawing.Color]::FromArgb(86, 99, 116)) ([System.Drawing.Color]::FromArgb(47, 58, 74))
	$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 28)
	$g.DrawEllipse($pen, 162, 158, 188, 188)
	for ($i = 0; $i -lt 8; $i++) {
		$angle = $i * [Math]::PI / 4
		$x1 = 256 + [Math]::Cos($angle) * 64
		$y1 = 252 + [Math]::Sin($angle) * 64
		$x2 = 256 + [Math]::Cos($angle) * 116
		$y2 = 252 + [Math]::Sin($angle) * 116
		$g.DrawLine($pen, [float]$x1, [float]$y1, [float]$x2, [float]$y2)
	}
	$dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(92, 107, 128))
	$g.FillEllipse($dark, 224, 220, 64, 64)
	$pen.Dispose()
	$dark.Dispose()
	Draw-CenteredText $g "SET" 362 46 ([System.Drawing.Color]::White)
}

Save-Icon "coins" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(255, 224, 75)) ([System.Drawing.Color]::FromArgb(235, 151, 23)) ([System.Drawing.Color]::FromArgb(143, 86, 11))
	$coin = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 237, 91))
	$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(169, 102, 13), 18)
	$g.FillEllipse($coin, 132, 116, 248, 248)
	$g.DrawEllipse($pen, 132, 116, 248, 248)
	Draw-CenteredText $g "$" 140 154 ([System.Drawing.Color]::White)
	$coin.Dispose()
	$pen.Dispose()
	Draw-CenteredText $g "COINS" 362 42 ([System.Drawing.Color]::White)
}

Save-Icon "wins" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(103, 244, 128)) ([System.Drawing.Color]::FromArgb(29, 177, 82)) ([System.Drawing.Color]::FromArgb(18, 112, 56))
	$gold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 222, 79))
	$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(121, 91, 12), 14)
	$g.FillRectangle($gold, 204, 284, 104, 36)
	$g.FillRectangle($gold, 184, 320, 144, 38)
	$g.FillEllipse($gold, 166, 112, 180, 174)
	$g.DrawEllipse($pen, 166, 112, 180, 174)
	$g.DrawArc($pen, 118, 148, 96, 110, 100, 165)
	$g.DrawArc($pen, 298, 148, 96, 110, -85, 165)
	$gold.Dispose()
	$pen.Dispose()
	Draw-CenteredText $g "WINS" 366 44 ([System.Drawing.Color]::White)
}

Save-Icon "story-stars" {
	param($g)
	Draw-Badge $g ([System.Drawing.Color]::FromArgb(212, 122, 255)) ([System.Drawing.Color]::FromArgb(108, 80, 229)) ([System.Drawing.Color]::FromArgb(73, 45, 151))
	$starBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 232, 88))
	$starPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(143, 84, 15), 18)
	Draw-Star $g 256 238 138 62 $starBrush $starPen
	$starBrush.Dispose()
	$starPen.Dispose()
	Draw-CenteredText $g "STARS" 370 42 ([System.Drawing.Color]::White)
}

$sheetResult = New-Bitmap 1400 760
$sheet = $sheetResult[0]
$sg = $sheetResult[1]
$sg.Clear([System.Drawing.Color]::FromArgb(245, 250, 255))
$titleFont = [System.Drawing.Font]::new("Arial", 42, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$bodyFont = [System.Drawing.Font]::new("Arial", 24, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$black = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(25, 45, 70))
$sg.DrawString("Block Blast Battle - Free HUD Icon Upload Pack", $titleFont, $black, 40, 28)

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
	$x = 60 + ($i % 4) * 330
	$y = 120 + [Math]::Floor($i / 4) * 300
	$sg.DrawImage($img, $x, $y, 210, 210)
	$sg.DrawString($label, $bodyFont, $black, $x + 20, $y + 220)
	$img.Dispose()
}

$sheetPath = Join-Path $mockupDir "hud-icon-upload-pack-preview.png"
$sheet.Save($sheetPath, [System.Drawing.Imaging.ImageFormat]::Png)
$black.Dispose()
$bodyFont.Dispose()
$titleFont.Dispose()
$sg.Dispose()
$sheet.Dispose()

Write-Host "Generated HUD icon PNGs in $outDir"
Write-Host "Generated preview sheet at $sheetPath"
