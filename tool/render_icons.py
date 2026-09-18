# -*- coding: utf-8 -*-
"""Genera el favicon y los íconos de la app con la misma gramática de la página:
fondo Night City, marco con esquina cortada, la A con aberración cromática y una
franja de peligro abajo.

    python tool/render_icons.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, 'web')
ICONS = os.path.join(WEB, 'icons')
os.makedirs(ICONS, exist_ok=True)

BG      = (7, 7, 12)
CYAN    = (0, 240, 255)
MAGENTA = (255, 42, 109)
YELLOW  = (252, 238, 10)
TEXT0   = (230, 241, 255)

FONT = r'C:\Windows\Fonts\bahnschrift.ttf'


def icon(size, *, margin_ratio=0.055, hazard=True, border_ratio=0.018,
         bleed=False):
    """Un ícono cuadrado de `size` px.

    `bleed` llena todo el cuadro de fondo y encoge el contenido: es lo que pide
    un ícono maskable, al que Android le recorta las esquinas.
    """
    s = size
    im = Image.new('RGB', (s, s), BG)
    d = ImageDraw.Draw(im)

    m = max(1, int(s * (margin_ratio if not bleed else 0.16)))
    bw = max(1, int(s * border_ratio))
    cut = int((s - 2 * m) * 0.22)

    # Marco con la esquina superior derecha y la inferior izquierda cortadas.
    l, t, r, b = m, m, s - m - 1, s - m - 1
    frame = [
        (l, t), (r - cut, t), (r, t + cut), (r, b),
        (l + cut, b), (l, b - cut),
    ]
    d.polygon(frame, fill=(14, 15, 26))
    d.line(frame + [frame[0]], fill=CYAN, width=bw, joint='curve')

    # La A, con el desplazamiento cromático de la página.
    glyph_h = int((s - 2 * m) * 0.78)
    try:
        f = ImageFont.truetype(FONT, glyph_h)
    except OSError:
        f = ImageFont.load_default()
    text = 'A'
    box = d.textbbox((0, 0), text, font=f)
    tw, th = box[2] - box[0], box[3] - box[1]
    cx = (s - tw) / 2 - box[0]
    cy = (s - th) / 2 - box[1] - s * 0.02
    off = max(1, int(s * 0.022))
    d.text((cx + off, cy), text, font=f, fill=MAGENTA)
    d.text((cx - off, cy), text, font=f, fill=CYAN)
    d.text((cx, cy), text, font=f, fill=TEXT0)

    # Franja de peligro apoyada en el borde de abajo, recortada contra el marco
    # para que no se pase de la esquina cortada.
    if hazard:
        band_h = max(2, int(s * 0.075))
        y0 = b - band_h - bw
        y1 = b - bw
        step = max(3, int(s * 0.055))
        band = Image.new('RGB', (s, s), BG)
        bd = ImageDraw.Draw(band)
        for x in range(l - band_h, r + step * 2, step):
            bd.polygon(
                [(x, y1), (x + step * 0.55, y1),
                 (x + step * 0.55 + band_h * 0.6, y0), (x + band_h * 0.6, y0)],
                fill=YELLOW,
            )
        mask = Image.new('L', (s, s), 0)
        md = ImageDraw.Draw(mask)
        md.polygon(frame, fill=255)
        md.rectangle([0, 0, s, y0 - 1], fill=0)
        md.rectangle([0, y1 + 1, s, s], fill=0)
        im.paste(band, (0, 0), mask)
        d.line(frame + [frame[0]], fill=CYAN, width=bw, joint='curve')

    return im


def save(im, path):
    im.save(path, optimize=True)
    print(os.path.relpath(path, ROOT), im.size, os.path.getsize(path) // 1024, 'KB')


# Pestaña del navegador: chico, sin franja, marco más grueso para que se lea.
save(icon(64, hazard=False, border_ratio=0.05, margin_ratio=0.08),
     os.path.join(WEB, 'favicon.png'))

save(icon(192), os.path.join(ICONS, 'Icon-192.png'))
save(icon(512), os.path.join(ICONS, 'Icon-512.png'))
save(icon(192, bleed=True), os.path.join(ICONS, 'Icon-maskable-192.png'))
save(icon(512, bleed=True), os.path.join(ICONS, 'Icon-maskable-512.png'))
