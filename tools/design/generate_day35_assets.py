from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "ui" / "day35"
OUT.mkdir(parents=True, exist_ok=True)


def rounded_rect(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def save_panel_shine():
    image = Image.new("RGBA", (512, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rounded_rect(draw, (18, 18, 494, 238), 44, (8, 25, 50, 238), (45, 196, 255, 255), 10)
    rounded_rect(draw, (34, 34, 478, 86), 28, (255, 255, 255, 38))
    rounded_rect(draw, (50, 142, 462, 216), 32, (4, 13, 28, 180), (19, 85, 142, 190), 4)
    image.save(OUT / "panel-shine-512x256.png")


def save_combo_burst():
    image = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    cx, cy = 256, 256
    points = []
    for index in range(32):
        angle = index * 3.14159265 * 2 / 32
        radius = 226 if index % 2 == 0 else 178
        points.append((cx + radius * __import__("math").cos(angle), cy + radius * __import__("math").sin(angle)))
    draw.polygon(points, fill=(129, 42, 221, 245), outline=(255, 238, 122, 255))
    draw.line(points + [points[0]], fill=(255, 255, 255, 245), width=8)
    glow = image.filter(ImageFilter.GaussianBlur(8))
    combined = Image.alpha_composite(glow, image)
    combined.save(OUT / "combo-burst-512.png")


def save_toy_block_pattern():
    image = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    colors = [
        (40, 177, 255, 255),
        (255, 198, 48, 255),
        (111, 219, 48, 255),
        (255, 117, 36, 255),
        (172, 77, 230, 255),
    ]
    for index, color in enumerate(colors):
        x = 30 + (index % 3) * 150
        y = 58 + (index // 3) * 172
        rounded_rect(draw, (x, y, x + 118, y + 118), 18, color, (17, 36, 67, 255), 8)
        for sx in (x + 36, x + 82):
            for sy in (y + 34, y + 80):
                draw.ellipse((sx - 13, sy - 13, sx + 13, sy + 13), fill=tuple(min(255, c + 28) for c in color[:3]) + (255,))
    image.save(OUT / "toy-block-pattern-512.png")


def save_rank_medals():
    image = Image.new("RGBA", (512, 192), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    medals = [((255, 206, 72), 1), ((210, 219, 231), 2), ((212, 126, 55), 3)]
    for index, (color, rank) in enumerate(medals):
        cx = 86 + index * 168
        draw.ellipse((cx - 52, 38, cx + 52, 142), fill=color + (255,), outline=(17, 36, 67, 255), width=8)
        draw.rectangle((cx - 18, 124, cx + 18, 170), fill=(17, 36, 67, 255))
        draw.text((cx - 10, 76), str(rank), fill=(8, 23, 45, 255))
    image.save(OUT / "rank-medals-512x192.png")


if __name__ == "__main__":
    save_panel_shine()
    save_combo_burst()
    save_toy_block_pattern()
    save_rank_medals()
