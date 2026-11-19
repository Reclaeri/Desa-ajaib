from collections import deque
from pathlib import Path
from PIL import Image

SOURCE = Path(r"C:\Users\Revan Oknanda\Downloads\Desa Ajaib Cartoon Game UI Spritesheet.png")
OUT = Path(r"D:\desa-ajaib\assets\ui\sheet")

SLICES = {
    "main_menu/logo_desa_ajaib.png": (24, 0, 690, 302),
    "main_menu/panel_main_menu.png": (58, 292, 700, 770),
    "pause_menu/panel_pause.png": (704, 18, 1204, 744),
    "buttons/button_play.png": (1204, 32, 1532, 132),
    "buttons/button_settings.png": (1204, 138, 1532, 229),
    "buttons/button_guide.png": (1204, 237, 1532, 328),
    "buttons/button_exit.png": (1204, 336, 1532, 426),
    "buttons/button_resume.png": (1204, 438, 1532, 535),
    "buttons/button_audio.png": (1204, 542, 1532, 638),
    "buttons/button_home.png": (1204, 644, 1532, 738),
    "characters/lili_portrait.png": (20, 770, 205, 970),
    "icons/icon_star.png": (228, 798, 425, 930),
    "icons/icon_pause.png": (430, 798, 525, 910),
    "icons/icon_home.png": (532, 798, 625, 910),
    "icons/icon_audio.png": (632, 798, 730, 910),
    "decorations/wooden_sign.png": (1090, 758, 1300, 950),
    "decorations/fence.png": (1292, 778, 1535, 950),
    "decorations/close.png": (1290, 922, 1388, 1018),
    "decorations/check.png": (1400, 922, 1515, 1018),
    "decorations/flower_strip.png": (180, 928, 925, 1024),
}


def color_distance(a, b):
    return sum(abs(int(a[i]) - int(b[i])) for i in range(3))


def remove_connected_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    px = image.load()
    width, height = image.size
    visited = bytearray(width * height)
    queue = deque()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
    while queue:
        x, y = queue.popleft()
        index = y * width + x
        if visited[index]:
            continue
        visited[index] = 1
        source = px[x, y]
        if source[3] < 8:
            px[x, y] = (source[0], source[1], source[2], 0)
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < width and 0 <= ny < height and not visited[ny * width + nx]:
                    queue.append((nx, ny))
            continue
        similar_neighbors = 0
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                neighbor = px[nx, ny]
                if color_distance(source, neighbor) <= 12:
                    similar_neighbors += 1
        if similar_neighbors >= 3:
            px[x, y] = (source[0], source[1], source[2], 0)
        else:
            continue
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and not visited[ny * width + nx]:
                queue.append((nx, ny))
    return image


def main():
    source = Image.open(SOURCE).convert("RGBA")
    for relative, box in SLICES.items():
        target = OUT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        crop = source.crop(box)
        cleaned = remove_connected_background(crop)
        cleaned.save(target, "PNG", optimize=True)
        print(target.relative_to(OUT), cleaned.size)


if __name__ == "__main__":
    main()
