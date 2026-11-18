# -*- coding: utf-8 -*-
"""Arma la vista rápida: el mismo contenido del sitio, en una página que carga al instante.

    python tool/build_vista_rapida.py

Lee `assets/data/portfolio.json` y escribe `web/cv/index.html` (castellano) y
`web/cv/en/index.html` (inglés). Son HTML estático, sin Flutter: sirven a quien
no tiene tiempo de caminar la calle, a los buscadores y a quien quiera imprimir.

Hay que correrlo cada vez que cambia el JSON. `test/vista_rapida_test.dart`
falla si la página quedó vieja, así que no se puede publicar desactualizada.
"""
import html
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data", "portfolio.json")
SITE = "https://agusg197.github.io"


def huella(datos: bytes) -> str:
    """FNV-1a de 32 bits sobre el JSON sin retornos de carro. El test hace la misma cuenta."""
    h = 0x811C9DC5
    for b in datos.replace(b"\r", b""):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


def e(texto) -> str:
    return html.escape(str(texto or ""), quote=True)


T = {
    "es": {
        "lang": "es",
        "title": "{name} · Flutter, Full Stack y AI Engineer",
        "description": "Vista rápida del portafolio de {name}: experiencia, proyectos en producción, habilidades y CV. Desarrollador Flutter, Full Stack y AI Engineer en Córdoba, Argentina, en remoto.",
        "quick": "Vista rápida",
        "street": "Ver el sitio interactivo",
        "street_note": "El portafolio completo es una calle en pixel art donde cada proyecto se prueba paso a paso.",
        "other": "English",
        "profile": "Perfil",
        "cv": "Descargar CV",
        "cv_other": "CV en inglés",
        "about": "Sobre mí",
        "experience": "Experiencia",
        "projects": "Proyectos",
        "skills": "Habilidades",
        "contact": "Contacto",
        "current": "actual",
        "private": "código privado",
        "repo": "Repositorio",
        "live": "Sitio en vivo",
        "walk": "Probarlo paso a paso",
        "mail": "Correo",
        "mail_fallback": "el correo está en el CV",
        "languages": "Idiomas",
        "footer": "Esta página se genera desde los mismos datos que el sitio interactivo.",
        "print": "Imprimir o guardar como PDF",
    },
    "en": {
        "lang": "en",
        "title": "{name} · Flutter, Full Stack and AI Engineer",
        "description": "Quick view of {name}'s portfolio: experience, projects in production, skills and CV. Flutter developer, Full Stack and AI Engineer in Córdoba, Argentina, working remotely.",
        "quick": "Quick view",
        "street": "See the interactive site",
        "street_note": "The full portfolio is a pixel-art street where every project can be tried step by step.",
        "other": "Español",
        "profile": "Profile",
        "cv": "Download CV",
        "cv_other": "CV in Spanish",
        "about": "About",
        "experience": "Experience",
        "projects": "Projects",
        "skills": "Skills",
        "contact": "Contact",
        "current": "current",
        "private": "private code",
        "repo": "Repository",
        "live": "Live site",
        "walk": "Try it step by step",
        "mail": "Email",
        "mail_fallback": "the email address is in the CV",
        "languages": "Languages",
        "footer": "This page is generated from the same data as the interactive site.",
        "print": "Print or save as PDF",
    },
}

CSS = """
:root{--bg:#0b0c14;--panel:#12131f;--line:#262a40;--text:#e6f1ff;--muted:#9aa3c0;--yellow:#fcee0a;--cyan:#00f0ff;--magenta:#ff2a6d}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--text);font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif}
@font-face{font-family:"Chakra Petch";font-weight:700;font-display:swap;src:url("__ROOT__assets/assets/google_fonts/ChakraPetch-Bold.ttf") format("truetype")}
a{color:var(--cyan)}
a:focus-visible,label:focus-visible,summary:focus-visible{outline:2px solid var(--yellow);outline-offset:2px}
.wrap{max-width:920px;margin:0 auto;padding:20px 20px 56px}
.top{display:flex;flex-wrap:wrap;gap:10px 18px;align-items:center;justify-content:space-between;font-size:14px;padding-bottom:14px;border-bottom:1px solid var(--line)}
.tag{background:var(--yellow);color:#07070c;font-weight:700;letter-spacing:.14em;text-transform:uppercase;font-size:12px;padding:3px 10px}
.top nav{display:flex;flex-wrap:wrap;gap:6px 16px}
header.me{display:flex;gap:22px;align-items:center;margin:28px 0 8px}
header.me img{width:104px;height:104px;object-fit:cover;border:2px solid var(--cyan);flex:none}
h1{font:700 clamp(30px,6vw,44px)/1.05 "Chakra Petch",system-ui,sans-serif;margin:0 0 6px;letter-spacing:-.01em}
h2{font:700 22px/1.2 "Chakra Petch",system-ui,sans-serif;margin:44px 0 14px;padding-bottom:6px;border-bottom:2px solid var(--yellow);text-transform:uppercase;letter-spacing:.06em}
h3{font-size:18px;margin:0 0 2px}
.sub{color:var(--muted);font-size:14.5px;margin:0}
.headline{font-size:18px;font-weight:600;margin:0 0 4px;color:var(--yellow)}
p{margin:0 0 12px}
ul{margin:8px 0 0;padding-left:20px}
li{margin-bottom:6px}
.tabs{display:flex;flex-wrap:wrap;gap:8px;margin:22px 0 4px;align-items:center}
.tabs span{color:var(--muted);font-size:13px;letter-spacing:.1em;text-transform:uppercase;margin-right:4px}
.tabs label{border:1px solid var(--line);padding:9px 16px;cursor:pointer;font-weight:600;font-size:15px;min-height:44px;display:inline-flex;align-items:center}
input.p{position:absolute;opacity:0;pointer-events:none}
.prof{display:none}
__PROFILE_RULES__
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:16px 0}
.stat{background:var(--panel);border:1px solid var(--line);padding:12px 14px}
.stat b{display:block;font:700 26px/1.1 "Chakra Petch",system-ui,sans-serif;color:var(--yellow)}
.stat span{color:var(--muted);font-size:13.5px}
.btns{display:flex;flex-wrap:wrap;gap:10px;margin:14px 0 0}
.btn{display:inline-flex;align-items:center;min-height:44px;padding:9px 16px;border:1px solid var(--cyan);color:var(--cyan);text-decoration:none;font-weight:600;font-size:15px}
.btn.main{background:var(--yellow);border-color:var(--yellow);color:#07070c}
.card{background:var(--panel);border:1px solid var(--line);padding:18px 20px;margin-bottom:14px}
.card .when{color:var(--muted);font-size:14px;margin:0 0 8px}
.now{display:inline-block;margin-left:8px;padding:1px 8px;background:var(--cyan);color:#07070c;font-size:11.5px;font-weight:700;text-transform:uppercase;letter-spacing:.08em;vertical-align:2px}
.chips{display:flex;flex-wrap:wrap;gap:6px;margin-top:12px;padding:0;list-style:none}
.chips li{margin:0;border:1px solid var(--line);padding:2px 9px;font-size:13px;color:var(--muted)}
.nums{display:flex;flex-wrap:wrap;gap:6px 22px;margin:10px 0 0;padding:0;list-style:none;font-size:14.5px}
.nums li{margin:0}
.nums b{color:var(--yellow)}
.links{display:flex;flex-wrap:wrap;gap:6px 18px;margin-top:12px;font-size:15px}
.skills{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:12px}
.skills .card{margin:0}
.skills h3{font-size:15px;color:var(--cyan);text-transform:uppercase;letter-spacing:.08em;margin-bottom:6px}
.note{color:var(--muted);font-size:14.5px}
footer{margin-top:48px;padding-top:16px;border-top:1px solid var(--line);color:var(--muted);font-size:14px}
@media (max-width:560px){header.me{flex-direction:column;align-items:flex-start;gap:14px}.wrap{padding:16px 16px 48px}}
@media print{
  :root{--bg:#fff;--panel:#fff;--line:#bbb;--text:#111;--muted:#444;--yellow:#111;--cyan:#111}
  body{font-size:11pt}.top nav,.tabs,.btns,.noprint{display:none!important}
  .tag,.now{background:none;border:1px solid #111;color:#111}
  .card,.stat{break-inside:avoid}a{color:#111;text-decoration:none}h2{margin-top:22pt}
}
"""


def L(valor, lang):
    if isinstance(valor, dict):
        return valor.get(lang) or valor.get("es") or valor.get("en") or ""
    return valor or ""


def pagina(d, lang, sha):
    t = T[lang]
    otro = "en" if lang == "es" else "es"
    root = "../" if lang == "es" else "../../"
    url = f"{SITE}/cv/" if lang == "es" else f"{SITE}/cv/en/"
    url_otro = f"{SITE}/cv/en/" if lang == "es" else f"{SITE}/cv/"
    rel_otro = "en/" if lang == "es" else "../"
    person = d["person"]
    nombre = person.get("fullName") or person["name"].title()
    perfiles = d["profiles"]
    asset = root + "assets/"

    reglas = "\n".join(
        f"#p-{p['id']}:checked~.wrap .prof-{p['id']}{{display:block}}\n"
        f"#p-{p['id']}:checked~.wrap label[for=p-{p['id']}]{{background:var(--cyan);border-color:var(--cyan);color:#07070c}}"
        for p in perfiles
    )
    css = CSS.replace("__ROOT__", root).replace("__PROFILE_RULES__", reglas)

    radios = "".join(
        f'<input class="p" type="radio" name="p" id="p-{p["id"]}"{" checked" if i == 0 else ""}>'
        for i, p in enumerate(perfiles)
    )
    tabs = f'<div class="tabs" role="group" aria-label="{e(t["profile"])}"><span>{e(t["profile"])}</span>' + "".join(
        f'<label for="p-{p["id"]}" tabindex="0">{e(L(p["label"], lang))}</label>' for p in perfiles
    ) + "</div>"

    def bloque_perfil(p):
        cv = p.get("cv") or {}
        botones = ""
        if cv.get(lang):
            botones += f'<a class="btn main" href="{e(asset + cv[lang])}" download>{e(t["cv"])} · {e(L(p["label"], lang))}</a>'
        if cv.get(otro):
            botones += f'<a class="btn" href="{e(asset + cv[otro])}" download>{e(t["cv_other"])}</a>'
        stats = "".join(
            f'<div class="stat"><b>{e(s["value"])}{e(s.get("suffix", ""))}</b><span>{e(L(s["label"], lang))}</span></div>'
            for s in p.get("stats", [])
        )
        return (
            f'<div class="prof prof-{p["id"]}">'
            f'<p class="headline">{e(L(p["headline"], lang))}</p>'
            f'<p>{e(L(p["bio"], lang))}</p>'
            f'<div class="stats">{stats}</div>'
            f'<div class="btns">{botones}</div>'
            "</div>"
        )

    def bloque_skills(p):
        cats = "".join(
            f'<div class="card"><h3>{e(L(c["name"], lang))}</h3><p class="sub">{e(" · ".join(i["name"] for i in c["items"]))}</p></div>'
            for c in p.get("skills", [])
        )
        return f'<div class="prof prof-{p["id"]}"><div class="skills">{cats}</div></div>'

    experiencia = ""
    for x in d["experience"]:
        ahora = f'<span class="now">{e(t["current"])}</span>' if x.get("current") else ""
        puntos = "".join(f"<li>{e(L(h, lang))}</li>" for h in x.get("highlights", []))
        chips = "".join(f"<li>{e(s)}</li>" for s in x.get("stack", []))
        experiencia += (
            '<article class="card">'
            f'<h3>{e(L(x["role"], lang))} · {e(x["company"])}{ahora}</h3>'
            f'<p class="when">{e(L(x["period"], lang))}</p>'
            f'<p>{e(L(x["summary"], lang))}</p>'
            f"<ul>{puntos}</ul>"
            f'<ul class="chips">{chips}</ul>'
            "</article>"
        )

    proyectos = ""
    for p in d["projects"]:
        nums = "".join(f'<li><b>{e(m["value"])}</b> {e(L(m["label"], lang))}</li>' for m in p.get("metrics", []))
        chips = "".join(f"<li>{e(s)}</li>" for s in p.get("tags", []))
        enlaces = []
        if p.get("liveUrl"):
            enlaces.append(f'<a href="{e(p["liveUrl"])}" rel="noopener">{e(t["live"])} ↗</a>')
        if p.get("repoUrl"):
            enlaces.append(f'<a href="{e(p["repoUrl"])}" rel="noopener">{e(t["repo"])} ↗</a>')
        if p.get("pipeline"):
            enlaces.append(f'<a class="noprint" href="{root}#/p/{e(p["id"])}">{e(t["walk"])} →</a>')
        privado = f' · {e(t["private"])}' if p.get("private") and not p.get("repoUrl") else ""
        proyectos += (
            f'<article class="card" id="{e(p["id"])}">'
            f'<h3>{e(p["name"])}</h3>'
            f'<p class="when">{e(L(p["tagline"], lang))} · {e(p.get("year", ""))}{privado}</p>'
            f'<p>{e(L(p["description"], lang))}</p>'
            f'<ul class="nums">{nums}</ul>'
            f'<ul class="chips">{chips}</ul>'
            + (f'<div class="links">{"".join(enlaces)}</div>' if enlaces else "")
            + "</article>"
        )

    redes = "".join(
        f'<a class="btn" href="{e(l["url"])}" rel="me noopener">{e(l["label"])}</a>'
        for l in person.get("links", [])
        if l.get("url") and not l["url"].startswith("mailto")
    )
    correo = (
        f'<a class="btn" id="mail" href="#contacto" data-u="{e(person.get("emailUser", ""))}" '
        f'data-h="{e(person.get("emailHost", ""))}">{e(t["mail"])}</a>'
    )

    ld = {
        "@context": "https://schema.org",
        "@type": "ProfilePage",
        "inLanguage": lang,
        "url": url,
        "mainEntity": {
            "@type": "Person",
            "name": nombre,
            "alternateName": person.get("handle", "").lstrip("@"),
            "jobTitle": [L(p["headline"], lang).split(" · ")[0] for p in perfiles],
            "url": SITE + "/",
            "image": f"{SITE}/assets/{person['photo']}" if person.get("photo") else None,
            "address": {"@type": "PostalAddress", "addressLocality": "Córdoba", "addressCountry": "AR"},
            "knowsLanguage": ["es", "en"],
            "sameAs": [l["url"] for l in person.get("links", []) if l.get("url", "").startswith("http")],
            "knowsAbout": sorted({i["name"] for p in perfiles for c in p.get("skills", []) for i in c["items"]}),
        },
    }
    ld["mainEntity"] = {k: v for k, v in ld["mainEntity"].items() if v}

    foto = (
        f'<img src="{e(asset + person["photo"])}" alt="{e(nombre)}" width="104" height="104">'
        if person.get("photo")
        else ""
    )
    titulo = t["title"].format(name=nombre)
    descripcion = t["description"].format(name=nombre)

    return f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(titulo)}</title>
<meta name="description" content="{e(descripcion)}">
<meta name="portfolio-sha" content="{sha}">
<meta name="theme-color" content="#0b0c14">
<link rel="canonical" href="{url}">
<link rel="alternate" hreflang="{lang}" href="{url}">
<link rel="alternate" hreflang="{otro}" href="{url_otro}">
<link rel="alternate" hreflang="x-default" href="{SITE}/cv/">
<link rel="icon" type="image/png" href="{root}favicon.png">
<meta property="og:type" content="profile">
<meta property="og:title" content="{e(titulo)}">
<meta property="og:description" content="{e(descripcion)}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{SITE}/og.png">
<meta name="twitter:card" content="summary_large_image">
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>
<style>{css}</style>
</head>
<body>
{radios}
<div class="wrap">
<div class="top">
<span class="tag">{e(t["quick"])}</span>
<nav aria-label="{e(t["quick"])}">
<a href="{root}">{e(t["street"])} →</a>
<a href="{rel_otro}" hreflang="{otro}" lang="{otro}">{e(t["other"])}</a>
</nav>
</div>

<header class="me">
{foto}
<div>
<h1>{e(nombre)}</h1>
<p class="sub">{e(person.get("handle", ""))} · {e(L(person.get("location"), lang))}</p>
<p class="sub">{e(t["languages"])}: {e(L(person.get("languages"), lang))}</p>
</div>
</header>

<main>
{tabs}
<section aria-label="{e(t["about"])}">
{"".join(bloque_perfil(p) for p in perfiles)}
<div class="btns noprint">{redes}{correo}</div>
</section>

<section>
<h2>{e(t["experience"])}</h2>
{experiencia}
</section>

<section>
<h2>{e(t["projects"])}</h2>
<p class="note noprint">{e(t["street_note"])} <a href="{root}">{e(t["street"])} →</a></p>
{proyectos}
</section>

<section>
<h2>{e(t["skills"])}</h2>
{"".join(bloque_skills(p) for p in perfiles)}
</section>

<section id="contacto">
<h2>{e(t["contact"])}</h2>
<p><span id="mail-text">{e(t["mail_fallback"])}</span></p>
<div class="btns noprint">{redes}<button class="btn" type="button" onclick="window.print()" style="background:none;cursor:pointer;font:inherit;font-weight:600">{e(t["print"])}</button></div>
</section>
</main>

<footer>{e(t["footer"])} · <a href="{root}">{SITE.replace("https://", "")}</a></footer>
</div>
<script>
(function(){{
  // El correo no viaja escrito en el HTML: se arma acá, igual que en el sitio.
  var a=document.getElementById('mail'),s=document.getElementById('mail-text');
  if(a&&a.dataset.u){{var m=a.dataset.u+'@'+a.dataset.h;a.href='mailto:'+m;if(s){{var l=document.createElement('a');l.href='mailto:'+m;l.textContent=m;s.replaceWith(l);}}}}
  // Las pestañas son radios: con teclado, Enter o espacio sobre la etiqueta la elige.
  document.querySelectorAll('.tabs label').forEach(function(l){{l.addEventListener('keydown',function(ev){{if(ev.key==='Enter'||ev.key===' '){{ev.preventDefault();document.getElementById(l.htmlFor).checked=true;}}}});}});
  // ?p=ai o #ai abre directo en ese perfil.
  var q=new URLSearchParams(location.search).get('p')||location.hash.slice(1);var r=q&&document.getElementById('p-'+q);if(r&&r.type==='radio')r.checked=true;
}})();
</script>
</body>
</html>
"""


def main():
    crudo = open(DATA, "rb").read()
    d = json.loads(crudo.decode("utf-8"))
    sha = huella(crudo)
    for lang, destino in (("es", "web/cv/index.html"), ("en", "web/cv/en/index.html")):
        ruta = os.path.join(ROOT, *destino.split("/"))
        os.makedirs(os.path.dirname(ruta), exist_ok=True)
        with open(ruta, "w", encoding="utf-8", newline="\n") as f:
            f.write(pagina(d, lang, sha))
        print(destino, os.path.getsize(ruta) // 1024, "KB", "· huella", sha)


if __name__ == "__main__":
    main()
