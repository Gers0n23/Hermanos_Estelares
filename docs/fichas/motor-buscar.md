# Ficha de motor — `buscar` («Escondite animal», tipo ¿Dónde está Wally? / Hidden Folks)

- **Autor**: `disenador-mecanicas`, 05-Nov-2026 (tarjeta HE-108).
- **Estado**: PROPUESTA. Falta: maqueta HTML (HE-110) y aprobación del PO, auditoría de `experto-ux-parvulo`
  (HE-111), escenas y calibración de `disenador-niveles` (HE-D6), arte de `disenador-personajes` (HE-114) y
  voces de `guionista` (HE-112). La implementación (HE-118) espera al playtest del capítulo 1 (HE-18).
- **Actualización HE-124 (05-Nov-2026, política de derrota)**: el sol llega a los tres perfiles (Sofía 1,6 ×
  par, Nicole 2,2 × par desde z1, Maxi 3 × par) y el regalo de Sofía pasa a 3 derrotas. Las preguntas de §16
  quedan **cerradas** (el PO delegó). Cambios marcados **[HE-124]** ([Decisión 05-Nov, HE-124]).
- **Fuentes**: GDD §1, §4 (Animalia), §5, §6 y §8; `docs/perfil-jugadores.md`; `docs/stack-tecnico.md`;
  `scripts/base/minijuego_base.gd`; `scripts/base/gestor_turnos.gd`; `docs/fichas/modo-equipo.md` §11.4;
  `docs/fichas/lienzo-escenas-retos.md` §1.6-§1.7 (cola de objetivos y lupa de Pinta v2);
  `docs/fichas/motor-lienzo-libre.md` §12.4 (lupa); `docs/fichas/motor-topos.md` §3 (`racha_toby.gd`); Toby
  (HE-A4b: la antena es su "radar de olfateo", gancho de este juego).

**Marcas**: **[PO]** decisión del PO (05-Nov-2026) · **[Ref]** tomado del juego de referencia ·
**[Propuesta]** de `disenador-mecanicas`, reversible · **[HE-124]** [Decisión 05-Nov, HE-124] (§16 ya no
tiene preguntas abiertas).

---

## 1. La mecánica en una frase y las referencias

**Los animales de Toby se escondieron en una escena grande de la selva llena de cosas que reaccionan al
tocarlas; hay que encontrar a los de la lista, uno por uno, guiándose por la voz, la silueta o una pista
escrita.**

| Referencia | Qué tomamos | Qué no |
|---|---|---|
| **¿Dónde está Wally?** (Handford, 1987) | Escena densa con mucho "ruido visual"; objetivo chico dentro de la multitud; **señuelos parecidos** (los que se visten como Wally) | La página fija: la escena se recorre arrastrando |
| **Hidden Folks** (Adriaan de Jongh, 2017) | **Todo lo tocable reacciona con su sonido** (su firma: sonidos hechos con la boca); **lista de objetivos** con su dibujo y una **pista escrita**; objetos que **se abren** al tocarlos (carpas, arbustos, puertas) y esconden a alguien; escenas que crecen de 1-2 pantallas a muchas; cero castigo | El pellizco para hacer zoom (GDD §6.4) y los mapas de 6-10 pantallas (sesiones de 2-5 min) |
| Juegos casuales de objetos ocultos | El **reloj** de escena (el sol), en los tres perfiles con su factor [HE-124] | El castigo por tocar al azar (aquí solo corta la racha) |

**Escala por edad sacada de las referencias** [Ref + Propuesta]: Hidden Folks sube la dificultad con el
**tamaño de la escena**, la **cantidad de objetivos**, lo **escondido** que está cada uno (parte visible,
camuflaje), las **acciones** necesarias para destaparlo y lo **críptico** de la pista. Wally suma los
**señuelos**. Maxi juega el nivel 1 de Hidden Folks sin lista (todo a la vista, todo suena); Nicole, sus
primeras áreas (1,5-2 pantallas, 5-7 objetivos, con dibujo); Sofía, áreas medias (2-3 pantallas, 8-12
objetivos, pistas escritas, camuflaje, señuelos tipo Wally y escondites de 2 pasos).

**Choques con otras mecánicas del juego**:

- **La lupa de Pinta v2** (tarjeta HE-108: "coordinar sin duplicar"): la lupa **no es la mecánica** de
  este juego, es una herramienta de navegación. **No se inventa otro zoom**: `buscar` usa **el mismo
  control** que Pinta (`lienzo-escenas-retos.md` §1.7: un toque arma la lupa, el siguiente toque acerca 2×
  ahí; otro toque a la lupa vuelve a 1×), con el mismo ícono y la misma voz. Propuesta a `dev-godot`: extraer
  la lupa de `lienzo_libre` a `scripts/ui/lupa_zoom.gd` para que la compartan los dos motores. Así el niño
  aprende **un** gesto para todo el juego. Además, las escenas se diseñan **legibles a 1×**: la lupa es una
  comodidad de Sofía, nunca un requisito.
- **No es la carta lupa de Parejas** ni las gafas-lupa del Coleccionauta: el "detector" de Toby es su
  **olfato** (la antena, §10.4).
- **La "misión de Maxi"** en el final (HE-39: "encuentra lo que nadie más ve") podrá reutilizar este motor.

## 2. Reglas que no se rompen

1. **Solo tocar y arrastrar** (GDD §6.4): tocar encuentra o hace reaccionar; arrastrar recorre la escena.
   Sin pellizco y sin doble toque.
2. **Todo responde en < 100 ms**: al presionar aparece una onda bajo el dedo y suena un "tic"; todo objeto de
   la escena tiene su reacción.
3. **Tocar nunca es un error**: tocar cosas que no son el objetivo es explorar. Solo corta la racha de Sofía.
4. **El juego no se pausa con voces**: la voz presenta cada objetivo (Brote) y responde a los toques en la
   lista; no habla entre toques.
5. Los escondites se diseñan a mano (**nada procedural**, GDD §8): cada animal tiene 2-3 escondites
   posibles en el nivel y se sortea uno por partida.
6. La lógica (`LogicaBuscar`) va sin pantalla y es determinista con semilla.
7. El motor no conoce el tema: escena, objetos, animales, escondites y pistas llegan del nivel.
8. **Nada de bichos** en ninguna escena (Nicole y Sofía): ni como objetivo, ni como señuelo, ni como
   decorado (nada de mariposas que "aleteen" como relleno donde juegan ellas: se reemplazan por pájaros u
   hojas que caen). El ambiente HE-A7b tiene mariposas: `disenador-personajes` las saca de las escenas de
   este juego.

## 3. ¿Se puede reutilizar un motor existente? (respuesta honesta)

- Ningún motor busca objetos en una escena. `lienzo_libre` sabe recorrer y acercar un lienzo grande (lupa,
  "ver todo"), pero es un editor de dibujo; meterle "objetivos escondidos" mezclaría dos juegos.
- **Se reutiliza**: la **lupa** (extraída, §1), la **cola de objetivos** como idea de UI (tarjetas con
  pictograma de Pinta v2 §1.5-§1.6: aquí, silueta del animal), `barra_record.gd`, `pista_con_costo.gd`,
  `celebracion.tscn`, `racha_toby.gd` y el modo equipo.

**Conclusión**: motor nuevo `buscar` (`scripts/motores/buscar/`), con la lupa compartida.

## 4. La escena

### 4.1 Pantalla (1280 × 720)

| Elemento | Dónde | Notas |
|---|---|---|
| **Escena** | toda la pantalla, detrás de todo | más ancha (y en z5, más alta) que la pantalla: se recorre arrastrando |
| Botón casa y Cometa | arriba a la izquierda | |
| **Lista de objetivos** | franja inferior (y 600-720), sobre un tronco | Maxi: sin lista (fila de amigos encontrados); Nicole: 1 tarjeta grande + puntitos; Sofía: 3 tarjetas + puntitos |
| Toby | abajo a la izquierda, sobre la franja (20-200, 470-720) | su antena es la pista de Sofía (96 px de toque) |
| Lupa | arriba a la derecha, 96 px | solo Sofía z3+ |
| Mapita | arriba a la derecha, bajo la lupa (200 × 60) | Nicole y Sofía: un rectángulo muestra qué parte de la escena se ve. Tocarlo lleva ahí |
| Barra de récord y sol | a la derecha | Brote (desde z2, con récord) y Estrella |

La **zona útil** de la escena (donde puede haber objetivos) termina en y 590 de la pantalla: nunca un animal
detrás de la lista.

### 4.2 Recorrer la escena

- **Arrastrar** con un dedo mueve la escena (con inercia suave, frenado en 0,4 s y rebote elástico en los
  bordes).
- **Toque frente a arrastre**: presionar dispara la onda al instante; al soltar, si el dedo se movió menos de
  **16 px**, es un toque (encuentra o hace reaccionar); si se movió más, fue arrastre y no toca nada.
- **Maxi no recorre**: su escena mide una pantalla.

## 5. Bucle de juego

1. **Presentación** (≤ 5 s): Toby cuenta "¡a la una, a las dos, a las tres!" tapándose los ojos y los animales
   corren a esconderse (se ven correr hacia sus escondites, en silueta rápida). Se puede saltar con un toque.
2. **Objetivo activo** (Brote: uno a la vez; Sofía: 3 tarjetas): Toby lo presenta por voz (Brote) o la
   tarjeta muestra la pista (Sofía).
3. **Explorar**: arrastrar y tocar. Todo reacciona (§7.1).
4. **Encontrar**: el animal salta afuera (§7.2) y vuela a su tarjeta. Entra el siguiente.
5. Con todos encontrados: celebración y `completado`.

## 6. Interacciones (tiempos y feedback)

| Acción | Respuesta | Tiempo | Feedback |
|---|---|---|---|
| Presionar en cualquier parte | Onda bajo el dedo | inmediato | anillo de 40 px que crece y se va (0,25 s) + "tic" suave |
| Tocar un **objetivo activo** | Encontrado | al soltar (≤ 16 px de movimiento) | §7.2 |
| Tocar un **animal de la lista que todavía no es el activo** (Brote) | Encontrado **igual** [Propuesta] | al soltar | se guarda en su tarjeta con un brillo; cuando le toque, entra ya encontrado ("¡ese ya lo encontraste!", como Pinta v2 §1.6) |
| Tocar un **señuelo** (animal parecido que no está en la lista) | Saluda | al soltar | su sonido, se presenta ("¡yo soy la cebra, no el caballo!") con un gesto chistoso. Sofía: corta la racha |
| Tocar un **objeto interactivo** | Su reacción | al soltar | §7.1 (arbusto que se sacude, carpa que se abre, laguna que salpica…) |
| Tocar un **escondite cerrado** que guarda a alguien | Se abre y muestra quién está | al soltar | 1.er toque: se abre (y el animal queda visible, asustado-risueño); 2.º toque, sobre el animal: encontrado. En Brote un toque basta para abrir **y** encontrar si es el activo |
| Tocar la tarjeta de un objetivo | Repite su voz o lee su pista | inmediato | la tarjeta rebota; la escena no se mueve |
| Tocar el mapita | La escena se desliza ahí | 0,35 s | — |
| Tocar la antena de Toby (Sofía) | Pista con costo (§10.4) | inmediato | `pista_con_costo.gd` |

**Zonas de toque de los objetivos** [Propuesta]: la caja de la parte **visible** del animal + 24 px de margen,
con un mínimo de 160 px (Semilla), 96 px (Brote) o 64 px (Estrella), siempre medido en pantalla a 1×. Si se
superpone con un señuelo, **gana el objetivo**. Si se superpone con un objeto interactivo, gana el animal.

## 7. Game feel

### 7.1 La escena es un juguete (lo que hace a Hidden Folks)

- Cada escena tiene **≥ 12 objetos interactivos** (≥ 6 en Semilla) con reacción y sonido propio: arbustos que
  se sacuden y sueltan hojas, flores que se abren, nenúfares que se hunden, piedras que ruedan un poco, nubes
  que hacen "puf", la carpa de Toby que sacude el toldo, ramas que se balancean.
- **Sonidos "hechos con la boca"** [Ref Hidden Folks]: el PO, la familia o `guionista` pueden grabarlos
  (una buena actividad con los niños: que ellos pongan los "fshhh" y los "plop"). Hasta entonces, CC0.
- Cada objeto tiene un enfriamiento de 0,5 s para no saturar si se toca a ráfagas, pero **siempre** responde
  algo (al menos la onda y el tic).

### 7.2 Encontrar

- El animal **salta fuera** de su escondite (squash al despegar, stretch en el aire, 0,3 s), gira, dice su
  sonido con una risita ("¡me encontraste!") y suelta 16 estrellitas y un anillo dorado.
- Vuela en arco (0,6 s) a su tarjeta, que pasa de silueta a color con un "¡pling!" que **sube un semitono por
  eslabón de racha**. Toby salta, orejas arriba.
- Con "¡ojo de águila!" (§9.1), estela dorada y campanita doble.
- **En la escena queda una marca**: el escondite vacío brilla un instante y luego tiene una huellita dorada,
  para no volver a buscar ahí.

### 7.3 Celebración final

- Todos los animales encontrados salen de la lista, corren a la escena y forman una **foto de grupo** con
  Toby al centro (flash de cámara, "¡clic!", y la foto se ve 1,5 s). [Propuesta: la foto podría ir al álbum de
  recuerdos como estampita; es decisión del PO, `album-recuerdos.md`.]
- Confeti de hojas y estrellas y `celebrar()` con el gesto real del hermano. Récord nuevo con el
  hueso-trofeo.

### 7.4 SFX

`tic`, `encontrado` (con tono), `vuelo_tarjeta`, `tarjeta_color`, sonidos de cada objeto interactivo
(`arbusto`, `carpa`, `chapoteo`, `flor`, `piedra`, `rama`, `nube`…), `abrir_escondite`, `senuelo_hola`,
`clic_foto`, `sol_se_pone`, y los sonidos de cada animal. Ningún sonido de error.

## 8. Escala Semilla / Brote / Estrella

### 8.1 Tabla por perfil (zona 1 → zona 5)

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella |
|---|---|---|---|
| `escena` (px) | 1280 × 720 | 1920 × 720 (z1-z2) → 2560 × 720 (z3-z5) | 2560 × 720 (z1-z2) → 3200 × 720 (z3-z4) → 3840 × 1080 (z5) |
| `objetivos` | 5 | 5 (GDD §4) → 7 | 8 → 12 |
| Lista | sin lista: libre | 1 activo a la vez (GDD §5: un objetivo a la vez), voz + silueta | 3 tarjetas con pista escrita (GDD §4) |
| `visible` (parte del animal a la vista) | ≥ 70 % | 60 % → 40 % | 40 % → 20 % |
| Tamaño del animal en pantalla | ≥ 160 px | 120 → 96 px | 90 → 64 px |
| Escondites que se abren | 0 (pero todo reacciona) | 0 (z1-z2) → 1 (z3-z4) → 2 (z5) | 1 (z1) → 3 (z3) → 4, dos de ellos de 2 pasos (z4-z5) |
| `camuflaje` (color parecido al fondo) | no | no | desde z2 |
| `senuelos` | no | 0 (z1-z3) → 1 (z4-z5) | 2 (z3) → 4 (z5) |
| Pista | — | voz + silueta ("¡busca al pony!") | z1-z2 descriptiva ("el que tiene rayas"); z3+ con dos rasgos ("rayas y bigotes, pero chiquito"); z5 indirecta ("le encanta el frío") |
| `tiempo_par_s` (escena) [HE-124] | 35 → 45 s por escena (solo para el sol; no se muestra) | 80 → 160 s (desde z1; el **bono** y el récord, solo con récord previo) | 150 → 270 s |
| Sol (derrota) [HE-124] | **sí: 3 × tiempo par** (§10.1) | **sí, desde z1: 2,2 × tiempo par** | **sí: 1,6 × tiempo par** (antes 2 ×) |
| `sol.minimo_reintento_s` [HE-124] | 60 | 60 | 45 |
| `regalo_tras_derrotas` [HE-124] | 2 | 2 | **3** |
| `ayuda_fuerte_tras_derrotas` [HE-124] | 3 (§10.1) | — | — |
| Lupa | no | no | desde z3 |
| Ayuda quieto | 6 s: el siguiente asoma la cabeza y llama; 10 s: Toby corre y lo señala | 12 s: la escena se desliza hacia la zona del activo; 20 s: el activo asoma y llama | — (pista con costo) |

**De dónde salen los números**: la primera área de Hidden Folks tiene alrededor de 1,5 pantallas y 5-8
objetivos; las medias, 3-4 pantallas y 10-15. Nicole juega a la altura de la primera área; Sofía, de la
primera a una media. **Tamaño del objetivo**: en un libro de Wally, Wally ocupa del orden del **0,1 %** de la
página doble. Sofía z5 (64 × 64 px en 3840 × 1080) queda en ~0,1 %: un reto de Wally real. Nicole z5 (96 px
en 2560 × 720) queda en ~0,5 %, y Maxi (160 px en una pantalla), en ~2,8 %. **Duración estimada**: Maxi ~1,5
min; Nicole ~2-3 min; Sofía ~3-5 min. Se confirma en la maqueta y el playtest.

### 8.2 Contenido (lo define HE-D6; lo que el motor debe soportar)

- **Maxi**: dinos en la cueva y la selva prehistórica [PO] (con rugidos), y animales de granja.
- **Nicole**: ponys, caballos, jirafas, gatitos; pistas por voz con el nombre.
- **Sofía**: rasgos para leer y deducir (rayas, manchas, plumas, caparazón, "le encanta el frío", "duerme de
  día"), animales chilenos (pudú, huemul, cóndor) y señuelos tipo Wally (cebra / caballo con pijama a
  rayas; gato atigrado / tigre; pony / caballo; lobo / perro). Todo lo que pida "deducir" debe ser
  inequívoco (lo revisa el validador de §11.2).

### 8.3 Refuerzo de lectura de Nicole [Propuesta]

La tarjeta del objetivo activo muestra, bajo la silueta, **el nombre en mayúsculas** ("PONY", 48 px). Nunca se
necesita leerlo: la voz lo dice y la silueta lo muestra. Se activa con `mostrar_palabra` (por defecto en
Brote).

## 9. Puntaje, estrellitas y récord

### 9.1 Puntaje (Brote y Estrella)

| Evento | Puntos |
|---|---|
| Encontrado | 100 × racha (×1 a ×5) |
| **"¡Ojo de águila!"** (encontrado sin tocar ningún señuelo ni objeto desde el anterior) | +100, sin multiplicador |
| Escondite de 2 pasos | +100 |
| Tiempo par (escena entera) | +10 por segundo que sobra |

- **Racha** (Sofía): encontrados seguidos **sin tocar un señuelo**. Tocar objetos interactivos **no** corta la
  racha (explorar nunca se castiga); tocar un señuelo sí. En Nicole, la racha solo se corta por el
  tiempo: más de 25 s entre dos encontrados.
- Así tocar al azar no sirve: no se pierde nada, pero no se gana el "ojo de águila" y, en Sofía, se corta la
  racha con los señuelos.

### 9.2 Estrellitas y récord

- **Nicole**: 1-3 por puntaje (`umbrales_puntaje`, p50 y p80 de la jugadora simulada), sin huecos vacíos.
- **Sofía**: 1-3 por puntaje (`umbrales_puntaje`); cada pista resta una; tras una derrota, máximo 2.
- **Récord personal** por estación y hermano (`registrar_record`), con la banderita de `barra_record.gd`.
- **Maxi**: sin puntaje.

## 10. El fallo

### 10.1 Semilla: tocar nunca es un error, perder es posible pero suave [HE-124]

- No hay lista ni orden: **cualquier** animal que encuentre vale, y **todo** lo que toque responde. Los
  animales se esconden a medias y **hacen ruido** cada tanto (cada 5-8 s uno al azar, desde su escondite: el
  sonido sale de su lado de la pantalla).
- La ayuda (6 s / 10 s) garantiza que nunca se trabe.
- **Lo único que hace perder es el sol** (3 × par: ~105-135 s por escena de 5-7 animales que Maxi encuentra en
  ~35-45 s). Su sol es un **solcito con carita que bosteza**; al ponerse, los escondidos salen a hacerle
  cosquillas a Toby (1,5 s, sin puntaje en el cartel, solo la flecha gigante).
- **Regalo tras 2 derrotas**: Toby encuentra uno. **Ayuda fuerte tras 3**: en la escena siguiente todos los
  animales **asoman la cabeza y llaman a la vez** y no hay sol (victoria asegurada); Toby lo presenta como
  "¡ahora se esconden mal a propósito!".

### 10.2 Derrota-gag: "¡Se puso el sol!" (los tres perfiles [HE-124])

- El sol baja despacio detrás de los árboles (relojito de `sol.factor_par` × tiempo par: Sofía 1,6, Nicole
  2,2, Maxi 3; sin tic-tac ni parpadeo).
- Si se pone con animales sin encontrar: **se encienden las lucecitas de la carpa de Toby** y todos los
  escondidos salen a la vez gritando "¡aquí estábamos!", haciendo caras chistosas; uno se le sube a Toby a la
  cabeza y otro le saca la lengua al casco; Toby se cae sentado de risa. 2,5 s.
- "¡Otra vez!" grande (tocar en cualquier parte del cartel). **Los ya encontrados se quedan encontrados**; los
  que faltan **se cambian de escondite** (otro de sus 2-3 posibles) y el sol vuelve con el tiempo
  proporcional a los que faltan (`tiempo_par × factor_par × faltan / total`, mínimo `minimo_reintento_s`).
- **Regalo** [HE-124]: Toby regala uno (lo encuentra él con el olfato) **tras 3 derrotas** en Sofía y **tras 2**
  en Nicole y Maxi. Se ofrece descansar tras 4 (Sofía) o 3 (Nicole).
- **Destellos y estrellitas solo al ganar**; los encontrados quedan encontrados.

### 10.3 Brote: con derrota desde z1 [HE-124; reemplaza "sin derrota"]

Wally y Hidden Folks no tienen reloj, pero los juegos casuales de objetos ocultos (la otra referencia de §1)
sí, y el PO pidió que perder sea posible en todo. Para no romper la regla de **un objetivo a la vez**, el sol
de Nicole mide la **escena entera** (2,2 × par: 80 s de par en z1 → 176 s de sol para 5 animales), nunca cada
objetivo, y la ayuda de 12 s / 20 s sigue activa: una niña que busca con ganas casi siempre llega (~75 % al
primer intento, p25). Al reintentar, lo encontrado se queda y solo los que faltan cambian de escondite.

### 10.4 Pista de Sofía (cuesta una estrellita): el radar de Toby

Tocar la antena: Toby **olfatea** (nariz arrugada, antena girando, "snif snif"). Si el objetivo de la primera
tarjeta está fuera de la pantalla, **brilla el borde** de la pantalla del lado donde está y la escena se
desliza un poco hacia allá; si está en la pantalla, aparece un **círculo cálido** de 300 px que lo contiene
(no lo señala exacto: hay que mirar). Con 1 sola estrellita, la pista es gratis.

## 11. Esquema JSON del nivel

### 11.1 Archivo de nivel

`datos/niveles/animalia/<zona>/buscar_<perfil>.json`

```jsonc
{
  "id_nivel": "animalia_z3_buscar_estrella",
  "motor": "buscar",
  "perfil": "estrella",
  "planeta": "animalia", "zona": "zona3_...",
  "escena": {
    "tamano": [3200, 720],
    "capas": ["res://assets/.../fondo_lejos.png", "res://assets/.../fondo_medio.png"],
    "inicio_vista": [0, 0],                // esquina de la vista al empezar
    "zona_util_max_y": 590                 // nada de objetivos detrás de la lista
  },
  "objetos": [                             // interactivos: reaccionan, a veces esconden
    { "id": "carpa_toby", "sprite": "res://...", "pos": [1400, 420], "reaccion": "abrir_toldo",
      "sonido": "sfx/buscar/carpa.ogg", "escondite": true, "pasos": 1 },
    { "id": "arbusto_3", "sprite": "res://...", "pos": [900, 500], "reaccion": "sacudir",
      "sonido": "sfx/buscar/arbusto.ogg" }
  ],
  "animales": [
    { "id": "cebra", "sprite": "res://...", "sonido": "sfx/animales/cebra.ogg",
      "nombre_voz": "voces/animalia/nombres/cebra.wav",
      "escondites": [                      // 2-3 posibles; se sortea uno por partida
        { "pos": [2100, 380], "escala": 0.6, "visible": 0.3, "detras_de": "arbusto_7" },
        { "pos": [600, 300], "escala": 0.6, "visible": 0.25, "dentro_de": "carpa_toby" }
      ],
      "pista": { "texto": "Busca al que tiene rayas y no es un tigre", "voz": "voces/…/pista_cebra.wav" } }
  ],
  "objetivos": ["cebra", "pudu", "condor"],   // los de la lista; el resto del pool son señuelos
  "senuelos": ["caballo_pijama", "tigre"],
  "modo_lista": "tarjetas",                // libre (Semilla) | uno (Brote) | tarjetas (Estrella)
  "tarjetas_visibles": 3,
  "mostrar_palabra": false,                // Brote: nombre bajo la silueta
  "zona_toque_min_px": 64,
  "margen_toque_px": 24,
  "umbral_arrastre_px": 16,
  "ruido_semilla_s": [5, 8],               // Semilla: cada cuánto suena un escondido
  "lupa": true,
  "mapita": true,
  "tiempo_par_s": 150,                     // [Decisión 05-Nov, HE-124] obligatorio en los tres perfiles (Semilla: por escena)
  "sol": { "factor_par": 1.6, "minimo_reintento_s": 45 },   // null = sin derrota. [Decisión 05-Nov, HE-124] estrella {1.6, 45} (antes 2.0) · brote {2.2, 60} desde z1 · semilla {3.0, 60}
  "puntos": { "encontrado": 100, "racha_max": 5, "ojo_aguila": 100, "dos_pasos": 100, "por_segundo": 10 },
  "racha_brote_s": 25,
  "umbrales_puntaje": { "dos": 1600, "tres": 2300 },
  "regalo_tras_derrotas": 3,               // [Decisión 05-Nov, HE-124] estrella 3 (antes 2) · brote 2 · semilla 2
  "ayuda_fuerte_tras_derrotas": null,      // [Decisión 05-Nov, HE-124] clave nueva. Semilla: { "derrotas": 3, "todos_asoman": true, "sin_sol": true }
  "descanso_tras_derrotas": 4,             // [Decisión 05-Nov, HE-124] clave nueva: estrella 4 · brote 3 · semilla null
  "ayuda_idle_s": null,                    // Semilla [6, 10]; Brote [12, 20]
  "pistas_cuestan_estrellita": true,
  "lineas_voz": {
    "intro": "…", "cuenta_toby": "…", "instruccion": "…", "busca": { "cebra": "…" },
    "ya_encontrado": "…", "senuelo": { "tigre": "…" }, "victoria": ["…"], "derrota_gag": "…",
    "regalo": "…", "pista_usada": "…", "record": "…", "primer_record": "…", "ayuda_fuerte": "…", "descansar": "…"
  }
}
```

- Retrocompatibilidad [HE-124]: sin `ayuda_fuerte_tras_derrotas` → no hay; sin `descanso_tras_derrotas` → 3;
  `sol` activo sin `tiempo_par_s` → `push_warning` y sin sol.

### 11.2 Validador de escenas (para `disenador-niveles`)

`herramientas/validar_buscar.py` (o `.gd`): para cada animal y cada uno de sus escondites, comprueba que la
zona de toque cumpla el mínimo del perfil, que no quede detrás de la lista ni fuera de la escena, que la
parte visible sea la declarada (± 10 %), que ninguna pista describa también a un señuelo de la misma escena y
que dos objetivos no compartan escondite en la misma partida.

### 11.3 El arte de las escenas (riesgo de costo)

Una escena tipo Hidden Folks es mucho arte. Propuesta para HE-114: **componer** las escenas con piezas SVG
reutilizables (árboles, arbustos, rocas, carpas, nenúfares) sobre los fondos de cada zona, y no pintar una
ilustración entera por escena. El nivel ya está pensado así (`objetos` con posición). Ver §16, pregunta 3.

## 12. Contrato con el núcleo y con el modo equipo

### 12.1 Solitario

- `MotorBuscar extends MinijuegoBase`. `asegurar_victoria()` en el instante en que el último animal es
  encontrado, antes de su vuelo a la tarjeta.
- `registrar_record`, `obtener_record`; `guardar_estado_parcial({encontrados, escondites})` tras cada
  encontrado en Sofía (escenas de ~5 min); al volver se retoma con los mismos escondites.
- `presentacion_vista("lupa_buscar")` / `("radar_toby")` para presentar la lupa y la pista una sola vez.
- Señales de `LogicaBuscar`: `encontrado(id, puntos, racha, ojo_aguila)`, `senuelo_tocado(id)`,
  `objeto_tocado(id)`, `escondite_abierto(id_objeto, id_animal)`, `objetivo_activo(id)`, `escena_completa()`.

### 12.2 Modo equipo (`modo-equipo.md` §11.4)

- **Una escena compartida** (2560 × 720) con 6 objetivos: lo que encuentra uno queda encontrado para todos.
- **Tope por turno** (`aciertos_max_turno`): semilla 1, brote 1, estrella 2. Cada encontrado llama
  `notificar_acierto()`; tras `tope_alcanzado`, el motor espera que el animal llegue a su tarjeta y llama
  `confirmar_turno_estable()`.
- **Fallo que corta el turno**: `segundos_por_turno` (brote 40, estrella 35) sin encontrar → el animal
  activo **se cambia de escondite** (se lo ve correr a otro, gag) y `terminar_turno(true)`. Tocar un señuelo
  → `notificar_fallo_suave()`.
- **Maxi**: en su turno el activo **asoma y hace ruido** desde el inicio y la escena se desliza hasta él; con
  `semilla_auto_s`, `jugada_automatica_pedida` hace que el animal salte solo y cuente como encontrado.
- `aplicar_perfil_turno(perfil)`: tamaño de zona de toque, ruido del escondido, pista escrita o por voz.
- **Derrota del equipo**: `gag_derrota_aspirar` levanta a los animales **no encontrados** de sus escondites
  hacia la mochila-torre; `gag_derrota_devolver` los estornuda a **escondites nuevos**; `reintentar_equipo()`
  recalcula escondites; `contar_logro_equipo()` = encontrados.
- `ancla_meta_turno()`: borde izquierdo de la franja de la lista.

## 13. Maqueta HTML jugable (HE-110): `docs/maquetas/buscar-v1.html`

Debe demostrar:

1. Una escena de 1, 2 y 3 pantallas **compuesta con piezas** (formas simples sirven), con arrastre, inercia,
   rebote, el umbral de 16 px entre toque y arrastre, y el mapita.
2. **Todo reacciona** al toque, con sonido.
3. Los tres modos de lista (libre, uno, tarjetas), la silueta con palabra de Nicole y las pistas escritas de
   Sofía.
4. Escondites que se abren (1 y 2 pasos), señuelos con su presentación chistosa y el cambio de escondite al
   reintentar.
5. La lupa **igual a la de Pinta v2** (un toque arma, el siguiente acerca 2×).
6. Racha, "ojo de águila", tiempo par, récord en `localStorage`, el sol de los tres perfiles (con el solcito
   que bosteza de Maxi) con la derrota-gag y el radar de Toby [HE-124].
7. Un registro de tiempos por objetivo (para calibrar `tiempo_par_s`) y un botón "ver zonas de toque".

## 14. Riesgos de usabilidad (para `experto-ux-parvulo`)

| # | Riesgo | Propuesta / qué mirar |
|---|---|---|
| R1 | **Toque y arrastre se confunden** (Nicole quiere tocar y mueve la escena, o al revés) | Umbral de 16 px y onda inmediata al presionar; medir en la tablet |
| R2 | **Escenas demasiado densas** que se vuelven ruido para Nicole | 40 % visible como mínimo y nada de camuflaje hasta Sofía; validar en captura |
| R3 | **Sofía toca a ráfagas** para encontrar al azar | No se castiga, pero no da "ojo de águila" y los señuelos cortan la racha; si igual pasa, bajar la zona de toque de los objetos interactivos |
| R4 | **La lupa** no se descubre o se queda puesta | Presentación de una vez; a 1× todo es legible |
| R5 | **Arte costoso** (HE-114) | Escenas compuestas con piezas (§11.3) |
| R6 | **Pistas ambiguas** ("el que tiene manchas": jirafa, vaca, dálmata…) | Validador §11.2 y revisión de `guionista` |
| R7 | **El mapita** a 200 × 60 px es chico para tocarlo | Zona de toque de 96 px de alto; si no se usa, se quita |
| R8 | **Mariposas** del ambiente HE-A7b en las escenas de Nicole y Sofía | Sacarlas (regla 8) |
| R9 | **Mareo** por inercia en tablet | Frenado corto (0,4 s) y la opción "menos movimiento" la apaga |
| R10 | **El sol convierte la exploración en apuro** y Nicole o Sofía empiezan a tocar a ráfagas [HE-124] | Tocar objetos sigue sin cortar nada y los señuelos solo cortan la racha; si el playtest muestra ráfagas, subir el factor (Nicole 2,5) antes que quitar el sol |

## 15. Qué debe probar el arnés (`herramientas/qa_test_buscar.gd`)

1. Sorteo de escondites con semilla: siempre uno de los declarados, dos objetivos nunca comparten escondite.
2. Toque frente a arrastre con el umbral; un toque sobre un objetivo superpuesto a un señuelo da el objetivo.
3. Encontrar, señuelo, objeto, escondite de 1 y 2 pasos con sus señales; "ya encontrado" en Brote.
4. Racha y puntaje según §9.1 (objetos no cortan; señuelos sí).
5. Semilla: sin lista, cualquier animal vale; ruido cada 5-8 s; ayudas a los 6 y 10 s; ayuda fuerte tras 3
   derrotas (todos asoman, sin sol, victoria asegurada) [HE-124].
6. Sol en los tres perfiles [HE-124]: derrota con su `factor_par`, encontrados intactos, escondites nuevos,
   tiempo proporcional con su mínimo, regalo tras 3 (Estrella) o 2 (Brote y Semilla), 0 destellos al perder.
7. Parcial: salir y volver retoma encontrados y escondites.
8. Equipo: tope por perfil, `segundos_por_turno` con cambio de escondite y `terminar_turno(true)`, jugada
   automática de Maxi.
9. Escena: zonas de toque mínimas por perfil medidas en pantalla; la lupa compartida funciona igual que en Pinta.

## 16. Decisiones (antes preguntas abiertas) [HE-124: el PO delegó, 05-Nov-2026]

1. **¿Nicole puede perder?** → **Sí, desde z1, con el sol de 2,2 × par** sobre la escena entera; Sofía 1,6 ×;
   Maxi 3 × (§8.1, §10). Política del PO: GDD §6 regla 11.
2. **Lupa compartida** → **sí**: `dev-godot` extrae la lupa de Pinta a `scripts/ui/lupa_zoom.gd` y la usan los
   dos motores (para los niños, Pinta no cambia).
3. **Arte** → **escenas compuestas con piezas SVG reutilizables** (§11.3): data-driven y alcanzable.
4. **Sonidos "hechos con la boca"** → **sí, los graban los niños** cuando el PO pueda organizar la sesión;
   mientras tanto, CC0. No bloquea la implementación.
5. **Foto de grupo** → **solo celebración**: el álbum queda reservado a las fotos reales de la familia.
