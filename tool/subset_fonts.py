# -*- coding: utf-8 -*-
"""Recorta las tipografías a los caracteres que el sitio puede escribir.

    pip install fonttools
    python tool/subset_fonts.py

Rajdhani viaja con todo el devanagari y Chakra Petch con el tailandés: 1,3 MB
de fuentes para un sitio que escribe en castellano y en inglés. Este script
lee las originales de `tool/fonts-src/` y deja en `assets/google_fonts/` una
copia solo con el latín, la puntuación, las flechas y cualquier otro carácter
que aparezca en los datos, en el código o en el HTML.

Si un texto nuevo usa un carácter que no entró, no se rompe nada: el motor
lo busca en una fuente de respaldo. Volver a correr el script lo suma.
"""
import glob
import os
import re

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "tool", "fonts-src")
DEST = os.path.join(ROOT, "assets", "google_fonts")

# Rangos que van siempre, para lo que escriba un visitante en las demos.
SIEMPRE = [
    (0x20, 0x7E),      # ASCII
    (0xA0, 0x17F),     # Latin-1 y Latín extendido A
    (0x2010, 0x2027),  # guiones, comillas, viñetas
    (0x2030, 0x205E),  # ‰ ‹ › …
    (0x20A0, 0x20BF),  # monedas
    (0x2190, 0x21FF),  # flechas
    (0x2200, 0x22FF),  # operadores
    (0x2500, 0x257F),  # cajas
    (0x25A0, 0x25FF),  # formas
]


def caracteres():
    chars = set()
    for patron in ("assets/data/*.json", "lib/**/*.dart", "web/*.html", "web/cv/**/*.html"):
        for ruta in glob.glob(os.path.join(ROOT, patron), recursive=True):
            texto = open(ruta, encoding="utf-8").read()
            chars |= set(texto)
            # Los escapes \uXXXX del código Dart.
            for m in re.findall(r"\\u([0-9a-fA-F]{4})", texto):
                chars.add(chr(int(m, 16)))
    for a, b in SIEMPRE:
        chars |= {chr(c) for c in range(a, b + 1)}
    return {c for c in chars if ord(c) >= 0x20}


def main():
    chars = caracteres()
    unicodes = sorted(ord(c) for c in chars)
    antes_total = despues_total = 0
    for origen in sorted(glob.glob(os.path.join(SRC, "*.ttf"))):
        nombre = os.path.basename(origen)
        destino = os.path.join(DEST, nombre)
        opciones = subset.Options()
        opciones.layout_features = ["*"]
        opciones.name_IDs = ["*"]
        opciones.name_languages = ["*"]
        opciones.notdef_outline = True
        opciones.hinting = True
        fuente = TTFont(origen)
        tenia = set(fuente.getBestCmap())
        recorte = subset.Subsetter(opciones)
        recorte.populate(unicodes=unicodes)
        recorte.subset(fuente)
        fuente.save(destino)
        queda = set(TTFont(destino).getBestCmap())
        perdidos = sorted(c for c in chars if ord(c) in tenia and ord(c) not in queda)
        antes, despues = os.path.getsize(origen), os.path.getsize(destino)
        antes_total += antes
        despues_total += despues
        print(f"{nombre}: {antes // 1024} KB -> {despues // 1024} KB · glifos {len(tenia)} -> {len(queda)}"
              + (f" · PERDIDOS: {perdidos}" if perdidos else ""))
    print(f"total: {antes_total // 1024} KB -> {despues_total // 1024} KB")


if __name__ == "__main__":
    main()
