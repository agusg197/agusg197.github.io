# Deploy — qué hay que tener en cuenta

Cómo publicar este portafolio sin pagar nada, qué revisar antes, y qué queda pendiente.
Escrito el 2026-09-18, con el sitio ya completo: seis proyectos, dos perfiles y el lab.

---

## 0. El bloqueante

**El proyecto todavía no es un repositorio git.** No hay historial, no hay remoto y no hay
nada que publicar desde ningún lado. Es el primer paso y no depende de ninguna decisión:

```bash
git init
git add .
git commit -m "Portafolio cyberpunk: seis proyectos, dos perfiles, lab"
```

Antes del primer `git add`, mirá la sección 3: hay archivos en el árbol que no conviene
subir tal cual.

---

## 1. Dónde publicarlo

Las dos opciones gratuitas que sirven para esto. Un Flutter web es HTML + JS + assets
estáticos: cualquier hosting de archivos lo sirve.

### GitHub Pages

| | |
|---|---|
| Costo | gratis, sin tarjeta |
| URL | `agusg197.github.io/<repo>` o `agusg197.github.io` si el repo se llama `agusg197.github.io` |
| Límites | 1 GB de repo, 100 GB de tráfico al mes, 10 builds por hora |
| Dominio propio | sí, con HTTPS de Let's Encrypt |
| Requisito | **el repo tiene que ser público** en la cuenta gratuita |

**El detalle que rompe la primera vez:** si el sitio vive en `usuario.github.io/portafolio`,
todas las rutas relativas cuelgan de `/portafolio/`. Hay que compilar con la base correcta:

```bash
flutter build web --release --base-href /portafolio/
```

Con un repo llamado `agusg197.github.io` la base es `/` y el problema no existe. Es la
opción más simple y la recomiendo.

**Workflow para que se publique solo en cada push a `main`** (`.github/workflows/deploy.yml`):

```yaml
name: deploy
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      # Con repo <usuario>.github.io, sacá --base-href.
      - run: flutter build web --release --base-href /portafolio/
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

Después hay que entrar una vez a **Settings → Pages** y poner *Source: GitHub Actions*.

### Firebase Hosting

| | |
|---|---|
| Costo | gratis en el plan Spark |
| URL | `<proyecto>.web.app` y `<proyecto>.firebaseapp.com` |
| Límites | 10 GB almacenados, **360 MB de transferencia por día** |
| Dominio propio | sí, con certificado automático |
| Ventaja real | control de cabeceras de caché y compresión |

```bash
npm i -g firebase-tools
firebase login
firebase init hosting     # public: build/web · single-page app: no (usamos rutas con #)
flutter build web --release
firebase deploy --only hosting
```

`firebase.json` con caché razonable:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "**/*.@(js|wasm|ttf|otf|woff2|png|jpg|json)",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
      },
      {
        "source": "/index.html",
        "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
      }
    ]
  }
}
```

**Cuidado con los 360 MB por día.** Una visita fría se lleva alrededor de 4 MB entre
CanvasKit, el bundle y las imágenes: son unas 90 visitas diarias antes de que el sitio se
apague hasta el otro día. Para un portafolio alcanza de sobra, pero si algo se vuelve viral
el que se cae es este. GitHub Pages no tiene ese corte.

### Cuál

**GitHub Pages**, con el repo llamado `agusg197.github.io`. Es gratis de verdad, no hay
cuota diaria que corte el sitio, el deploy queda automatizado en el mismo lugar donde vive
el código, y los tres repos de los proyectos ya están ahí.

---

## 2. Lo que hay que revisar antes de publicar

### Ya está hecho

- [x] Título de la pestaña, descripción y Open Graph actualizados a «AGUSTÍN // Flutter &
      AI Engineer». Antes decían `AGUSG197 // Portfolio`.
- [x] Rutas con `#` (`/#/p/echo`). Es lo que hace que un hosting estático no necesite
      reescrituras: sin eso, entrar directo a `/p/echo` da 404 en GitHub Pages.
- [x] `mock: false` en `portfolio.json`: no queda contenido de relleno.
- [x] Los tres proyectos privados (`leadbox`, `crediclub`, `echo`) sin `repoUrl` y con el
      candado en la tarjeta.
- [x] Las capturas de Leadbox, redactadas.

### Falta decidir

- [x] **`og:image`**: `web/og.png`, 1200×630, una captura real del hero. Cuando haya
      dominio conviene pasarla a URL absoluta (`https://…/og.png`): LinkedIn y algunos
      scrapers no resuelven rutas relativas contra el `<base href>`.
- [x] **Favicon e íconos de la app**: generados con `tool/render_icons.py` — marco con
      esquina cortada, la A con aberración cromática y la franja de peligro. Incluye las
      variantes maskable, que son las que usa Android al instalar la PWA.
- [ ] **La imagen original del retrato quedó en la raíz**
      (`ChatGPT Image Sep 18, 2026, 06_05_18 PM.png`, 2,5 MB). La versión recortada ya vive
      en `assets/images/about/`. Conviene moverla a una carpeta `design/` o ignorarla: si
      no, se sube un PNG de 2,5 MB que nadie usa.
- [ ] **Los CV en PDF se publican enteros** (`assets/cv/`). Revisá que no tengan teléfono,
      dirección ni documento: en un repo público quedan indexables para siempre.
- [ ] **El mail está a la vista** en la tarjeta de identidad y en la terminal. Es a
      propósito, pero cuenta con que lo van a rastrear los bots. La alternativa es un
      formulario o un mail alias.
- [ ] **Las fuentes se bajan de Google en cada visita** (`google_fonts`). Funciona, pero
      agrega una dependencia externa y un parpadeo en la primera carga. Empaquetarlas en
      `assets/fonts/` las vuelve locales y saca la petición.

### Conviene medir una vez publicado

- [ ] Lighthouse en móvil. El punto flojo previsible es el peso inicial de CanvasKit; el
      splash tapa la espera pero no la elimina.
- [ ] Abrirlo en un teléfono real, no solo en el emulador del navegador: el cursor neón, el
      tilt de las tarjetas y el scroll horizontal de las capturas se comportan distinto con
      dedos.
- [ ] Probar los dos idiomas y los dos perfiles después del deploy: el JSON se sirve como
      asset y un error de ruta ahí deja la página en «cargando» para siempre.

---

## 3. Lo que no debería subir al repo público

El sitio va a ser público, así que el repositorio también (en Pages gratis no hay otra).

| Archivo | Qué hacer |
|---|---|
| `ChatGPT Image Sep 18, ….png` | moverlo a `design/` o ignorarlo |
| `CVs/` (en la raíz) | son los originales de trabajo; los publicados son los de `assets/cv/` |
| `build/` | ya está ignorado |
| `tool/redact_leadbox_shots.py` | apunta a rutas locales del repo privado de Leadbox. No filtra nada, pero deja el mapa de qué se tapó. Decidí si queda |
| `.claude/` | configuración de la sesión; no molesta, pero no aporta |

Un `.gitignore` con esto arriba de lo que ya hay:

```gitignore
# Material de trabajo que no va al sitio
/CVs/
/design/
ChatGPT Image*.png
```

---

## 4. El orden

1. Resolver los pendientes de la sección 2 que quieras resolver (og:image y favicon son los
   que más se notan al compartir el link).
2. Ajustar `.gitignore` y mover lo de la sección 3.
3. `git init`, primer commit.
4. Crear el repo `agusg197.github.io` en GitHub y pushear.
5. Agregar el workflow, activar Pages con *Source: GitHub Actions*.
6. Esperar el primer build (unos 3–4 minutos: la acción baja Flutter).
7. Abrir el sitio en un teléfono y en una computadora, con los dos perfiles y los dos
   idiomas.
8. Recién ahí compartir el link.

---

## 5. Después

- **Datos vivos de GitHub**: los repos públicos podrían traer estrellas y último commit en
  tiempo de build. La API sin token da 60 pedidos por hora, así que conviene pedirla en el
  workflow y escribir un JSON, no en el navegador del visitante.
- **Dominio propio**: un `.dev` o `.ar` cuesta plata, pero el hosting sigue siendo gratis.
  Se configura con un `CNAME` en el repo.
- **Cuando Echo tenga repositorio público**, agregarle `repoUrl` en `portfolio.json` y se le
  enciende el enlace solo.
