from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "ui" / "mockups" / "design-approval"
BACKGROUND = Path(
    r"C:\Users\Bear4\AppData\Local\Temp\codex-clipboard-b7dae7ea-fcb0-4587-91b1-6a946bd1a830.png"
)

W, H = 1920, 1080
MW, MH = 1080, 1920

FONT_DIR = Path(r"C:\Windows\Fonts")


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    candidates = {
        "black": ["arialbd.ttf", "segoeuib.ttf", "arial.ttf"],
        "bold": ["segoeuib.ttf", "arialbd.ttf", "arial.ttf"],
        "body": ["segoeui.ttf", "arial.ttf"],
    }
    for filename in candidates[name]:
        path = FONT_DIR / filename
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


FONTS = {
    "title56": font("black", 56),
    "title44": font("black", 44),
    "title36": font("black", 36),
    "title30": font("black", 30),
    "bold28": font("bold", 28),
    "bold24": font("bold", 24),
    "bold22": font("bold", 22),
    "bold20": font("bold", 20),
    "bold18": font("bold", 18),
    "bold16": font("bold", 16),
    "body24": font("body", 24),
    "body20": font("body", 20),
    "body18": font("body", 18),
    "body16": font("body", 16),
    "body14": font("body", 14),
}


SPECS = {
    "B1": {
        "name": "Blocky Competitive",
        "palette": {
            "navy": "#101827",
            "charcoal": "#182235",
            "blue": "#1EA7FF",
            "blueDeep": "#0D5EEB",
            "gold": "#F5B83E",
            "green": "#36D96A",
            "danger": "#F04E66",
            "text": "#F7FBFF",
        },
        "font": "GothamBlack for titles, GothamBold for buttons/stats, Gotham for body.",
        "corner": "10-14 px cards; 18 px primary action; small pills for stats.",
        "stroke": "2-4 px crisp dark outlines with electric-blue selected strokes.",
        "shadow": "Offset charcoal shadows at 28-36% opacity, no soft muddy glow.",
        "spacing": "8 / 12 / 16 / 24 / 32 px scale.",
        "button": "Chunky rectangular buttons, beveled top highlight, compressed pressed state.",
        "panel": "Navy/charcoal layered panels with gold reward chips and blue action rails.",
        "icon": "White chunky silhouettes in navy tiles, one perspective, heavy readable shapes.",
        "desktop_mobile": "Desktop keeps nav on the left and match panel on right; mobile collapses to bottom dock plus top resources.",
        "benefit": "Most competitive and readable, preserves a lot of gameplay visibility.",
        "tradeoff": "Less playful than arcade and needs careful art direction so it does not feel too serious.",
    },
    "B2": {
        "name": "Polished Arcade",
        "palette": {
            "ink": "#172039",
            "sky": "#1EBBFF",
            "cyan": "#6EF4FF",
            "lime": "#7BED4B",
            "pink": "#FF5DC8",
            "gold": "#FFD247",
            "orange": "#FF8B3D",
            "text": "#FFFFFF",
        },
        "font": "GothamBlack for playful headers, GothamBold for buttons, Gotham for helper text.",
        "corner": "14-20 px buttons; 16 px cards; circular icon badges.",
        "stroke": "3 px dark structural strokes; 2 px inner bright highlight strokes.",
        "shadow": "Layered hard arcade shadows plus subtle white top highlights.",
        "spacing": "10 / 14 / 18 / 28 / 36 px scale.",
        "button": "Dimensional puzzle-color buttons with clear selected, hover, locked, and disabled states.",
        "panel": "Bright blue shop/play cards inside dark frame; rewards separate from nav.",
        "icon": "Chunky toy-like silhouettes, simple fill shapes, no tiny details.",
        "desktop_mobile": "Desktop uses left island nav and right shop panel; mobile turns nav into thumb-safe bottom tabs.",
        "benefit": "Strongest Block Blast identity and most front-page-friendly energy.",
        "tradeoff": "More visual weight; must be tuned so it does not crowd smaller screens.",
    },
    "B3": {
        "name": "Clean Block Tech",
        "palette": {
            "glass": "#07111F",
            "panel": "#111A2C",
            "line": "#3847FF",
            "violet": "#8E5CFF",
            "cyan": "#31D7FF",
            "gold": "#E7C15B",
            "success": "#28E08F",
            "text": "#F4F8FF",
        },
        "font": "GothamBold/GothamMedium feeling for tight labels, GothamBlack only for key headings.",
        "corner": "8-12 px compact cards; 999 px small status pills.",
        "stroke": "1-2 px translucent blue/purple strokes; selected state adds a bright left rail.",
        "shadow": "Soft glass shadows, low opacity, minimal glow.",
        "spacing": "6 / 10 / 14 / 20 / 28 px scale.",
        "button": "Compact translucent controls, clear keyboard/gamepad focus rings, minimal hover lift.",
        "panel": "Dark glass panels with geometric separators and small reward chips.",
        "icon": "Solid geometric block symbols, white/cyan, compact and monochrome-friendly.",
        "desktop_mobile": "Desktop HUD hugs edges; mobile shows only top stats, bottom quick actions, and one focused sheet.",
        "benefit": "Best gameplay visibility and premium feel.",
        "tradeoff": "Less playful and may need stronger block identity elsewhere in the map/art.",
    },
}


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.strip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def bg(size: tuple[int, int]) -> Image.Image:
	source = Image.open(BACKGROUND).convert("RGBA")
	sw, sh = source.size
	tw, th = size
	scale = max(tw / sw, th / sh)
	resized = source.resize((math.ceil(sw * scale), math.ceil(sh * scale)), Image.LANCZOS)
	left = (resized.width - tw) // 2
	top = (resized.height - th) // 2
	image = resized.crop((left, top, left + tw, top + th))
	image = image.filter(ImageFilter.GaussianBlur(14))
	wash = Image.new("RGBA", size, (32, 46, 64, 172))
	image = Image.alpha_composite(image, wash)

	# Rebuild a clean neutral gameplay backdrop over the screenshot-derived color
	# field so rejected/current UI does not appear as a second interface.
	d = ImageDraw.Draw(image, "RGBA")
	for y in range(th):
		t = y / th
		if t < 0.48:
			r = int(84 + (38 * t))
			g = int(183 + (26 * t))
			b = int(238 + (10 * t))
			d.line((0, y, tw, y), fill=(r, g, b, 235))
		else:
			r = int(62 - (14 * (t - 0.48)))
			g = int(145 - (42 * (t - 0.48)))
			b = int(95 - (26 * (t - 0.48)))
			d.line((0, y, tw, y), fill=(r, g, b, 220))

	horizon = int(th * 0.47)
	d.rectangle((0, horizon, tw, horizon + int(th * 0.03)), fill=(78, 186, 128, 230))
	platform = [
		(int(tw * 0.05), int(th * 0.88)),
		(int(tw * 0.28), int(th * 0.54)),
		(int(tw * 0.74), int(th * 0.54)),
		(int(tw * 0.95), int(th * 0.88)),
	]
	d.polygon(platform, fill=(128, 143, 130, 245))
	d.line(platform + [platform[0]], fill=(83, 96, 84, 255), width=max(4, tw // 270))

	path = [
		(int(tw * 0.44), int(th * 0.88)),
		(int(tw * 0.48), int(th * 0.56)),
		(int(tw * 0.58), int(th * 0.56)),
		(int(tw * 0.66), int(th * 0.88)),
	]
	d.polygon(path, fill=(70, 215, 242, 220))
	for i in range(12):
		x = int(tw * (0.1 + i * 0.075))
		d.line((x, int(th * 0.57), x - int(tw * 0.04), int(th * 0.86)), fill=(97, 110, 101, 100), width=2)
	for i in range(9):
		y = int(th * (0.58 + i * 0.035))
		d.line((int(tw * 0.16), y, int(tw * 0.86), y + int(th * 0.02)), fill=(92, 105, 96, 80), width=2)

	for x, y, color in [
		(0.30, 0.50, (26, 116, 210, 255)),
		(0.70, 0.50, (144, 85, 222, 255)),
		(0.53, 0.49, (245, 198, 70, 255)),
	]:
		cx, cy = int(tw * x), int(th * y)
		d.rounded_rectangle((cx - 34, cy - 20, cx + 34, cy + 20), 8, fill=color)
		d.rectangle((cx - 34, cy + 16, cx + 34, cy + 24), fill=(0, 0, 0, 46))

	# Simple player silhouette to keep the mockups feeling in-game without
	# depending on unreadable old UI from the screenshot.
	px, py = int(tw * 0.50), int(th * 0.63)
	d.ellipse((px - 44, py - 12, px + 44, py + 18), fill=(0, 0, 0, 55))
	d.ellipse((px - 24, py - 104, px + 24, py - 56), fill=(42, 32, 28, 255))
	d.rounded_rectangle((px - 36, py - 58, px + 36, py + 28), 18, fill=(28, 32, 39, 255))
	d.rounded_rectangle((px - 62, py - 42, px - 34, py + 16), 12, fill=(40, 45, 54, 255))
	d.rounded_rectangle((px + 34, py - 42, px + 62, py + 16), 12, fill=(40, 45, 54, 255))
	d.rounded_rectangle((px - 34, py + 22, px - 6, py + 100), 12, fill=(70, 92, 118, 255))
	d.rounded_rectangle((px + 6, py + 22, px + 34, py + 100), 12, fill=(70, 92, 118, 255))
	return image


def draw_shadow(draw: ImageDraw.ImageDraw, rect, radius, offset=(0, 8), alpha=80):
    x1, y1, x2, y2 = rect
    ox, oy = offset
    draw.rounded_rectangle((x1 + ox, y1 + oy, x2 + ox, y2 + oy), radius, fill=(0, 0, 0, alpha))


def panel(draw, rect, fill, outline, radius=16, width=3, shadow=True):
    if shadow:
        draw_shadow(draw, rect, radius)
    draw.rounded_rectangle(rect, radius, fill=fill, outline=outline, width=width)


def pill(draw, rect, fill, outline=None, width=2):
    radius = (rect[3] - rect[1]) // 2
    draw.rounded_rectangle(rect, radius, fill=fill, outline=outline, width=width if outline else 1)


def centered(draw, rect, text, font_obj, fill):
    box = draw.textbbox((0, 0), text, font=font_obj)
    x = rect[0] + ((rect[2] - rect[0]) - (box[2] - box[0])) / 2
    y = rect[1] + ((rect[3] - rect[1]) - (box[3] - box[1])) / 2 - 2
    draw.text((x, y), text, font=font_obj, fill=fill)


def text(draw, xy, content, key, fill, anchor=None):
    draw.text(xy, content, font=FONTS[key], fill=fill, anchor=anchor)


def wrap(draw, content, key, max_width):
    words = content.split()
    lines = []
    current = ""
    f = FONTS[key]
    for word in words:
        test = word if not current else current + " " + word
        if draw.textlength(test, font=f) <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def icon(draw, cx, cy, kind, color, scale=1.0):
    s = int(18 * scale)
    if kind == "play":
        draw.polygon([(cx - s // 2, cy - s), (cx - s // 2, cy + s), (cx + s, cy)], fill=color)
    elif kind == "shop":
        draw.rectangle((cx - s, cy - 3, cx + s, cy + s), fill=color)
        draw.arc((cx - s, cy - s, cx + s, cy + s), 205, 335, fill=color, width=max(2, s // 5))
    elif kind == "quest":
        draw.rounded_rectangle((cx - s, cy - s, cx + s, cy + s), 4, outline=color, width=max(3, s // 4))
        draw.line((cx - s // 2, cy, cx - s // 5, cy + s // 3, cx + s // 2, cy - s // 2), fill=color, width=4)
    elif kind == "settings":
        draw.ellipse((cx - s, cy - s, cx + s, cy + s), outline=color, width=5)
        draw.ellipse((cx - s // 3, cy - s // 3, cx + s // 3, cy + s // 3), fill=color)
    elif kind == "coins":
        draw.ellipse((cx - s, cy - s // 2, cx + s, cy + s // 2), fill=color)
        draw.rectangle((cx - s, cy - s // 2, cx + s, cy + s // 2), outline=(0, 0, 0, 60), width=1)
    elif kind == "wins":
        draw.polygon([(cx - s, cy - s), (cx + s, cy - s), (cx + s // 2, cy + s), (cx - s // 2, cy + s)], fill=color)
    else:
        draw.rectangle((cx - s, cy - s, cx + s, cy + s), fill=color)


def resource_bar(draw, x, y, style):
    if style == "B1":
        fill, outline = rgba("#101827", 230), rgba("#1EA7FF")
        chips = [
            ("LV 8", "#1EA7FF"),
            ("XP 62%", "#36D96A"),
            ("3,440", "#F5B83E"),
            ("12 Wins", "#F7FBFF"),
            ("7 Stars", "#8E5CFF"),
        ]
        chip_fill = rgba("#182235", 245)
    elif style == "B2":
        fill, outline = rgba("#172039", 235), rgba("#1EBBFF")
        chips = [
            ("LV 8", "#6EF4FF"),
            ("XP 62%", "#7BED4B"),
            ("3,440 Coins", "#FFD247"),
            ("12 Wins", "#FFFFFF"),
            ("7 Stars", "#FF5DC8"),
        ]
        chip_fill = rgba("#172039", 245)
    else:
        fill, outline = rgba("#07111F", 205), rgba("#3847FF", 210)
        chips = [
            ("LV 8", "#31D7FF"),
            ("XP 62%", "#28E08F"),
            ("3,440", "#E7C15B"),
            ("12W", "#F4F8FF"),
            ("7S", "#8E5CFF"),
        ]
        chip_fill = rgba("#111A2C", 230)
    panel(draw, (x, y, x + 760, y + 62), fill, outline, radius=18, width=2, shadow=False)
    cx = x + 22
    for label, color in chips:
        w = int(draw.textlength(label, font=FONTS["bold20"])) + 42
        pill(draw, (cx, y + 11, cx + w, y + 51), chip_fill, rgba(color, 235), 2)
        icon(draw, cx + 20, y + 31, "coins", rgba(color), 0.5)
        text(draw, (cx + 38, y + 18), label, "bold20", rgba("#FFFFFF"))
        cx += w + 12


def nav_button(draw, rect, label, kind, palette, state="normal", compact=False):
    x1, y1, x2, y2 = rect
    selected = state == "selected"
    hover = state == "hover"
    locked = state == "locked"
    disabled = state == "disabled"
    fill = palette["selected"] if selected else palette["button"]
    if hover:
        fill = palette["hover"]
    if locked or disabled:
        fill = palette["disabled"]
    outline = palette["accent"] if selected or hover else palette["outline"]
    panel(draw, rect, fill, outline, radius=14, width=3 if selected else 2, shadow=not compact)
    icon_color = palette["gold"] if selected else rgba("#FFFFFF", 235 if not disabled else 120)
    icon(draw, x1 + 32, (y1 + y2) // 2, kind, icon_color, 0.8)
    if not compact:
        text(draw, (x1 + 64, y1 + 16), label, "bold20", rgba("#FFFFFF", 235 if not disabled else 120))
    if locked:
        centered(draw, (x2 - 76, y1 + 14, x2 - 16, y2 - 14), "LOCK", FONTS["bold14"], rgba("#FFFFFF", 150))


def play_action(draw, rect, title, subtitle, palette, arcade=False):
    panel(draw, rect, palette["play"], palette["playOutline"], radius=22, width=4)
    x1, y1, x2, y2 = rect
    draw.rounded_rectangle((x1 + 8, y1 + 8, x2 - 8, y1 + 24), 10, fill=rgba("#FFFFFF", 42))
    icon(draw, x1 + 52, (y1 + y2) // 2, "play", rgba("#FFFFFF"), 1.05)
    title_key = "title36" if arcade and (x2 - x1) > 520 else "title30"
    text(draw, (x1 + 92, y1 + 28), title, title_key, rgba("#FFFFFF"))
    text(draw, (x1 + 94, y1 + 76), subtitle, "bold18", rgba("#FFFFFF", 220))


def draw_menu_panel(draw, rect, title_text, palette, rows):
    panel(draw, rect, palette["panel"], palette["outline"], radius=20, width=3)
    x1, y1, x2, y2 = rect
    text(draw, (x1 + 28, y1 + 22), title_text, "title36", rgba("#FFFFFF"))
    panel(draw, (x2 - 70, y1 + 18, x2 - 24, y1 + 64), palette["close"], palette["closeOutline"], radius=12, width=3, shadow=False)
    centered(draw, (x2 - 70, y1 + 18, x2 - 24, y1 + 64), "X", FONTS["title30"], rgba("#FFFFFF"))
    y = y1 + 86
    for row in rows:
        state = row.get("state", "normal")
        fill = palette["card"]
        outline = palette["accent"] if state == "selected" else palette["outline"]
        if state == "locked":
            fill = palette["disabled"]
        panel(draw, (x1 + 24, y, x2 - 24, y + 92), fill, outline, radius=16, width=3 if state == "selected" else 2, shadow=False)
        icon(draw, x1 + 64, y + 46, row["icon"], palette.get("gold", rgba("#F5B83E")), 0.9)
        text(draw, (x1 + 104, y + 18), row["title"], "bold24", rgba("#FFFFFF", 235 if state != "locked" else 140))
        text(draw, (x1 + 104, y + 52), row["body"], "body18", rgba("#D8E5FF", 220 if state != "locked" else 120))
        if state == "hover":
            panel(draw, (x2 - 150, y + 24, x2 - 46, y + 68), palette["hover"], palette["accent"], radius=12, width=2, shadow=False)
            centered(draw, (x2 - 150, y + 24, x2 - 46, y + 68), "HOVER", FONTS["bold16"], rgba("#FFFFFF"))
        elif state == "locked":
            panel(draw, (x2 - 150, y + 24, x2 - 46, y + 68), palette["disabled"], palette["outline"], radius=12, width=2, shadow=False)
            centered(draw, (x2 - 150, y + 24, x2 - 46, y + 68), "LOCKED", FONTS["bold16"], rgba("#FFFFFF", 145))
        y += 112


def b1_desktop():
    im = bg((W, H))
    d = ImageDraw.Draw(im, "RGBA")
    pal = {
        "panel": rgba("#101827", 235),
        "card": rgba("#182235", 242),
        "button": rgba("#182235", 235),
        "selected": rgba("#0D5EEB", 242),
        "hover": rgba("#1EA7FF", 235),
        "disabled": rgba("#3A4355", 205),
        "outline": rgba("#32435F", 230),
        "accent": rgba("#1EA7FF"),
        "gold": rgba("#F5B83E"),
        "play": rgba("#0D5EEB", 245),
        "playOutline": rgba("#79D8FF"),
        "close": rgba("#F04E66"),
        "closeOutline": rgba("#801B2B"),
    }
    resource_bar(d, 580, 30, "B1")
    panel(d, (28, 116, 320, 324), pal["panel"], pal["accent"], 18, 3)
    text(d, (56, 140), "CAPTINNINJATACO", "bold22", rgba("#FFFFFF"))
    text(d, (56, 176), "Level 8  |  620 / 1000 XP", "body18", rgba("#D8E5FF"))
    pill(d, (56, 212, 286, 232), rgba("#0B1322"), rgba("#1EA7FF"), 2)
    pill(d, (58, 214, 204, 230), rgba("#36D96A"), None)
    text(d, (56, 256), "Status: Floating Hub", "bold18", rgba("#F5B83E"))
    text(d, (56, 286), "Queue pads are ahead", "body16", rgba("#D8E5FF", 210))
    nav_y = 356
    for label, kind, state in [("Battle", "play", "selected"), ("Shop", "shop", "hover"), ("Quests", "quest", "normal"), ("Settings", "settings", "normal")]:
        nav_button(d, (28, nav_y, 292, nav_y + 70), label, kind, pal, state)
        nav_y += 84
    play_action(d, (650, 902, 1270, 1010), "BATTLE QUEUE", "2 players needed  |  Casual arena open", pal)
    draw_menu_panel(d, (1320, 190, 1868, 788), "Modes", pal, [
        {"title": "Battle Arena", "body": "Queue for score pressure rounds", "icon": "play", "state": "selected"},
        {"title": "Custom Lab", "body": "Rotate and tune block pieces", "icon": "settings", "state": "hover"},
        {"title": "Ranked", "body": "Coming after balancing", "icon": "wins", "state": "locked"},
        {"title": "Story", "body": "Solo puzzle chapters", "icon": "quest", "state": "normal"},
    ])
    text(d, (36, 38), "Block Blast Battle", "title36", rgba("#FFFFFF"))
    return im


def b2_desktop():
    im = bg((W, H))
    d = ImageDraw.Draw(im, "RGBA")
    pal = {
        "panel": rgba("#172039", 238),
        "card": rgba("#1EBBFF", 238),
        "button": rgba("#172039", 235),
        "selected": rgba("#FF5DC8", 245),
        "hover": rgba("#7BED4B", 245),
        "disabled": rgba("#576070", 210),
        "outline": rgba("#071022", 245),
        "accent": rgba("#6EF4FF"),
        "gold": rgba("#FFD247"),
        "play": rgba("#7BED4B", 250),
        "playOutline": rgba("#0F6D2E"),
        "close": rgba("#FF4D5F"),
        "closeOutline": rgba("#7E1422"),
    }
    resource_bar(d, 500, 28, "B2")
    panel(d, (34, 148, 156, 610), rgba("#172039", 235), rgba("#1EBBFF"), 22, 4)
    items = [("Battle", "play", "selected"), ("Shop", "shop", "hover"), ("Quests", "quest", "normal"), ("Settings", "settings", "normal")]
    y = 174
    for label, kind, state in items:
        nav_button(d, (52, y, 138, y + 82), "", kind, pal, state, compact=True)
        y += 104
    play_action(d, (650, 872, 1270, 1016), "PLAY BATTLE!", "Fast puzzle combat  |  Rewards ready", pal, arcade=True)
    draw_menu_panel(d, (462, 168, 1458, 822), "Shop", pal, [
        {"title": "Featured Bundle", "body": "Bright block trail + reward boost", "icon": "shop", "state": "selected"},
        {"title": "VIP Pass", "body": "Gold nameplate and daily bonus", "icon": "wins", "state": "hover"},
        {"title": "Deluxe Cosmetics", "body": "Requires Creator Dashboard ID", "icon": "settings", "state": "locked"},
        {"title": "Coins Pack", "body": "Server receipt required", "icon": "coins", "state": "normal"},
    ])
    for i, (label, color) in enumerate([("Daily", "#FFD247"), ("Rewards", "#FF8B3D"), ("Codes", "#1EBBFF")]):
        panel(d, (1520, 210 + i * 118, 1830, 300 + i * 118), rgba(color, 225), rgba("#172039"), 18, 4)
        text(d, (1550, 230 + i * 118), label, "bold28", rgba("#FFFFFF"))
        text(d, (1550, 268 + i * 118), "Coming soon state shown", "body18", rgba("#172039"))
    text(d, (44, 50), "Block Blast Battle", "title44", rgba("#FFFFFF"))
    text(d, (46, 100), "Puzzle islands await", "bold20", rgba("#6EF4FF"))
    return im


def b3_desktop():
    im = bg((W, H))
    d = ImageDraw.Draw(im, "RGBA")
    pal = {
        "panel": rgba("#07111F", 212),
        "card": rgba("#111A2C", 220),
        "button": rgba("#111A2C", 205),
        "selected": rgba("#172A58", 235),
        "hover": rgba("#24376A", 235),
        "disabled": rgba("#202734", 180),
        "outline": rgba("#3E4A7A", 170),
        "accent": rgba("#31D7FF"),
        "gold": rgba("#E7C15B"),
        "play": rgba("#131F46", 235),
        "playOutline": rgba("#31D7FF"),
        "close": rgba("#411B39", 235),
        "closeOutline": rgba("#8E5CFF"),
    }
    resource_bar(d, 610, 24, "B3")
    panel(d, (28, 148, 124, 536), pal["panel"], pal["outline"], 14, 2)
    y = 168
    for label, kind, state in [("", "play", "selected"), ("", "shop", "normal"), ("", "quest", "normal"), ("", "settings", "hover")]:
        nav_button(d, (44, y, 108, y + 64), label, kind, pal, state, compact=True)
        y += 86
    panel(d, (148, 148, 418, 298), pal["panel"], pal["accent"], 14, 2)
    text(d, (172, 170), "Hub Status", "bold24", rgba("#FFFFFF"))
    text(d, (172, 212), "Battle queue open", "body18", rgba("#D8E5FF"))
    text(d, (172, 244), "Story portal unlocked", "body18", rgba("#8E5CFF"))
    play_action(d, (148, 874, 560, 972), "PLAY", "Battle queue", pal)
    draw_menu_panel(d, (1280, 160, 1858, 722), "Settings", pal, [
        {"title": "Graphics", "body": "Balanced visual quality", "icon": "settings", "state": "selected"},
        {"title": "Reduced Motion", "body": "Off  -  hover state preview", "icon": "settings", "state": "hover"},
        {"title": "Gamepad Focus", "body": "Navigation ring enabled", "icon": "play", "state": "normal"},
        {"title": "Ranked Alerts", "body": "Locked until ranked opens", "icon": "quest", "state": "locked"},
    ])
    text(d, (36, 48), "BLOCK BLAST", "title36", rgba("#FFFFFF"))
    text(d, (37, 86), "BATTLE", "bold24", rgba("#31D7FF"))
    return im


def mobile(option: str):
    image = bg((MW, MH))
    d = ImageDraw.Draw(image, "RGBA")
    spec = SPECS[option]
    colors = spec["palette"]
    if option == "B1":
        pal = {
            "panel": rgba("#101827", 238),
            "card": rgba("#182235", 238),
            "button": rgba("#182235", 235),
            "selected": rgba("#0D5EEB", 245),
            "hover": rgba("#1EA7FF", 235),
            "disabled": rgba("#3A4355", 205),
            "outline": rgba("#32435F", 230),
            "accent": rgba("#1EA7FF"),
            "gold": rgba("#F5B83E"),
            "play": rgba("#0D5EEB", 245),
            "playOutline": rgba("#79D8FF"),
            "close": rgba("#F04E66"),
            "closeOutline": rgba("#801B2B"),
        }
    elif option == "B2":
        pal = {
            "panel": rgba("#172039", 238),
            "card": rgba("#1EBBFF", 238),
            "button": rgba("#172039", 235),
            "selected": rgba("#FF5DC8", 245),
            "hover": rgba("#7BED4B", 245),
            "disabled": rgba("#576070", 210),
            "outline": rgba("#071022", 245),
            "accent": rgba("#6EF4FF"),
            "gold": rgba("#FFD247"),
            "play": rgba("#7BED4B", 250),
            "playOutline": rgba("#0F6D2E"),
            "close": rgba("#FF4D5F"),
            "closeOutline": rgba("#7E1422"),
        }
    else:
        pal = {
            "panel": rgba("#07111F", 212),
            "card": rgba("#111A2C", 220),
            "button": rgba("#111A2C", 205),
            "selected": rgba("#172A58", 235),
            "hover": rgba("#24376A", 235),
            "disabled": rgba("#202734", 180),
            "outline": rgba("#3E4A7A", 170),
            "accent": rgba("#31D7FF"),
            "gold": rgba("#E7C15B"),
            "play": rgba("#131F46", 235),
            "playOutline": rgba("#31D7FF"),
            "close": rgba("#411B39", 235),
            "closeOutline": rgba("#8E5CFF"),
        }
    text(d, (42, 58), f"{option} Mobile", "title36", rgba("#FFFFFF"))
    resource_bar(d, 42, 120, option)
    play_action(d, (82, 1370, 998, 1502), "PLAY BATTLE", "Thumb-safe primary action", pal, arcade=option == "B2")
    panel(d, (58, 340, 1022, 1018), pal["panel"], pal["accent"], 22, 3)
    text(d, (96, 380), "Shop Preview" if option == "B2" else "Modes Preview", "title36", rgba("#FFFFFF"))
    rows = [
        {"title": "Battle Arena", "body": "Selected state", "icon": "play", "state": "selected"},
        {"title": "Quests", "body": "Hover/focus state", "icon": "quest", "state": "hover"},
        {"title": "Ranked", "body": "Locked state", "icon": "wins", "state": "locked"},
    ]
    y = 460
    for row in rows:
        panel(d, (96, y, 984, y + 130), pal["card"] if row["state"] != "locked" else pal["disabled"], pal["accent"] if row["state"] != "locked" else pal["outline"], 18, 3, shadow=False)
        icon(d, 146, y + 65, row["icon"], pal["gold"], 1.0)
        text(d, (198, y + 30), row["title"], "bold28", rgba("#FFFFFF", 235 if row["state"] != "locked" else 140))
        text(d, (198, y + 76), row["body"], "body20", rgba("#D8E5FF", 220 if row["state"] != "locked" else 125))
        y += 158
    panel(d, (58, 1608, 1022, 1732), pal["panel"], pal["outline"], 24, 2)
    navs = [("Play", "play", "selected"), ("Shop", "shop", "normal"), ("Quests", "quest", "normal"), ("Settings", "settings", "normal")]
    x = 92
    for label, kind, state in navs:
        nav_button(d, (x, 1634, x + 190, 1708), label, kind, pal, state, compact=True)
        text(d, (x + 95, 1714), label, "bold16", rgba("#FFFFFF"), anchor="ma")
        x += 232
    return image


def comparison(images: dict[str, Image.Image]) -> Image.Image:
    sheet = Image.new("RGBA", (1920, 2280), rgba("#08111F"))
    d = ImageDraw.Draw(sheet, "RGBA")
    text(d, (64, 42), "Block Blast Battle UI Direction Mockups", "title44", rgba("#FFFFFF"))
    text(d, (64, 96), "Design approval only - not implemented in Roblox", "bold22", rgba("#9DB6D8"))
    y = 160
    for key in ["B1", "B2", "B3"]:
        spec = SPECS[key]
        thumb = images[key].resize((960, 540), Image.LANCZOS)
        sheet.alpha_composite(thumb, (64, y))
        panel(d, (1060, y, 1856, y + 540), rgba("#101827", 235), rgba("#334866"), 18, 2)
        text(d, (1096, y + 32), f"{key} - {spec['name']}", "title36", rgba("#FFFFFF"))
        text(d, (1096, y + 92), "Palette", "bold22", rgba("#9FD8FF"))
        cx = 1096
        for color in spec["palette"].values():
            draw_shadow(d, (cx, y + 126, cx + 46, y + 172), 8, offset=(0, 3), alpha=45)
            d.rounded_rectangle((cx, y + 126, cx + 46, y + 172), 8, fill=rgba(color), outline=rgba("#FFFFFF", 80), width=1)
            cx += 58
            if cx > 1760:
                break
        bullets = [
            f"Identity: {spec['name']}",
            f"Buttons: {spec['button']}",
            f"Mobile: {spec['desktop_mobile']}",
            f"Benefit: {spec['benefit']}",
            f"Tradeoff: {spec['tradeoff']}",
        ]
        by = y + 206
        for bullet in bullets:
            lines = wrap(d, bullet, "body18", 690)
            for line in lines[:2]:
                text(d, (1096, by), line, "body18", rgba("#D8E5FF"))
                by += 28
            by += 6
        y += 680
    return sheet


def write_specs():
    lines = ["# Block Blast Battle UI Mockup Specs", ""]
    for key in ["B1", "B2", "B3"]:
        spec = SPECS[key]
        lines += [
            f"## {key} - {spec['name']}",
            "",
            "### Color Palette",
        ]
        for name, color in spec["palette"].items():
            lines.append(f"- `{name}`: `{color}`")
        lines += [
            "",
            f"- Font choices: {spec['font']}",
            f"- Corner radii: {spec['corner']}",
            f"- Stroke widths: {spec['stroke']}",
            f"- Shadow treatment: {spec['shadow']}",
            f"- Standard spacing scale: {spec['spacing']}",
            f"- Button treatment: {spec['button']}",
            f"- Panel treatment: {spec['panel']}",
            f"- Icon style: {spec['icon']}",
            f"- Desktop and mobile behavior: {spec['desktop_mobile']}",
            f"- Benefits: {spec['benefit']}",
            f"- Tradeoffs: {spec['tradeoff']}",
            "",
        ]
    (OUT / "ui-mockup-specs.md").write_text("\n".join(lines), encoding="utf-8")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    desktop = {
        "B1": b1_desktop(),
        "B2": b2_desktop(),
        "B3": b3_desktop(),
    }
    for key, image in desktop.items():
        image.save(OUT / f"{key.lower()}-{SPECS[key]['name'].lower().replace(' ', '-')}-desktop-1920x1080.png")
        mobile(key).save(OUT / f"{key.lower()}-{SPECS[key]['name'].lower().replace(' ', '-')}-mobile-1080x1920.png")
    comparison(desktop).save(OUT / "comparison-b1-b2-b3.png")
    write_specs()
    print(f"Wrote mockups to {OUT}")


if __name__ == "__main__":
    main()
