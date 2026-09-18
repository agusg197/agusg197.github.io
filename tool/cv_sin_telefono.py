# -*- coding: utf-8 -*-
"""Publica los CV sin el teléfono.

    python tool/cv_sin_telefono.py

Lee los originales de `CVs/` y escribe en `assets/cv/` una copia sin el número.
No tapa el texto con un recuadro: lo saca del contenido, así no se puede
seleccionar ni extraer. El correo y el LinkedIn quedan, que es lo que uno
espera encontrar en un CV.
"""
import io
import os
import re
import sys

from pypdf import PdfReader, PdfWriter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(ROOT, 'CVs')
DEST = os.path.join(ROOT, 'assets', 'cv')

# El teléfono aparece como una cadena suelta seguida del separador de la línea.
TELEFONO = re.compile(rb'\(\s*\+\s*54[^)]*\)\s*Tj\s*(\(\|\)\s*Tj\s*)?')
CUALQUIER_TEL = re.compile(rb'\(\s*\+\s*\d[^)]{6,}\)\s*Tj\s*(\(\|\)\s*Tj\s*)?')


def limpiar(origen, destino):
    escritor = PdfWriter(clone_from=origen)
    lector = PdfReader(origen)
    quitados = 0

    for pagina in escritor.pages:
        contenido = pagina.get_contents()
        if contenido is not None:
            datos = contenido.get_data()
            nuevos, n = TELEFONO.subn(b'', datos)
            if n == 0:
                nuevos, n = CUALQUIER_TEL.subn(b'', datos)
            if n:
                contenido.set_data(nuevos)
                # set_data sobre la copia no alcanza: hay que reemplazar el
                # contenido de la pagina para que el escritor lo tome.
                pagina.replace_contents(contenido)
                quitados += n

    # Metadatos: que no quede el número en el título o en el autor.
    meta = {k: v for k, v in (lector.metadata or {}).items()
            if not re.search(r'\+?\d[\d ().-]{7,}\d', str(v))}
    escritor.add_metadata(meta)

    with open(destino, 'wb') as f:
        escritor.write(f)

    texto = ' '.join(p.extract_text() or '' for p in PdfReader(destino).pages)
    quedan = re.findall(r'\+?\d[\d ().-]{9,}\d', texto)
    print(os.path.basename(destino),
          '· apariciones quitadas:', quitados,
          '· números que quedan:', quedan or 'ninguno',
          '·', os.path.getsize(destino) // 1024, 'KB')
    return not quedan


def main():
    if not os.path.isdir(ORIG):
        print('No encuentro la carpeta CVs/ con los originales.')
        return 1
    ok = True
    for nombre in sorted(os.listdir(ORIG)):
        if nombre.lower().endswith('.pdf'):
            ok &= limpiar(os.path.join(ORIG, nombre), os.path.join(DEST, nombre))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
