# -*- coding: utf-8 -*-
"""Arma el dossier en PDF a partir del mismo `portfolio.json` que alimenta la página.

    python tool/build_presentacion.py

Escribe `entrega/Dossier-Agustin.pdf`. No incluye ningún dato de contacto: ni
correo, ni usuario, ni redes. Los enlaces a los repositorios públicos sí van,
porque son el código del que habla cada ficha.

Necesita Microsoft Edge (o Chrome) para imprimir el HTML. La alternativa sería
una librería de PDF, pero se perdería el control tipográfico y los enlaces.
"""
import base64
import io
import json
import mimetypes
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, 'entrega')
HTML = os.path.join(OUT_DIR, 'dossier.html')
PDF = os.path.join(OUT_DIR, 'Dossier-Agustin.pdf')

NAVEGADORES = [
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
]

# Qué capturas acompañan a cada proyecto, y con qué recorte.
SHOTS = {
    'leadbox': ['02-pendientes.png', '04-fases.png'],
    'echo': ['02-escuchando.png', '01-preparacion.png'],
    'cifra': ['01-periodo.png', '03-tarjeta.png'],
    'trino': ['01-reposo.png', '03-confirmar.png'],
    'tiza': ['resultado-pizarron.png', 'vista-json.png'],
    'advisor': ['01-ruteo.png'],
}

ES = 'es'


def t(v):
    """Toma el castellano de un valor bilingüe."""
    if isinstance(v, dict):
        return v.get(ES, '')
    return v or ''


def b64(path):
    if not os.path.exists(path):
        return None
    tipo = mimetypes.guess_type(path)[0] or 'image/png'
    with open(path, 'rb') as f:
        return 'data:%s;base64,%s' % (tipo, base64.b64encode(f.read()).decode())


def esc(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


def sec_tag(n):
    return 'SEC.%02d' % n


CSS = u'''
@page { size: A4 landscape; margin: 0; }
* { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
html, body { margin: 0; padding: 0; background: #07070C; color: #E6F1FF; }
body { font-family: 'Segoe UI', system-ui, sans-serif; }

.page {
  position: relative; width: 297mm; height: 210mm; padding: 14mm 16mm 12mm;
  background: #07070C; overflow: hidden; page-break-after: always;
  display: flex; flex-direction: column;
}
.page:last-child { page-break-after: auto; }

/* Rejilla tenue, como el fondo de la página. */
.page::before {
  content: ''; position: absolute; inset: 0; opacity: .5;
  background-image:
    linear-gradient(to right, #12142440 1px, transparent 1px),
    linear-gradient(to bottom, #12142440 1px, transparent 1px);
  background-size: 18mm 18mm;
}
.page > * { position: relative; }

.hud { display: flex; align-items: center; gap: 8px; margin-bottom: 6mm; }
.tag {
  background: #FCEE0A; color: #07070C; font-family: Consolas, monospace;
  font-size: 8pt; letter-spacing: 2px; padding: 2px 7px; font-weight: 700;
}
.hud .via { font-family: Consolas, monospace; font-size: 8pt; color: #4B5273; letter-spacing: 2px; }
.hud .right { margin-left: auto; font-family: Consolas, monospace; font-size: 8pt; color: #4B5273; letter-spacing: 2px; }

h1 { font-family: Bahnschrift, 'Segoe UI', sans-serif; font-weight: 700; font-size: 58pt;
     line-height: .92; margin: 0; letter-spacing: -1px;
     text-shadow: 2px 0 #FF2A6D, -2px 0 #00F0FF; }
h2 { font-family: Bahnschrift, 'Segoe UI', sans-serif; font-weight: 700; font-size: 30pt;
     margin: 0 0 1mm; letter-spacing: -.5px; }
h3 { font-family: Bahnschrift, 'Segoe UI', sans-serif; font-weight: 600; font-size: 13pt;
     margin: 0 0 2mm; color: #E6F1FF; }
p { font-size: 10.2pt; line-height: 1.45; color: #8A93B2; margin: 0 0 2.5mm; }
p strong, .lead strong { color: #E6F1FF; font-weight: 600; }
.lead { font-size: 12pt; color: #E6F1FF; }
.mono { font-family: Consolas, monospace; }
.dim { color: #4B5273; }

.rule { height: 3px; background: repeating-linear-gradient(
  -45deg, #FCEE0A 0 6px, transparent 6px 12px); margin: 3mm 0 5mm; }

.cols { display: flex; gap: 10mm; flex: 1; min-height: 0; }
.col { flex: 1; min-width: 0; }

.metrics { display: flex; gap: 8mm; margin: 3mm 0; flex-wrap: wrap; }
.metric .v { font-family: Bahnschrift, sans-serif; font-weight: 700; font-size: 22pt; line-height: 1; }
.metric .l { font-family: Consolas, monospace; font-size: 7.5pt; color: #8A93B2;
             letter-spacing: 1px; text-transform: uppercase; margin-top: 1mm; }

.chips { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 3mm; }
.chip { font-family: Consolas, monospace; font-size: 7.5pt; padding: 2px 6px;
        border: 1px solid #1B1E33; color: #8A93B2; }

.panel { border: 1px solid #1B1E33; background: #0E0F1A; padding: 4mm; }
.panel .k { font-family: Consolas, monospace; font-size: 7.5pt; letter-spacing: 2px;
            color: #4B5273; text-transform: uppercase; margin-bottom: 2mm; }

/* Las capturas nunca pueden pisar la columna de texto: se limitan por ancho
   ademas de por alto, porque no todas tienen la misma proporcion. */
.shots { display: flex; gap: 5mm; align-items: flex-start; justify-content: flex-end;
         height: 100%; overflow: hidden; }
.shots img { border: 1px solid #1B1E33; max-height: 118mm; max-width: calc(50% - 3mm);
             width: auto; height: auto; object-fit: contain; }
.shots.one img { max-width: 100%; }
.shots.wide img { max-height: 92mm; max-width: 100%; }

.toc { display: grid; grid-template-columns: 1fr 1fr; gap: 3mm 10mm; margin-top: 4mm; }
.toc a { text-decoration: none; color: #E6F1FF; display: flex; align-items: baseline;
         gap: 4px; font-size: 11pt; border-bottom: 1px solid #12142A; padding-bottom: 2mm; }
.toc a .n { font-family: Consolas, monospace; color: #FCEE0A; font-size: 8pt; letter-spacing: 1px; }
.toc a .d { margin-left: auto; font-family: Consolas, monospace; color: #4B5273; font-size: 8pt; }

.exp { border-left: 2px solid #1B1E33; padding-left: 5mm; margin-bottom: 5mm; }
.exp .when { font-family: Consolas, monospace; font-size: 8pt; color: #FCEE0A; letter-spacing: 1px; }
.exp h3 { margin: 1mm 0 1mm; }
.exp .where { font-family: Consolas, monospace; font-size: 8.5pt; color: #00F0FF; margin-bottom: 2mm; }
.exp ul { margin: 0; padding-left: 4mm; }
.exp li { font-size: 9.5pt; color: #8A93B2; line-height: 1.45; margin-bottom: 1.5mm; }

.stages { margin-top: 3mm; }
.stage { display: flex; gap: 3mm; align-items: baseline; margin-bottom: 1.4mm; }
.stage .n { font-family: Consolas, monospace; font-size: 8pt; color: #4B5273; }
.stage .t { font-family: Consolas, monospace; font-size: 9pt; color: #E6F1FF; letter-spacing: 1px; }

.cover { justify-content: center; }
.cover .claim { font-family: Bahnschrift, sans-serif; font-size: 27pt; line-height: 1.12;
                color: #E6F1FF; margin-top: 8mm; max-width: 158mm; font-weight: 600; }
.cover .sub2 { font-size: 10.5pt; color: #8A93B2; margin-top: 5mm; max-width: 145mm;
               line-height: 1.5; }
p b { color: #E6F1FF; font-weight: 600; }

.why { display: flex; gap: 10mm; flex: 1; min-height: 0; }
.why .col { flex: 1; min-width: 0; }
.why .big { font-family: Bahnschrift, sans-serif; font-size: 16pt; color: #E6F1FF;
            line-height: 1.25; margin-bottom: 4mm; }
.why p { font-size: 9.8pt; line-height: 1.48; }
.why .bullet { display: flex; gap: 4mm; }
.why .bullet .n { font-family: Consolas, monospace; font-size: 8pt; color: #FCEE0A;
                  padding-top: 1mm; }
.why .bullet .b { flex: 1; min-width: 0; }
.cover .who { font-family: Consolas, monospace; font-size: 9pt; letter-spacing: 4px; color: #FCEE0A; }
.cover .sub { font-family: Bahnschrift, sans-serif; font-size: 17pt; color: #00F0FF; margin-top: 3mm; }
.cover .foot { position: absolute; left: 16mm; right: 16mm; bottom: 10mm;
               display: flex; font-family: Consolas, monospace; font-size: 8pt;
               color: #4B5273; letter-spacing: 2px; }
.cover .foot .r { margin-left: auto; }
.portrait { position: absolute; right: 16mm; top: 50%; transform: translateY(-50%);
            width: 92mm; border: 1px solid #1B1E33;
            clip-path: polygon(0 0, calc(100% - 12mm) 0, 100% 12mm, 100% 100%, 12mm 100%, 0 calc(100% - 12mm)); }

.skills { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 6mm; margin-top: 4mm; }
.skills .cat .k { font-family: Consolas, monospace; font-size: 8pt; letter-spacing: 2px;
                  color: #FF2A6D; text-transform: uppercase; margin-bottom: 2mm; }

.note { font-size: 9pt; color: #4B5273; }
a.repo { font-family: Consolas, monospace; font-size: 8.5pt; color: #00F0FF; text-decoration: none; }
'''


def build_html(data):
    person = data['person']
    perfiles = data['profiles']
    proyectos = {p['id']: p for p in data['projects']}
    orden = perfiles[0]['projectOrder']

    out = []
    a = out.append
    a(u'<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">')
    a(u'<title>Dossier — %s</title>' % esc(person['name']))
    a(u'<style>%s</style></head><body>' % CSS)

    # ------------------------------------------------------------- portada ---
    foto = b64(os.path.join(ROOT, person.get('photo', '').replace('/', os.sep))) if person.get('photo') else None
    a(u'<section class="page cover" id="portada">')
    a(u'<div class="who">DOSSIER // 2026</div>')
    a(u'<h1>%s</h1>' % esc(person['name']))
    a(u'<div class="claim">Construyo productos que se entienden en el primer toque '
      u'y aguantan el segundo año.</div>')
    a(u'<div class="sub2">Apps en Flutter para teléfono, escritorio y web. Sistemas con '
      u'modelos de lenguaje que dicen qué hicieron y cuánto costaron. Un solo código, '
      u'varias pantallas, y números medidos en vez de adjetivos.</div>')
    if foto:
        a(u'<img class="portrait" src="%s" alt="">' % foto)
    a(u'<div class="foot"><span>%s</span>'
      u'<span class="r">%d PROYECTOS · CADA UNO CON SUS NÚMEROS</span></div>'
      % (esc(t(person['location'])).upper(), len(orden)))
    a(u'</section>')

    # ----------------------------------------------------- por qué se ve así ---
    a(u'<section class="page" id="intro">')
    a(u'<div class="hud"><span class="tag">%s</span>'
      u'<span class="via">// PRIMERA IMPRESION</span>'
      u'<span class="right">DOSSIER // 2026</span></div>' % sec_tag(1))
    a(u'<h2>Por qué esto se ve así</h2><div class="rule"></div>')
    a(u'<div class="why"><div class="col">')
    a(u'<div class="big">Lo primero que ves ya es una muestra del trabajo.</div>')
    a(u'<p>Este documento sale de una página hecha en Flutter, la misma herramienta con la '
      u'que construiría tu producto: un solo código que corre en Android, iOS, escritorio y '
      u'navegador. No es una plantilla comprada ni un tema de WordPress. Si te gusta cómo se '
      u'mueve, eso es exactamente lo que sé hacer.</p>')
    a(u'<div class="bullet"><span class="n">01</span><div class="b"><p>'
      u'<b>El estilo cyberpunk no es decoración, es una prueba de carga.</b> Glitches, '
      u'barridos, partículas y una grilla viva son de lo más caro que se le puede pedir a una '
      u'interfaz. Que todo eso corra fluido, también en un teléfono, es la demostración de que '
      u'el rendimiento no se negocia: el fondo pasó de 614 llamadas de dibujo a 11, medidas '
      u'con un test y no a ojo.</p></div></div>')
    a(u'<div class="bullet"><span class="n">02</span><div class="b"><p>'
      u'<b>Y es una manera de mirar el producto.</b> Un tablero oscuro obliga a lo que le pido '
      u'a cualquier sistema: que cada número esté a la vista, que cada estado tenga nombre '
      u'—esperando red, reintentando en 8 segundos— y que nada finja un progreso que no '
      u'existe. Acá no hay barras de carga decorativas.</p></div></div>')
    a(u'<div class="bullet"><span class="n">03</span><div class="b"><p>'
      u'<b>Con respeto por quien lo usa.</b> Todos los efectos se apagan de un clic y la '
      u'página sigue siendo la misma, legible y completa. Un producto que solo funciona si al '
      u'usuario le gusta el brillo no es un producto: es un truco.</p></div></div>')
    a(u'</div>')
    a(u'<div class="col"><div class="panel" style="height:100%;border-left:3px solid #00F0FF">')
    a(u'<div class="k">CÓMO LEER CADA PROYECTO</div>')
    a(u'<p>Las siete fichas que siguen tienen la misma forma, y ninguna es un folleto.</p>')
    a(u'<p><b>Qué problema resuelve</b>, en una frase que no usa palabras de venta.</p>')
    a(u'<p><b>El recorrido</b>: las etapas por las que pasa el sistema, de la entrada a la '
      u'salida. En la página se caminan una por una con tus propios datos; acá quedan '
      u'listadas.</p>')
    a(u'<p><b>Los números</b>: tiempos, tests, tasas. Si algo no se midió, no está escrito '
      u'como si se hubiera medido.</p>')
    a(u'<p><b>El hallazgo</b>: la decisión que define el proyecto, incluidas las que salieron '
      u'al revés. Dos optimizaciones que llevaron trabajo se midieron y se descartaron, y eso '
      u'también está escrito.</p>')
    a(u'<div class="rule" style="margin:5mm 0"></div>')
    a(u'<p class="mono" style="font-size:9pt">Tres proyectos con el código abierto, tres de '
      u'trabajo con el código cerrado y uno propio en camino a la tienda.</p>')
    a(u'</div></div></div></section>')

    # --------------------------------------------------------------- índice ---
    a(u'<section class="page" id="indice">')
    a(u'<div class="hud"><span class="tag">%s</span><span class="via">// INDICE</span>'
      u'<span class="right">DOSSIER // 2026</span></div>' % sec_tag(2))
    a(u'<h2>Qué hay acá adentro</h2><div class="rule"></div>')
    a(u'<p class="lead">Siete proyectos, cada uno con el problema que resuelve, los '
      u'números que se midieron y la decisión que lo define. Los títulos de esta lista llevan '
      u'a su página.</p>')
    a(u'<div class="toc">')
    entradas = [(u'Por qué esto se ve así', 'intro', u'la primera impresión'),
                (u'Los dos perfiles', 'perfiles', u'cómo trabajo'),
                (u'Experiencia', 'experiencia', u'dónde estuve')]
    for pid in orden:
        pr = proyectos[pid]
        entradas.append((pr['name'], 'p-' + pid, t(pr['tagline'])))
    entradas.append((u'Skills', 'skills', u'con qué trabajo'))
    for i, (titulo, ancla, desc) in enumerate(entradas, start=1):
        a(u'<a href="#%s"><span class="n">%02d</span><span>%s</span><span class="d">%s</span></a>'
          % (ancla, i, esc(titulo), esc(desc)))
    a(u'</div></section>')

    # ------------------------------------------------------------- perfiles ---
    a(u'<section class="page" id="perfiles">')
    a(u'<div class="hud"><span class="tag">%s</span><span class="via">// PERFILES</span>'
      u'<span class="right">02 / %02d</span></div>' % (sec_tag(3), len(entradas)))
    a(u'<h2>El mismo trabajo, contado de dos maneras</h2><div class="rule"></div>')
    a(u'<div class="cols">')
    colores = ['#00F0FF', '#FF2A6D']
    for i, perfil in enumerate(perfiles):
        a(u'<div class="col"><div class="panel" style="height:100%%;border-color:%s">' % colores[i])
        a(u'<div class="k">PERFIL %02d</div>' % (i + 1))
        a(u'<h3 style="color:%s;font-size:16pt">%s</h3>' % (colores[i], esc(t(perfil['label']))))
        a(u'<p class="mono" style="font-size:9pt;color:#E6F1FF">%s</p>' % esc(t(perfil['headline'])))
        a(u'<p>%s</p>' % esc(t(perfil['bio'])))
        a(u'<div class="metrics">')
        for st in perfil['stats']:
            valor = u'%s%s' % (st['value'], st.get('suffix', '') or '')
            a(u'<div class="metric"><div class="v" style="color:%s">%s</div>'
              u'<div class="l">%s</div></div>' % (colores[i], esc(valor), esc(t(st['label']))))
        a(u'</div></div></div>')
    a(u'</div></section>')

    # ----------------------------------------------------------- experiencia ---
    a(u'<section class="page" id="experiencia">')
    a(u'<div class="hud"><span class="tag">%s</span><span class="via">// EXPERIENCIA</span>'
      u'<span class="right">03 / %02d</span></div>' % (sec_tag(4), len(entradas)))
    a(u'<h2>Experiencia</h2><div class="rule"></div>')
    a(u'<div class="cols"><div class="col">')
    mitad = (len(data['experience']) + 1) // 2
    for i, e in enumerate(data['experience']):
        if i == mitad:
            a(u'</div><div class="col">')
        a(u'<div class="exp">')
        a(u'<div class="when">%s</div>' % esc(t(e['period'])))
        a(u'<h3>%s</h3>' % esc(t(e['role'])))
        a(u'<div class="where">%s</div>' % esc(e['company']))
        a(u'<p style="font-size:9.5pt">%s</p>' % esc(t(e['summary'])))
        a(u'<ul>')
        for h in e['highlights'][:2]:
            a(u'<li>%s</li>' % esc(t(h)))
        a(u'</ul>')
        a(u'<div class="chips">')
        for s in e['stack'][:6]:
            a(u'<span class="chip">%s</span>' % esc(s))
        a(u'</div></div>')
    a(u'</div></div></section>')

    # ------------------------------------------------------------ proyectos ---
    acentos = {'cyan': '#00F0FF', 'yellow': '#FCEE0A', 'magenta': '#FF2A6D', 'violet': '#7A5CFF'}
    for n, pid in enumerate(orden, start=4):
        pr = proyectos[pid]
        acento = acentos.get(pr.get('accent'), '#00F0FF')
        a(u'<section class="page" id="p-%s">' % pid)
        a(u'<div class="hud"><span class="tag">%s</span>'
          u'<span class="via">// %s</span><span class="right">%02d / %02d</span></div>'
          % (sec_tag(n + 1), esc(pid.upper()), n, len(entradas)))
        a(u'<div class="cols">')

        # --- texto
        a(u'<div class="col" style="flex:1.25">')
        a(u'<h2 style="color:%s">%s</h2>' % (acento, esc(pr['name'])))
        a(u'<div class="mono" style="color:%s;font-size:10pt;letter-spacing:1px">%s</div>'
          % (acento, esc(t(pr['tagline']))))
        a(u'<div class="rule" style="background:repeating-linear-gradient(-45deg,%s 0 6px,transparent 6px 12px)"></div>' % acento)
        a(u'<p>%s</p>' % esc(t(pr['description'])))
        if pr.get('metrics'):
            a(u'<div class="metrics">')
            for m in pr['metrics']:
                a(u'<div class="metric"><div class="v" style="color:%s">%s</div>'
                  u'<div class="l">%s</div></div>' % (acento, esc(m['value']), esc(t(m['label']))))
            a(u'</div>')
        if pr.get('pipeline'):
            a(u'<div class="stages">')
            a(u'<div class="k mono" style="font-size:7.5pt;letter-spacing:2px;color:#4B5273;'
              u'text-transform:uppercase;margin-bottom:2mm">EL RECORRIDO</div>')
            for i, st in enumerate(pr['pipeline'], start=1):
                a(u'<div class="stage"><span class="n">%02d</span>'
                  u'<span class="t">%s</span></div>' % (i, esc(t(st['title']).upper())))
            a(u'</div>')
        hallazgo = None
        if pr.get('evals') and pr['evals'].get('finding'):
            hallazgo = t(pr['evals']['finding'])
        elif pr.get('pipeline'):
            for st in pr['pipeline']:
                if st.get('risk'):
                    hallazgo = t(st['risk'])
                    break
        if hallazgo:
            corte = hallazgo if len(hallazgo) < 300 else hallazgo[:297].rsplit(' ', 1)[0] + u'…'
            a(u'<div class="panel" style="margin-top:4mm;border-left:3px solid %s">' % acento)
            a(u'<div class="k">EL HALLAZGO</div><p style="margin:0;font-size:9.5pt">%s</p></div>' % esc(corte))
        a(u'<div class="chips">')
        for tag in pr.get('tags', []):
            a(u'<span class="chip" style="border-color:%s33;color:%s">%s</span>' % (acento, acento, esc(tag)))
        a(u'</div>')
        if pr.get('repoUrl'):
            a(u'<div style="margin-top:3mm"><a class="repo" href="%s">%s</a></div>'
              % (esc(pr['repoUrl']), esc(pr['repoUrl'].replace('https://', ''))))
        elif pr.get('private'):
            a(u'<div style="margin-top:3mm" class="mono dim" '
              u'>CODIGO PRIVADO</div>')
        a(u'</div>')

        # --- capturas
        shots = SHOTS.get(pid, [])
        imgs = []
        for nombre in shots:
            src = b64(os.path.join(ROOT, 'assets', 'images', 'projects', pid, nombre))
            if src:
                imgs.append(src)
        if imgs:
            clases = u''
            if pid == 'advisor':
                clases = u' wide'
            elif len(imgs) == 1:
                clases = u' one'
            a(u'<div class="col"><div class="shots%s">' % clases)
            for src in imgs:
                a(u'<img src="%s" alt="">' % src)
            a(u'</div></div>')
        a(u'</div></section>')

    # --------------------------------------------------------------- skills ---
    # Las dos listas de skills, sin repetir categorias.
    categorias = []
    vistos = set()
    for perfil in perfiles:
        for cat in perfil['skills']:
            clave = t(cat['name'])
            if clave in vistos:
                continue
            vistos.add(clave)
            categorias.append(cat)
    a(u'<section class="page" id="skills">')
    a(u'<div class="hud"><span class="tag">%s</span><span class="via">// SKILLS</span>'
      u'<span class="right">%02d / %02d</span></div>'
      % (sec_tag(len(orden) + 5), len(entradas), len(entradas)))
    a(u'<h2>Con qué trabajo</h2><div class="rule"></div>')
    a(u'<div class="skills">')
    for cat in categorias:
        a(u'<div class="cat"><div class="k">%s</div><div class="chips">' % esc(t(cat['name'])))
        for it in cat['items']:
            a(u'<span class="chip">%s</span>' % esc(it['name']))
        a(u'</div></div>')
    a(u'</div>')
    a(u'<div style="margin-top:auto"><div class="rule"></div>'
      u'<p class="note mono">SIN DATOS DE CONTACTO EN ESTE DOCUMENTO. '
      u'GENERADO DESDE EL MISMO CONTENIDO QUE LA PAGINA.</p></div>')
    a(u'</section>')

    a(u'</body></html>')
    return u'\n'.join(out)


def main():
    data = json.load(io.open(os.path.join(ROOT, 'assets', 'data', 'portfolio.json'), encoding='utf-8'))
    os.makedirs(OUT_DIR, exist_ok=True)
    html = build_html(data)
    io.open(HTML, 'w', encoding='utf-8').write(html)
    print('html', len(html) // 1024, 'KB ->', os.path.relpath(HTML, ROOT))

    navegador = next((n for n in NAVEGADORES if os.path.exists(n)), None)
    if navegador is None:
        print('No encontre Edge ni Chrome; el HTML queda listo para imprimir a mano.')
        return 1

    url = 'file:///' + HTML.replace('\\', '/')
    cmd = [
        navegador, '--headless=new', '--disable-gpu', '--no-first-run',
        '--print-to-pdf=' + PDF, '--print-to-pdf-no-header',
        url,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    if not os.path.exists(PDF):
        print(r.stdout, r.stderr)
        return 1
    print('pdf', os.path.getsize(PDF) // 1024, 'KB ->', os.path.relpath(PDF, ROOT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
