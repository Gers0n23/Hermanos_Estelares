# Ficha — Las migas de papá: álbum de recuerdos familiares

> **Decisión del PO (27-Sep-2026)**: la aventura suma una capa de **coleccionables con fotos
> reales de la familia** (los niños de bebés hasta hoy, con mamá y papá). Se encuentran jugando
> y quedan guardados en un **álbum** que se abre desde la pantalla principal cuando quieran.
> El PO eligió la historia "las migas de papá", **un álbum por hermano más uno familiar**,
> ~12-15 fotos por hermano y ~8-10 familiares, y cada foto con un **audio grabado por la
> familia** (los 3 niños, papá y mamá; el PO ya los está grabando).

- **Autor**: Dev a pedido del PO (propuesta de diseño) — **pendiente de validación** por
  `guionista` (líneas de Cometa y de papá), `disenador-mecanicas` (game feel de la entrega),
  `experto-ux-parvulo` (álbum y entrega para 2-8 años) y `disenador-personajes` (marco,
  sobre y placeholders).
- **Estado**: diseño propuesto, 27-Sep-2026.
- **Reglas**: GDD §6 (UX infantil) manda sobre todo lo de esta ficha.

---

## 1. Idea en una frase

Cuando el Coleccionauta se llevó a papá, a papá **se le cayeron las fotos de la billetera**, y
quedaron flotando por la galaxia como **estrellas-recuerdo**. Cada foto que los hermanos
encuentran es una miga del camino hacia papá. Al final, papá ve el álbum completo y el
Coleccionauta entiende que los recuerdos no se guardan en cajas: **se comparten**.

## 2. Por qué funciona

- **Calza con el guion**: Cometa colecciona amigos (álbum de abrazos) y el Coleccionauta
  colecciona cosas en cajas (GDD §2). Juntar recuerdos prepara la lección final sin explicarla.
- **Crecer como progresión**: los recuerdos se entregan **en orden de edad**. Avanzar en la
  aventura es verse crecer, de bebé a hoy.
- **Voz de casa**: cada foto suena con la voz real de la familia. Así se cierra en parte la
  pregunta abierta P2 del GDD.

## 3. Estructura: cuatro álbumes

| Álbum | Qué contiene | Quién lo llena | Cantidad |
|---|---|---|---|
| Álbum de Maxi | Fotos de Maxi, de recién nacido a hoy | Solo la ruta de Maxi | 12-15 |
| Álbum de Nicole | Fotos de Nicole, de recién nacida a hoy | Solo la ruta de Nicole | 12-15 |
| Álbum de Sofía | Fotos de Sofía, de recién nacida a hoy | Solo la ruta de Sofía | 12-15 |
| Álbum familiar | Mamá, papá y los tres (y fotos de a dos o tres hermanos) | **Cualquier** hermano; una vez encontrado, es de todos | 8-10 |

- Cada hermano ve **su álbum y el familiar** con el mismo protagonismo. También puede mirar los
  álbumes de sus hermanos (solo mirar): la idea es que los vean juntos.
- Un recuerdo familiar lo desbloquea **el primer hermano** que llega al momento, y queda para los
  tres. El mensaje: "¡Sofía encontró una foto de toda la familia!".

## 4. Momentos de entrega

Regla de oro: **cada recuerdo tiene un momento fijo y siempre se entrega**. No hay azar ni sobres
sorpresa, nada se pierde y nada exige un desempeño que un niño de 2 años no alcance.

| Momento | Qué entrega | Por qué ahí |
|---|---|---|
| **Viaje estelar entre planetas** (modo Galaga) | 1 recuerdo **personal**: una burbuja-recuerdo cruza la pantalla y se atrapa tocándola o chocándola con la nave | Es el momento más emocionante y es la "miga" literal en el camino |
| **Completar una zona del mapa del planeta** (sus 4 estaciones, con cualquier resultado) | 1 recuerdo **personal** (en zonas alternas, ver §5) | Premia constancia, no desempeño: vale igual para Maxi, Nicole y Sofía |
| **Pieza de la nave** (escena de historia de cada planeta) | 1 recuerdo **familiar** | Momento grande, con video-llamada de papá |
| **Primera vez que se abre el juego** | 1 recuerdo **familiar** (la foto "antes del secuestro") | El álbum empieza con algo desde el minuto uno: nunca está vacío |
| **Rescate final** | 1 recuerdo **familiar** (la última: los cinco juntos, o los tres jugando este juego) | Cierra el álbum y la historia |
| **Estrellitas máximas de Sofía** | **No da contenido extra**: le pone a la foto de esa zona un **marco dorado** | El reto real de Sofía brilla sin quitarles fotos a Maxi ni a Nicole |

- Los minijuegos sueltos **no dan fotos**, para que cada foto se sienta especial. Su premio
  coleccionable son las estampitas (§9, idea 7).
- **Si el momento no se completa** (por ejemplo, sale del viaje antes de atrapar la burbuja), la
  burbuja **vuelve a pasar** en el siguiente viaje. Nunca se pierde.
- Los mapas de zonas por capítulo (GDD §3) marcan el ritmo: el **capítulo 1** (Arcoíris) entrega
  las primeras fotos de bebé, y cada capítulo siguiente avanza en la línea de tiempo.

## 5. Reparto propuesto (placeholder, se ajusta al cerrar cada capítulo)

Por hermano, 14 recuerdos personales:

- **6 planetas × 2** = 12, al completar las zonas 2 y 4 de cada planeta (Arcoíris: charcos e islotes).
- **2 viajes estelares especiales**: el primer despegue (capítulo 1) y el viaje al planeta final.

Familiares, 9:

- 1 primera apertura + 6 piezas de la nave + 1 rescate final + 1 en el viaje al planeta final.

> Si un planeta todavía no tiene zonas (capítulos futuros), sus recuerdos quedan en el catálogo
> sin momento asignado y no aparecen como huecos hasta que el capítulo exista.

## 6. La entrega: game feel

1. Todo se detiene suavemente, sin cortar la celebración anterior. Cometa dice:
   *"¡Mira! ¡Otra foto de la billetera de papá!"*.
2. Un **sobre-estrella** baja girando y llega al centro de la pantalla, grande (más de 200 px).
3. **Un toque en cualquier parte** lo abre. Si pasan 3 s sin toque, se abre solo (Maxi).
4. La foto sale con un marco tipo **polaroid estelar**, crece hasta ocupar ~70% de la pantalla,
   suena el **audio de la familia** y cae confeti suave.
5. La foto vuela hacia un **ícono de álbum** que rebota: así el niño aprende dónde queda.
6. Sin botón de "continuar": al terminar el audio (o con un toque), se vuelve al flujo normal.

## 7. El álbum en la pantalla principal

- **Entrada**: un botón grande con forma de **libro-álbum con estrellas** en la pantalla de título
  o de selección de personaje. Tiene un brillo pulsante cuando hay una foto nueva sin ver.
- **Portada**: 4 tapas grandes (Maxi, Nicole, Sofía y Familia), cada una con la cara del
  personaje. Las toca cualquiera, sin selección de perfil previa.
- **Páginas**: una cuadrícula de 2×3 fotos por página, con miniaturas grandes (más de 180 px), en
  orden de edad. Se pasa de página deslizando o con flechas grandes.
- **Huecos**: silueta de marco con una estrella y un signo de interrogación. Al tocarlo, Cometa
  da una pista hablada: *"Esta foto está escondida en el Planeta Arcoíris"*.
- **Foto abierta**: pantalla completa, se repite el audio y hay un botón grande para cerrar.
  Opcional: un pie de foto con la edad ("Maxi, 3 meses"), dibujado y narrado, nunca obligatorio
  de leer.
- **Sin texto obligatorio**: todo se navega por íconos y voz (GDD §6).

## 8. Datos y archivos (para `dev-godot`)

### Catálogo

`datos/recuerdos/catalogo.json` es data-driven. El núcleo nunca conoce minijuegos concretos
(regla de oro 3): los momentos se identifican con eventos genéricos.

```json
{
  "recuerdos": [
    {
      "id": "maxi_01",
      "album": "maxi",
      "orden": 1,
      "edad": "1 año y 3 meses",
      "momento": {"tipo": "viaje", "id": "primer_despegue"},
      "foto": "res://assets/recuerdos/fotos/maxi_01.jpg",
      "voz": "res://assets/recuerdos/voces/maxi_01.ogg"
    },
    {
      "id": "familia_01",
      "album": "familia",
      "orden": 1,
      "momento": {"tipo": "primera_apertura"}
    }
  ]
}
```

- `momento.tipo` puede ser `primera_apertura`, `viaje`, `zona_completa` (con `planeta` y `zona`),
  `pieza_nave` (con `planeta`) o `rescate_final`.
- Si falta `foto` o `voz`, se usa la convención `<id>.jpg` / `<id>.ogg`.
- **Placeholders**: si el archivo no existe en disco, se muestra el placeholder versionado
  `assets/recuerdos/placeholders/<album>.svg` (marco de polaroid con la silueta del personaje y el
  número del recuerdo) y se usa una línea de Cometa genérica en vez del audio. Así el juego
  funciona completo sin las fotos reales, y el PO solo copia los archivos con el nombre del id.

### Progreso

`Progreso` suma `recuerdos_encontrados: {id: {fecha, visto, dorado}}` a **nivel global**, no por
perfil. El álbum familiar es compartido, y los personales se indexan por el campo `album`. Para
esto hace falta una migración de versión del guardado.

### Privacidad (decisión del PO)

- `assets/recuerdos/fotos/` y `assets/recuerdos/voces/` están en `.gitignore`: **las fotos y las
  voces de la familia nunca se suben a GitHub**. Solo viajan dentro del APK.
- Sí se versionan el catálogo, los placeholders y el código.
- Pipeline de fotos: redimensionar a un máximo de 1280 px en el lado largo y usar JPG de calidad
  ~85, para cuidar el tamaño del APK. Un script en `herramientas/` lo automatiza.

### Implementación provisional (Dev, 27-Sep-2026, a pedido del PO)

Pendiente de la validación HE-44. Lo que cambió respecto de lo propuesto arriba:

- **Autoload `Recuerdos`** (`scripts/autoloads/recuerdos.gd`) y `Progreso` en versión 2 del guardado.
- **`momento.requiere`**: ruta `res://` que debe existir para que el hueco se vea (piezas de la nave,
  rescate y viaje final apuntan a escenas/datos que todavía no existen). `zona_completa` se deduce
  sola del `mapa.json` del planeta (por `zona` o por `numero`).
- **Placeholders en PNG, no SVG**: `assets/recuerdos/placeholders/<album>.png`, recortes de las hojas
  de `assets/anclas/` (decisión visual del PO: el personaje del álbum a color, con el número del
  recuerdo dibujado; los huecos, los tres hermanos atenuados con un sello de estrella y "?").
- **Sin foto ni voz real**: la voz se reemplaza por `recuerdos_generica_*` si está grabada; si no,
  silencio con la animación.
- **Entrada al álbum**: botón libro-álbum en la **selección de personaje** (el título entero ya es
  un solo objetivo táctil, "toca para empezar"). La primera apertura también se entrega ahí: la
  foto vuela a ese botón. La recomendación del guion (tras la intro) queda para cuando exista la
  escena de la intro.
- Instrucciones para el PO: `assets/recuerdos/LEEME.md`; herramienta: `herramientas/preparar_recuerdos.py`.

## 9. Otras ideas de personalización aprobadas (PO 27-Sep-2026, todas al backlog)

1. **Cumpleaños y fechas especiales**: el día del cumpleaños de cada hermano, Cometa lo saluda por
   su nombre, canta y hay confeti. También hay saludos para el 18 de septiembre (con la bandera de
   Chile, conectado al contenido educativo), Navidad y el Día del Padre y de la Madre.
2. **"Mis obras" en el álbum**: los dibujos que hacen en el lienzo libre se guardan solos en una
   sección del álbum personal (en `user://`, nunca se suben).
3. **Dibujos reales en el juego**: se escanea un dibujo de papel de cada hermano y se convierte en
   un planeta, una criatura o una estampita dentro de la aventura.
4. **Video-llamadas con papá real**: un clip o audio real de papá en cada entrega de pieza, en vez
   de la voz sintética. Mamá aparece en el final dándoles la bienvenida a casa.
5. **La casa real**: el living del inicio se inspira en su living de verdad, con cameos de
   mascotas, peluches o juguetes favoritos (cruzar con las fichas de la Fase 0).
6. **Cápsula del tiempo**: al terminar el juego, se desbloquea un mensaje de mamá y papá para cada
   hermano, pensado para cuando lo vuelvan a ver de más grandes.
7. **Estampitas cartoon**: una segunda capa de coleccionables del universo del juego (anfitriones,
   planetas, Coco) para premiar los minijuegos sueltos y decorar la nave.
8. **Frases de la familia**: las frases típicas de la casa, dichas por Cometa en las
   celebraciones.

## 10. Lo que el PO prepara

- Las fotos, con nombre `<id>.jpg`, según la lista de huecos del catálogo. Una guía sugerida por
  álbum va de recién nacido, primer baño, primera sonrisa, primeros pasos y primer cumpleaños,
  hasta el jardín o el colegio y hoy.
- Los audios, con nombre `<id>.ogg` (o WAV, que el pipeline convierte), de 3-10 s cada uno.
- Opcional: la edad o el momento de cada foto, para el pie de foto narrado.

## Validación HE-44 — disenador-mecanicas (28-Sep-2026, PROPUESTA)

**Aprobado con cambios, sin bloqueantes.** El detalle está en
`docs/validaciones/HE-44_disenador-mecanicas.md`. Los cambios mayores son:

- **Toques sobre la foto**: no la cierran hasta que termina la voz de la familia. Mientras tanto dan una
  reacción juguetona. En Semilla, la foto nunca se cierra con un toque.
- **Apertura automática**: ocurre después de la línea de Cometa (mínimo 3 s, tope 6 s). Cometa se
  apaga en 0,15 s en vez de cortarse.
- **Salida de la foto**: queda 1,5 s a la vista después del audio. Sin audio, 4,5 s.

## Implementación dev-godot 28-Sep-2026 (validaciones HE-44, PROVISIONAL)

- Voces de Cometa del guion (`recuerdos.md`, 77 líneas) con relleno TTS de Windows en `assets/audio/voces/recuerdos/*.wav` (TSV propio, todas en `pendientes_fal.txt`).
- Catálogo: `entrega_zona` (tras el regalo del anfitrión) y `pie` / `pie_en_audio` por recuerdo; el pie suena antes del audio de la familia en la entrega y en el álbum.
- Entrega: el sobre se abre tras la frase de Cometa (+0,4 s, entre 3 y 6 s) con invitación a tocar a los 1,5 s; si el niño abre antes, Cometa se desvanece en 0,15 s; flash de polaroid; la foto no se cierra antes de terminar su audio (toques = reacción juguetona), se va sola 1,5 s después (4,5 s sin audio); en Semilla nunca se cierra por toque; ícono con 0,8 s de halo.
- Mapa: la entrega espera la señal `celebracion_zona_terminada` (tope 15 s), no se desbloquea si ya se lanzó un juego y bloquea los toques del mapa mientras está activa. Marco dorado alcanzable (Pinta no cuenta).
- Álbum: tocar fuera de la foto la cierra.

## 11. Escala de Maxi y Nicole por edad real (PO, 10-nov-2026)

**Por qué:** las fechas de nacimiento que dio el PO son Sofía 27-jun-2018, Nicole 12-oct-2020 y
Maxi 26-nov-2022. A hoy tienen 8 años, 6 años y 3 años y 11 meses. La escala del §5 y el catálogo
original asumían Maxi de 2 y Nicole de 5, así que las fotos reales no calzaban.

**Opción elegida (B):** redistribuir las edades de los recuerdos de Maxi y Nicole según sus fotos
reales. Sofía no cambia. Reglas aplicadas (decididas por el orquestador, con la aprobación del PO):

- Cada foto ocupa el siguiente recuerdo en orden de edad. Los momentos (zonas, viajes) siguen en su
  orden original.
- La edad mostrada es la real de la foto (redondeada al mes).
- El pie de voz se asigna solo si la edad calza con un pie ya grabado (±1 mes), sin repetir pie.
  Si no calza, la foto va sin pie. No se grabó ninguna voz nueva.
- `hoy` solo lleva una foto de menos de 2 meses.
- La sugerencia del catálogo ya no aplica a Maxi ni a Nicole: sus fotos se eligieron por edad.

**Estado tras el cambio:**

- **Maxi:** 13 de 14 recuerdos con foto. `maxi_14` (hoy) queda como hueco porque su foto más
  reciente tiene 2,4 meses. Pie en 5 de 13.
- **Nicole:** 13 de 14 con foto. `nicole_01` (recién nacida) queda como hueco porque no hay foto de
  esa edad. Pie en 3 de 13.
- **Fotos sin recuerdo:** 2 de Maxi (04-feb-2025 y 25-sep-2025), por falta de hueco. Quedan en
  `assets/recuerdos/banco/`.
- **Sofía:** sin cambios. Hay unas 12 fotos suyas sin recuerdo de su edad. Se puede aplicar la
  misma redistribución si el PO lo pide.
- **Familiares:** 7 de 9. `familia_02` (mamá y papá con Sofía bebé) y `familia_07` (Navidad o 18 de
  septiembre) quedan sin foto. `familia_05` (cumpleaños) y `familia_06` (vacaciones) se eligieron
  por contenido y el PO debe revisarlas.
- **Álbum familiar:** es visible para los tres perfiles (`scripts/nucleo/album_recuerdos.gd`,
  `ALBUMES`), y cualquier hermano encuentra un recuerdo familiar (`scripts/autoloads/recuerdos.gd:183`).

**Pendiente para el PO:** las fechas exactas de las fotos sin hueco solo se resuelven con recuerdos
nuevos de 3 a 4 años, o con pies grabados para esas edades. Eso es decisión de contenido, no de código.

## 12. Huecos por etapa (PO, 10-nov-2026)

**Regla:** una foto por etapa completada. Una etapa es una zona del mapa de cada planeta (5 por
planeta, la quinta secreta). Hay 6 planetas: **30 etapas**. Arcoíris y Animalia ya tienen mapa (10
etapas); Melodía, Cuenta-Cuentas, Letralandia y Corazón no (20 etapas).

**Huecos:**

| Álbum | Cálculo | Huecos | Fotos | Faltan / sobran |
|---|---|---|---|---|
| Maxi | viaje inicial + 30 etapas + viaje final | 32 | 15 | faltan 17 |
| Nicole | viaje inicial + 30 etapas + viaje final | 32 | 13 | faltan 19 |
| Sofía | viaje inicial + 30 etapas + viaje final | 32 | 15 (+1 sin fecha) | faltan 17 |
| Familia | 9 actuales + 30 etapas | 39 | 37 | 2 sin foto (`familia_02`, `familia_07`); sobran 13 |
| **Total** | | **135** | **80 de 94** | faltan 53 de hermanos; sobran 13 familiares |

**Visibles hoy** (con mapa de Arcoíris y Animalia): 11 por hermano y 11 familiares = **44**.
**Ocultos hasta programar** los planetas restantes y las piezas, el rescate y el viaje final: **91**
(80 de etapas en 4 planetas + 11 de piezas, rescate y viajes).

**Familiares:** las fotos con mamá o papá son **holográficas** (`rareza: "holografica"`, borde arcoíris
que gira). Las de dos o tres niños son láminas normales. Criterio por etiqueta: "familia" o "papa".

**Pendiente del PO:**
- Fotos que faltan por hermano (cifras arriba). Dime cuáles agregas y las coloco.
- `IMG-5715.JPG` (Sofía, bebé con gorro) no tiene fecha: sin fecha no tiene edad y no puedo ubicarla.
- Las 13 fotos familiares sobrantes: quedan en `assets/recuerdos/banco/`. Si quieres más huecos
  familiares, el número es libre: basta con agregarlos al catálogo.
- Sección 11 queda superseded: la escala de Maxi y Nicole ahora es una por etapa, no la de hitos
  fijos.
