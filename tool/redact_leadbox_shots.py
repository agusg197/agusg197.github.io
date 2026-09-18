# -*- coding: utf-8 -*-
"""Capturas del build de demo, con la marca y los identificadores de producto tapados.

Las coordenadas est\u00e1n en el sistema del preview de 360 px de ancho; se escalan al
original (1080 px) y despu\u00e9s la imagen se baja a 540 px para la web.
"""
import os
from PIL import Image, ImageDraw

SRC = r'E:\Users\SugaT\leadbox-mobile\docs\demo\screenshots'
DST = r'E:\Pagina portafolio\assets\images\projects\leadbox'
os.makedirs(DST, exist_ok=True)

BG = (7, 7, 12)          # CyberColors.bg0
EDGE = (255, 42, 109)    # CyberColors.magenta
K = 3.0                  # preview 360 -> original 1080
OUT_W = 540

# (archivo destino, archivo origen, [(x0, y0, x1, y1) en coordenadas de preview])
JOBS = [
    ('01-sucursales.png', '03_locations_all.png', [
        (18, 68, 108, 96),      # marca, arriba a la izquierda
        (258, 66, 348, 94),     # marca, detr\u00e1s de la hoja
        (16, 118, 176, 148),    # nombre de la persona
        (58, 388, 240, 412),    # filas: nombre de cada sucursal
        (58, 437, 240, 461),
        (58, 486, 240, 510),
        (58, 535, 240, 559),
        (58, 584, 240, 608),
        (58, 633, 240, 657),
        (58, 682, 240, 706),
        (28, 776, 90, 794),   # eco del nombre, abajo
    ]),
    ('02-pendientes.png', '21_pending_badge.png', [
        (176, 58, 266, 84),     # marca en la barra superior
        (52, 196, 324, 218),    # placeholder de b\u00fasqueda
        (10, 235, 74, 253),     # conteo con la palabra del dominio
        (118, 283, 310, 348),   # bloque de texto de cada ficha
        (118, 431, 310, 496),
        (118, 582, 310, 647),
        (118, 705, 310, 767),
    ]),
    ('03-staged.png', '14_staged.png', [
        (58, 60, 262, 86),      # t\u00edtulo de la ficha
        (10, 320, 350, 370),    # franja de identificadores
    ]),
    ('04-fases.png', '20_sync_100.png', [
        (68, 68, 294, 96),      # chip con identificador de la ficha
    ]),
    ('05-corrida.png', '22_syncall_1.png', [
        (192, 438, 286, 470),   # la palabra del dominio en el t\u00edtulo
        (116, 531, 164, 550),   # y en la l\u00ednea de detalle
    ]),
    ('06-interrumpida.png', '43_after_interrupt.png', [
        (176, 58, 266, 84),
        (52, 196, 324, 218),
        (10, 235, 74, 253),
        (118, 281, 310, 348),
        (118, 429, 310, 496),
        (118, 576, 310, 643),
        (118, 703, 310, 767),
    ]),
]

for out_name, src_name, boxes in JOBS:
    im = Image.open(os.path.join(SRC, src_name)).convert('RGB')
    d = ImageDraw.Draw(im)
    for (x0, y0, x1, y1) in boxes:
        r = [x0 * K, y0 * K, x1 * K, y1 * K]
        d.rectangle(r, fill=BG)
        d.rectangle(r, outline=EDGE, width=3)
    w, h = im.size
    im = im.resize((OUT_W, int(h * OUT_W / w)), Image.LANCZOS)
    path = os.path.join(DST, out_name)
    im.save(path, optimize=True)
    print(out_name, im.size, os.path.getsize(path) // 1024, 'KB')
