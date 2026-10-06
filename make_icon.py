"""風語輸入法 — 由 AIW 風光Ai窗 官方 logo 產生輸入法圖示（.ico）。

用法：python make_icon.py <mark|feng> <輸出.ico> [預覽.png]
  mark：AiW 標誌
  feng：logo 中的「風」字
"""
import sys
from PIL import Image, ImageDraw

LOGO = r'C:/Users/admin/.claude/skills/aig-brand-deck-20260629/assets/logos/AIW風光Ai窗_logo_白.png'
CROPS = {'mark': (0, 746), 'feng': (801, 1025)}  # logo 中的水平範圍（像素）
SIZES = [16, 24, 32, 48, 64, 256]


def glyph(kind):
    src = Image.open(LOGO).convert('RGBA')
    x0, x1 = CROPS[kind]
    g = src.crop((x0, 0, x1, 260))   # 只取上方圖形，排除英文字樣
    return g.crop(g.getbbox())


def render(kind, size):
    s = size * 4  # 超取樣後縮小，邊緣較平滑
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle((0, 0, s - 1, s - 1), radius=s // 6, fill=(0, 0, 0, 255))
    g = glyph(kind)
    fit = 0.84 if kind == 'mark' else 0.72
    scale = min(s * fit / g.width, s * fit / g.height)
    g = g.resize((round(g.width * scale), round(g.height * scale)), Image.LANCZOS)
    im.alpha_composite(g, ((s - g.width) // 2, (s - g.height) // 2))
    return im.resize((size, size), Image.LANCZOS)


def main(kind, out, preview=None):
    imgs = [render(kind, n) for n in SIZES]
    imgs[-1].save(out, format='ICO', sizes=[(n, n) for n in SIZES], append_images=imgs[:-1])
    if preview:
        sheet = Image.new('RGBA', (sum(SIZES) + 10 * len(SIZES), 266), (230, 230, 230, 255))
        x = 5
        for im in imgs:
            sheet.alpha_composite(im, (x, 5))
            x += im.width + 10
        sheet.save(preview)


if __name__ == '__main__':
    main(*sys.argv[1:])
