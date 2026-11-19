from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "assets" / "icons"
WEB_DIR = ROOT / "web"
WEB_ICON_DIR = WEB_DIR / "icons"

NAVY = (0, 0, 128)
BLUE = (19, 68, 210)
RED = (236, 28, 36)
WHITE = (255, 255, 255)

FONT_BOLD = "/System/Library/Fonts/Avenir Next Condensed.ttc"
FONT_REGULAR = "/System/Library/Fonts/HelveticaNeue.ttc"


def rounded_line(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[int, int]],
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    draw.line(points, fill=fill, width=width, joint="curve")
    radius = width // 2
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill)


def cubic_points(
    p0: tuple[int, int],
    p1: tuple[int, int],
    p2: tuple[int, int],
    p3: tuple[int, int],
    steps: int = 48,
) -> list[tuple[int, int]]:
    points = []
    for i in range(steps + 1):
        t = i / steps
        inv = 1 - t
        x = (
            inv**3 * p0[0]
            + 3 * inv**2 * t * p1[0]
            + 3 * inv * t**2 * p2[0]
            + t**3 * p3[0]
        )
        y = (
            inv**3 * p0[1]
            + 3 * inv**2 * t * p1[1]
            + 3 * inv * t**2 * p2[1]
            + t**3 * p3[1]
        )
        points.append((round(x), round(y)))
    return points


def make_mark(primary: tuple[int, int, int], size: int = 1024) -> Image.Image:
    scale = 4
    canvas = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")

    def s(point: tuple[int, int]) -> tuple[int, int]:
        return (point[0] * scale, point[1] * scale)

    primary_rgba = primary + (255,)
    red_rgba = RED + (255,)

    swoosh = cubic_points(
        s((336, 315)),
        s((462, 126)),
        s((810, 190)),
        s((815, 540)),
        steps=72,
    )
    rounded_line(draw, swoosh, red_rgba, 46 * scale)

    roof = cubic_points(
        s((235, 620)),
        s((320, 475)),
        s((445, 560)),
        s((520, 470)),
        steps=28,
    )
    roof += cubic_points(
        s((520, 470)),
        s((600, 375)),
        s((715, 425)),
        s((770, 525)),
        steps=28,
    )[1:]
    roof += cubic_points(
        s((770, 525)),
        s((845, 540)),
        s((900, 585)),
        s((890, 650)),
        steps=22,
    )[1:]
    rounded_line(draw, roof, primary_rgba, 62 * scale)

    body = cubic_points(
        s((250, 650)),
        s((345, 545)),
        s((500, 570)),
        s((610, 602)),
        steps=28,
    )
    body += cubic_points(
        s((610, 602)),
        s((695, 628)),
        s((792, 626)),
        s((860, 650)),
        steps=24,
    )[1:]
    rounded_line(draw, body, primary_rgba, 58 * scale)

    rounded_line(
        draw,
        [s((400, 686)), s((708, 686))],
        primary_rgba,
        72 * scale,
    )

    for center in [(365, 705), (742, 705)]:
        x, y = s(center)
        r = 62 * scale
        draw.ellipse((x - r, y - r, x + r, y + r), fill=primary_rgba)

    for center, radius in [((250, 430), 26), ((300, 380), 18), ((816, 322), 16)]:
        x, y = s(center)
        r = radius * scale
        draw.ellipse((x - r, y - r, x + r, y + r), fill=red_rgba)

    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def gradient_background(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), NAVY + (255,))
    pixels = canvas.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (size * 2 - 2)
            pixels[x, y] = tuple(
                int(NAVY[i] * (1 - t) + BLUE[i] * t) for i in range(3)
            ) + (255,)
    return canvas


def fit(image: Image.Image, size: tuple[int, int], scale: float = 0.8) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("image is empty")
    cropped = image.crop(bbox)
    ratio = min(size[0] * scale / cropped.width, size[1] * scale / cropped.height)
    resized = cropped.resize(
        (round(cropped.width * ratio), round(cropped.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2),
    )
    return canvas


def make_launcher(mark: Image.Image) -> Image.Image:
    canvas = gradient_background()
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw.rounded_rectangle(
        (72, 72, 952, 952),
        radius=230,
        outline=(255, 255, 255, 38),
        width=8,
    )
    canvas.alpha_composite(fit(mark, (1024, 1024), scale=0.72))
    return canvas.convert("RGB")


def text_bbox(draw: ImageDraw.ImageDraw, xy, text: str, font: ImageFont.FreeTypeFont):
    return draw.textbbox(xy, text, font=font)


def make_wordmark(primary: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGBA", (1800, 820), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    mark = fit(make_mark(primary, 1024), (470, 470), scale=0.9)
    canvas.alpha_composite(mark, (90, 165))

    title_font = ImageFont.truetype(FONT_BOLD, 220)
    sub_font = ImageFont.truetype(FONT_REGULAR, 76)
    pro_font = ImageFont.truetype(FONT_BOLD, 78)

    x = 560
    title = "MOBIZ"
    subtitle = "AUTO CARE"
    draw.text((x, 218), title, font=title_font, fill=primary + (255,))
    title_box = text_bbox(draw, (x, 218), title, title_font)
    sub_y = title_box[3] + 28
    draw.text((x + 8, sub_y), subtitle, font=sub_font, fill=primary + (230,))

    sub_box = text_bbox(draw, (x + 8, sub_y), subtitle, sub_font)
    pill_x = sub_box[2] + 34
    pill_y = sub_y - 7
    pill_w = 178
    pill_h = 84
    draw.rounded_rectangle(
        (pill_x, pill_y, pill_x + pill_w, pill_y + pill_h),
        radius=18,
        fill=RED + (255,),
    )
    pro_box = text_bbox(draw, (0, 0), "PRO", pro_font)
    draw.text(
        (
            pill_x + (pill_w - (pro_box[2] - pro_box[0])) // 2,
            pill_y + (pill_h - (pro_box[3] - pro_box[1])) // 2 - 8,
        ),
        "PRO",
        font=pro_font,
        fill=WHITE + (255,),
    )
    return fit(canvas, (1800, 820), scale=0.92)


def save_resized(image: Image.Image, path: Path, size: tuple[int, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize(size, Image.Resampling.LANCZOS).save(path, "PNG")


def main() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    WEB_ICON_DIR.mkdir(parents=True, exist_ok=True)

    mark_blue = fit(make_mark(NAVY), (1024, 1024), scale=0.86)
    mark_white = fit(make_mark(WHITE), (1024, 1024), scale=0.86)
    foreground = fit(make_mark(WHITE), (1024, 1024), scale=0.72)
    launcher = make_launcher(make_mark(WHITE))
    logo_blue = make_wordmark(NAVY)
    logo_white = make_wordmark(WHITE)

    outputs = {
        ICON_DIR / "mobiz_autocare_mark_blue.png": mark_blue,
        ICON_DIR / "mobiz_autocare_mark_white.png": mark_white,
        ICON_DIR / "mobiz_autocare_foreground.png": foreground,
        ICON_DIR / "mobiz_autocare_launcher.png": launcher,
        ICON_DIR / "mobiz_autocare_logo_blue.png": logo_blue,
        ICON_DIR / "mobiz_autocare_logo_white.png": logo_white,
    }

    for path, image in outputs.items():
        image.save(path, "PNG")
        print(f"saved {path.relative_to(ROOT)}")

    save_resized(launcher, WEB_DIR / "favicon.png", (48, 48))
    save_resized(launcher, WEB_ICON_DIR / "Icon-192.png", (192, 192))
    save_resized(launcher, WEB_ICON_DIR / "Icon-512.png", (512, 512))
    save_resized(launcher, WEB_ICON_DIR / "Icon-maskable-192.png", (192, 192))
    save_resized(launcher, WEB_ICON_DIR / "Icon-maskable-512.png", (512, 512))


if __name__ == "__main__":
    main()
