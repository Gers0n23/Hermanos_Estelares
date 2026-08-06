# Ficha de nivel — Planeta Arcoíris (Planeta 1, capítulo 1)

> Cubre los 3 minijuegos confirmados en GDD §4 para el Planeta Arcoíris —
> **Lluvia de colores**, **Formas traviesas** y **Pinta con Coco** — con su contenido
> temático por ruta (Maxi/Semilla, Nicole/Brote, Sofía/Estrella), assets, líneas de voz y
> condición de destello. Cierra la tarjeta HE-D4 y es el insumo directo de HE-13
> (arte del planeta) y HE-14/15/16 (implementación de cada minijuego).

- **Autor**: `disenador-niveles`
- **Estado**: diseño — pendiente de implementación (`dev-godot`), arte final (`disenador-personajes`,
  HE-13), líneas de voz finales (`guionista`), auditoría UX y QA
- **Planeta**: Arcoíris (#1) — tema "Colores y formas", anfitriona **Camaleona Coco**
- **Archivos de datos**: `datos/niveles/arcoiris_*.json` (uno por minijuego × perfil, ver §1-3)
- **Referencia GDD**: §1 (tono/derrota-gag), §2 (personajes y perfiles), §4 (Planeta Arcoíris,
  minijuegos y escalado S/B/E), §5 (rutas personalizadas, reglas por perfil), §6 (UX obligatoria)
- **Referencia de arte**: `docs/guia-estilo-generacion.md` §3 — Camaleona Coco
  (`assets/anclas/camaleona_coco_referencia.png`, pendiente de aprobación del PO) y entorno del
  Planeta Arcoíris (`assets/anclas/planeta_arcoiris_referencia.png`, pendiente de aprobación del PO)
- **Perfiles de los niños**: `docs/perfil-jugadores.md` (fuente de todo el contenido temático)

---

## 0. Cómo leer esta ficha

- **Un motor, tres rutas de contenido** (GDD §5): cada minijuego describe primero su **motor**
  (mecánica agnóstica de tema, reutilizable en otros planetas) y después el **contenido**
  específico de cada hermano — nunca "el mismo nivel con más elementos", sino un tema propio
  sobre el mismo esqueleto técnico.
- **Motores nuevos, sin ficha dedicada todavía**: solo el motor "emparejar"
  (`docs/fichas/motor-emparejar.md`) tiene ficha propia de `disenador-mecanicas`. Los tres
  motores de esta ficha (`clasificar`, `encajar`, `lienzo_libre`) se especifican aquí con el
  detalle mínimo para que `dev-godot` pueda implementarlos y `disenador-niveles` cargue
  contenido — si el equipo prefiere formalizarlos como fichas de motor independientes
  (mismo patrón que `emparejar`) antes de implementar, es un paso sano pero no bloqueante:
  el contrato de datos de cada uno ya queda cerrado abajo.
- **Reglas por perfil aplicadas transversalmente** (GDD §5, no se repiten en cada sección):
  - **Semilla (Maxi)**: imposible perder o trabarse, nada de texto ni menús intermedios,
    objetivos táctiles ≥96 px lógicos, un único gesto (tocar; arrastrar solo si el imán es
    generosísimo y perdona cualquier trayectoria).
  - **Brote (Nicole)**: puede "no lograrlo" con derrota-gag y reintento suave inmediato, un
    objetivo a la vez, instrucciones 100% por voz.
  - **Estrella (Sofía)**: reto real, derrota-gag posible, puntaje de 1-3 estrellitas, nunca
    imposible para 8 años, sin ayudas automáticas gratuitas.
- **Destellos**: la energía estelar que hace brillar los trajes y arma la nave (GDD §1/§3). En
  esta ficha cada minijuego otorga destellos de forma generosa y nunca los quita — ver
  condición exacta en cada sección y el resumen de economía en §5.
- **Todo desbloqueado entre hermanos** (GDD §5): cualquier niño puede jugar la ruta de otro sin
  penalidad; esta ficha define la ruta *curada* de cada uno, no un candado.

---

## 1. Minijuego 1 — Lluvia de colores

### 1.1 Motor compartido: `clasificar`

Elementos con un **atributo** (aquí, color) aparecen en pantalla y el niño los lleva a un
**objetivo** que pide ese atributo (aquí, un charco de pintura del mismo color); el motor
compara el atributo del elemento contra el que acepta el objetivo donde fue soltado/tocado.
Es el mismo esqueleto que después sirve, por ejemplo, para "Cada quien a su casa" del Planeta
Animalia (animal → hábitat) — un motor, muchos temas.

**Cómo escala genéricamente** (vía archivo de nivel, sin tocar código):

- `modo`: `"libre"` (cualquier objetivo vale, Semilla) | `"directo"` (un solo atributo por
  elemento/objetivo, Brote) | `"mezcla"` (el objetivo pide una combinación de 2 atributos
  primarios para producir uno nuevo, Estrella).
- `velocidad_caida` (px/s): 0 = los elementos aparecen quietos junto a su objetivo (Semilla);
  valores bajos y generosos para Brote; algo más vivo para Estrella, nunca al punto de exigir
  reflejos — esto sigue siendo un juego de 8 años, no un juego de ritmo.
- `elementos_simultaneos`: cuántos elementos hay a la vez en pantalla (1 para Semilla, sube
  para Brote/Estrella) — nunca sobrecarga visual.
- `iman_tolerancia_px`: qué tan generoso es el "snap" al soltar cerca de un objetivo (muy alto
  en Semilla, moderado en Brote, ajustado pero nunca frustrante en Estrella).
- `limite_intentos`: `null` en Semilla siempre; entero opcional en Brote/Estrella (activa
  derrota-gag, ver §1.9).
- Cantidad de `elementos`/`charcos` distintos define cuántos colores están en juego.

### 1.2 Contrato de datos (ejemplo genérico)

```jsonc
{
  "id_nivel": "arcoiris_lluvia_<perfil>_01",
  "motor": "clasificar",
  "perfil": "semilla",                  // "semilla" | "brote" | "estrella"
  "tema": "lluvia de colores",
  "modo": "libre",                      // "libre" | "directo" | "mezcla"
  "anfitrion_id": "coco",
  "fondo_id": "planeta_arcoiris_charcos",
  "velocidad_caida": 0,
  "elementos_simultaneos": 1,
  "iman_tolerancia_px": 160,
  "limite_intentos": null,
  "lineas_voz": { /* ver §1.7 */ },
  "elementos": [
    { "id": "gota_roja_01", "atributo": "rojo", "sprite": "sprites/arcoiris/gota_roja.png" }
  ],
  "objetivos": [
    {
      "id": "charco_rojo",
      "acepta": ["rojo"],               // "directo"/"libre": 1 atributo
      "sprite_vacio": "sprites/arcoiris/charco_rojo.png"
    },
    {
      "id": "charco_mezcla_verde",       // solo modo "mezcla" (estrella)
      "receta": ["azul", "amarillo"],
      "resultado": "verde",
      "sprite_vacio": "sprites/arcoiris/charco_vacio.png",
      "sprite_resultado": "sprites/arcoiris/charco_verde.png"
    }
  ]
}
```

### 1.3 Ruta Maxi — Semilla

**Objetivo**: tocar gotas y ver magia de color — sin concepto de "correcto/incorrecto".

- `modo: "libre"`: cualquier gota que toca cae/salpica en el charco más cercano y **siempre**
  "acierta" visualmente (destello, sonido, salpicadura de color), aunque el charco no
  corresponda exactamente al color de la gota — GDD §4 lo pide explícito ("S: tocar cualquier
  gota hace magia de color").
- 3 colores primarios grandes (rojo, azul, amarillo), una sola gota en pantalla a la vez,
  posicionada muy cerca de su charco (`velocidad_caida: 0`).
- Conexión con Maxi (GDD §4/HE-D3): a los 2 años el gancho es la **respuesta sensorial
  inmediata** (tocar → algo bonito pasa al instante), no un personaje favorito — por eso el
  contenido no fuerza dinosaurios/autos aquí; el guiño a sus gustos vive en el **secreto**
  de §1.10, no en el tema central.

### 1.4 Ruta Nicole — Brote

**Objetivo**: arrastrar cada gota a su charco del color correcto (emparejamiento real, GDD §4).

- `modo: "directo"`, `velocidad_caida` baja y pareja (nunca exige reflejo), 4-5 colores
  (incluye rosa, su color favorito confirmado en `docs/perfil-jugadores.md`), una gota a la vez
  para respetar la regla Brote de "un objetivo a la vez".
- Los charcos usan formas suaves con las que ella se identifica: un charco con **borde de
  florecita** para el rosa, uno con **orejitas de jirafa** dibujadas al borde para el amarillo
  (conecta con "jirafas" de su ficha), y el resto charcos redondos lisos — sin sobrecargar el
  tablero de decoración.
- `limite_intentos` opcional y holgado (activa el derrota-gag de §1.9); pista por voz si se
  dispersa mucho.

### 1.5 Ruta Sofía — Estrella

**Objetivo**: mezclar colores primarios para lograr los secundarios que pide Coco — el reto
real que su ficha pide explícitamente ("lo fácil le parece de bebés").

- `modo: "mezcla"`: 2-3 charcos de mezcla piden un color secundario (verde = azul+amarillo,
  naranja = rojo+amarillo, violeta = azul+rojo — sus colores favoritos, rosa y turquesa, son
  la paleta de fondo del tablero, no la del reto). Dejar caer el primer componente correcto
  "tiñe a medias" el charco (feedback visible de progreso); el segundo componente correcto
  completa la mezcla con una pequeña explosión de color.
- `velocidad_caida` algo más viva que Brote, `elementos_simultaneos: 2`, sin resaltados
  automáticos (GDD §5: "sin ayudas automáticas, el reto es real"); Cometa repite la instrucción
  si lo toca.
- `limite_intentos` holgado pero real (p. ej. 10, para 3 mezclas), habilita puntaje 1-3
  estrellitas según intentos usados.
- Dato curioso de Coco al completar cada mezcla (encargo de voz en §1.7) — conecta con su
  curiosidad declarada en su ficha ("le encantaría conocer todo tipo de mundos, con datos
  interesantes").

### 1.6 Assets necesarios

Ya existentes (`assets/anclas/`): Camaleona Coco (`camaleona_coco_referencia.png`), fondo del
Planeta Arcoíris con sus charcos de colores (`planeta_arcoiris_referencia.png`) — ambos
pendientes de aprobación final del PO pero ya sirven de referencia de estilo/paleta.

Faltan (encargo para `disenador-personajes`/pipeline de arte, HE-13):

- Sprites de gota por color (mínimo rojo/azul/amarillo/rosa/verde/naranja/violeta): forma de
  gota redondeada tipo "peluche pintado", coherente con la biblia de arte.
- Sprites de charco por color (vacío y "lleno"/resuelto), variantes decorativas de Nicole
  (borde florecita, borde jirafa).
- Sprites de charco de mezcla (vacío, medio-teñido con 1 componente, resultado final) — 3
  combinaciones (verde, naranja, violeta).
- Sprite del "secreto de Maxi" (§1.10): silueta de dinosaurio pequeño hecha de manchas de
  pintura, con una animación corta de squash al aparecer.
- Sprite del "bonus de Nicole" (§1.10): gota con silueta de jirafa/pony.
- SFX: salpicadura de agua/pintura suave, "ding" de acierto, sonido de mezcla mágica (chispa),
  sonido de "casi" amistoso (ya existe `assets/audio/sfx/ui/no_es_este.ogg`, reutilizable).

### 1.7 Líneas de voz necesarias (encargo para `guionista`)

No se escribe el texto final aquí — solo qué hace falta, quién habla y en qué momento.

| Clave | Quién | Momento | Encargo (tono/propósito) |
|---|---|---|---|
| `intro_semilla` | Coco | Al entrar al nivel (Maxi) | Muy breve, invita a tocar cualquier gota; cero instrucción compleja |
| `intro_brote` | Coco | Al entrar al nivel (Nicole) | Explica en una frase simple "lleva la gota a su charco del mismo color" |
| `intro_estrella` | Coco | Al entrar al nivel (Sofía) | Presenta el reto de mezcla con tono cómplice, no infantilizado |
| `acierto_libre` (x2-3) | Coco/Cometa | Cada toque de Maxi que "hace magia" | Celebración corta y variada, evita monotonía de repetir siempre la misma frase |
| `acierto_directo` (x2-3) | Coco | Cada gota de Nicole que cae en su charco correcto | Ánimo alegre, breve |
| `no_es_este` (x1-2) | Coco | Nicole/Sofía sueltan una gota en charco equivocado | Amistoso, nunca de error — "todavía no", no "mal" |
| `pista` | Cometa | Nicole se dispersa varios intentos seguidos | Pista suave, sin presión |
| `componente_a_medias` | Coco | Sofía deja el primer color correcto en un charco de mezcla | Refuerza que va bien, genera expectativa por el segundo color |
| `mezcla_lograda` (x3, una por color secundario) | Coco | Sofía completa cada mezcla | Celebración + el "dato curioso" sobre ese color (encargo específico: un dato simple y real sobre mezcla de colores, apto 8 años) |
| `secreto_maxi` | Cometa | Aparece el dino de pintura (§1.10) | Sorpresa juguetona, muy breve (Maxi tiene poca paciencia para charla) |
| `bonus_nicole` | Coco | Aparece la gota-jirafa/pony (§1.10) | Cálido, tono de "amiga nueva", coherente con su solidaridad |
| `victoria_final_semilla` / `_brote` / `_estrella` | Coco | Completar el nivel (uno por perfil) | Celebración de cierre, adapta el tono a la edad (más simple en Semilla) |
| `derrota_gag_brote` | Coco | Nicole agota `limite_intentos` (§1.9) | Comentario cómico, nunca de regaño, invita a reintentar ya |
| `derrota_gag_estrella` | Coco | Sofía agota `limite_intentos` (§1.9) | Comentario cómico + ánimo específico para su frustración fácil (GDD/ficha) |

### 1.8 Condición de destello

- **Todos los perfiles**: 1 destello garantizado al completar la definición de "completado" de
  su propio modo (Maxi: haber tocado todas las gotas que aparecieron en la secuencia del
  nivel; Nicole: haber emparejado todas las gotas configuradas; Sofía: haber logrado las 3
  mezclas, sin importar cuántos intentos usó).
- **Estrella, bonus opcional**: +1 destello si logra 3/3 estrellitas (mezclas resueltas con
  pocos intentos) — nunca obligatorio, es un extra de celebración, no una condición para
  avanzar (GDD §6: "el fracaso nunca castiga").
- Celebración asociada: confeti, Coco hace su cresta arcoíris al máximo brillo, conteo animado
  de destellos, gesto real de celebración del hermano jugador (GDD §2).

### 1.9 Gag de derrota

- **Semilla**: no existe — `limite_intentos` siempre `null`, cualquier toque produce algo
  bonito.
- **Brote (Nicole)**: si se agotan los intentos sin terminar de emparejar todas las gotas, las
  gotas no atrapadas caen sobre **Coco**, que se tiñe de todos esos colores a la vez y
  **estornuda un arcoíris** (coherente con su rasgo de cambiar de color, GDD/guía de arte) —
  gag tierno y a su medida, sin marcador de errores visible. Botón gigante "¡otra vez!" de
  inmediato; los charcos ya acertados quedan resueltos, no se repiten.
- **Estrella (Sofía)**: si se agotan los intentos sin lograr las 3 mezclas, los charcos se
  desbordan y **salpican pintura por todo el tablero — incluida Coco**, que queda cubierta de
  manchas de todos los colores y se sacude riendo como un perrito mojado (este es exactamente
  el ejemplo de gag que da GDD §1: "el personaje queda cubierto de pintura"). Reintento de un
  toque; las mezclas ya logradas quedan resueltas.

### 1.10 Momento memorable

- **Maxi**: de tanto en tanto (no siempre, para que sorprenda), tocar una gota hace que la
  salpicadura forme por un instante la silueta de un **dinosaurio pequeño** que "ruge" bajito y
  se desvanece en chispas — su gusto más fuerte (ficha) colado como secreto, sin tocar el tema
  central del nivel.
- **Nicole**: una de las gotas que caen no es un color cualquiera — tiene silueta de
  **jirafa o pony** en miniatura; al emparejarla dispara un arcoíris extra y Coco hace un
  gesto especial hacia ella (empatía/solidaridad, coherente con su personalidad).
- **Sofía**: al lograr la tercera mezcla, el tablero entero se ilumina con un mini-mural
  arcoíris y Coco comparte el dato curioso final del nivel — el tipo de detalle que conecta
  con su curiosidad declarada y le da algo "que aprendió" para contar después.

---

## 2. Minijuego 2 — Formas traviesas

### 2.1 Motor compartido: `encajar`

Piezas con una **forma** se arrastran hasta la **silueta** que les corresponde en un tablero;
el motor compara la forma de la pieza contra la que acepta cada silueta. En su variante
`compuesto`, una silueta final requiere **más de una pieza** combinada (ej. una casa = un
triángulo + un cuadrado) — mismo motor, sin tocar código, solo el archivo de nivel.

**Cómo escala genéricamente**:

- `modo`: `"simple"` (una pieza = una silueta, Semilla/Brote) | `"compuesto"` (2-3 piezas
  arman una silueta final, Estrella).
- Cantidad de `piezas`/`siluetas`: 3 grandes en Semilla, 6-8 en Brote, 3-4 figuras compuestas
  en Estrella (GDD §4).
- `iman_tolerancia_px`: muy generoso en Semilla, moderado en Brote, ajustado en Estrella.
- `limite_intentos`: `null` en Semilla; opcional en Brote/Estrella (derrota-gag, §2.9).
- Campo opcional `decoracion` por pieza: una textura/motivo de superficie sobre la forma
  geométrica base (ver contenido por ruta) — no cambia la forma en sí, solo su piel visual.

### 2.2 Contrato de datos (ejemplo genérico)

```jsonc
{
  "id_nivel": "arcoiris_formas_<perfil>_01",
  "motor": "encajar",
  "perfil": "brote",
  "modo": "simple",                     // "simple" | "compuesto"
  "anfitrion_id": "coco",
  "fondo_id": "planeta_arcoiris_islotes",
  "iman_tolerancia_px": 130,
  "limite_intentos": null,
  "lineas_voz": { /* ver §2.7 */ },
  "piezas": [
    {
      "id": "corazon_01",
      "forma": "corazon",
      "sprite": "sprites/arcoiris/forma_corazon.png",
      "decoracion": null
    }
  ],
  "siluetas": [
    { "id": "hueco_corazon", "acepta": ["corazon_01"], "posicion": { "x": 640, "y": 360 } }
  ],
  "figuras_compuestas": [               // solo modo "compuesto" (estrella)
    {
      "id": "figura_casa",
      "piezas_requeridas": ["triangulo_grande_01", "cuadrado_grande_01"],
      "sprite_resultado": "sprites/arcoiris/figura_casa.png"
    }
  ]
}
```

### 2.3 Ruta Maxi — Semilla

**Objetivo**: encajar 3 formas grandes (círculo, cuadrado, triángulo) con imán generosísimo —
GDD §4 pide explícito "imán generoso".

- `modo: "simple"`, 3 piezas, `iman_tolerancia_px` muy alto (encaja aunque suelte lejos del
  centro exacto), siluetas con contorno grueso brillante para que se noten a simple vista.
- Contenido: cada forma lleva una **decoración de superficie** ligada a sus gustos sin romper
  la forma geométrica: el círculo con textura de rueda de auto, el triángulo con un patrón de
  aleta/espalda de dinosaurio — un guiño reconocible sin necesitar un tema nuevo.

### 2.4 Ruta Nicole — Brote

**Objetivo**: encajar 6-8 formas (GDD §4), un objetivo resaltado a la vez por voz.

- `modo: "simple"`, set ampliado: círculo, cuadrado, triángulo, estrella, **corazón** (su
  gesto real de celebración, GDD §2) y rombo/óvalo.
- Paleta pastel rosa dominante en siluetas y bordes (color favorito confirmado en su ficha).
- Contiene una pieza "extra" no obligatoria con silueta de corazón especial — ver §2.10.

### 2.5 Ruta Sofía — Estrella

**Objetivo**: armar figuras compuestas de 2-3 piezas — el reto genuino que pide GDD §4 ("una
casa hecha de triángulo+cuadrado").

- `modo: "compuesto"`, 3-4 figuras: **casa** (ejemplo base del GDD), **cohete/nave** (triángulo
  + rectángulo + círculo, guiño al hilo espacial del juego), **gato** (triángulo + óvalo,
  conecta con "gatitos cachorros" de su ficha) y una figura sorpresa (§2.10).
- Sin resaltado automático de qué pieza va con cuál — debe deducirlo mirando la silueta
  completa (reto real, GDD §5).
- `limite_intentos` holgado, habilita puntaje 1-3 estrellitas.

### 2.6 Assets necesarios

Ya existentes: mismo fondo del Planeta Arcoíris (islotes con forma de figuras geométricas ya
descritos en `docs/guia-estilo-generacion.md` §3 — encajan directo con este minijuego, GDD lo
señala como el ancla visual de "Formas traviesas").

Faltan (encargo para `disenador-personajes`/HE-13):

- Set base de piezas geométricas grandes (círculo, cuadrado, triángulo, estrella, corazón,
  rombo/óvalo, rectángulo) + sus siluetas vacías, estilo "peluche pintado".
- Decoraciones de superficie para Maxi (rueda de auto sobre círculo, aleta de dino sobre
  triángulo) — mismo criterio de "sticker" ya usado como referencia de gustos sin copiar IP
  (GDD §4, nota de dinosaurios/autos).
- Pieza especial "corazón dorado" de Nicole (§2.10) con un pequeño brillo distintivo.
- Sprites resultado de las figuras compuestas de Sofía: casa, cohete, gato, y la figura
  sorpresa (corona, §2.10).
- SFX: encastre suave ("clic" amable), tambaleo cómico (derrota-gag), aplauso final.

### 2.7 Líneas de voz necesarias (encargo para `guionista`)

| Clave | Quién | Momento | Encargo |
|---|---|---|---|
| `intro_semilla` | Coco | Entrada Maxi | Muy breve, invita a "meter la forma donde va" con lenguaje de juego, sin tecnicismos |
| `intro_brote` | Coco | Entrada Nicole | Explica la mecánica en una frase; nombra la forma a buscar una a la vez |
| `intro_estrella` | Coco | Entrada Sofía | Presenta el reto de figuras compuestas, tono de "misión" no "tarea escolar" |
| `objetivo_actual` (rotativa) | Coco | Cada vez que Nicole debe ir por la siguiente pieza | Nombra la forma/color a buscar (regla Brote: un objetivo a la vez) |
| `acierto` (x2-3) | Coco | Cada pieza bien encajada (todos los perfiles) | Celebración corta variada |
| `no_es_este` | Coco | Pieza en silueta equivocada (Brote/Estrella) | Amistoso, nunca "error" |
| `pieza_extra_nicole` | Coco | Nicole encuentra/coloca el corazón dorado (§2.10) | Cálido, reacciona con su propio gesto (corazón coreano) |
| `figura_sorpresa_sofia` | Coco | Sofía completa la figura sorpresa (corona, §2.10) | Tono "te corono líder", conecta con su rol de hermana mayor (GDD §2) |
| `victoria_final_semilla` / `_brote` / `_estrella` | Coco | Cierre del nivel por perfil | Celebración de cierre, tono adaptado a edad |
| `derrota_gag_brote` | Coco | Nicole agota intentos (§2.9) | Cómico, invita a reintentar ya |
| `derrota_gag_estrella` | Coco | Sofía agota intentos (§2.9) | Cómico + ánimo puntual para su frustración fácil |

### 2.8 Condición de destello

- 1 destello garantizado al completar todas las piezas/figuras del nivel, en los tres
  perfiles.
- Estrella: +1 destello bonus opcional por 3/3 estrellitas (nunca obligatorio).
- Celebración: aplauso de Coco, piezas hacen un pequeño bailecito al encajar, gesto de
  celebración real del hermano jugador, conteo de destellos.

### 2.9 Gag de derrota

- **Semilla**: no existe.
- **Brote (Nicole)**: al agotar intentos, las piezas sueltas se enredan entre sí, ruedan y se
  apilan en una torre tambaleante que se derrumba con un "¡plop!" cómico — Coco se ríe y ayuda
  a reordenarlas. Botón "¡otra vez!" inmediato; piezas ya bien puestas quedan puestas.
- **Estrella (Sofía)**: al agotar intentos sin armar la figura, las piezas "cobran vida" un
  instante y bailan en desorden por el tablero antes de volver a su sitio original, con un
  comentario juguetón de Coco. Reintento de un toque; figuras ya logradas quedan resueltas.

### 2.10 Momento memorable

- **Maxi**: la decoración de rueda/aleta hace un mini-gesto al encajar (la rueda "gira" medio
  segundo, la aleta "sacude" como si el dino se sacudiera) — puro deleite sensorial.
- **Nicole**: una pieza extra, no obligatoria para completar el nivel, tiene forma de
  **corazón dorado** escondido entre las demás; si la encuentra y coloca, Coco le responde con
  su propio corazón-coreano en pantalla — un espejo directo de su gesto real de celebración
  (GDD §2), pensado para que lo note y lo cuente después.
- **Sofía**: la figura sorpresa final es una **corona** (triángulo + rectángulo + detalles),
  no anunciada de antemano; al completarla Coco "la corona" en broma como líder de la misión —
  conecta con su rol narrativo de hermana mayor que guía a los otros dos (GDD §1-§2).

---

## 3. Minijuego 3 — Pinta con Coco

### 3.1 Motor compartido: `lienzo_libre`

Lienzo de dibujo libre con dedo/mouse: el niño elige color y pincel y pinta sin ningún
objetivo ni condición de victoria/derrota — Coco imita en vivo los colores que se van usando
(su cresta se enciende con cada color, coherente con su diseño en
`docs/guia-estilo-generacion.md`). **GDD §4 es explícito: "Igual para todos"** — este motor no
escala por dificultad. Lo único que varía por perfil es lo que la UI puede exigirle a cada
edad (GDD §6) y pequeños deleites temáticos, nunca la mecánica ni ningún objetivo.

**Por qué no hay "escalado" aquí**: no existe condición de acierto/error que ajustar. La única
adaptación real es de **usabilidad**: Maxi (2 años) no puede operar un menú con muchas
opciones pequeñas, así que su versión de la UI reduce controles a lo mínimo tocable en grande
(GDD §6.1); Nicole y Sofía sí pueden manejar una paleta más amplia sin ayuda.

### 3.2 Contrato de datos (ejemplo genérico)

```jsonc
{
  "id_nivel": "arcoiris_pintar_todos_01",
  "motor": "lienzo_libre",
  "perfil": "cualquiera",               // el motor ajusta UI internamente por perfil activo
  "anfitrion_id": "coco",
  "fondo_id": "planeta_arcoiris_lienzo_trebol",
  "coco_imita_color": true,
  "guardar_dibujo": true,
  "paleta": {
    "semilla": ["rojo", "azul", "amarillo", "verde", "rosa", "morado"],   // 6 blobs grandes
    "brote_y_estrella": ["rojo","naranja","amarillo","verde","azul","violeta","rosa","turquesa","blanco","negro","cafe","celeste"]
  },
  "pinceles": {
    "base": "pincel_redondo",
    "maxi_extra": ["sello_dino", "sello_auto"],
    "nicole_extra": ["pincel_corazon", "pincel_estrella"],
    "sofia_extra": ["pincel_estrella", "pincel_purpurina"]
  },
  "lineas_voz": { /* ver §3.7 */ }
}
```

### 3.3 Ruta Maxi — Semilla

**Objetivo**: pintar libremente con un pincel gigante y colores en blobs grandes; sin palabra,
sin menú de guardado — el destello llega solo con jugar un momento (GDD §5: "todo lo tocable
responde con algo agradable").

- 6 colores como blobs enormes (≥96 px), un solo pincel grande fijo, sin selector de forma de
  pincel más allá de 2 "sellos" sorpresa (dino, auto) que aparecen como íconos igual de grandes
  — ligados a sus gustos más fuertes (ficha), pensados como deleite, no como objetivo.
- Sin flujo de "guardar": el dibujo se guarda solo de fondo; Cometa simplemente celebra cuando
  Maxi toca al ícono de Coco (ver §3.8), sin exigirle entender un botón de "guardar" per se.

### 3.4 Ruta Nicole — Brote

**Objetivo**: pintar con paleta más amplia y pinceles temáticos, mostrar su dibujo a Coco.

- Paleta completa (12 colores) con rosa destacado, pincel redondo base + dos pinceles extra
  desbloqueados de entrada: **pincel corazón** y **pincel estrella** — conecta con su gusto por
  personalizar/crear (ficha: Roblox, juegos de "vestir", "le encanta dibujar y pintar").
- Botón grande de "mostrar a Coco" (icónico, sin texto) que guarda el dibujo y dispara la
  celebración (§3.8).

### 3.5 Ruta Sofía — Estrella

**Objetivo**: mismo lienzo libre, con pinceles extra y el detalle de que su dibujo puede
guardarse para mostrarlo después — sin bajar el mecanismo a "reto", porque GDD lo pide igual
para todos.

- Paleta completa + **pincel estrella** y **pincel purpurina** (brillo/destello al arrastrar),
  coherente con su gusto por la estética kawaii/mágica (My Melody, Harry Potter, ficha).
- Mismo botón de "mostrar a Coco"; sin puntaje ni estrellitas en este minijuego específico —
  no aplica aquí (GDD §4 lo excluye de escalado).

### 3.6 Assets necesarios

Ya existentes: fondo del Planeta Arcoíris con su claro central en forma de trébol (ya descrito
como "el lienzo" en `docs/guia-estilo-generacion.md` §3), Camaleona Coco.

Faltan (encargo para `disenador-personajes`/HE-13):

- UI de paleta en dos variantes (blobs grandes Semilla / grilla completa Brote-Estrella).
- Pincel base + pinceles extra: corazón, estrella, purpurina (con partícula de brillo al
  arrastrar), y los 2 sellos de Maxi (dino, auto) como estampas de un solo toque.
- Botón "mostrar a Coco" (ícono de Coco, sin texto, ≥96 px).
- Animación de Coco reaccionando/imitando color en tiempo real (probablemente ya contemplada
  en el rig de Coco; confirmar con `dev-godot` si necesita un estado de animación dedicado).
- SFX: trazo suave, "pop" al usar un sello/estampa, aplauso al mostrar el dibujo.

### 3.7 Líneas de voz necesarias (encargo para `guionista`)

| Clave | Quién | Momento | Encargo |
|---|---|---|---|
| `intro_semilla` | Coco | Entrada Maxi | Muy breve, invita a "pintar lo que quieras", sin instrucción de objetivo |
| `intro_brote_estrella` | Coco | Entrada Nicole/Sofía | Invita a pintar libre y mostrarle el dibujo cuando quiera |
| `reaccion_color` (pool variado) | Coco | Cada vez que se usa un color nuevo (todos los perfiles) | Reacción breve y variada imitando/celebrando el color, evita repetición |
| `uso_sello_maxi` | Cometa | Maxi usa un sello (dino/auto) | Sorpresa juguetona y breve |
| `uso_pincel_especial` | Coco | Nicole/Sofía usan su pincel extra por primera vez | Cálido, nota el gusto/estilo propio del hermano |
| `mostrar_a_coco` | Coco | Se toca el botón de mostrar el dibujo (todos los perfiles) | Celebración generosa, sin evaluar calidad del dibujo — puro festejo |

### 3.8 Condición de destello

- **Todos los perfiles**: 1 destello al tocar el botón "mostrar a Coco" (o su equivalente
  automático simplificado en Semilla) — **sin mínimo de trazos ni tiempo exigido**: ni siquiera
  hace falta haber usado más de un color. Esto es deliberado (GDD §6: "el fracaso nunca
  castiga" aplicado también en positivo — nunca se le exige un umbral de "esfuerzo" a un nivel
  de expresión libre).
- Celebración: Coco reacciona con su cresta en todos los colores usados, aplauso, conteo de
  destello, gesto de celebración real del hermano.
- No hay estrellitas ni puntaje en este minijuego (GDD §4 lo marca "igual para todos", sin
  escalado).

### 3.9 Gag de derrota

No aplica — este minijuego no tiene condición de pérdida en ningún perfil (GDD §4: expresión
libre, sin objetivo). Ni siquiera Estrella pierde aquí; el reto real de Sofía en este planeta
vive en Lluvia de colores y Formas traviesas.

### 3.10 Momento memorable

- **Universal**: si el niño pinta un trazo que recorre varios colores seguidos, la cresta de
  Coco se enciende en un arcoíris completo por un instante (mímica directa de su rasgo de
  diseño, GDD/guía de arte) — un "espejo mágico" que cualquiera de los tres puede descubrir
  solo, sin que se lo expliquen.
- **Maxi**: el sello de dinosaurio, al estamparlo varias veces seguidas, hace que el grupo de
  estampas "camine" un pasito en fila antes de quedarse quietas — puro gag físico simple (GDD
  §1: "humor físico simple").
- **Nicole**: al usar el pincel corazón, Coco puede reaccionar la primera vez con su propio
  gesto (corazón coreano) — mismo eco de reconocimiento que en Formas traviesas (§2.10), sin
  duplicar exactamente el mismo momento (aquí es reacción a un pincel, no a una pieza extra).
- **Sofía**: el pincel purpurina dejado quieto sobre el lienzo un segundo genera una mini
  lluvia de destellos dorados — un pequeño "efecto especial" con el que puede presumir su
  dibujo, coherente con su gusto por lo mágico/kawaii.

---

## 4. Verificación contra GDD §6 (UX obligatoria)

| Regla §6 | Cómo se cumple en esta ficha |
|---|---|
| 1. Objetivos táctiles enormes | Elementos de Maxi ≥96 px lógicos en los 3 minijuegos (iman_tolerancia alto, blobs de paleta grandes); nada interactivo baja de 64 px en Brote/Estrella |
| 2. Todo se narra por voz | Todas las intros/instrucciones de §1.7/§2.7/§3.7 son líneas de audio; Cometa repite instrucción al tocarlo |
| 3. Sin texto para navegar | Ningún campo de contenido depende de texto en pantalla; los contratos de datos son metadatos internos, no UI |
| 4. Sin gestos complejos | Solo toque (Semilla) y arrastre simple (Brote/Estrella); mismo input unificado táctil+mouse |
| 5. Respuesta inmediata <100 ms | Todo toque/arrastre dispara feedback inmediato en los 3 motores (pulso, sonido), igual que el motor `emparejar` ya validado |
| 6. Sin publicidad/compras/enlaces | No aplica contenido externo en ningún minijuego |
| 9. Feedback de celebración generoso | Confeti, gesto real del hermano, línea de voz de cierre y conteo de destellos en los 3 minijuegos |
| Derrota-gag (§1 tono) | Definida y nunca punitiva en Lluvia de colores y Formas traviesas (Brote/Estrella); Semilla sin fallo posible; Pinta con Coco sin fallo posible para nadie |
| Salir siempre seguro (§6.8) | Ningún minijuego de esta ficha exige guardar estado manual para no perder progreso — se apoya en el guardado automático de `Progreso` (stack técnico §2) |

---

## 5. Economía de destellos del planeta (resumen)

Cada hermano completa su propia ruta de 3 minijuegos (con opción de jugar también los de sus
hermanos, sin penalidad):

| Minijuego | Destello garantizado | Bonus opcional |
|---|---|---|
| Lluvia de colores | 1 | +1 si Sofía logra 3/3 estrellitas |
| Formas traviesas | 1 | +1 si Sofía logra 3/3 estrellitas |
| Pinta con Coco | 1 | — (sin puntaje, GDD §4) |
| **Total mínimo por hermano** | **3** | hasta 5 para Sofía |

Al reunir los destellos de los 3 minijuegos de su ruta, se dispara la escena de historia del
planeta (GDD §3): Coco agradece, entrega la pieza de la nave (**ala izquierda**, GDD/guía de
arte §3 nave-estrella) y llega la video-llamada cómica de papá.

---

## 6. Qué queda pendiente para otras disciplinas

- **`guionista`**: escribir el texto final de todas las líneas de voz encargadas en §1.7, §2.7
  y §3.7 (claves, personaje y momento ya definidos; falta el texto en español cálido y el tono
  específico por hermano, siguiendo el `guion_voces.md` del stack técnico).
- **`disenador-personajes` / pipeline de arte (HE-13)**: producir los sprites listados en
  §1.6, §2.6 y §3.6 — gotas y charcos por color, set de formas geométricas + decoraciones,
  figuras compuestas de Sofía, pinceles/sellos temáticos y UI de paleta en sus dos variantes.
  Partir de las anclas ya generadas de Coco y del entorno del Planeta Arcoíris (pendientes de
  aprobación final del PO) para mantener coherencia de estilo.
- **`dev-godot`** (HE-14/15/16): implementar los tres motores (`clasificar`, `encajar`,
  `lienzo_libre`) como escenas reutilizables sobre `minijuego_base.gd`, cargando los contratos
  de datos de §1.2/§2.2/§3.2; considerar si conviene formalizar cada uno como ficha de motor
  independiente (patrón `docs/fichas/motor-emparejar.md`) antes de implementar, dado que hoy
  solo están especificados dentro de esta ficha de nivel.
- **`experto-ux-parvulo`**: auditar, sobre build real, los tamaños táctiles y timings de los
  tres minijuegos por perfil (mismos riesgos que la ficha de `emparejar` §8: confusión
  selección/acierto, tolerancia de imán, tamaño de hitbox con más elementos en Estrella) y
  confirmar que ningún derrota-gag genere ansiedad en playtest, en particular el de Sofía
  (frustración fácil, según su ficha).
- **`tester-qa`**: humo de los 3 minijuegos × 3 perfiles (9 combinaciones), incluyendo forzar
  cada derrota-gag y confirmar reintento de un toque + cero progreso perdido + señal
  `completado(destellos)` recibida correctamente.
- **PO**: aprobar formalmente las anclas de Camaleona Coco y del entorno del Planeta Arcoíris
  (hoy "pendientes de aprobación", según `docs/guia-estilo-generacion.md` §3) antes de que
  `disenador-personajes` produzca el arte derivado de esta ficha.
