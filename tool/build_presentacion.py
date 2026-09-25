# -*- coding: utf-8 -*-
"""Arma el dossier de presentacion en PDF, en castellano y en ingles.

    python tool/build_presentacion.py          # los dos idiomas
    python tool/build_presentacion.py en       # solo ingles

Escribe `entrega/Dossier-Agustin.pdf` y `entrega/Dossier-Agustin-EN.pdf`, con el
mismo `portfolio.json` que alimenta la pagina. No lleva ningun dato de contacto:
ni correo, ni telefono, ni redes. Los enlaces a los repositorios publicos si
van, porque son el codigo del que habla cada ficha.

Cada proyecto ocupa dos hojas: que es, con sus numeros y sus pantallas, y como
funciona, etapa por etapa, con el hallazgo que lo define. Los proyectos de
trabajo se cuentan a nivel de arquitectura: que capas tiene, como sincroniza,
que se mide. Nada de reglas de negocio, nombres de clientes ni pantallas sin
tapar.

Comparte el armado de pagina con `build_project_briefs.py`, que hace la version
larga de cada proyecto por separado.

Necesita Microsoft Edge o Chrome para imprimir, y Pillow para las capturas.
"""
import io
import json
import os
import subprocess
import sys
import shutil
import tempfile

import build_project_briefs as fichas
from build_project_briefs import ACENTOS, esc, img_b64, numeros_en, stripes

ROOT = fichas.ROOT
OUT_DIR = os.path.join(ROOT, 'entrega')
NAVEGADORES = fichas.NAVEGADORES

ARCHIVO = {'es': 'Dossier-Agustin.pdf', 'en': 'Dossier-Agustin-EN.pdf'}

# Las dos capturas que acompanan a cada proyecto en el dossier. La version
# larga de cada uno, con todas, vive en su ficha.
SHOTS = {
    'leadbox': ['02-pendientes.png', '04-fases.png'],
    'echo': ['02-escuchando.png', '01-preparacion.png'],
    'cifra': ['03-tarjeta.png', '01-periodo.png'],
    'trino': ['02-amanecer.png', '03-confirmar.png'],
    'tiza': ['resultado-pizarron.png', 'vista-json.png'],
    'advisor': ['01-ruteo.png'],
}


def t(v, lang, defecto=u''):
    """El texto en el idioma pedido de un valor bilingue."""
    if isinstance(v, dict):
        return v.get(lang) or v.get('es') or v.get('en') or defecto
    return v or defecto


def num(s, lang):
    """Los numeros se cargaron en castellano; en ingles cambian de separador."""
    return numeros_en(s) if lang == 'en' else s


# --------------------------------------------------------------------------
# Todo el texto que no sale del JSON. Escrito dos veces a proposito: traducir
# a maquina esto se nota enseguida.
# --------------------------------------------------------------------------
PROSA = {
    'es': {
        'doc': u'DOSSIER // 2026',
        'claim': u'Construyo productos que se entienden en el primer toque y aguantan '
                 u'el segundo año.',
        'sub': u'Apps en Flutter para teléfono, escritorio y web. Sistemas con modelos '
               u'de lenguaje que dicen qué hicieron y cuánto costaron. Un solo código, '
               u'varias pantallas, y números medidos en vez de adjetivos.',
        'pie_portada': u'%d PROYECTOS · CADA UNO CON SUS NÚMEROS',
        'por_que': u'Por qué esto se ve así',
        'por_que_sec': u'PRIMERA IMPRESIÓN',
        'por_que_big': u'Lo primero que ves ya es una muestra del trabajo.',
        'por_que_p': u'Este documento sale de una página hecha en Flutter, la misma '
                     u'herramienta con la que construiría tu producto: un solo código '
                     u'que corre en Android, iOS, escritorio y navegador. No es una '
                     u'plantilla comprada ni un tema de WordPress. Si te gusta cómo se '
                     u'mueve, eso es exactamente lo que sé hacer.',
        'b1': u'<b>El estilo cyberpunk no es decoración, es una prueba de carga.</b> '
              u'Glitches, barridos, partículas y una grilla viva son de lo más caro que '
              u'se le puede pedir a una interfaz. Que todo eso corra fluido, también en '
              u'un teléfono, es la demostración de que el rendimiento no se negocia: el '
              u'fondo pasó de 614 llamadas de dibujo a 11, medidas con un test y no a ojo.',
        'b2': u'<b>Y es una manera de mirar el producto.</b> Un tablero oscuro obliga a '
              u'lo que le pido a cualquier sistema: que cada número esté a la vista, que '
              u'cada estado tenga nombre —esperando red, reintentando en 8 segundos— y '
              u'que nada finja un progreso que no existe.',
        'b3': u'<b>Con respeto por quien lo usa.</b> Todos los efectos se apagan de un '
              u'clic y la página sigue siendo la misma, legible y completa. Un producto '
              u'que solo funciona si al usuario le gusta el brillo no es un producto: es '
              u'un truco.',
        'leer': u'CÓMO LEER CADA PROYECTO',
        'leer_p': [
            u'Cada proyecto ocupa dos hojas y ninguna es un folleto.',
            u'<b>La primera</b> dice qué problema resuelve, con qué está hecho y qué se '
            u'midió. Los números son de corridas reales: tiempos, tests, tasas.',
            u'<b>La segunda</b> abre el recorrido completo, etapa por etapa, de la '
            u'entrada a la salida, y termina en el hallazgo: la decisión que define al '
            u'proyecto, incluidas las que salieron al revés.',
            u'<b>Los proyectos de trabajo</b> se cuentan a nivel de arquitectura: capas, '
            u'sincronización, evidencia. Sin reglas de negocio, sin clientes, y con las '
            u'capturas tapadas.',
        ],
        'leer_pie': u'TRES PROYECTOS CON EL CÓDIGO ABIERTO, TRES DE TRABAJO CON EL '
                    u'CÓDIGO CERRADO Y UNO PROPIO EN CAMINO A LA TIENDA.',
        'indice': u'Qué hay acá adentro',
        'indice_sec': u'ÍNDICE',
        'indice_lead': u'Siete proyectos, cada uno con el problema que resuelve, los '
                       u'números que se midieron y la decisión que lo define.',
        'perfiles': u'El mismo trabajo, contado de dos maneras',
        'perfiles_sec': u'PERFILES',
        'perfil': u'PERFIL %02d',
        'experiencia': u'Experiencia',
        'experiencia_sec': u'EXPERIENCIA',
        'actual': u'ACTUAL',
        'proyecto': u'PROYECTO %02d / %02d',
        'medido': u'MEDIDO',
        'hecho_con': u'HECHO CON',
        'codigo': u'CÓDIGO',
        'privado': u'CÓDIGO PRIVADO',
        'privado_nota': u'El código es privado. Lo que está escrito acá es cómo se '
                        u'organizó el trabajo, no qué muestra el producto en pantalla.',
        'como_funciona': u'Cómo funciona',
        'recorrido': u'EL RECORRIDO',
        'hallazgo': u'EL HALLAZGO',
        'evidencia': u'EVIDENCIA',
        'skills': u'Con qué trabajo',
        'skills_sec': u'SKILLS',
        'cierre': u'Dónde verlo funcionando',
        'cierre_sec': u'CIERRE',
        'cierre_big': u'Todo lo que está acá se puede abrir y tocar.',
        'cierre_p': [
            u'La página corre en el navegador, con los proyectos en modo interactivo: '
            u'cada recorrido se camina etapa por etapa con tus propios datos.',
            u'Cada proyecto tiene además su propia ficha en PDF, con el recorrido '
            u'completo, la tabla de evaluaciones y todas las pantallas.',
        ],
        'cierre_nota': u'SIN DATOS DE CONTACTO EN ESTE DOCUMENTO. GENERADO DESDE EL '
                       u'MISMO CONTENIDO QUE LA PÁGINA.',
        'la_pagina': u'LA PÁGINA',
        'anio': u'AÑO',
        'stack': u'STACK',
    },
    'en': {
        'doc': u'DOSSIER // 2026',
        'claim': u'I build products that make sense on the first tap and hold up in '
                 u'their second year.',
        'sub': u'Flutter apps for phone, desktop and web. Language-model systems that '
               u'report what they did and what it cost. One codebase, several screens, '
               u'and measured numbers instead of adjectives.',
        'pie_portada': u'%d PROJECTS · EACH ONE WITH ITS NUMBERS',
        'por_que': u'Why this looks the way it does',
        'por_que_sec': u'FIRST IMPRESSION',
        'por_que_big': u'The first thing you see is already a sample of the work.',
        'por_que_p': u'This document comes out of a site built in Flutter, the same tool '
                     u'I would build your product with: one codebase running on Android, '
                     u'iOS, desktop and the browser. It is not a bought template or a '
                     u'WordPress theme. If you like how it moves, that is exactly what I '
                     u'know how to do.',
        'b1': u'<b>The cyberpunk styling is not decoration, it is a load test.</b> '
              u'Glitches, sweeps, particles and a living grid are about the most '
              u'expensive thing you can ask of an interface. Running all of it smoothly, '
              u'on a phone too, is the proof that performance is not negotiable: the '
              u'background went from 614 draw calls to 11, measured by a test and not by '
              u'eye.',
        'b2': u'<b>And it is a way of looking at a product.</b> A dark console forces '
              u'what I ask of any system: every number in sight, every state with a name '
              u'—waiting for network, retrying in 8 seconds— and nothing faking progress '
              u'that is not happening.',
        'b3': u'<b>With respect for whoever uses it.</b> Every effect switches off in one '
              u'click and the page is still the same page, readable and complete. A '
              u'product that only works if the user likes the glow is not a product: it '
              u'is a trick.',
        'leer': u'HOW TO READ EACH PROJECT',
        'leer_p': [
            u'Every project takes two pages, and neither of them is a brochure.',
            u'<b>The first</b> says which problem it solves, what it is built with and '
            u'what was measured. The numbers come from real runs: latencies, tests, rates.',
            u'<b>The second</b> opens the whole path, stage by stage, from input to '
            u'output, and ends in the finding: the decision that defines the project, '
            u'including the ones that turned out wrong.',
            u'<b>Work projects</b> are described at the architecture level: layers, '
            u'synchronisation, evidence. No business rules, no client names, and the '
            u'screenshots redacted.',
        ],
        'leer_pie': u'THREE PROJECTS WITH OPEN CODE, THREE FROM WORK WITH CLOSED CODE '
                    u'AND ONE OF MY OWN ON ITS WAY TO THE STORE.',
        'indice': u'What is inside',
        'indice_sec': u'CONTENTS',
        'indice_lead': u'Seven projects, each with the problem it solves, the numbers '
                       u'that were measured and the decision that defines it.',
        'perfiles': u'The same work, told two ways',
        'perfiles_sec': u'PROFILES',
        'perfil': u'PROFILE %02d',
        'experiencia': u'Experience',
        'experiencia_sec': u'EXPERIENCE',
        'actual': u'CURRENT',
        'proyecto': u'PROJECT %02d / %02d',
        'medido': u'MEASURED',
        'hecho_con': u'BUILT WITH',
        'codigo': u'CODE',
        'privado': u'PRIVATE CODE',
        'privado_nota': u'The code is private. What is written here is how the work was '
                        u'organised, not what the product shows on screen.',
        'como_funciona': u'How it works',
        'recorrido': u'THE PATH',
        'hallazgo': u'THE FINDING',
        'evidencia': u'EVIDENCE',
        'skills': u'What I work with',
        'skills_sec': u'SKILLS',
        'cierre': u'Where to see it running',
        'cierre_sec': u'CLOSING',
        'cierre_big': u'Everything in here can be opened and touched.',
        'cierre_p': [
            u'The site runs in the browser with the projects in interactive mode: every '
            u'path is walked stage by stage with your own input.',
            u'Each project also has its own brief in PDF, with the full path, the '
            u'evaluation table and every screen.',
        ],
        'cierre_nota': u'NO CONTACT DETAILS IN THIS DOCUMENT. GENERATED FROM THE SAME '
                       u'CONTENT AS THE SITE.',
        'la_pagina': u'THE SITE',
        'anio': u'YEAR',
        'stack': u'STACK',
    },
}

SITIO = u'agusg197.github.io'

# Lo que se agrega sobre la hoja base de las fichas.
CSS = fichas.CSS + u'''
.cover2 { justify-content: center; }
.cover2 .who { font-family: Consolas, monospace; font-size: 9pt; letter-spacing: 4px;
               color: #FCEE0A; }
.cover2 h1 { font-size: 58pt; margin-top: 5mm; text-shadow: 1.4px 0 #FF2A6D, -1.4px 0 #00F0FF; }
.cover2 .claim { font-family: Bahnschrift, sans-serif; font-size: 25pt; line-height: 1.14;
                 color: #E6F1FF; margin-top: 8mm; max-width: 152mm; font-weight: 600; }
.cover2 .sub { font-size: 10.5pt; color: #8A93B2; margin-top: 5mm; max-width: 145mm;
               line-height: 1.55; }
.portrait { position: absolute; right: 16mm; top: 50%; transform: translateY(-50%);
            width: 90mm; border: 1px solid #1B1E33;
            clip-path: polygon(0 0, calc(100% - 12mm) 0, 100% 12mm, 100% 100%,
                               12mm 100%, 0 calc(100% - 12mm)); }

.why { display: flex; gap: 11mm; flex: 1; min-height: 0; }
.why .col { flex: 1; min-width: 0; }
.why .big { font-family: Bahnschrift, sans-serif; font-size: 16pt; color: #E6F1FF;
            line-height: 1.25; margin-bottom: 4mm; }
.why p { font-size: 9.8pt; line-height: 1.5; }
.why .bullet { display: flex; gap: 4mm; }
.why .bullet .n { font-family: Consolas, monospace; font-size: 8pt; color: #FCEE0A;
                  padding-top: 1mm; }
.why .bullet .b { flex: 1; min-width: 0; }

.toc { margin-top: 5mm; }
.toc .row { display: flex; align-items: baseline; gap: 6mm; font-size: 11.5pt;
            border-bottom: 1px solid #12142A; padding: 2.6mm 0; }
.toc .row .n { font-family: Consolas, monospace; color: #FCEE0A; font-size: 8.5pt;
               letter-spacing: 1px; min-width: 16mm; }
.toc .row .d { margin-left: auto; font-family: Consolas, monospace; color: #3C4363;
               font-size: 8.5pt; }

.exp { border-left: 2px solid #1B1E33; padding-left: 5mm; margin-bottom: 6mm; }
.exp .when { font-family: Consolas, monospace; font-size: 8pt; color: #FCEE0A;
             letter-spacing: 1px; }
.exp h3 { margin: 1.5mm 0; }
.exp .where { font-family: Consolas, monospace; font-size: 8.5pt; color: #00F0FF;
              margin-bottom: 2mm; }
.exp ul { margin: 0 0 2.5mm; padding-left: 4mm; }
.exp li { font-size: 9.4pt; color: #8A93B2; line-height: 1.45; margin-bottom: 1.5mm; }

.skills { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10mm; margin-top: 5mm;
          flex: 1; align-content: space-between; }
.skills .cat .kk { font-family: Consolas, monospace; font-size: 9pt; letter-spacing: 2px;
                   color: #FF2A6D; text-transform: uppercase; margin-bottom: 3mm;
                   border-bottom: 1px solid #1B1E33; padding-bottom: 2mm; }
.skills .chip { font-size: 8.5pt; padding: 3px 8px; }

/* Las dos capturas que acompanan a cada proyecto en el dossier. */
.par { display: flex; gap: 5mm; flex: 1; min-height: 0; align-items: flex-start;
       justify-content: center; }
.par.apilado { flex-direction: column; align-items: center; }
/* Dos capturas al lado: cada una entra en su mitad, si no la de la derecha se
   sale de la hoja. */
.par img { border: 1px solid #1B1E33; max-width: calc((100% - 5mm) / 2);
           max-height: 132mm; width: auto; height: auto; object-fit: contain; }
.par.apilado img { max-height: 63mm; max-width: 100%; }
.par.sola img { max-width: 100%; }

.pasos { display: grid; grid-template-columns: 1fr 1fr; gap: 6mm 11mm; align-content: start; }
.paso { display: flex; gap: 4mm; }
.paso .n { font-family: Consolas, monospace; font-size: 8pt; padding-top: 1.5mm; }
.paso .b { flex: 1; min-width: 0; }
.paso h3 { font-size: 12pt; margin-bottom: 1.5mm; }
.paso p { font-size: 9.3pt; line-height: 1.45; margin: 0; }
'''


class Dossier(object):
    """Las paginas se juntan primero y se numeran despues, porque el indice
    necesita saber en que hoja cae cada proyecto."""

    def __init__(self, lang, autor):
        self.lang = lang
        self.autor = autor
        self.L = PROSA[lang]
        self.paginas = []

    def add(self, seccion, cuerpo, acento='#00F0FF', clase=u'', etiqueta=None):
        self.paginas.append((seccion, cuerpo, acento, clase, etiqueta))
        return len(self.paginas)

    def render(self, titulo):
        total = len(self.paginas)
        out = [u'<!DOCTYPE html><html lang="%s"><head><meta charset="utf-8">' % self.lang,
               u'<title>%s</title>' % esc(titulo),
               u'<style>%s</style></head><body>' % CSS]
        for i, (seccion, cuerpo, acento, clase, etiqueta) in enumerate(self.paginas, start=1):
            out.append(u'<section class="page %s">' % clase)
            if seccion is not None:
                out.append(
                    u'<div class="hud"><span class="tag" style="background:%s">%s</span>'
                    u'<span class="sec">%s</span><span class="via">// %s</span>'
                    u'<span class="right">%02d / %02d</span></div>'
                    % (acento, esc(etiqueta or self.L['doc'].split(' ')[0]),
                       esc(seccion.upper()), esc(self.L['doc']), i, total))
            out.append(cuerpo)
            if 'cover2' not in clase:   # la portada trae su propio pie
                out.append(
                    u'<div class="foot"><span>%s · %s</span>'
                    u'<span class="r">%02d / %02d</span></div>'
                    % (esc(self.autor.upper()), esc(self.L['doc']), i, total))
            out.append(u'</section>')
        out.append(u'</body></html>')
        return u'\n'.join(out)


# --------------------------------------------------------------------- hojas ---

def portada(doc, data, lang):
    L, person = doc.L, data['person']
    a = []
    a.append(u'<div class="who">%s</div>' % L['doc'])
    a.append(u'<h1>%s</h1>' % esc(person['name']))
    a.append(u'<div class="claim">%s</div>' % esc(L['claim']))
    a.append(u'<div class="sub">%s</div>' % esc(L['sub']))
    foto = person.get('photo')
    if foto:
        dato = img_b64(os.path.join(ROOT, foto.replace('/', os.sep)), 1100)
        if dato:
            a.append(u'<img class="portrait" src="%s" alt="">' % dato[0])
    a.append(u'<div class="foot"><span>%s</span><span class="r">%s</span></div>'
             % (esc(t(person['location'], lang)).upper(),
                L['pie_portada'] % len(data['profiles'][0]['projectOrder'])))
    doc.add(None, u'\n'.join(a), clase=u'cover2')


def por_que(doc):
    L = doc.L
    a = []
    a.append(u'<h2>%s</h2><div class="rule" style="background:%s"></div>'
             % (esc(L['por_que']), stripes('#FCEE0A')))
    a.append(u'<div class="why"><div class="col">')
    a.append(u'<div class="big">%s</div>' % esc(L['por_que_big']))
    a.append(u'<p>%s</p>' % esc(L['por_que_p']))
    for i, b in enumerate((L['b1'], L['b2'], L['b3']), start=1):
        a.append(u'<div class="bullet"><span class="n">%02d</span><div class="b"><p>%s</p>'
                 u'</div></div>' % (i, b))
    a.append(u'</div><div class="col">')
    a.append(u'<div class="panel" style="height:100%;border-left:3px solid #00F0FF;'
             u'display:flex;flex-direction:column">')
    a.append(u'<div class="k">%s</div>' % esc(L['leer']))
    for p in L['leer_p']:
        a.append(u'<p>%s</p>' % p)
    a.append(u'<div style="margin-top:auto">')
    a.append(u'<div class="rule" style="margin:5mm 0 3mm;background:%s"></div>' % stripes('#FCEE0A'))
    a.append(u'<p class="mono" style="font-size:8.5pt;line-height:1.6;margin:0">%s</p>'
             % esc(L['leer_pie']))
    a.append(u'</div></div></div></div>')
    doc.add(L['por_que_sec'], u'\n'.join(a), '#FCEE0A')


def indice(doc):
    L = doc.L
    a = []
    a.append(u'<h2>%s</h2><div class="rule" style="background:%s"></div>'
             % (esc(L['indice']), stripes('#FCEE0A')))
    a.append(u'<p class="lead">%s</p>' % esc(L['indice_lead']))
    a.append(u'{{TOC}}')
    return doc.add(L['indice_sec'], u'\n'.join(a), '#FCEE0A')


def perfiles(doc, data, lang):
    L = doc.L
    a = []
    a.append(u'<h2>%s</h2><div class="rule" style="background:%s"></div>'
             % (esc(L['perfiles']), stripes('#00F0FF')))
    a.append(u'<div class="cols">')
    colores = ['#00F0FF', '#FF2A6D']
    for i, perfil in enumerate(data['profiles']):
        a.append(u'<div class="col"><div class="panel" style="flex:1;border-color:%s">'
                 % colores[i])
        a.append(u'<div class="k">%s</div>' % (L['perfil'] % (i + 1)))
        a.append(u'<h3 style="color:%s;font-size:17pt">%s</h3>'
                 % (colores[i], esc(t(perfil['label'], lang))))
        a.append(u'<p class="mono" style="font-size:9pt;color:#E6F1FF">%s</p>'
                 % esc(t(perfil['headline'], lang)))
        a.append(u'<p>%s</p>' % esc(t(perfil['bio'], lang)))
        a.append(u'<div class="metrics" style="margin-top:auto">')
        for st in perfil['stats']:
            valor = u'%s%s' % (st['value'], st.get('suffix') or '')
            a.append(u'<div class="metric"><div class="v" style="color:%s">%s</div>'
                     u'<div class="l">%s</div></div>'
                     % (colores[i], esc(num(valor, lang)), esc(t(st['label'], lang))))
        a.append(u'</div></div></div>')
    a.append(u'</div>')
    doc.add(L['perfiles_sec'], u'\n'.join(a), '#00F0FF')


def experiencia(doc, data, lang):
    L = doc.L
    a = []
    a.append(u'<h2>%s</h2><div class="rule" style="background:%s"></div>'
             % (esc(L['experiencia']), stripes('#00F0FF')))
    a.append(u'<div class="cols"><div class="col">')
    mitad = (len(data['experience']) + 1) // 2
    for i, e in enumerate(data['experience']):
        if i == mitad:
            a.append(u'</div><div class="col">')
        a.append(u'<div class="exp">')
        a.append(u'<div class="when">%s%s</div>'
                 % (esc(t(e['period'], lang)),
                    u'  ·  ' + L['actual'] if e.get('current') else u''))
        a.append(u'<h3>%s</h3>' % esc(t(e['role'], lang)))
        a.append(u'<div class="where">%s</div>' % esc(e['company']))
        a.append(u'<p style="font-size:9.6pt">%s</p>' % esc(t(e['summary'], lang)))
        a.append(u'<ul>')
        for h in e['highlights'][:3]:
            a.append(u'<li>%s</li>' % esc(num(t(h, lang), lang)))
        a.append(u'</ul>')
        a.append(u'<div class="chips">')
        for s in e['stack'][:6]:
            a.append(u'<span class="chip">%s</span>' % esc(s))
        a.append(u'</div></div>')
    a.append(u'</div></div>')
    doc.add(L['experiencia_sec'], u'\n'.join(a), '#00F0FF')


def proyecto_que_es(doc, pr, lang, n, total):
    """Primera hoja: que resuelve, con qué está hecho, qué se midió, y dos
    capturas que muestran de qué se está hablando."""
    L = doc.L
    acento = ACENTOS.get(pr.get('accent'), '#00F0FF')

    nombres = SHOTS.get(pr['id']) or [os.path.basename(g['image'])
                                      for g in (pr.get('gallery') or [])[:2]]
    imgs = []
    for nombre in nombres:
        dato = img_b64(os.path.join(ROOT, 'assets', 'images', 'projects', pr['id'], nombre), 950)
        if dato:
            imgs.append(dato)
    # Una ventana de escritorio necesita ancho; dos capturas de telefono, no.
    ancha = bool(imgs) and imgs[0][1] >= 0.6

    a = []
    a.append(u'<div class="cols">')

    a.append(u'<div class="col" style="flex:%s">' % (u'1' if ancha else u'1.3'))
    a.append(u'<h2 style="color:%s">%s</h2>' % (acento, esc(pr['name'])))
    a.append(u'<div class="mono" style="color:%s;font-size:10.5pt;letter-spacing:1px">%s</div>'
             % (acento, esc(t(pr['tagline'], lang))))
    a.append(u'<div class="rule" style="background:%s"></div>' % stripes(acento))
    a.append(u'<p class="lead" style="font-size:11pt">%s</p>' % esc(t(pr['description'], lang)))
    if pr.get('metrics'):
        a.append(u'<div class="k" style="margin-top:5mm">%s</div><div class="metrics">'
                 % L['medido'])
        for m in pr['metrics']:
            a.append(u'<div class="metric"><div class="v" style="color:%s">%s</div>'
                     u'<div class="l">%s</div></div>'
                     % (acento, esc(num(m['value'], lang)), esc(t(m['label'], lang))))
        a.append(u'</div>')
    if not pr.get('pipeline'):
        a.append(u'<p style="margin-top:5mm">%s</p>' % esc(L['privado_nota']))
    a.append(u'<div style="margin-top:auto">')
    a.append(u'<div class="k">%s</div><div class="chips">' % L['hecho_con'])
    for tag in pr.get('tags', []):
        a.append(u'<span class="chip" style="border-color:%s55;color:%s">%s</span>'
                 % (acento, acento, esc(fichas.ETIQUETAS_EN.get(tag, tag) if lang == 'en' else tag)))
    a.append(u'</div>')
    a.append(u'<div class="k" style="margin:4mm 0 1.5mm">%s</div>' % L['codigo'])
    if pr.get('repoUrl'):
        a.append(u'<div class="mono" style="font-size:8.5pt;color:%s">%s</div>'
                 % (acento, esc(pr['repoUrl'].replace('https://', ''))))
    else:
        a.append(u'<div class="mono dim" style="font-size:8.5pt">%s</div>' % L['privado'])
    a.append(u'</div></div>')

    # --- las capturas
    if imgs:
        # Dos capturas al lado solo si son de telefono, que son angostas. Una
        # ventana de escritorio al lado de otra no se lee: va sola y grande.
        if ancha or len(imgs) == 1:
            imgs, clase = imgs[:1], u' sola'
        else:
            clase = u''
        a.append(u'<div class="col" style="flex:%s"><div class="par%s">'
                 % (u'1.5' if ancha else u'1', clase))
        for src, _ in imgs:
            a.append(u'<img src="%s" alt="">' % src)
        a.append(u'</div></div>')
    a.append(u'</div>')
    return doc.add(L['proyecto'] % (n, total), u'\n'.join(a), acento, etiqueta=pr['name'])


def proyecto_como_funciona(doc, pr, lang, n, total):
    """Segunda hoja: el recorrido entero y el hallazgo que define al proyecto."""
    L = doc.L
    etapas = pr.get('pipeline') or []
    if not etapas:
        return None
    acento = ACENTOS.get(pr.get('accent'), '#00F0FF')
    a = []
    a.append(u'<h2>%s <span style="color:%s">%s</span></h2>'
             % (esc(L['como_funciona']), acento, esc(pr['name'])))
    a.append(u'<div class="rule" style="background:%s"></div>' % stripes(acento))
    a.append(u'<div class="pasos">')
    for i, st in enumerate(etapas, start=1):
        a.append(u'<div class="paso"><span class="n" style="color:%s">%02d</span>'
                 u'<div class="b"><h3>%s</h3><p>%s</p></div></div>'
                 % (acento, i, esc(t(st['title'], lang)),
                    esc(num(t(st.get('detail'), lang), lang))))
    a.append(u'</div>')

    ev = pr.get('evals') or {}
    hallazgo = t(ev.get('finding'), lang)
    if hallazgo:
        a.append(u'<div class="panel" style="margin-top:auto;border-left:2px solid %s">' % acento)
        a.append(u'<div class="k" style="margin-bottom:2mm">%s' % L['hallazgo'])
        if t(ev.get('title'), lang):
            a.append(u'<span style="color:#2F3550"> — %s · %s</span>'
                     % (L['evidencia'], esc(num(t(ev['title'], lang), lang))))
        a.append(u'</div>')
        a.append(u'<p style="font-size:9.8pt;color:#C5CEE4;margin:0">%s</p>'
                 % esc(num(hallazgo, lang)))
        a.append(u'</div>')
    return doc.add(L['proyecto'] % (n, total), u'\n'.join(a), acento, etiqueta=pr['name'])


def skills(doc, data, lang):
    L = doc.L
    categorias, vistos = [], set()
    for perfil in data['profiles']:
        for cat in perfil['skills']:
            clave = t(cat['name'], lang)
            if clave in vistos:
                continue
            vistos.add(clave)
            categorias.append(cat)
    a = []
    a.append(u'<h2>%s</h2><div class="rule" style="background:%s"></div>'
             % (esc(L['skills']), stripes('#FF2A6D')))
    a.append(u'<div class="skills">')
    for cat in categorias:
        a.append(u'<div class="cat"><div class="kk">%s</div><div class="chips">'
                 % esc(t(cat['name'], lang)))
        for it in cat['items']:
            nombre = it['name']
            if lang == 'en':
                nombre = fichas.ETIQUETAS_EN.get(nombre, nombre)
            a.append(u'<span class="chip">%s</span>' % esc(nombre))
        a.append(u'</div></div>')
    a.append(u'</div>')
    doc.add(L['skills_sec'], u'\n'.join(a), '#FF2A6D')


def cierre(doc, data, lang):
    L = doc.L
    a = []
    a.append(u'<h2>%s</h2><div class="rule" style="background:%s"></div>'
             % (esc(L['cierre']), stripes('#00F0FF')))
    a.append(u'<div class="cols"><div class="col" style="flex:1.2">')
    a.append(u'<div class="why"><div class="col">')
    a.append(u'<div class="big" style="font-family:Bahnschrift,sans-serif;font-size:17pt;'
             u'color:#E6F1FF;line-height:1.25;margin-bottom:5mm">%s</div>' % esc(L['cierre_big']))
    for p in L['cierre_p']:
        a.append(u'<p>%s</p>' % esc(p))
    a.append(u'<div class="k" style="margin-top:6mm">%s</div>' % L['la_pagina'])
    a.append(u'<div class="mono" style="font-size:13pt;color:#00F0FF">%s</div>' % SITIO)
    a.append(u'</div></div></div>')
    a.append(u'<div class="col"><div class="panel" '
             u'style="flex:0 0 auto;border-left:2px solid #FCEE0A">')
    a.append(u'<div class="k">%s</div>' % L['indice_sec'])
    proyectos = {p['id']: p for p in data['projects']}
    for pr in [proyectos[pid] for pid in data['profiles'][0]['projectOrder']]:
        a.append(u'<div style="display:flex;gap:4mm;align-items:baseline;padding:2mm 0;'
                 u'border-top:1px solid #14162A">'
                 u'<span class="mono" style="font-size:9.5pt;color:%s;letter-spacing:1px;'
                 u'min-width:32mm">%s</span>'
                 u'<span style="font-size:9.4pt;color:#8A93B2">%s</span></div>'
                 % (ACENTOS.get(pr.get('accent'), '#00F0FF'), esc(pr['name']),
                    esc(t(pr['tagline'], lang))))
    a.append(u'</div></div></div>')
    a.append(u'<div style="margin-top:5mm"><div class="rule" style="margin:0 0 3mm;'
             u'background:%s"></div>' % stripes('#1B1E33'))
    a.append(u'<p class="mono" style="font-size:8pt;color:#3C4363;margin:0">%s</p></div>'
             % esc(L['cierre_nota']))
    doc.add(L['cierre_sec'], u'\n'.join(a), '#00F0FF')


def tabla_indice(entradas):
    """Una sola columna: cada proyecto ocupa dos hojas y se lista como un rango,
    en vez de repetir "como funciona" en una fila aparte."""
    filas = []
    for paginas, titulo, desc in entradas:
        filas.append(u'<div class="row"><span class="n">%s</span><span>%s</span>'
                     u'<span class="d">%s</span></div>'
                     % (paginas, esc(titulo), esc(desc)))
    return u'<div class="toc">%s</div>' % u''.join(filas)


def construir(data, lang):
    doc = Dossier(lang, data['person']['name'])
    L = doc.L
    orden = data['profiles'][0]['projectOrder']
    proyectos = {p['id']: p for p in data['projects']}

    portada(doc, data, lang)
    entradas = []
    por_que(doc)
    entradas.append((u'02', L['por_que'], L['por_que_sec'].lower()))
    indice(doc)
    entradas.append((u'%02d' % (len(doc.paginas) + 1), L['perfiles'],
                     L['perfiles_sec'].lower()))
    perfiles(doc, data, lang)
    entradas.append((u'%02d' % (len(doc.paginas) + 1), L['experiencia'],
                     L['experiencia_sec'].lower()))
    experiencia(doc, data, lang)

    for i, pid in enumerate(orden, start=1):
        pr = proyectos[pid]
        pagina = proyecto_que_es(doc, pr, lang, i, len(orden))
        pagina_b = proyecto_como_funciona(doc, pr, lang, i, len(orden))
        rango = u'%02d' % pagina if pagina_b is None else u'%02d–%02d' % (pagina, pagina_b)
        entradas.append((rango, pr['name'], t(pr['tagline'], lang)))

    entradas.append((u'%02d' % (len(doc.paginas) + 1), L['skills'], L['skills_sec'].lower()))
    skills(doc, data, lang)
    entradas.append((u'%02d' % (len(doc.paginas) + 1), L['cierre'], L['cierre_sec'].lower()))
    cierre(doc, data, lang)

    titulo = u'%s — %s' % (u'Dossier', data['person']['name'])
    return doc.render(titulo).replace(u'{{TOC}}', tabla_indice(entradas))


def imprimir(navegador, html, pdf, perfil):
    url = 'file:///' + html.replace('\\', '/')
    cmd = [navegador, '--headless=new', '--disable-gpu', '--no-first-run',
           '--user-data-dir=' + perfil,
           '--print-to-pdf=' + pdf, '--print-to-pdf-no-header', url]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=240)
    if not os.path.exists(pdf):
        print(r.stdout, r.stderr)
        return False
    return True


def main(argv):
    idiomas = [x.lower() for x in argv if x.lower() in ('es', 'en')] or ['es', 'en']
    data = json.load(io.open(os.path.join(ROOT, 'assets', 'data', 'portfolio.json'),
                             encoding='utf-8'))
    os.makedirs(OUT_DIR, exist_ok=True)
    navegador = next((n for n in NAVEGADORES if os.path.exists(n)), None)
    # Perfil aparte: no se toca el navegador que el usuario tenga abierto.
    perfil = tempfile.mkdtemp(prefix='dossier-')
    try:
        for lang in idiomas:
            html_txt = construir(data, lang)
            html = os.path.join(OUT_DIR, 'dossier-%s.html' % lang)
            pdf = os.path.join(OUT_DIR, ARCHIVO[lang])
            io.open(html, 'w', encoding='utf-8').write(html_txt)
            paginas = html_txt.count('<section class="page')
            if navegador is None:
                print('%s  %d paginas -> %s (sin navegador, solo HTML)'
                      % (lang, paginas, os.path.relpath(html, ROOT)))
                continue
            if os.path.exists(pdf):
                os.remove(pdf)
            if imprimir(navegador, html, pdf, perfil):
                print('%s  %d paginas  %4d KB  -> %s'
                      % (lang, paginas, os.path.getsize(pdf) // 1024,
                         os.path.relpath(pdf, ROOT)))
            else:
                print('%s  fallo la impresion' % lang)
    finally:
        shutil.rmtree(perfil, ignore_errors=True)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
