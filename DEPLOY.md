# Deploy — qué hay que tener en cuenta

Cómo publicar este portafolio sin pagar nada, qué revisar antes, y qué queda pendiente.
Escrito el 2026-09-18, con el sitio ya completo: seis proyectos, dos perfiles y el lab.

---

## 0. Dónde estamos

El repositorio ya existe, con el primer commit hecho sobre la rama `main`, y el árbol ya
está limpio de lo que no debía subir. **Lo único que falta es lo que solo podés hacer vos:
crear el repositorio en GitHub y empujar.** Los comandos están en la sección 4.

Decidido el 2026-09-18:

| Decisión | Qué se eligió |
|---|---|
| Hosting | GitHub Pages, repositorio `agusg197.github.io` (sitio en la raíz del dominio) |
| CV | se publican sin el teléfono; el mail y el LinkedIn quedan |
| Correo en la página | visible, pero partido en el JSON y armado en tiempo de ejecución |

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
- [x] **Las tipografías viajan con el sitio.** Están en `assets/google_fonts/` y
      `GoogleFonts.config.allowRuntimeFetching = false` impide que el paquete salga a
      buscarlas. La pantalla de carga usa las mismas, servidas desde `web/fonts/`. Antes
      cada visita hacía tres pedidos a Google; ahora, ninguno. Verificado en el panel de red.
- [x] **Los CV se publican sin el teléfono.** `tool/cv_sin_telefono.py` toma los originales
      de `CVs/` (que no se suben) y escribe en `assets/cv/` una copia sin el número: no lo
      tapa con un recuadro, lo saca del contenido, así no se puede seleccionar ni extraer.
- [x] **El correo no está escrito entero en ningún asset.** El JSON guarda `emailUser` y
      `emailHost` por separado y el enlace como `mailto:` a secas; la dirección se arma en
      el modelo. En la página se ve igual y el botón de copiar funciona igual.
- [x] **El retrato original salió de la raíz** a `design/`, que está ignorado.
- [x] **Workflow de publicación** en `.github/workflows/deploy.yml`: corre `flutter analyze`
      y `flutter test` antes de compilar, y si alguno falla no publica.

### Falta decidir

- [x] **`og:image`**: `web/og.png`, 1200×630, la calle dibujada por el mismo pintor del sitio
      (`flutter test tool/render_og.dart` la regenera). Va con URL absoluta
      (`https://agusg197.github.io/og.png`): con la relativa, Discord mostraba el enlace
      sin imagen.
- [x] **Favicon e íconos de la app**: generados con `tool/render_icons.py` — marco con
      esquina cortada, la A con aberración cromática y la franja de peligro. Incluye las
      variantes maskable, que son las que usa Android al instalar la PWA.
- [x] **Datos frescos después de un deploy.** Pages deja cachear cada archivo diez
      minutos y Flutter no le pone hash a los assets: el código nuevo podía llegar con el
      `portfolio.json` viejo. El JSON se pide con `cache: no-cache` (revalida; si no
      cambió, es un 304 vacío).
- [x] **Los embeds tienen caché propia.** Discord y compañía guardan la vista previa de
      un enlace un buen rato: después de cambiar el título o la imagen, el mismo enlace
      puede seguir mostrando la versión vieja. Para probar, pegar el enlace con algo al
      final (`https://agusg197.github.io/?v=2`).
- [ ] **El dossier en PDF viaja en el repositorio** (`entrega/Dossier-Agustin.pdf`, 1,8 MB).
      Si querés ofrecerlo como descarga desde la página hay que copiarlo a `web/`; si no,
      puede quedar fuera del repositorio.
- [ ] **Las tipografías pesan 1,3 MB** en total, casi todo Rajdhani, que trae devanagari
      además de latino. Recortarlas a los caracteres que se usan las dejaría en una fracción,
      pero hace falta `fonttools` y hay que rehacerlo cada vez que cambie el idioma.

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

Ya está aplicado en `.gitignore`:

```gitignore
# Material de trabajo que no va al sitio
/CVs/
/design/
/entrega/dossier.html
```

El primer commit tiene 112 archivos y 6,9 MB. `build/`, `CVs/`, `design/` y el HTML
intermedio del dossier quedaron afuera.

---

## 4. Lo que falta hacer

Todo lo anterior ya está en el commit. Estos cuatro pasos necesitan tu cuenta:

**1. Crear el repositorio.** En GitHub, nuevo repositorio **público** llamado exactamente
`agusg197.github.io`. Sin README, sin `.gitignore`, sin licencia: el árbol ya los trae y
un repositorio con commits propios obliga a un merge innecesario.

**2. Empujar.**

```bash
git remote add origin https://github.com/agusg197/agusg197.github.io.git
git push -u origin main
```

**3. Activar Pages.** En el repositorio: *Settings → Pages → Build and deployment →
Source: **GitHub Actions***. Sin esto el workflow corre y falla al publicar.

**4. Esperar el primer build.** Tarda unos 4 minutos: la acción instala Flutter, corre
`analyze`, corre los tests y recién entonces compila. El sitio queda en
`https://agusg197.github.io`.

Después, una vuelta de comprobación: los dos perfiles, los dos idiomas, un teléfono real, y
abrir un proyecto directo por su URL (`/#/p/echo`) para confirmar que las rutas con `#`
resuelven bien en Pages. En la calle: caminarla de punta a punta, abrir un panel por enlace
(`/#/?ver=bonta`), volver de un proyecto al taller y mirar que `/#/clasica` caiga en la calle.
En una ventana privada: primero el idioma, después la bienvenida, y al recargar ya no sale.

---

## 5. Después

- **Datos vivos de GitHub**: los repos públicos podrían traer estrellas y último commit en
  tiempo de build. La API sin token da 60 pedidos por hora, así que conviene pedirla en el
  workflow y escribir un JSON, no en el navegador del visitante.
- **Dominio propio**: un `.dev` o `.ar` cuesta plata, pero el hosting sigue siendo gratis.
  Se configura con un `CNAME` en el repo.
- **Cuando Echo tenga repositorio público**, agregarle `repoUrl` en `portfolio.json` y se le
  enciende el enlace solo.
