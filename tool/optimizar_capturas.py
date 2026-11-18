# -*- coding: utf-8 -*-
"""Pasa las capturas de los proyectos de PNG a WebP y corrige las rutas del JSON.

    python tool/optimizar_capturas.py

Las capturas se bajan recién cuando alguien abre la galería de un proyecto,
pero en un teléfono con datos móviles cada una pesa. WebP con calidad 90 deja
el texto de las pantallas nítido y pesa bastante menos que el PNG.

Convierte lo que encuentre en `assets/images/projects/**/*.png`, borra el PNG
y reescribe `assets/data/portfolio.json`. Después hay que regenerar la vista
rápida (`python tool/build_vista_rapida.py`), porque el JSON cambió.
"""
import glob
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data", "portfolio.json")


def main():
    antes = despues = 0
    cambios = {}
    for png in sorted(glob.glob(os.path.join(ROOT, "assets", "images", "projects", "**", "*.png"), recursive=True)):
        webp = png[:-4] + ".webp"
        imagen = Image.open(png)
        imagen = imagen.convert("RGBA" if imagen.mode in ("RGBA", "LA", "P") else "RGB")
        imagen.save(webp, "WEBP", quality=90, method=6)
        a, d = os.path.getsize(png), os.path.getsize(webp)
        if d >= a:
            # No siempre gana: si el WebP pesa más, queda el PNG.
            os.remove(webp)
            continue
        antes += a
        despues += d
        rel = os.path.relpath(png, ROOT).replace(os.sep, "/")
        cambios[rel] = rel[:-4] + ".webp"
        os.remove(png)

    if cambios:
        texto = open(DATA, encoding="utf-8").read()
        for viejo, nuevo in cambios.items():
            texto = texto.replace('"' + viejo + '"', '"' + nuevo + '"')
        with open(DATA, "w", encoding="utf-8", newline="\n") as f:
            f.write(texto)
    print(f"{len(cambios)} capturas: {antes // 1024} KB -> {despues // 1024} KB")


if __name__ == "__main__":
    main()
