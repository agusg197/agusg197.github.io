# agusg197.github.io

Mi portafolio: **[agusg197.github.io](https://agusg197.github.io)**

Flutter web con estética cyberpunk: el sitio es una cuadra de Night City en pixel art que
se camina de costado. Cada edificio es una sección, y cada proyecto se recorre etapa por
etapa con los datos que escribe el visitante.

![El sitio](web/og.png)

---

## Qué tiene de distinto

**Una calle en vez de una página.** Rueda, flechas o arrastre para caminar. Un merc —mi
retrato en 18×34 píxeles— camina con la cámara y explica cada edificio en un globo, con
el botón para entrar. Todo está dibujado por código: no hay un solo archivo de arte.

| Edificio | Qué se hace |
|---|---|
| La casa del merc | la ficha (el retrato se escanea de píxel a foto) y, tras la puerta 197, la terminal |
| La torre | un ascensor con un piso por trabajo |
| El taller | una persiana por app: qué es y qué problema resuelve contado simple, una línea de armado para probarla paso a paso, y qué aprendí con los números traducidos |
| El ripperdoc | las skills se instalan como implantes y dicen en qué proyectos y trabajos se usaron |
| El arcade | una máquina por proyecto web; Bontà Dolce se juega entero, del armado de la caja al mensaje de WhatsApp |
| El teléfono | el contacto, con el mensaje medio armado para mandar desde el correo propio |

La ciudad es pixel art; el trabajo no: capturas y demos se ven nítidas. Está pensada
también para quien no programa: cada cartel dice qué hacer ahí ("> TOCÁ UNA MÁQUINA"), el
merc lo explica sin nombres de tecnologías, y el botón **?** abre el mapa de la cuadra. La
primera visita arranca con una bienvenida corta, y en la vidriera de la casa saluda Clawd, la
mascota de Claude Code. La home de antes y el laboratorio de efectos ya no existen:
`/#/clasica` y `/#/lab` redirigen a la calle.

**Los proyectos se caminan, no se leen.** Cada ficha trae un recorrido de etapas y una
entrada de texto: el visitante escribe algo suyo y ve qué le hace cada etapa. El detector
de preguntas de Echo, por ejemplo, es el mismo criterio que corre en la app de escritorio,
portado tal cual. Todo local, sin una sola llamada a ninguna API, y la pantalla lo dice.

**Dos perfiles, un contenido.** El mismo trabajo contado como Flutter y como AI Engineer:
cambian la biografía, los números, el orden de los proyectos, las skills y el CV que se
descarga. El cambio se anuncia con un barrido, porque una página que se reescribe entera
sin avisar parece rota.

**Se pregunta el idioma.** En la primera visita, un panel ofrece castellano e inglés
escrito en los dos: preguntar en uno solo ya es elegir por el visitante. Al pasar el
puntero, el panel muestra cómo va a quedar.

**Todo se puede apagar.** Glitch, partículas, cursor y textura CRT tienen tres
intensidades. En la más baja no se congela la animación: se dibuja un frame compuesto a
propósito, que es distinto.

---

## Cómo está hecho

| | |
|---|---|
| Framework | Flutter 3.47 · Dart 3.13 · web (CanvasKit) |
| Estado | Riverpod 3 |
| Rutas | go_router con `#`, para que un hosting estático no necesite reescrituras |
| Efectos | `CustomPainter` + tickers propios; nada de paquetes de animación |
| Pixel art | un buffer RGBA pintado a mano, una `ui.Image` por capa, escala entera y `FilterQuality.none` |
| Contenido | un JSON: `assets/data/portfolio.json` |
| Tipografías | empaquetadas; el sitio no le pide nada a Google en cada visita |
| Publicación | GitHub Actions → GitHub Pages en cada push a `main` |

Alrededor de 19.000 líneas de Dart en 74 archivos.

### Rendimiento, medido

Los fondos son lo más caro de una interfaz así, y se midieron con un `Canvas` que cuenta
operaciones en vez de mirar el frame rate:

| | Antes | Ahora |
|---|---|---|
| Campo de partículas | 614 llamadas de dibujo | **11** |
| Textura CRT | 625 | **9** |
| Grilla del hero | 82 llamadas + 5 `saveLayer` | 82 + **0** |
| La calle: 83 neones, tráfico, koi, dron, ascensor, gente, noticias y easter eggs | 53 | **45** |

Las técnicas: agrupar puntos y líneas en `drawRawPoints` por opacidad, cachear shaders y
buffers en vez de crearlos en cada `paint`, resolver las líneas de barrido con un gradiente
repetido en un solo rectángulo, y apagar los tickers de lo que no está en pantalla. En la
calle, la ciudad se rasteriza una vez por capa y todo lo que brilla o se mueve sale de un
solo atlas, recorte por recorte y solo lo que está en pantalla. Con un panel abierto la calle
deja de dibujarse, y en FX SUTIL va a 30 cuadros.

Una trampa que costó encontrar: `drawAtlas` bajaba la calle a 12 llamadas, pero en CanvasKit
no deja elegir el muestreo y filtra los píxeles, y los carteles escalados ×4 se veían
borrosos. `drawImageRect` sí respeta `FilterQuality.none`. El test ahora falla si alguien
vuelve a usar `drawAtlas` en la calle.

Los tests que lo miden están en [`test/paint_cost_test.dart`](test/paint_cost_test.dart) y
[`test/street_cost_test.dart`](test/street_cost_test.dart): si alguien vuelve a dibujar de a
una línea, el número salta y se ve.

---

## Correrlo

```bash
flutter pub get
flutter run -d chrome
```

Enlaces directos: `/#/?at=workshop` arranca frente a un edificio (`home`, `arcade`,
`workshop`, `clinic`, `tower`, `phone`) y `/#/?ver=bonta` abre un panel (`ficha`,
`terminal`, `bonta`, `skills`, `torre`, `contacto`, `taller` o `taller-<id>` para una app
puntual, como `taller-trino`).

```bash
flutter analyze   # sin issues
flutter test      # costo de dibujo, layout de la calle, el port de Bontà y los textos del taller
```

---

## El contenido vive en un JSON

Nada del contenido está escrito en el código. Todo sale de
[`assets/data/portfolio.json`](assets/data/portfolio.json): la persona, los dos perfiles
con sus skills y CV, la experiencia, y los proyectos con su recorrido, su tabla de
resultados y sus capturas. Cada texto es un par `{es, en}`.

Cada app trae además un bloque `plain`: el proyecto contado para quien no programa (qué es,
el problema, una comparación de todos los días, qué aprendí) y un texto simple por cada paso
del recorrido y por cada número, en el mismo orden. Es lo que muestra el taller; la ficha
técnica (`/#/p/<id>`) sigue teniendo el detalle completo. `test/workshop_plain_test.dart`
avisa si un paso o una métrica queda sin su versión simple.

Agregar un proyecto es agregar un objeto, y la calle se acomoda sola: una app suma una
persiana al taller y un proyecto web (`"kind": "web"`) prende una máquina del arcade, con
su sitio en vivo si `embeddable` está en `true`. Solo hace falta tocar Dart si el proyecto
trae una simulación nueva, que vive en
[`lib/features/projects/project_demos.dart`](lib/features/projects/project_demos.dart).

---

## Herramientas

Scripts que no son parte del sitio pero lo alimentan:

| | |
|---|---|
| `tool/build_presentacion.py` | arma el dossier de presentación en PDF, en castellano y en inglés |
| `tool/build_project_briefs.py` | arma una ficha en PDF por proyecto, en inglés |
| `tool/render_icons.py` | genera el favicon y los íconos de la PWA |
| `tool/render_og.dart` | dibuja `web/og.png` con el pintor de la calle: `flutter test tool/render_og.dart` |
| `tool/cv_sin_telefono.py` | publica los CV sin el teléfono |
| `tool/render_advisor_shots.py` | capturas de terminal para el proyecto que no tiene pantallas |
| `tool/redact_leadbox_shots.py` | tapa marca e identificadores en las capturas de un proyecto laboral |

---

## Documentos

- [`PLAN.md`](PLAN.md) — las decisiones de diseño y qué se descartó
- [`DEPLOY.md`](DEPLOY.md) — cómo se publica y qué revisar antes

---

Hecho en Córdoba, Argentina.
