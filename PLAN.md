# Portafolio Cyberpunk — Plan de desarrollo (Flutter Web)

> Estado: v1 (2026-09-17). Fases 0, 1, 2 y 3a implementadas + pasada de rendimiento.
> Contenido REAL cargado desde los dos CVs y tres repos públicos.
> Siguiente: 3b — más proyectos (el usuario dijo que va a pasar otros), datos vivos de
> la API de GitHub, transición glitch entre rutas y despliegue.
> Entorno: Flutter 3.47.0 stable / Dart 3.13 / Windows 11.
> Decisiones confirmadas: paleta Night City, one-page, ES/EN, full glitch por defecto,
> sin sonido (salvo un easter egg, bajito y sintetizado), hosting GitHub Pages, paquete `agusg197_cyber`.
>
> Correr en local: `flutter run -d web-server --web-port 5173` y abrir http://localhost:5173.
> Para verificar como en producción: `flutter build web --release` y servir `build/web`.
> Rutas: `/` (la calle) y `/#/p/:id` (la ficha técnica de un proyecto). `/#/clasica` (la
> home de v1) y `/#/lab` (el laboratorio de efectos) redirigen a la calle.

---

## 0. v2 — la calle (2026-09-25)

El sitio pasó a ser una cuadra de Night City en pixel art, vista de costado, que se camina
con rueda, flechas o arrastre. Reemplaza a la home de v1, que se retiró entera (hero,
secciones y carrusel): la calle ya tiene todo, y mantener dos sitios con el mismo contenido
era trabajo doble.

**Por qué así.** La v1 ya mostraba proyectos jugables; lo que faltaba era que la página
entera se explorara igual. Una calle de costado mantiene lo bueno del one-page (se
recorre en un solo gesto, no hay controles de juego que aprender) y le da a cada sección
un lugar físico.

**Reglas que se sostienen:**
- Sin horizonte ni perspectiva: fachadas planas, neón con fallas, hazard stripes, grafiti.
- La ciudad es pixel art; el trabajo no. Capturas y demos van nítidas.
- Todo dibujado por código: un buffer RGBA por capa, escala entera y `FilterQuality.none`.
  Los sprites (el merc) son grillas de texto en el código.
- El merc (retrato del dueño, 18×34) hace de guía: se para frente a cada edificio y lo
  explica en un globo con el botón para entrar. Es lo que hace que se entienda dónde está
  cada cosa.
- Estático no es pausado: sin animación se dibuja un cuadro compuesto, con todo prendido.
- Nada de barras de nivel: las skills se prueban con proyectos y trabajos (ripperdoc).

**Los edificios** (en `lib/features/city/`), en orden: casa del merc (ficha y terminal),
torre (experiencia), taller (una persiana por app), ripperdoc (skills), arcade (un
proyecto web por máquina; Bontà Dolce con su demo propia, el resto con una máquina genérica
que sale del JSON) y teléfono (contacto). Primero quién soy y dónde trabajé, después lo que
hice, y al final cómo escribirme. La cuadra se calcula desde los datos: más apps o más proyectos web
agrandan su edificio y corren el resto.

**Rendimiento.** La calle entera son unas 33 llamadas de dibujo por frame: las capas se
rasterizan una vez, y neones, autos, koi, dron, gente y noticias salen de un solo atlas,
recorte por recorte con `drawImageRect` y solo lo que está en pantalla. No `drawAtlas`: en
CanvasKit no deja elegir el muestreo, filtra los píxeles y los carteles se ven borrosos. El globo y los botones escuchan una señal
aparte que cambia pocas veces, no cada cuadro. Con un panel abierto la calle se pausa. Lo
mide `test/street_cost_test.dart`, en los tres modos de FX.

**Para quien no programa.** Los globos del merc dicen qué hay y qué hacer, sin nombres de
tecnologías; cada cartel lleva abajo la instrucción ("> ELEGÍ UN IMPLANTE"), y el botón **?**
abre un mapa de la cuadra con un botón para ir a cada edificio. El detalle técnico sigue
estando, adentro de cada panel, para quien lo busque.

**La bienvenida** (`panels/welcome_panel.dart`) sale una sola vez, en la primera visita,
justo después de elegir idioma: quién soy en una línea, cómo se usa en tres pasos (con texto
de dedo en el teléfono) y la cuadra en orden para ir directo a algo.
Queda marcada en `localStorage` (`agusg197.intro`); un enlace con `?ver=` no la muestra,
porque esa visita ya sabe a qué vino. Después vuelve con el botón **?**.

**Clawd** (`art/clawd.dart`), la mascota de Claude Code, saluda desde la vidriera de la casa,
al lado del afiche de "disponible": el logo de la terminal llevado a píxeles, con tres poses
de brazo y un globito de "HOLA!". Va en el atlas para poder moverse; en ESTÁTICO queda en el
gesto de saludo.

**El teléfono** deja el mensaje con corchetes para completar ("una posición de [puesto] en
[empresa]"), no pisa lo que escribió la visita al cambiar de motivo o de idioma, y además del
botón que abre el correo tiene "copiar el mensaje", para quien usa el correo en el navegador
y no tiene nada que abra un `mailto:`.

**El taller** (`panels/workshop_panel.dart`) ya no manda a la ficha clásica: cada persiana
abre un panel en la calle con tres partes. *Qué es*: el problema y una comparación ("es
como dictarle a un secretario prolijo") y cada herramienta explicada en una línea. *Probalo*:
la línea de armado, con el ejemplo del visitante recorriendo cada estación, lo que hace
dicho en criollo, lo que sale "como lo ve la máquina" y el detalle técnico detrás de un
botón. *Qué aprendí*: el hallazgo de las mediciones y cada número con su traducción. Se pasa
de una app a otra con una persiana que baja y sube, sin salir; la ficha técnica y el código
quedan al final, para quien programa.

**FX en la calle.** ESTÁTICO: cuadro compuesto, todo prendido y en su lugar. SUTIL: todo se
mueve a 30 cuadros, mitad de lluvia, sin glitches ni dron. FULL: 60 cuadros, lluvia
completa, más tráfico, dron y carteles que se rompen en aberración cromática cada tanto.

---

## 1. Concepto visual

> Dirección confirmada (2026-09-17): **cyberpunk punk / urbano**, no synthwave. Sin horizonte ni
> grilla en perspectiva. Fondo plano tipo HUD sucio (grilla de puntos, sectores etiquetados,
> columnas hex, scan line, bloques corruptos). Franjas de peligro amarillo/negro, etiquetas
> tipo sticker rotadas, códigos de barras, botones inclinados, aberración cromática dura
> (offsets magenta/cyan sin blur) en vez de glow difuso. Display: **Chakra Petch**.

### Paleta (tokens)
| Token            | Uso                               | Valor sugerido |
|------------------|-----------------------------------|----------------|
| `bg0`            | Fondo base                        | `#07070C`      |
| `bg1`            | Paneles / cards                   | `#0E0F1A`      |
| `grid`           | Líneas de grilla / bordes tenues  | `#1B1E33`      |
| `neonCyan`       | Acento primario, links, glow      | `#00F0FF`      |
| `neonMagenta`    | Acento secundario, glitch, alerts | `#FF2A6D`      |
| `neonYellow`     | Highlights, badges, HUD           | `#FCEE0A`      |
| `neonViolet`     | Degradados, fondos de sección     | `#7A5CFF`      |
| `text0`          | Texto principal                   | `#E6F1FF`      |
| `text1`          | Texto secundario                  | `#8A93B2`      |

Variante a decidir: **Night City** (cyan + amarillo dominante) vs **Blade Runner** (magenta + naranja + azul frío).

### Tipografía
- Display / títulos: **Orbitron** o **Rajdhani** (geométrica, tech).
- Mono / HUD / terminal: **Share Tech Mono** o **JetBrains Mono**.
- Cuerpo: **Inter** o **Rajdhani** light (legibilidad primero).
- Cargar con `google_fonts` + preload en `index.html` para evitar FOUT.

### Texturas y "capas de atmósfera"
- Scanlines CRT (overlay repetido, opacidad 3–6 %).
- Grano / ruido animado sutil.
- Viñeta en bordes.
- Grilla en perspectiva (horizonte tipo synthwave) en el hero.
- Aberración cromática en títulos (offset RGB) en hover / al entrar en pantalla.
- Bordes "hologram": esquinas recortadas (clip path) + glow neón.

---

## 2. Efectos e interacciones (motor de efectos)

Se construyen como widgets/painters reutilizables en `core/effects/` y se prueban en una
página interna `/lab` (playground) antes de integrarlos a las secciones.

| # | Efecto | Técnica en Flutter | Prioridad |
|---|--------|--------------------|-----------|
| 1 | Fondo reactivo: partículas conectadas + grilla perspectiva que sigue el mouse | `CustomPainter` + `Ticker`, `MouseRegion` global | Alta |
| 2 | Scanlines + grano + viñeta (overlay CRT) | `CustomPainter` / `ShaderMask`, `RepaintBoundary` | Alta |
| 3 | Glitch text (saltos, slicing, RGB split) | `Stack` con 3 capas desplazadas + `AnimationController` con curva random | Alta |
| 4 | Typewriter + cursor parpadeante (hero, terminal) | `AnimatedBuilder` sobre `String.substring` | Alta |
| 5 | Neon glow (bordes, botones, iconos) | `BoxShadow` múltiples, `ShaderMask` con gradiente, pulso con `TweenSequence` | Alta |
| 6 | Reveal al hacer scroll (fade + slide + "decode" de texto) | `visibility_detector` o `ScrollController` + `Sliver` | Alta |
| 7 | Hologram card con tilt 3D en hover | `Transform(Matrix4 perspective)` + posición del mouse, brillo especular | Alta |
| 8 | Cursor custom con trail neón | `MouseRegion` + `Overlay` + `CustomPainter` (solo desktop) | Media |
| 9 | Timeline de experiencia tipo circuito: nodos que se "encienden" y trazas que se dibujan | `Path` + `PathMetric.extractPath` animado, expand/collapse por nodo | Alta |
| 10 | Transición glitch entre secciones / rutas | `PageRouteBuilder` + `ShaderMask`/slices desplazados | Media |
| 11 | Terminal interactiva ✅ — implementada dentro de "Sobre mí" | `TextField` + parser de comandos sobre el JSON | Hecha |
| 12 | Fragment shaders (CRT curvatura, aberración, distorsión al hover) | `FragmentProgram` (`.frag`) — funciona en CanvasKit y skwasm | Media |
| 13 | HUD de datos en cards de proyecto (stars, lenguaje, último commit) | GitHub REST API + `http` / `dio`, animación de contadores | Media |
| 14 | Skills como hex-grid con "carga de energía" ✅ | `CustomPainter` + hit-test sobre centros | Hecha |
| 15 | ~~Sonido UI~~ — descartado por decisión del usuario | — | — |
| 16 | Boot sequence al cargar (logs falsos, barra de carga) | Splash en `index.html` (HTML/CSS) + continuación en Flutter | Media |

Reglas del motor:
- Todo efecto respeta un `EffectsController` global: intensidad (estático / sutil / full) y `reduceMotion`
  (leído de `MediaQuery.disableAnimations` + toggle manual en la UI).
- En mobile: sin cursor custom, menos partículas, sin shaders pesados, tilt desactivado.
- Cada painter va envuelto en `RepaintBoundary` y se detiene (`Ticker.stop`) cuando no está visible.
- **Modo estático**: apagar la intensidad NO congela la animación en un frame cualquiera. Cada efecto
  dibuja un frame compuesto a propósito: sectores a opacidad plena, sin línea de escaneo, typewriter
  resuelto y sin cursor, partículas como constelación fija. Scanlines, viñeta y aberración cromática
  se mantienen porque son textura, no movimiento.

### Rendimiento (medido, no estimado)
`test/paint_cost_test.dart` cuenta las llamadas de dibujo por cuadro de cada capa del fondo
con un `Canvas` instrumentado. Correr con `flutter test test/paint_cost_test.dart`.

| Capa | Antes | Después |
|------|-------|---------|
| ParticleField (90 partículas) | 614 llamadas | **11** |
| CrtOverlay | 625 llamadas | **9** |
| TechGridBackground | 82 llamadas + 5 `saveLayer` | 82 llamadas, **0 `saveLayer`** |

Técnicas aplicadas, a respetar en efectos nuevos:
- Nunca una llamada de dibujo por elemento: agrupar en `drawRawPoints` por bucket de opacidad.
- Nunca `saveLayer` para bajar opacidad de texto: cuantizar el color del `TextPainter`.
- Cachear shaders y buffers `Float32List`; jamás construirlos dentro de `paint()`.
- Scanlines = un gradiente con `TileMode.repeated`, no un rect por línea.
- Los fondos decorativos repintan a ~30 fps, no a 60.
- **`AnimateWhenVisible`** (`TickerMode`) envuelve el hero y cada sección: fuera de pantalla
  se silencian todos los tickers. Antes el fondo del hero seguía animando al final de la página.

### Contenido (fases 2 y 3)
Todo el contenido vive en `assets/data/portfolio.json` con textos `{es, en}`. `"mock": false` desde
la fase 3: los datos son reales. Modelos en `lib/data/models/portfolio.dart`, carga en
`lib/data/sources/portfolio_repository.dart`.

**Doble perfil.** El JSON tiene `person` (identidad compartida) y `profiles[]`, uno por CV:
`flutter` y `ai`. Cada perfil trae titular, roles del typewriter, biografía, su PDF de CV, sus
números, su orden de proyectos y sus skills. El conmutador vive en la barra superior y reordena
la página entera. La experiencia se filtra con `profiles[]` por entrada.

**Proyectos interactivos.** La ruta `/p/:id` los muestra en tres pestañas:
- **Recorrido** — la explicación y la demo son lo mismo. El visitante escribe una entrada y
  camina el pipeline etapa por etapa: a la izquierda qué hace la etapa y qué puede fallar,
  a la derecha qué produce **con esa entrada**. Hay reproducción automática y navegación manual.
  Motor en `lib/features/projects/project_demos.dart` (`runPipeline` devuelve los bloques por
  etapa). Todo local, **sin llamadas a ninguna API**, rotulado en pantalla.
- `evals` — tabla de resultados medidos, nota metodológica y el hallazgo.
- `gallery[]` — capturas reales con su epígrafe.
  - Advisor no tiene pantallas: es un backend. Sus «capturas» son ventanas de terminal
    generadas por `tool/render_advisor_shots.py` a partir de artefactos reales del repo
    (`runs/*.json` y `runs/security/asr_*.json`): se recorta y se colorea, no se inventa
    ningún número, y el epígrafe aclara que son trazas.
  - En el teléfono la captura se dimensiona por alto (620 px) dentro de un scroll
    horizontal, con un cartel que lo dice. Ajustarla al ancho dejaba el texto de una
    terminal en 6 px. En escritorio sigue entrando entera (`contain`, 560 px).

> Lección de diseño: la demo aislada no se entendía porque estaba separada de la explicación.
> Una demo sin contexto es ruido. Fusionarlas fue el arreglo.

Fuentes: `github.com/agusg197/trino-voz`, `.../tiza`, `.../advisor-multiagent`.
Capturas copiadas a `assets/images/projects/`, CVs a `assets/cv/`.

### Proyecto laboral privado (`leadbox`)

La migración del cliente móvil a la plataforma Leadbox-OS entra como proyecto, pero
**solo a nivel técnico**: cómo está armado, no qué muestra. Reglas de lo que no se
publica: hosts, rutas de endpoints, nombres de registries, identificadores de ticket,
clientes, credenciales y capturas de la app. Lo que sí: forma de la arquitectura,
patrones, política de reintentos y conteos sobre el repositorio.

- `private: true`, sin `repoUrl` ni `demoUrl`; la tarjeta muestra el candado.
- Las pestañas del detalle se arman según lo que el proyecto tenga (`_tabsFor`): un
  `gallery: []` no dibuja la pestaña de capturas, y si queda una sola no se muestra la
  barra.
- Capturas: salen del **build de demo** del repo (datos de fixture), nunca de una sesión
  real, y se publican redactadas — barras opacas con borde magenta sobre la marca, los
  nombres de sucursal, los identificadores y los títulos de ítem. Quedan afuera las
  pantallas que exponen infraestructura (la de re-autenticación muestra el dominio del
  tenant) y las de módulos cuyo valor es el nombre de la función de producto
  (reportes). El script está en `tool/redact_leadbox_shots.py`; los originales, en el
  repo privado bajo `docs/demo/screenshots/`.
- `evals` se usa como tabla de estado del cliente nuevo (pantallas / providers / tests /
  offline por módulo), contada sobre el repositorio.
- El recorrido toma como entrada un **módulo** (inventario, galería, dashboard, sync,
  login, reportes) y muestra qué le pasó en cada etapa de la migración
  (`_runLeadbox`). Entrada libre cae en un perfil «sin mapear» que igual explica el
  procedimiento.

### Prototipo propio (`echo`)

App de escritorio Flutter para Windows (`E:\Project Flutter Windows\echo_qa`), en beta y
sin repositorio público todavía; en la página se llama **ECHO**, sin el `_qa`.
Entra completo: recorrido de seis etapas, tabla de evals y cinco capturas de la app
corriendo de verdad. Se sacaron lanzando el build de Windows y fotografiando la ventana
con  (GetWindowRect + CopyFromScreen, recortado a la ventana).
La captura de la escucha en vivo es real: la pregunta entró por el loopback del sonido
del sistema, dicha por el sintetizador de voz de Windows, así que whisper transcribió
audio de verdad y el detector la marcó. No se gastó ningún pedido: contestan los
apuntes locales.

- El recorrido **no simula** el detector de preguntas: lo porta. `_runEcho` es el mismo
  criterio que `lib/features/questions/detector.dart` — signos, discurso referido,
  aperturas modales, interrogativa inicial contra suelta, y «por»/«para» que
  solo cuentan seguidas de «qué». Corre local acá por la misma razón por la
  que corre local allá.
- Las muestras están elegidas para que se vean los tres niveles y los dos casos que el
  proyecto aprendió midiendo: el discurso referido («voy a preguntar qué
  significa») y el «para» suelto («ahí te veo para el Discord»).
- Los números de las métricas y de la tabla salen del README del prototipo: 341 tests
  sin red, el tramo de ~2050 a ~330 ms con whisper residente, y los veinte pedidos por
  día que son el recurso escaso.

### App propia publicable (`cifra`)

App Android de gastos, en camino a Play y sin repositorio público todavía.
Recorrido de seis etapas, tabla y cinco capturas.

- Las capturas salieron de correr la app en el emulador que ya estaba andando: build de
  release para x86_64, `adb install`, y `adb exec-out screencap`. Se fotografió el
  dispositivo, no el escritorio: no hay forma de que se cuele otra ventana.
- Los datos que se ven son los de prueba del emulador (Sueldo, Hosting, Heladera), no las
  finanzas reales de nadie.
- La tabla de evals es la auditoría de permisos: qué declara cada tipo de build y por
  qué el chequeo del CI corre sobre el manifest fusionado de release.
- El recorrido convierte el importe que escribe el visitante a unidades menores y dice si
  ese número cae exacto en coma flotante (`_runCifra`). La primera versión multiplicaba
  por tres y mostraba dos resultados idénticos mientras afirmaba que había diferencia:
  un ejemplo que no ejemplifica es peor que no poner ninguno.

### Proyecto de colaboración (`crediclub`)

Referencia superficial, a propósito: es trabajo por contrato dentro del equipo de otro
producto. Entra como **tarjeta sin detalle** — sin `pipeline`, `evals`, `gallery` ni
`demo`, así que `hasDetail` es `false`, la tarjeta no abre ruta y el pie muestra solo
el candado. Los números son los mismos que declara el CV. El carrusel del hero filtra
por `hasDetail`, porque su tarjeta abre el detalle.

> En el teléfono la galería de capturas sube su tope de alto a 640 px: con 420 px la
> captura vertical quedaba en una tira de 187 px, ilegible.

---

## 3. Secciones de la página

1. **Hero** — nombre con glitch, rol con typewriter, CTA "ver proyectos" / "descargar CV",
   fondo con grilla + partículas, indicador de scroll.
2. **Sobre mí** — interactiva: tarjeta de identidad con ranura tipo escáner que sigue al puntero,
   fichas de registro con hover (sin barras) y una **terminal funcional** (`help`, `whoami`,
   `stack`, `exp`, `projects`, `stats`, `contact`, `clear`) que consulta el JSON. La biografía se
   imprime sola al cargar para que el contenido sea legible sin escribir nada.
3. **Experiencia** — timeline circuito interactiva; cada nodo abre panel con logros y stack.
4. **Proyectos** — grid de hologram cards, filtro por tecnología, detalle en modal/ruta con
   galería, descripción, links (repo/demo). Datos: mezcla de repos públicos (GitHub API) y
   proyectos privados/laborales cargados desde JSON.
5. **Skills** — panal hexagonal interactivo: cada celda es una celda de energía que se llena
   con el nivel; hover/tap la enciende y actualiza un panel de lectura. Filtro por categoría.
   **Sin barras de progreso** (decisión del usuario).
6. **Contacto** — formulario estilo terminal o links neón (mail, LinkedIn, GitHub), copiar al portapapeles.
7. **Footer / Terminal** — barra tipo statusline con hora, "system status", link al lab.

---

## 4. Arquitectura técnica

```
lib/
  main.dart
  app/               # MaterialApp, router, tema, EffectsController
  core/
    theme/           # tokens de color, tipografía, spacing, breakpoints
    effects/         # painters y widgets de efectos (uno por archivo)
    widgets/         # botones neón, panels, section wrapper, responsive builder
    utils/           # extensiones, helpers de responsive, random seeded
  features/
    hero/  about/  experience/  projects/  skills/  contact/  lab/
    (cada una: view.dart + widgets/ + model si aplica)
  data/
    models/          # Experience, Project, Skill, Profile
    sources/         # loader de JSON local, cliente GitHub API
assets/
  data/profile.json, experience.json, projects.json, skills.json
  shaders/*.frag
  images/, fonts/ (si no se usa google_fonts)
```

- **Routing:** `go_router` con rutas `/`, `/projects/:id`, `/lab`; scroll a sección por anchor.
- **Estado:** `Riverpod` (ligero, testeable) para EffectsController, datos y filtros.
- **Contenido separado de UI:** todo el CV vive en JSON para que actualizar datos no toque código.
- **Responsive:** breakpoints `mobile < 600`, `tablet < 1024`, `desktop >= 1024`; layout con
  `LayoutBuilder` y un `Responsive` helper.
- **Renderer web:** build con `flutter build web --wasm` (skwasm, mejor performance para
  painters/shaders); fallback automático a CanvasKit en browsers sin WasmGC.

---

## 5. Performance, accesibilidad y SEO

- Splash HTML cyberpunk en `index.html` mientras carga el engine (Flutter web tarda 1–3 s).
- Limitar partículas (~80 desktop / ~30 mobile), usar `Ticker` único compartido.
- Imágenes en WebP, lazy load, `cacheWidth`.
- `deferred as` para el lab y el detalle de proyectos.
- Contraste: verificar magenta/amarillo sobre fondo (WCAG AA en texto, decorativo puede ser menor).
- `Semantics` en cards y botones, navegación por teclado, focus visible neón.
- Toggle "reducir animaciones" visible en la barra superior.
- SEO: meta tags + Open Graph + favicon en `index.html`; `title` dinámico por ruta;
  `sitemap.xml` y `robots.txt` simples. Aceptar la limitación SPA de Flutter web.

---

## 6. Deploy

- Opciones: **GitHub Pages** (gratis, `--base-href /repo/`), **Firebase Hosting** o **Vercel**.
- CI con GitHub Actions: `flutter build web --wasm --release` y deploy automático en push a `main`.
- Dominio propio opcional.

---

## 7. Fases de desarrollo

| Fase | Contenido | Entregable |
|------|-----------|------------|
| 0 ✅ | `flutter create`, estructura de carpetas, tema y tokens, tipografías, router, responsive base, splash HTML | App vacía con layout y tema navegable |
| 1 ✅ | Motor de efectos (items 1–9 de la tabla, salvo transición glitch/shaders/terminal) + página `/lab` para probarlos con sliders | Playground de efectos funcionando |
| 2 ✅ | Secciones con datos mock (`assets/data/portfolio.json`): about con ID card, experiencia como timeline circuito, proyectos filtrables, skills con barras segmentadas, contacto | Página completa con contenido ficticio |
| 3 | Integrar CV real, repos de GitHub (API), proyectos privados, terminal, transiciones glitch | Página con contenido real |
| 4 | Shaders, sonido opcional, pulido mobile, performance, a11y, SEO, deploy con CI | Sitio publicado |

---

## 8. Decisiones pendientes (a confirmar)

1. Variante de paleta: Night City (cyan/amarillo) o Blade Runner (magenta/naranja).
2. One-page con scroll (recomendado) o multi-ruta.
3. Idioma: español, inglés o ambos con toggle.
4. Intensidad por defecto de los efectos: sutil o "full glitch".
5. Sonido UI: incluir (con mute por defecto) o descartar.
6. Hosting preferido y si hay dominio propio.
7. Nombre del paquete Dart (ej. `portfolio_cyber`).
