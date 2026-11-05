# Ficha — Batalla final de Animalia ("¡Las carrozas del desfile!") y ceremonia de partida

> **Tarjeta HE-115.** El PO delegó todas las decisiones de esta ficha (05-Nov-2026). Cada decisión propia
> va marcada **[Decisión del equipo 05-Nov]**; lo que se hereda de Arcoíris va con su fuente.
> No queda ninguna pregunta abierta: lo que falta son **números que fija el simulador** (§6) y la
> validación de UX y QA (§15 y §16).

- **Autor**: `disenador-mecanicas`, 05-Nov-2026. Coreografía de las tarjetas de cinemática: queda para
  `director-cinematicas` (§9 deja ids, contenido y duración).
- **Implementa**: HE-121 (batalla) y HE-122 (partida), que esperan HE-18. **Datos**:
  `datos/batallas/animalia_final.json` (ya escrito). Los 5 niveles de ronda en `datos/niveles/animalia/batalla/`
  los arma `disenador-niveles` con los bloques del §4.6 y del §5.10.
- **Fuentes**: GDD §1 (tono, derrota-gag), §5 (mecánicas probadas y reto real), §6 y §8;
  `planeta-animalia-zonas.md` (§2, §6.1, §9); `modo-equipo.md` §11 y §14 (batalla de Arcoíris, Torre
  §14.16); `motor-lanzar.md` §12, §13 y §25.18 (guardado entre etapas, momentos, partida);
  `motor-topos.md`, `motor-buscar.md`, `motor-caminos.md` y `motor-runner.md` (§12.2, modo equipo);
  `hangar-nave.md` §5.4; `scripts/base/gestor_turnos.gd`; `datos/batallas/arcoiris_final.json`.

---

## 0. Las decisiones de un vistazo

| # | Decisión [Decisión del equipo 05-Nov] | Por qué |
|---|---|---|
| D1 | El jefe usa la mecánica de **Fruit Ninja** (cortar con el trazo objetos que vuelan en arco). Motor nuevo **`cortar`**, usado **solo** en esta batalla | Es nueva en el proyecto, se juega solo con tocar y arrastrar, no necesita física y trae su propia escala de dificultad (§2) |
| D2 | El villano mete las **4 carrozas del Gran Desfile** en burbujas atadas a su mochila-torre. Cada ronda ganada revienta una burbuja y devuelve una carroza. En el jefe, sopla burbujas con **los animales del desfile**, y los hermanos las revientan para liberarlos | Usa el hilo del planeta (la siesta y el desfile) y repite el "es un rescate, no una pérdida" de Arcoíris |
| D3 | **4 rondas en equipo** (una por cada juego de Animalia, con la pista de galletas) + el jefe en **3 oleadas**. **Sin epílogo jugable** | Mismo esqueleto que Arcoíris. Animalia no tiene un juego "sin derrota" que haga de epílogo, y la batalla ya dura ~26 min |
| D4 | Orden: **¿Quién habla?** → **Escondite** → **Cada quien a su casa** → **Carrera de postas** → **La Gran Burbujeada** | Curva: lo conocido y rápido, después un respiro tranquilo, después el puzle cooperativo, después la ronda más física, y al final el jefe |
| D5 | El jefe usa el **modo sin pista** de `GestorTurnos` (el de la Torre). El reloj son los **frascos de jabón** del Coleccionauta: 9 por oleada (M5 N2 S2), y 13 desde la 1.ª derrota de esa oleada (M7 N3 S3). Cada intento empieza y termina con Maxi | Reparto probado en la Torre (UX HE-71 M4). `GestorTurnos` **no cambia** |
| D6 | **Política de derrota (PO 05-Nov)**: las rondas se ganan al 1.er intento un **80-90 %** de las veces; las oleadas del jefe van en escalera: **60-75 / 45-60 / 30-40 %**, y cada una se gana en ≤ 3 intentos con ≥ 95 %. Una batalla típica tiene 1 o 2 derrotas-gag | Perder tiene que pasar a veces, siempre con gag y reintento de un toque. El guardado evita repetir lo ganado |
| D7 | Guardado parcial **al cerrar cada turno, después de cada gag, al empezar cada oleada y en el cuadro en que se vacía cada piso**. Las rondas ganadas y las oleadas ganadas nunca se pierden | Patrón de la Torre (§14.16.1 de modo-equipo; §25.18 de motor-lanzar) |
| D8 | Al reintentar el jefe queda liberado el **30 %** de lo que se liberó en el intento perdido (redondeado hacia abajo). En las rondas se conserva **todo** | Igual que la Torre (conserva parte del daño) y que las rondas de Arcoíris (§14.5) |
| D9 | Premio: **100 destellos** por hermano (una vez), la **foto del desfile** en el rincón de regalos del hangar y la **revancha** del jefe. No hay foto nueva en el álbum familiar | El álbum familiar ya llegó a 10 fotos, el tope de su ficha |
| D10 | Ceremonia de partida: **los mismos 5 pasos que Arcoíris**, con contenido nuevo: el tanque con la **manguera de bombero** (Maxi), los **3 broches con cara de animal** del ala derecha (Nicole), la ruta **M-E-L-O-D-Í-A** con estrellas que suenan como notas (Sofía), la despedida con Toby y la video-llamada | Reutiliza HE-81 (estado familiar de la partida) y HE-82 (viaje por datos). El ala derecha es "la otra ala" |
| D11 | Cinemáticas: **ganchos saltables con tarjeta estática + voz** (el video queda postergado). Se saltan desde la 2.ª vez, por familia; `retomar_burbujeada` se salta desde la 1.ª vez | Decisión del PO 05-Nov sobre el video y política de momentos de motor-lanzar §25.18.6 |
| D12 | La batalla y la partida de Animalia **condicionan el viaje a Melodía** como estado familiar, con la llave de padres como respaldo y la regla de "dos hermanos con el retrato del tercero" | Regla del PO para Arcoíris (motor-lanzar §13.4), aplicada al planeta 2 |

---

## 1. La idea en una frase y la historia

**El Coleccionauta llega al Campamento justo cuando Toby tiene listo el Gran Desfile, mete las cuatro
carrozas en burbujas gigantes "para su colección" y, cuando los hermanos se las reventaron todas, intenta
llevarse a los animales mismos con su burbujeador: la Gran Burbujeada.**

- **Cuándo aparece**: como en Arcoíris, cuando **el primer hermano** completa su zona 3 (escena «La huellita
  de Toby» + ala derecha). La video-llamada de papá de esa escena termina con el teaser: se cuela el
  Coleccionauta («¿un desfile de animales? ¡Para mi colección!») y en el mapa aterriza su mochila-torre,
  con **4 burbujas atadas como globos**, junto a la nave estacionada al lado de la carpa de Toby.
- **El robo existe solo dentro de la batalla** (M3 de UX HE-66): el mapa de cada hermano no pierde nada y
  los animales del mapa siguen despiertos. Dentro de las burbujas, **las carrozas y los animales se ven
  contentos**: saludan, rebotan y hacen sus sonidos. Toby lo dice de entrada: «¡Están guardaditos ahí! ¡Los
  vamos a sacar juntos!».
- **Canon del Coleccionauta**: gafas-lupa y mochila-torre. Lo nuevo es una **varita de burbujas** que sale
  de la punta de la mochila con una manguera en espiral (el "burbujeador"). Sin redes, sin jaulas, sin
  nada con patas de bicho. Sus burbujas son tornasoladas y llevan un sellito con forma de lupa (es su
  "etiqueta de colección").
- **Qué aprende** (la semilla del final del juego, sin decirla): «¡un desfile no cabe en una mochila!». Al
  final, Toby lo invita a desfilar y él se pone al final de la fila. No se lleva nada.
- **Nunca menciona a papá** durante la batalla (regla del guion de Arcoíris). Papá aparece en la
  video-llamada de la partida.
- **Toby** es el anfitrión de los juegos (como Coco en Arcoíris) y **Cometa** sigue arriba a la izquierda:
  tocarlo repite la regla y de quién es el turno (GDD §6.2).

---

## 2. La mecánica del jefe: por qué Fruit Ninja

### 2.1 Qué se tomó de Fruit Ninja (Halfbrick, 2010)

| Fruit Ninja | Aquí (motor `cortar`) |
|---|---|
| Las frutas salen desde abajo en **arco** y vuelven a caer | Las **burbujas de colección** salen del pasto alto en arco, con un animal adentro |
| Se cortan con el **trazo del dedo**; un trazo puede cortar varias | Se revientan con el trazo (arrastrar) **o con un toque**; un trazo revienta todas las que cruza |
| **Combo**: 3 o más frutas en un solo trazo | **¡Combo!**: 3 o más burbujas en un trazo → Toby libera **un animal más** de la mochila |
| **Bomba**: si la cortas, pierdes (Classic) o pierdes tiempo (Arcade) | **El calcetín del Coleccionauta**: si lo revientas, las burbujas de ese soplido se escapan (Nicole) o se te acaba el turno (Sofía) |
| Fruta que se cae sin cortar = "miss" | Burbuja que vuelve al pasto = se escapa: la manguera la sorbe de vuelta a la mochila ("sluuurp") y **vuelve a salir más tarde** |
| Bananas del modo Arcade: **Freeze** (cámara lenta) y **Frenzy** (lluvia de frutas) | **Burbuja de la siesta** (todo va a la mitad de velocidad 4 s) y **burbuja trompeta** (4 burbujas extra desde los costados) |
| Modo **Zen**: sin bombas | Ruta **Semilla**: sin calcetín y sin escapes |

**Escala por edad sacada de Fruit Ninja** (regla de oro 3): con el puntaje, Fruit Ninja sube **cuántas
frutas por tanda**, **qué tan rápido caen** y **cuántas bombas** salen, y agrega los power-ups de Arcade.
Aquí esas mismas cuatro palancas son las que cambian por perfil y por oleada (§5.4). Zen da el modelo de
Maxi y Classic + Arcade dan el de Sofía.

### 2.2 Alternativas descartadas

| Referencia | Por qué no |
|---|---|
| **Simon** (secuencias de sonidos de animales) | Reservado: es la ruta Brote/Estrella de **La banda de Octavio** (GDD §4, Melodía). Además `topos` ya trabaja la escucha de sonidos de animales en Animalia (y `motor-topos.md` dice explícitamente "no es Simon") |
| **Breakout / Pong** | Mover la paleta para atajar una pelota es **precisión fina en tiempo real**, imposible a los 2 años; y el rebote en ángulo, aunque sea cinemático, se siente como física |
| **Memorice** | Ya es `emparejar` (Arcoíris) |
| **Bubble Shooter / Zuma / resortera** | Disparar con apuntado ya lo hacen el Río y la Torre (regla de una mecánica por lugar) |

### 2.3 Por qué encaja

- **Solo tocar y arrastrar** (GDD §6.4): un trazo es un arrastre libre, sin precisión, sin velocidad mínima
  y sin forma. Un toque directo también revienta. No hay doble toque ni gesto de mantener.
- **Sin física** (GDD §8): cada burbuja sigue una **parábola calculada** (posición = función del tiempo, con
  una semilla). No hay motor de física, colisiones entre burbujas ni rebotes. **No pide excepción al §8**,
  a diferencia de `lanzar`.
- **Se distingue de todo lo de Animalia**: en `topos` los animales asoman de hoyos fijos y se elige por
  sonido; en el `runner`, un toque es un salto con buen momento. Aquí los blancos **se mueven en arco**, un
  gesto revienta **varios** y lo que importa es **qué no tocar** (el calcetín). De las burbujas con letras de
  Letralandia (que se tocan una a una) lo separan el trazo, los arcos, el combo y el calcetín: la mecánica
  es otra.
- **El jugo de Fruit Ninja es el jugo que queremos**: cada trazo deja una estela, cada burbuja revienta con
  squash y cada animal salta libre con su sonido. Sirve para la celebración y también para la mecánica.

---

## 3. Estructura de la batalla

### 3.1 Flujo completo

```
Hito en el Campamento (mochila-torre con 4 burbujas)
  → Cometa: «¡Es el Coleccionauta! … necesitamos a los tres»
  → "¡todos a la nave!" (cada uno toca su retrato) → "¡Despegar!"
  → [entrada] (tarjeta + voz, ≤ 12 s)
  → Ronda 1 · ¿Quién habla? (arranca sola, pausa_antes_ronda_1: false)
  → [pop_corralito] → mapa de batalla, pausa con pregunta (pausa_01)
  → Ronda 2 · Escondite → [pop_laguna] → pausa (pausa_02)
  → Ronda 3 · Cada quien a su casa → [pop_pradera] → pausa (pausa_03)
  → Ronda 4 · Carrera de postas → [pop_toby] → pausa antes del jefe (pausa_antes_jefe)
  → toque al hito del jefe → [presenta_burbujeada] (≤ 12 s) → intro corta
  → Jefe · La Gran Burbujeada: oleada 1 → [fin_oleada] → oleada 2 → [fin_oleada] → oleada 3
  → [gran_estornudo] (≈ 12 s) → completado(0)
  → fiesta de equipo + 100 destellos + foto del desfile → [cierre_a] (≤ 20 s)
  → mapa del planeta: el hito pasa a "hito de partida"
```

### 3.2 El mapa de batalla (entre rondas)

- **5 hitos** sobre el sendero de huellitas: las 4 carrozas (íconos de los 4 juegos) y, al final, el más
  grande, la mochila-torre con la varita de burbujas (el jefe).
- Las rondas ganadas muestran su **carroza de vuelta**, con sus animales bailando. La siguiente brilla y
  Toby salta hacia ella. Todos los hitos responden al toque en < 100 ms (se menean y Toby nombra el
  juego), pero **solo el que brilla lleva a jugar** (m3 de UX HE-66).
- Sin "1/4" ni barras: el avance se ve en la espalda del Coleccionauta, que va perdiendo burbujas y queda
  cada vez más liviano (un saltito por ronda).

### 3.3 Indicadores (sin números)

| Dónde | Qué se ve |
|---|---|
| Toda la batalla | En la pista de galletas, **las burbujas que le quedan atadas** a la mochila del Coleccionauta (4 → 0) |
| Dentro de cada ronda | La cinta de la mesa del equipo (la del gestor) y la pista de galletas, como en Arcoíris |
| Jefe, toda la etapa | La mochila-torre con **3 pisos con ventanitas** llenas de animales que saludan. Cada oleada vacía un piso, que queda transparente |
| Jefe, dentro de la oleada | La ventanita del piso actual: cada animal liberado sale de ahí (se ve cómo baja el nivel). Los **frascos de jabón** en fila en su cinturón: cada tanda gasta uno, que se tira con un "¡plin!" |

### 3.4 Pausas y duración

- **Pausa con pregunta** en el mapa de batalla después de cada carroza y antes del jefe (4 en total, patrón
  M1.2). Nunca avanza sola y la casa está a la vista. **Entre oleadas no hay pregunta** (como entre etapas
  de la Torre): cada oleada es un buen lugar para cortar y el guardado lo respeta (§7).
- **Duración estimada**: ~26 min típica y ~34 min p80 con derrotas. Se juega en **2-3 sesiones**, que es
  el caso normal. Meta: **≤ 5 min por ronda** y **≤ 12 min el jefe**. Si el playtest muestra cansancio, la
  primera palanca es bajar 1 a los `pasos_rival` de Casas (la ronda más larga) y, después, los objetivos del
  Escondite de 10 a 9.

---

## 4. Las 4 rondas de carroza (motores existentes, en modo equipo)

### 4.1 Reglas comunes (heredadas de modo-equipo §14.3, sin cambios)

- Por turnos `maxi_intercalado` (M → N → M → S), con puerta de turno, pase y la pista de galletas del
  Coleccionauta (`rival: "coleccionauta"`). El rival avanza en el paso 2 del pase, nunca por el error de
  alguien con nombre (B3). **Maxi no lo mueve** (`maxi_mueve_rival: false`).
- **Tope de aciertos por turno** en todas las rondas (lo que fijan las fichas de motor). Con tope, llegar al
  tope sin que un fallo corte el turno es **turno perfecto**: el rival retrocede y en el pase se resbala.
  Eso ya lo hace el gestor solo.
- **El turno de Maxi nunca le exige más que su ruta Semilla** del mismo motor (B3.3). Con
  `semilla_auto_s: 20`, su turno se resuelve solo y Toby dice «¡Maxi nos dejó un regalito!».
- **Cada hermano juega al menos 2 turnos por ronda** (B2.3). Las cantidades del §4.2 están hechas con esa
  cuenta: los 7 primeros turnos (M N M S M N M) no alcanzan a terminar la ronda.
- **Sin puntaje, estrellitas ni récord individual** dentro de la batalla, y ningún texto con dígitos (M8.5).
- **Si pierden la ronda**: la derrota-gag de cada motor (su `gag_derrota_aspirar/devolver`, §12.2 de cada
  ficha) hacia la boca de la mochila-torre, «¡otra vez!» de 160 × 160 px desde el segundo 0, el logro común
  de Cometa y el reintento con **todo lo logrado conservado** y el rival en la galleta 0.

### 4.2 Tabla de rondas

| # | Ronda (motor) | Carroza que devuelve | Tamaño compartido | Tope por turno M / N / S | Qué corta el turno | `pasos_rival` |
|---|---|---|---|---|---|---|
| 1 | **¿Quién habla?** (`topos`) | Del corralito (naranja) | 1 claro de 6 madrigueras, **16 pedidos** | 1 / 3 / 4 | El **escape** del pedido (Nicole, Sofía). Tocar a otro = fallo suave | 4 |
| 2 | **Escondite animal** (`buscar`) | De la laguna (azul) | 1 escena de 2560 × 720, **10 animales** | 1 / 1 / 2 | `segundos_por_turno` (N 30, S 35) sin llegar al tope: el animal activo **se cambia de escondite** (gag). Señuelo = fallo suave | 3 |
| 3 | **Cada quien a su casa** (`caminos`) | De la pradera (amarillo) | **2 tableros de 6 × 6** (5 y 4 pares), sin llenado, caminos llegados fijos | 1 / 1 / 2 | `segundos_por_turno` (N 40, S 45) sin llegar al tope: el animal "se sienta a esperar". Casa ajena (S) = fallo suave | 3 |
| 4 | **Carrera de postas** (`runner`) | De Toby (verde) | 1 carrera con meta en **28 obstáculos limpios** | 2 / 5 / 8 | Choque sin burbuja (en equipo no hay burbuja) | 4 |

**Cuentas de B2.3** (los 7 primeros turnos no terminan la ronda):

- Topos: 1+3+1+4+1+3+1 = 14 < 16.
- Escondite y Casas: 1+1+1+2+1+1+1 = 8 < 10 y 8 < 9.
- Postas: 2+5+2+8+2+5+2 = 26 < 28.

**[Decisión del equipo 05-Nov] Cambios respecto del §12.2 de cada ficha de motor** (solo en la batalla):

- **Escondite**: 10 objetivos en vez de 6, por B2.3. `segundos_por_turno` baja a 30 y 35 y cuenta **el turno
  entero** desde `turno_iniciado` (no "por objetivo"), para que el turno de Sofía con tope 2 sea un reto de
  verdad.
- **Casas**: 2 tableros en vez de 1, por B2.3 (cuando se resuelve el 1.º, entra el 2.º con un "fiu"
  durante el pase). `segundos_por_turno` sube a 40 y 45, y también cuenta el turno entero.
- **Postas**: sin cambios.
- **¿Quién habla?**: sin cambios.

### 4.3 Qué es un acierto y cómo juega cada uno

| Ronda | Acierto | Maxi (Semilla) | Nicole (Brote) | Sofía (Estrella) |
|---|---|---|---|---|
| ¿Quién habla? | Tocar al animal que sonó | Solo asoman 2; el pedido no se esconde y sus ondas son completas. Todo lo que toca celebra, pero solo el pedido cuenta | `t_arriba_s` 2,4, 3 asomados, ondas completas, sonido una vez | Modo tandas, 4 asomados, `t_arriba_s` 1,4, ondas mínimas, pares parecidos (`p_similar` 0,2) |
| Escondite | Encontrar al animal activo | El activo **asoma y hace ruido** desde el inicio y la escena se desliza hasta él | Uno a la vez, con voz, silueta y palabra | Tarjeta con pista escrita (+ voz al tocar a Cometa) |
| Casas | Un animal llega a su casa | El motor elige **el par más corto**: el animal brilla y viaja bajo el dedo, con guía e imán | Casa de su color, sin guía, sin cortar caminos llegados | Casas de hábitat, sin guía; casa ajena = rechazo «¡aquí no vivo yo!» |
| Postas | Pasar limpio un obstáculo | Corre el T-rex: obstáculos blandos, salto imantado y 240 px/s | Corre el pony: 420 px/s, salto amable, sin aéreos | Corre Toby: 580 px/s, aéreos altos y bajos |

En la carrera, el corredor cambia en cada posta (el huesito dorado pasa al siguiente) y **el mundo se
congela durante el pase**.

### 4.4 Derrota de cada ronda (variante del gag y logro común)

| Ronda | Qué aspira el Coleccionauta y cómo vuelve | Logro común de Cometa |
|---|---|---|
| ¿Quién habla? | Los animales asomados vuelan en espiral a la boca de la mochila; los estornuda y caen en sus hoyos con un "¡plop!" | «¡Igual reconocimos a un montón de animales!» |
| Escondite | Los no encontrados suben desde sus escondites; los estornuda a **escondites nuevos** | «¡Los que encontramos se quedan encontrados!» |
| Casas | Las huellitas de los caminos **a medias** vuelan en fila a la mochila; los animales sin casa se sacuden y vuelven a su punto | «¡Los que llegaron a su casa ahí se quedan!» |
| Postas | Los obstáculos de la pantalla suben a la mochila y caen estornudados más adelante, con aire para arrancar | «¡Igual corrimos un montón de camino!» |

### 4.5 Contrato técnico de cada motor en la batalla

Todo esto **ya está descrito en el §12.2 de cada ficha de motor**; aquí se junta lo que la batalla necesita,
para que HE-116 a HE-119 lo dejen listo y HE-121 solo lo conecte.

| Método / señal | Lo usa | `topos` | `buscar` | `caminos` | `runner` |
|---|---|---|---|---|---|
| `aplicar_perfil_turno(perfil)` (al recibir `turno_iniciado`) | motor | `t_arriba_s`, asomados, ondas | zona de toque, ruido, pista escrita o voz | guía, imán, animal bajo el dedo, par elegido de Maxi | velocidad, salto, huecos, aéreos y **corredor** |
| `turnos.notificar_acierto()` | motor → gestor | pedido tocado | animal encontrado | animal en casa | obstáculo limpio |
| `tope_alcanzado` → `confirmar_turno_estable()` | gestor ↔ motor | cuando el animal termina su salto | cuando el animal llega a su tarjeta | cuando el animal entra a su casa | cuando el corredor queda quieto con la posta entregada |
| `turnos.terminar_turno(true)` | motor | escape del pedido (al terminar de bajar) | se acabó `segundos_por_turno` (tras el gag de cambio de escondite) | se acabó `segundos_por_turno` | choque (al quedar sentado) |
| `turnos.notificar_fallo_suave()` | motor | tocar a otro animal | tocar un señuelo | casa ajena (S) | — |
| `jugada_automatica_pedida` | gestor → motor | el pedido salta solo a la barra | el animal salta solo y cuenta | el animal camina solo a su casa | el dino salta solo el siguiente obstáculo |
| `ancla_meta_turno()` | gestor | x 290, centro de las madrigueras | borde izquierdo de la franja de la lista | borde izquierdo del tablero | (60, 470) |
| `gag_derrota_aspirar(destino)` / `gag_derrota_devolver(perfil)` / `gag_derrota_terminar_ya(perfil)` | base | §4.4 | §4.4 | §4.4 | §4.4 |
| `reintentar_equipo()` | base | nada | recalcula escondites de los pendientes | nada | nada |
| `contar_logro_equipo()` | base | aciertos de la ronda | encontrados | animales en casa | obstáculos limpios |
| `obtener_parcial_equipo()` / `restaurar_parcial_equipo(estado)` | base / `batalla.gd` | pedidos hechos y pool | encontrados + escondites actuales | caminos llegados (celdas), tablero actual | obstáculos superados + semilla del tramo siguiente |
| Entrada bloqueada (`entrada_bloqueada_cambio`) | gestor → motor | todos abajo, solo pulso | solo pulso; el arrastre de la escena sigue | solo pulso | mundo congelado |
| Sin dígitos en pantalla (M8.5) | motor | sin puntaje ni racha con número | sin tiempo par ni contador | sin trazos ni tiempo | sin distancia en números |

**[Decisión del equipo 05-Nov] Parcial de cada ronda** (qué devuelve `obtener_parcial_equipo()`; el núcleo
no lo interpreta):

```jsonc
// topos
{ "pedidos_hechos": 9, "pool_restante": ["vaca", "pato", "..."] }
// buscar
{ "encontrados": ["patito", "flamenco"], "escondites": { "cisne": "juncal_2", "hipopotamo": "bote" } }
// caminos
{ "tablero": 1, "llegados": { "pony": [[0,1],[0,2],[1,2]], "gatito": [[4,0],[4,1]] } }
// runner
{ "limpios": 17, "semilla_tramo": 88123 }
```

### 4.6 Bloques `equipo` de los niveles de ronda (para `disenador-niveles`)

Los 4 niveles llevan `"modo_juego": "equipo"`, `"zona": "batalla"` y este bloque (cambia solo lo marcado).
Las `lineas_voz` siguen el esquema de cada motor más las claves del gestor (`le_toca`, `porras_fin_maxi`,
`rival_*`, `turno_perfecto`, `derrota_gag_equipo`, `logro_comun`, `repetir_equipo_tope`), con las rutas
del §10.

```jsonc
"equipo": {
  "rival": "coleccionauta",
  "variante_rival": "burbujas",           // arte: la pista lleva la mochila con las burbujas atadas (§3.3)
  "orden": "maxi_intercalado",
  "puerta_tras_semilla": "arrastre",
  "bloqueo_tras_puerta_ms": 400,
  "maxi_mueve_rival": false,
  "semilla_auto_s": 20,
  "aciertos_max_turno": { "semilla": 1, "brote": 3, "estrella": 4 },   // topos
  //                     { "semilla": 1, "brote": 1, "estrella": 2 }   // buscar y caminos
  //                     { "semilla": 2, "brote": 5, "estrella": 8 }   // runner
  "segundos_por_turno": { "brote": 30, "estrella": 35 },               // buscar; caminos 40 / 45; topos y runner no lo usan
  "composiciones": {
    "maxi+nicole+sofia": { "pasos_rival": 4, "aciertos_totales": 16 }   // topos 4·16 · buscar 3·10 · caminos 3·9 · runner 4·28
  }
}
```

---

## 5. El jefe: «La Gran Burbujeada» (motor nuevo `cortar`)

### 5.1 La idea

El Coleccionauta, sin carrozas, se enoja (chistoso: patalea, se le chuecan las gafas-lupa) y **aspira a
todos los animales del desfile a su mochila-torre**, que queda con 3 pisos llenos de ventanitas. Después
saca la varita de burbujas: «¡La Gran Burbujeada! ¡Los voy a guardar en burbujas de colección!». Cada vez
que sopla, salen burbujas del pasto con un animal adentro. Si el equipo las revienta, el animal salta libre
con un paraguas de hoja y corre hacia el desfile. Si se le escapan, la manguera las sorbe de vuelta y
volverán a salir. **Una oleada se gana cuando se vacía el piso**; con los 3 pisos vacíos, el jefe está
ganado.

### 5.2 Escena y layout (1280 × 720)

| Elemento | Rect / posición | Tocable |
|---|---|---|
| Cometa (gestor) | `PistaRival.RECT_COMETA` (arriba a la izquierda, hasta x 118, y 100) | Sí: repite la regla y de quién es el turno |
| Casa | arriba a la derecha (desde x 1172) | Sí (≥ 96 px) |
| **Zona de juego** (donde vuelan las burbujas y donde cuentan los trazos) | `Rect2(140, 110, 1000, 490)` (y 110-600) | Sí |
| Pasto alto (de donde salen y adonde vuelven las burbujas) | franja y 590-640, x 140-1140 | No (decorado) |
| Coleccionauta + mochila-torre de 3 pisos + frascos | `Rect2(1150, 170, 130, 430)` | Sí: se ríe y saluda (< 100 ms), no revienta nada |
| Boca del burbujeador (`ancla_rival_motor()`) | (1160, 300) | — |
| Salida de los liberados | corren hacia (60, 560) y se suman a una mini fila de desfile que cruza por detrás del pasto | No |
| Barra del equipo (gestor) | abajo, y ≥ 610 | La del gestor |

- Hay ≥ 24 px entre la zona de juego y Cometa, la casa, el Coleccionauta y la barra.
- **Nada que se pueda reventar sale de la zona de juego**: las parábolas se calculan para que el ápice
  quede en y 190-330 y el ancho del arco no se salga de x 140-1140.

### 5.3 Interacciones y game feel

| Acción | Respuesta | Tiempo |
|---|---|---|
| **Presionar** en cualquier parte de la zona de juego | Onda del color del hermano (`GestorTurnos.COLORES`) bajo el dedo y un "tik" suave | ≤ 1 cuadro (16 ms) |
| Presionar **sobre una burbuja** (hitbox) | Revienta: squash (escala 1,15 → 0 en 0,12 s), "¡pop!", gotitas tornasol, el animal salta con su sonido, se abre un paraguas de hoja y corre a la salida | Inicio ≤ 50 ms; animación 0,6 s |
| **Arrastrar** | Estela de estrellitas del color del hermano (vida 150 ms, se apaga con fundido). Cada par de muestras de entrada forma un segmento: **revienta toda burbuja cuyo círculo de hitbox cruce el segmento** (así un trazo rápido no "salta" burbujas) | La estela sigue al dedo sin retraso |
| Varias burbujas en un mismo trazo | Cada pop sube **un semitono** respecto del anterior (escalera alegre). Con 3 o más: «¡combo!» (destello dorado en la estela + campanita) y **Toby saca un animal más** por la ventanita del piso | El combo se decide al soltar o con la 3.ª burbuja, lo que llegue primero |
| Burbuja que vuelve al pasto | La manguera hace "sluuurp" (≤ 1,2 s, sonido de sorbete, nunca de aspiradora) y el animal saluda contento desde la ventanita | — |
| Reventar el **calcetín** | "¡fffff!" con nube de pelusa; el calcetín a rayas sale volando y **cae sobre el casco de Toby** como sombrero (guiño a la Torre); Toby estornuda. Efecto según perfil (§5.4) | ≤ 50 ms |
| Tocar al Coleccionauta, los frascos o el pasto | Reaccionan (risita, "plin", el pasto se mece). Nunca cuenta nada | < 100 ms |
| Tocar durante el pase o la puerta | Solo el pulso; la entrada está bloqueada (el gestor) | < 100 ms |

- **Hitboxes** (más grandes que el dibujo): Brote = radio visual + 15 px, Estrella = radio visual + 10 px.
  **El calcetín** tiene hitbox **más chica** que su dibujo (radio − 8 px), para que rozarlo sin querer no
  cuente.
- **Sin velocidad mínima de trazo** y sin forma: cualquier arrastre vale. **No hay doble toque** ni
  "mantener".
- **Entrada unificada**: solo eventos táctiles (el proyecto emula el toque con el mouse). Se sigue **un
  dedo** (el primero que presiona); un segundo dedo apoyado se ignora.
- **Anticipación del soplido**: antes de cada soplido, el Coleccionauta infla los cachetes 0,6 s (se
  lee "ahí vienen") y la varita tiembla.
- **Burbujas**: se bambolean ±6 px en x mientras vuelan (sinusoide, 2 Hz). Adentro se ve el animal entero
  y sonriente. En Semilla la burbuja es más grande y el animal, más grande todavía.
- **"Menos movimiento"** (zona de padres): sin gotitas y sin bamboleo; la estela pasa a una línea simple.

### 5.4 El turno, el reloj y las reglas por perfil y por oleada

**Turno = una tanda**: el Coleccionauta destapa **un frasco de jabón** ("¡plip!") y sopla. Una tanda tiene
uno o dos **soplidos** según el perfil. **La tanda termina cuando todas sus burbujas se resolvieron**
(reventadas o sorbidas): ahí el motor llama `terminar_turno(false)` (o `terminar_turno(true)` si el
calcetín cortó el turno de Sofía). Durante el pase no vuela nada.

**El reloj de la oleada son los frascos** (modo sin pista, D5):

- Intento 1 de cada oleada: **9 frascos** = M5 N2 S2 (M N M S M N M S M).
- Desde la 1.ª derrota **de esa oleada**: **13** = M7 N3 S3. Toby: «¡Le pasé más jabón! ¡Así sopla más y
  los liberamos a todos!». Es chistoso y se entiende: más burbujas, más chances.
- **Cada intento y cada oleada empiezan con Maxi** (`turnos.reiniciar_rival("maxi")`), y la última tanda
  es siempre la suya, que es segura.
- Si el piso se vacía, se gana la oleada en el acto, aunque queden frascos. Si se gastó el último frasco y
  quedan animales: `turnos.terminar_turno_sin_recursos("maxi")` → derrota-gag (§5.5).

**El pool**: cada piso tiene `meta` animales. Las burbujas salen del pool; un escape devuelve al animal al
pool. Se gana la oleada al liberar a todos.

| Parámetro | Maxi · Semilla (O1 · O2 · O3) | Nicole · Brote (O1 · O2 · O3) | Sofía · Estrella (O1 · O2 · O3) |
|---|---|---|---|
| Soplidos por tanda × burbujas | 1 × 1 | 2 × 3 · 2 × 3 · 2 × 4 | 2 × 5 · 2 × 6 · 2 × 7 |
| Intervalo entre burbujas de un soplido | — | 0,6 · 0,55 · 0,5 s | 0,35 · 0,3 · 0,25 s |
| Pausa entre soplidos | — | 0,8 s | 0,6 s |
| `vuelo_s` (salida → vuelta al pasto) | sube en 1,2 s y **se queda flotando** en el ápice hasta que la revienten | 2,6 · 2,4 · 2,2 s | 1,9 · 1,7 · 1,5 s |
| Diámetro de la burbuja | 200 px | 140 · 136 · 130 px | 110 · 104 · 96 px |
| Hitbox | **toda la zona de juego** | radio + 15 px | radio + 10 px |
| Calcetín (probabilidad por soplido; máx.) | **nunca** | 0 · 0,25 · 0,35 (máx. 1 por tanda) | 0,35 · 0,5 · 0,6 (máx. 1 · 1 · 2 por tanda) |
| Efecto del calcetín | — | Las burbujas **de ese soplido** que siguen en el aire se escapan; el 2.º soplido sale igual | Las de ese soplido se escapan y **el turno termina** (`terminar_turno(true)`) |
| Burbuja de la siesta (Freeze) | — | — | — · 1 por intento · 1 por intento: todo va a la mitad de velocidad 4 s, los animales bostezan "zzz" |
| Burbuja trompeta (Frenzy) | — | — | — · — · 1 por intento: entran 4 burbujas extra desde los costados en 3 s |
| Combo (≥ 3 en un trazo) | — (una sola burbuja) | vale (raro) | vale: +1 liberado |
| Animal preferido | dinos (triceratops, braquiosaurio) y el perrito bombero, si quedan en el pool | pony, gatito, jirafa si quedan | perrito, cachorros si quedan |

**El turno de Maxi (Semilla, nunca falla)**:

- Su burbuja sube despacio y **se queda flotando** en el centro (x 400-880, y 300-380), bamboleándose. No
  se escapa nunca.
- **Cualquier toque o trazo en cualquier parte de la zona de juego la revienta**: de su dedo sale un
  chorrito de estrellas que vuela hasta la burbuja en 0,15 s. Si tocó a menos de 150 px: «¡justo ahí!».
- Un toque **antes** de que la burbuja llegue al ápice no se pierde: la burbuja "acelera" hacia su dedo
  («¡ya voy!») y revienta al llegar.
- Con `semilla_auto_s: 20` sin tocar, Toby salta y la revienta: «¡Maxi nos dejó un regalito!».
- Nunca ve el calcetín ni los power-ups.

**El calcetín** (la bomba de Fruit Ninja): burbuja **gris con rayas** y un calcetín adentro. Se bambolea
distinto (más lento, como si pesara) y hace un "fff" bajito al salir. Si no lo tocan, cae al pasto y **no
pasa nada**. La 1.ª vez por familia, en un turno de Sofía, sale **solo y despacio** con
`presenta_calcetin` («¡Ojo! Esa burbuja tiene el calcetín del Coleccionauta. ¡Esa no se toca!»).

### 5.5 Fallo, derrota-gag y reintento

**Lo "incorrecto" dentro de un turno** (nunca hay sonido de error):

- Burbuja que se escapa: el sorbete y el saludo desde la ventanita. El Coleccionauta comenta como mucho 1
  de cada 3 escapes («¡Sluuurp! ¡Para mi colección!»), sin pisar otra voz.
- Calcetín: el gag del sombrero de Toby (§5.3), con el efecto del §5.4. En Nicole y Sofía es
  `notificar_fallo_suave()` (los hermanos que miran animan, B2), salvo el corte de turno de Sofía, que es
  `terminar_turno(true)`.

**La derrota de la oleada**: se gastó el último frasco (la tanda de Maxi) y quedan animales.
`terminar_turno_sin_recursos("maxi")` deja a Maxi al centro y `minijuego_base` orquesta el gag con
`variante_derrota()`. **3 gags que rotan** (1.ª, 2.ª y 3.ª derrota de la batalla; desde la 4.ª, rotan sin
repetir el anterior):

1. **"¡Burbuja-gorro!"**: sopla tan fuerte que una burbuja gigante lo envuelve a él; flota, choca con su
   propia mochila, revienta y cae sentado. «¡Ups! ¡Me burbujeé yo solito!».
2. **"Estornudo de jabón"**: le entra espuma a la nariz, estornuda una nube de burbujitas y se le empañan
   las gafas-lupa; camina a tientas y abraza su mochila creyendo que es Toby.
3. **"El calcetín volador"**: el calcetín le cae en la cara, baila a ciegas, se lo saca y lo huele: «¡Ah,
   era mi calcetín favorito!».

Secuencia (la de modo-equipo §11.4 en modo sin pista, como la Torre): «¡otra vez!» de ≥ 160 × 160 px **desde
el segundo 0** → `gag_derrota_aspirar(ancla_rival_motor())` (las burbujas que queden en el aire vuelan a la
varita) → `gag_derrota_devolver(perfil)` (la mochila estornuda una lluvia de burbujas que **revientan solas
en confeti**: los animales vuelven a asomar contentos por las ventanitas) → voz del gag → logro común de
Cometa («¡Igual liberamos a un montón!», o con 0: «¡Esta vez se nos escaparon, pero ya sabemos cómo!»).

**Al tocar «¡otra vez!»** (`reintentar_equipo()`):

- Queda liberado el **30 %** de lo liberado en el intento perdido, redondeado hacia abajo (D8). Los demás
  vuelven al piso.
- **Ayudas escalonadas** (cuentan derrotas **de la oleada**):
  - 1.ª derrota: **13 frascos** desde el intento 2 («¡Le pasé más jabón!»).
  - 2.ª derrota: además, **Toby ayuda**: al empezar el intento 3 salta y revienta 3 burbujas él solo
    («¡Yo también ayudo! ¡Pop, pop, pop!»).
  - Desde la 3.ª derrota: Cometa ofrece descansar («¿Descansamos un ratito y volvemos? Lo que liberamos
    queda guardado.»). La casa se agranda un 10 % y respira; seguir es tocar «¡otra vez!».
- `turnos.reiniciar_rival("maxi")`: el intento nuevo abre la puerta de Maxi.
- Las **oleadas ganadas nunca se pierden**.

### 5.6 Celebración: fin de oleada y victoria

**Fin de las oleadas 1 y 2** (`fin_oleada`, ≈ 5 s, se salta desde la 2.ª vez):

1. En el cuadro en que sale el último animal del piso: congelado, destello y **guardado** (§7).
2. El Coleccionauta sacude la varita: sale una sola burbujita "blup" que revienta en su nariz. Se sienta.
3. El piso vacío queda transparente con un "¡pop!" grave; la mochila baja un escalón y él da un saltito
   («¡uy, mi mochila está más livianita!»).
4. Los animales de esa oleada pasan por delante en mini desfile, saludando. Los tres retratos de la barra
   aplauden.
5. Se levanta: «¡Pero tengo más!» (abre el piso siguiente) → la oleada siguiente empieza con la puerta de
   Maxi. **Sin intro corta** (la reemplaza este momento; patrón de la Torre §14.16.1, punto 7).

**Victoria (fin de la oleada 3)** (`gran_estornudo`, ≈ 12 s, se salta desde la 2.ª vez):

1. Cuadro del último animal: congelado y destello.
2. La mochila vacía tiembla, se infla y estornuda la varita, que sopla **una burbuja gigante alrededor del
   Coleccionauta**. Él flota, se ríe y se le empañan las gafas.
3. La burbuja revienta suavecito ("plof") y él cae sentado en el pasto, rodeado por **todo el desfile**,
   que baila a su alrededor con los sonidos en escalera afinada (el coro de `motor-topos.md` §7.5).
4. Toby le ofrece la patita y él se pone **al final de la fila del desfile**.
5. Cometa: «¡Lo lograron! ¡Todos los animales están libres!» → `completado(0)` → la fiesta de equipo de
   `batalla.gd` (gestos por turno, choque de manos, "+100" bajo cada premiado, confeti) → `cierre_a`.

Esta escena **no** es el Gran Desfile del planeta (§6.1 de la ficha de zonas, al completar la zona 5): aquí
desfilan solo los animales de la batalla, en la escena de la batalla, y en el mapa no cambia nada.

### 5.7 Guardado parcial del jefe

- **Cuándo**: en `turno_cerrado` (todo resuelto), al terminar cada gag, al empezar cada oleada y **en el
  cuadro en que se vacía el piso** de O1 y O2, con la oleada siguiente ya anotada. Mismo camino de siempre:
  `parcial_equipo_listo` → `Progreso.guardar_parcial_batalla(id_batalla, "burbujeada", estado)`.
- **Qué entrega el motor**:

  ```jsonc
  {
    "oleada": 2,                          // la que se juega (o la siguiente, si se guardó al vaciar un piso)
    "oleadas_ganadas": ["o1"],
    "oleada_iniciada": true,              // false hasta el primer soplido de la oleada → re-entrada caso A/B
    "intento": 2,                         // de la oleada en curso
    "derrotas_oleada": 1,                 // fija las ayudas
    "derrotas": 1,                        // conteo de gags de la batalla (rotación)
    "ultimo_gag": "burbuja_gorro",
    "frascos_restantes": 7,
    "liberados": ["pato", "pato", "vaca", "flamenco"],   // de la oleada en curso
    "toby_ayudo": false,                  // en este intento
    "siesta_usada": false, "trompeta_usada": false,       // en este intento
    "calcetin_presentado": true
  }
  ```

- **Al retomar**: "¡todos a la nave!" corto → momento `retomar_burbujeada` (≈ 5 s; **se salta desde la 1.ª
  vez**: un toque deja todo listo) → `turnos.empezar_retomando()`: **empieza Maxi**.
  - Caso A (`oleada_iniciada: true`): la oleada tal cual, con su piso y sus liberados.
  - Caso B (`false`): la oleada se presenta otra vez («¡Pero tengo más!»).
  - **Frascos al retomar**: los `frascos_restantes`, con un mínimo de 5, redondeados **hacia arriba** a 5, 9
    o 13 (≡ 1 mód 4, así el retomado también termina con Maxi), sin pasar la canasta llena del intento.
    Si se agregó alguno, Toby: «¡Encontré unos frascos más!».
- **Al ganar el jefe**: `batalla.gd` registra la ronda `burbujeada` y borra el parcial.

### 5.8 Revancha: «La Burbujeada otra vez»

- Con la partida hecha, el hito del Campamento pasa a "la Burbujeada otra vez" (§8.6). Se juegan **solo
  las 3 oleadas del jefe**, nunca la batalla entera, sin destellos y sin cinemáticas de cierre.
- **Estrellitas de equipo**: ★ ganar · ★★ sin perder ninguna oleada · ★★★ además, ≥ 2 frascos sobrantes
  en cada oleada. **Récord familiar** = frascos usados en total (−1 si hubo ayudas). Nunca hay comparación
  entre hermanos.
- **Con dos hermanos** (dos retratos): se puede jugar, sin estrellitas ni récord (motor-lanzar §11.1).
  Frascos: 9 / 13 con Maxi (M5 X4 / M7 X6) y 8 / 12 para `nicole+sofia` (N4 S4 / N6 S6).
- **Guarda solo entre oleadas** (en el hueco `"burbujeada_revancha"`), con los acumulados de estrellitas y
  récord, igual que motor-lanzar §25.18.7. Salir a mitad de una oleada la reinicia entera.

### 5.9 Contrato técnico del motor `cortar`

| Pieza | Ruta | Sabe de… | No sabe de… |
|---|---|---|---|
| Motor | `scripts/motores/cortar/motor_cortar.gd` + `escenas/minijuegos/cortar/motor_cortar.tscn` | Burbujas, trazo, soplidos, frascos, pool, perfiles, gags, momentos | Batalla, guardado, navegación |
| Lógica pura | `scripts/motores/cortar/logica_cortar.gd` (sin nodos) | Parábolas, intersección segmento-círculo, sorteo con semilla, pool, frascos, conservación del 30 %, ayudas, rotación de gags, estrellitas de revancha | Pantalla |
| Rival compartido | `coleccionauta.tscn` (el de la Torre) + accesorio "varita de burbujas" y mochila de 3 pisos | Poses | Reglas |
| `GestorTurnos` | **sin cambios** | Modo sin pista | Burbujas |

- `MotorCortar extends MinijuegoBase`. Emite `completado(0)` en la batalla. En solitario funciona (para el
  arnés), pero **ninguna estación lo usa**: es la única aparición de la mecánica (regla de oro 3).
- **Trayectoria** (determinista, sin física): para una burbuja que sale en `(x0, y_pasto)` con ápice
  `(xa, ya)` y vuelo total `T`: `x(t) = x0 + (xa − x0)·(2t/T)`, `y(t) = y_pasto − 4·(y_pasto − ya)·(t/T)·(1 − t/T)`,
  más el bamboleo. Las semillas salen del nivel (`semilla`) + `intento` + `oleada`, así el arnés puede
  reproducir cualquier tanda.
- **Configuración del gestor**: `rival: null`, `confirmar_turno: true`, **sin** `aciertos_max_turno` (el
  turno lo corta el motor al resolverse la tanda).
- **Llamadas al gestor**:
  - `notificar_acierto()` por cada animal liberado (la barra aplaude);
  - `notificar_fallo_suave()` con el calcetín de Nicole y de Sofía;
  - `terminar_turno(false)` al resolverse la tanda; `terminar_turno(true)` cuando el calcetín corta el turno
    de Sofía;
  - `terminar_turno_sin_recursos("maxi")` sin frascos y con animales;
  - `reiniciar_rival("maxi")` al empezar cada intento y cada oleada;
  - `empezar_retomando()` tras `restaurar_parcial_equipo`;
  - escucha `jugada_automatica_pedida` (Toby revienta la burbuja de Maxi) y `turno_iniciado` (aplica el
    perfil).
- **Virtuales de la base que implementa**: `aplicar_perfil_turno(perfil)`, `ancla_rival_motor()` (1160,
  300), `variante_derrota()` (`"burbuja_gorro"`, `"estornudo_jabon"` o `"calcetin_volador"`),
  `gag_derrota_aspirar`, `gag_derrota_devolver`, `gag_derrota_terminar_ya`, `reintentar_equipo()`,
  `contar_logro_equipo()` (liberados de la oleada en curso), `obtener_parcial_equipo()`,
  `restaurar_parcial_equipo(estado)`, `saltar_momento(id)`, `var revancha` y
  `signal resultado_revancha(estrellitas, record)`.
- **Momentos** (`momento_saltable_iniciado/terminado`): `fin_oleada`, `gran_estornudo`,
  `retomar_burbujeada`, `presenta_calcetin`, `presenta_siesta`, `presenta_trompeta`, `presenta_combo`. La
  política de cada uno está en `animalia_final.json` → `rondas[burbujeada].momentos`. La presentación del
  jefe es `rondas[].presentacion` = `presenta_burbujeada`.
- **Señales propias** (para el arnés y quien quiera escucharlas): `liberado(id_animal, indice_en_trazo)`,
  `escapo(id_animal)`, `calcetin_reventado(perfil)`, `combo(n)`, `piso_vaciado(oleada)`.

### 5.10 Nivel del jefe: `datos/niveles/animalia/batalla/burbujeada_equipo.json` (contrato; los valores finales los fija el simulador)

```jsonc
{
  "id_nivel": "animalia_batalla_burbujeada_equipo",
  "motor": "cortar",
  "modo_juego": "equipo",
  "planeta": "animalia",
  "zona": "batalla",
  "semilla": 2511,
  "zona_juego": [140, 110, 1000, 490],
  "pasto_y": 610,
  "apice_y": [190, 330],
  "salida_x": [220, 1060],
  "deriva_x_px": [-200, 200],
  "bamboleo": { "px": 6, "hz": 2.0 },
  "boca_rival": [1160, 300],
  "salida_liberados": [60, 560],
  "trazo": { "estela_ms": 150, "un_solo_dedo": true },
  "combo": { "min_trazo": 3, "libera_extra": 1 },
  "frascos": { "intento_1": 9, "desde_derrota_1": 13, "retomar_valores": [5, 9, 13] },
  "conservar_al_reintentar": 0.3,
  "toby_ayuda": { "desde_derrota": 2, "revienta": 3 },
  "ofrecer_descanso_desde_derrota": 3,
  "gags": ["burbuja_gorro", "estornudo_jabon", "calcetin_volador"],
  "oleadas": [
    { "id": "o1", "meta": 31,
      "pool": { "vaca": 3, "perro": 3, "gato": 3, "pato": 4, "caballo": 3, "pony": 3, "gallina": 3, "flamenco": 3, "pinguino": 3, "perrito_bombero": 3 } },
    { "id": "o2", "meta": 33,
      "pool": { "jirafa": 4, "jirafita": 3, "cebra": 4, "elefante": 4, "alpaca": 3, "huemul": 3, "triceratops": 4, "hipopotamo": 3, "lobo_marino": 3, "gatito": 2 } },
    { "id": "o3", "meta": 38,
      "pool": { "mono": 4, "tucan": 4, "loro": 4, "buho": 3, "perezoso": 3, "braquiosaurio": 4, "pony": 4, "perrito": 4, "triceratops": 4, "jirafa": 4 } }
  ],
  "perfiles": {
    "semilla":  { "soplidos": 1, "burbujas": 1, "diametro": 200, "sube_s": 1.2, "flota": true, "hitbox": "zona", "justo_ahi_px": 150,
                  "preferidos": ["triceratops", "braquiosaurio", "perrito_bombero"] },
    "brote":    { "soplidos": 2, "burbujas": [3, 3, 4], "intervalo_s": [0.6, 0.55, 0.5], "pausa_soplidos_s": 0.8,
                  "vuelo_s": [2.6, 2.4, 2.2], "diametro": [140, 136, 130], "hitbox_extra_px": 15,
                  "calcetin": { "p": [0, 0.25, 0.35], "max_tanda": [0, 1, 1], "efecto": "escapa_soplido" },
                  "preferidos": ["pony", "gatito", "jirafa"] },
    "estrella": { "soplidos": 2, "burbujas": [5, 6, 7], "intervalo_s": [0.35, 0.3, 0.25], "pausa_soplidos_s": 0.6,
                  "vuelo_s": [1.9, 1.7, 1.5], "diametro": [110, 104, 96], "hitbox_extra_px": 10,
                  "calcetin": { "p": [0.35, 0.5, 0.6], "max_tanda": [1, 1, 2], "efecto": "corta_turno", "hitbox_menos_px": 8 },
                  "siesta": { "por_intento": [0, 1, 1], "factor": 0.5, "dura_s": 4 },
                  "trompeta": { "por_intento": [0, 0, 1], "extra": 4, "dura_s": 3 },
                  "preferidos": ["perrito", "gatito", "pony"] }
  },
  "equipo": {
    "rival": null,
    "confirmar_turno": true,
    "orden": "maxi_intercalado",
    "puerta_tras_semilla": "arrastre",
    "bloqueo_tras_puerta_ms": 400,
    "ms_volteo_equipo": 1200,
    "semilla_auto_s": 20,
    "composiciones": {
      "maxi+nicole+sofia": { "frascos": [9, 13] },
      "maxi+nicole":       { "frascos": [9, 13] },
      "maxi+sofia":        { "frascos": [9, 13] },
      "nicole+sofia":      { "frascos": [8, 12] }
    }
  },
  "lineas_voz": { "…": "claves y rutas del §10.3" }
}
```

---

## 6. Política de derrota y calibración

### 6.1 Metas [PO 05-Nov: "perder es posible y debe pasar a veces"; números: Decisión del equipo 05-Nov]

| Etapa | Gana al 1.er intento | En ≤ 3 intentos |
|---|---|---|
| Cada ronda de carroza | **80-90 %** | ≥ 99 % |
| Oleada 1 | **60-75 %** | ≥ 95 % |
| Oleada 2 | **45-60 %** | ≥ 95 % |
| Oleada 3 | **30-40 %** | ≥ 95 % |

Con esas metas, una batalla típica trae **1 o 2 derrotas-gag** (casi siempre en el jefe), y la
probabilidad de jugarla entera sin perder nunca queda bajo el 10 %. Así perder "pasa a veces", pero nunca
traba: el guardado y las ayudas cierran cada etapa.

### 6.2 Cómo se fija (lo corre `disenador-niveles` antes de HE-121)

- **Rondas**: `herramientas/simular_equipo.py` con los modelos de jugador de las maquetas HE-110 (topos,
  buscar, caminos y runner en equipo). Palanca única: `pasos_rival` (±1). Si con `pasos_rival` 3 una ronda
  queda sobre el 90 %, se baja `segundos_por_turno` en 5 s (buscar, caminos) o se sube 1 obstáculo o pedido.
- **Jefe**: extensión `--cortar` del simulador. Jugador por perfil = probabilidad de reventar cada burbuja
  según su diámetro y su `vuelo_s` (sale de una maqueta `docs/maquetas/cortar-v1.html` con registro de
  aciertos y jugadores simulados, como en HE-110), probabilidad de tocar el calcetín y de hacer combo.
  Palanca principal: `meta` de cada oleada. Secundarias, en este orden: burbujas por soplido y `vuelo_s`.
- **Reglas de decisión** (fijadas antes de correr): si una oleada se va de su rango, se mueve `meta` de a 1;
  si con la ayuda de 13 frascos el intento 2 sale bajo el 85 %, se baja la `meta` de esa oleada en vez de
  agregar más ayudas. Los valores de esta ficha (31 / 33 / 38) son la estimación a mano de partida:
  E[liberados] ≈ 32 / 34 / 37 con Nicole acertando 85 / 80 / 72 % y Sofía 80 / 75 / 68 %.
- **Playtest**: medir cuántas derrotas hubo, si alguien se frustró después de la 2.ª derrota de una oleada
  y si Sofía siente que el calcetín es "injusto". Si en el playtest perder pasa en las rondas más de 1 vez
  por batalla, sube 1 el `pasos_rival` de la ronda donde se perdió.

---

## 7. Guardado y estado (`Progreso`, sin subir versión)

Todo vive dentro de `equipo.batallas.animalia_batalla_final` con la API que ya existe (modo-equipo §14.9 y
motor-lanzar §13.3): `registrar_ronda_batalla`, `obtener_rondas_batalla`, `registrar_batalla_ganada`,
`batalla_ganada`, `guardar_parcial_batalla`, `obtener_parcial_batalla`, `borrar_parcial_batalla`,
`registrar_revancha_batalla`, `obtener_revancha_batalla`, y en `equipo.cinematicas_vistas` los ids
`animalia_batalla_final:<momento>`.

```jsonc
"animalia_batalla_final": {
  "rondas_ganadas": ["coro", "escondite"],   // nunca se borran
  "epilogo": true,                           // [Decisión del equipo 05-Nov] con "epilogo": null se marca true al ganar el jefe
  "ganada": false,
  "premiados": [],
  "parcial": { "ronda": "casas", "estado": { } },
  "revanchas": { "burbujeada": { "estrellitas": 0, "record": -1 } }
}
```

- **Rondas**: parcial al cerrar cada turno (lo de siempre). **Jefe**: §5.7.
- **Salir nunca cuesta nada**: no se pide confirmación (GDD §6.4). Al volver, empieza Maxi.
- **Si un hermano se tiene que ir**: las rondas ganadas quedan y la batalla sigue otro día. Mientras tanto,
  cada uno juega su ruta normal.

---

## 8. Ceremonia de partida de Animalia

### 8.1 Cuándo y qué

- **Requisito** (estado familiar, motor-lanzar §13.4): **un** hermano con el ala derecha (su zona 3) **y**
  la batalla ganada. La ceremonia asegura el ala y la nave queda lista **para todos**: cualquier hermano
  puede viajar a Melodía aunque todavía no tenga su ala derecha, y completar Animalia después.
- **La pieza**: el **ala derecha** (pieza 2 de HE-A6: panel curvo verde selva con una huellita pintada), "la
  otra ala". Se gana en la zona 3, llega al hangar **floja** (6° y se mece, opción A de `hangar-nave.md`
  §5.4) y en la partida se asegura. **Nadie instala lo que ganó otro**: Toby tira de la punta para mostrar
  que está floja y Nicole cierra los broches.
- **Escena**: `escenas/planetas/animalia/partida_animalia.tscn`. **[Decisión del equipo 05-Nov]**: HE-122
  reutiliza los componentes de la partida de Arcoíris (HE-84) y lee los textos, la ruta y los broches de un
  bloque de datos (§8.4). Si HE-84 dejó la partida atada a Arcoíris, HE-122 la extrae a
  `scripts/nucleo/partida.gd` + `datos/partidas/<planeta>.json` y Arcoíris pasa a usar el mismo camino. El
  núcleo no conoce planetas concretos (regla de oro 4).
- **Pasos** (mismos ids que Arcoíris, para `Progreso.marcar_paso_partida`): `tanque`, `ala`, `ruta`,
  `despedida`, `llamada`. Se guarda al terminar cada paso; al volver, se retoma en el primero que falte.

### 8.2 Los pasos (reglas de interacción de motor-lanzar §13.5, con contenido nuevo)

| Paso | Quién | Qué hace | Reglas |
|---|---|---|---|
| `tanque` | **Maxi** | **La manguera de bombero**: Toby desenrolla una manguera roja (el sueño de bombero de Maxi). Cada toque en la boquilla (≥ 200 px) suelta un chorro arcoíris al tanque, con "¡uiu!"; 6 chorros lo llenan | Cualquier toque en la boquilla suma un chorro. A los 24 s sin toques: «¡Te ayudo con la patita!» y la patita de Toby toca la boquilla, un chorro cada 4 s (máx. 6, ≤ 24 s). Cualquier toque suma otro sin cortar el ritmo de Toby |
| `ala` | **Nicole** | El ala derecha floja tiene **3 broches con cara de animal**: pony, gatito y jirafa (sus favoritos). Toby nombra uno y suena su sonido («¡El broche del pony!» + relincho); el nombrado respira. Al tocarlo gira con "clic" y el animalito guiña | Un objetivo a la vez. Broches de ⌀ 110 px con ≥ 30 px entre ellos. Tocar otro broche: se menea y hace su sonido, sin voz y sin fallo. Recordatorios a los 8, 16 y 24 s; a los 32 s la patita de Toby lo gira sola (como si lo hubiera girado ella); si ya pasó una vez, el siguiente se gira solo a los 12 s con un recordatorio a los 6 s |
| `ruta` | **Sofía** | **M-E-L-O-D-Í-A** con estrellas: cada estrella correcta, al encenderse, **toca una nota** (do, re, mi, fa, sol, la, si) y al completar la ruta suena la escala entera: un adelanto del planeta de la música. Señuelos: N, F, B y Q (parecidas a M, E, D y O) | Campo `Rect2(150, 128, 980, 440)`; estrellas ⌀ 96 px con ≥ 24 px borde a borde; mapa de referencia en `Rect2(540, 8, 200, 80)`. Toque directo: la correcta se enciende y el señuelo hace "bup" amable y se menea. En arrastre, **solo cuenta la siguiente correcta** (las demás brillan apenas, sin "bup"). La pista («Busca la… ¡M!») suena siempre junto con el latido de la correcta |
| `despedida` | Los tres | Toby le da a cada uno una **calcomanía para la nave** (Maxi: huellita de dino; Nicole: pony; Sofía: Toby) y choca la patita con cada uno | La patita se activa **cuando termina la voz del regalo** de ese hermano; un toque antes solo la hace menear |
| `llamada` | — | Video-llamada de papá (tarjeta estática + voz): vio el desfile, y el Coleccionauta pasó por la colección **tarareando**: «¡creo que va a un planeta de música!» (gancho a Melodía) | Saltable desde la 2.ª vez por familia |

**Cuenta regresiva y despegue**: Sofía («¡Tres!») → Nicole («¡Dos!») → Maxi («¡Uno!» y despegue), un
retrato a la vez, con los rects de motor-lanzar §13.5 (Sofía `Rect2(40,130,160,160)`, Nicole
`Rect2(40,314,160,160)`, Maxi `Rect2(230,400,200,200)`). Tocar uno que no brilla: salta y se ríe, sin "bup".
Recordatorio a los 8 s; salta solo a los 20 s (Sofía, Nicole) y a los 15 s (Maxi). El desfile entero saluda
desde abajo mientras la nave sube. Después: Mapa Estelar con «¡rumbo nuevo!» y se enciende el camino
`animalia>melodia`.

### 8.3 Estado familiar, llave y viaje (HE-81 y HE-82, sin código nuevo de núcleo)

- `Progreso.completar_partida("animalia", "animalia>melodia")` al terminar la ceremonia;
  `forzar_partida("animalia", "animalia>melodia")` desde la llave de la zona de padres, **"Instalar el ala
  derecha sin la batalla"**, detrás del candado adulto. Con la línea de estado al lado: «Animalia: la nave
  espera la batalla de los tres (o de dos, con un hermano jugando el turno del que falta). ¿Nunca coinciden?
  → "Instalar el ala derecha sin la batalla"».
- **Ceremonia después de la llave** (`forzada: true`, `ceremonia: false`): se juega una vez si después ganan
  la batalla. El paso `ala` se da por hecho (el ala ya se ve puesta) y la tarea de Nicole son los broches. El
  despegue cierra con `animalia_despegue_vuelo_de_vuelta` y vuelve al Mapa sin «¡rumbo nuevo!».
- **Melodía antes de la partida** (M9): lejana y desenfocada, **sin candado** ni gris; al tocarla late una
  vez (escala 1,08, 0,25 s) con un "tilín", suena `animalia_despegue_mapa_melodia_antes_01` o `_02` (se
  alternan, máximo una por visita) y una flechita de luz va de Melodía a Animalia.
- **La red que no necesita al papá**: la batalla y la partida se juegan también con dos hermanos presentes y
  el retrato del tercero (un hermano juega con el perfil del ausente; si falta Maxi, su tanda de burbuja
  flotante siempre revienta).
- **La nave con las dos alas** se dibuja si `partida_hecha("animalia")`.

### 8.4 Bloques de datos

**`datos/planetas/animalia/mapa.json`** (reemplaza el bloque `batalla` del borrador del §9 de la ficha de
zonas y agrega 2 campos de primer nivel):

```jsonc
"viaje_siguiente_requiere": { "partida": "animalia" },
"voz_destino_espera": ["voces/animalia/despegue/mapa_melodia_antes_01.wav", "voces/animalia/despegue/mapa_melodia_antes_02.wav"],
"batalla": {
  "id": "animalia_batalla_final",
  "datos": "res://datos/batallas/animalia_final.json",
  "escena": "res://escenas/nucleo/batalla.tscn",
  "aparece_tras_zona": 3,
  "condicion": "primer_hermano",
  "posicion": [450, 630],                // junto a la nave estacionada al lado de la carpa; ≥ 24 px del hito de la zona 1 (lo ajusta la maqueta HE-110)
  "voz_hito": ["voces/animalia/batalla/hito_01.wav", "voces/animalia/batalla/hito_02.wav"],
  "tras_ganar": {
    "partida": { "escena": "res://escenas/planetas/animalia/partida_animalia.tscn", "rumbo": "animalia>melodia" },
    "revancha": true
  }
}
```

**Hito del Campamento (3 estados, mismo mecanismo que el Claro de Arcoíris)**:

| Estado | Hito |
|---|---|
| Batalla no ganada | La mochila-torre con las **4 burbujas** atadas (las carrozas adentro saludan) |
| Ganada y `partida_hecha` en `false` | **Hito de partida**: la nave estacionada brillando, con la manguera enrollada al lado |
| `partida_hecha` en `true` | El Coleccionauta soplando burbujas de colores **para los animales**, que juegan con ellas: **"la Burbujeada otra vez"** (revancha) |

Tono M7.3 en los tres: sin alertas ni parpadeo, con voz como máximo una vez por visita.

**`datos/partidas/animalia.json`** (para `partida.gd`, §8.1):

```jsonc
{
  "planeta_id": "animalia",
  "rumbo": "animalia>melodia",
  "pieza": "ala_derecha",
  "anfitrion": "toby",
  "pasos": ["tanque", "ala", "ruta", "despedida", "llamada"],
  "tanque": { "variante": "manguera_bombero", "chorros": 6, "ayuda_s": 24, "ayuda_cada_s": 4 },
  "broches": [
    { "id": "pony",    "voz": "voces/animalia/despegue/broche_pide_pony.wav",    "sonido": "voces/animalia/nombres/pony.wav" },
    { "id": "gatito",  "voz": "voces/animalia/despegue/broche_pide_gatito.wav",  "sonido": "voces/animalia/nombres/gatito.wav" },
    { "id": "jirafa",  "voz": "voces/animalia/despegue/broche_pide_jirafa.wav",  "sonido": "voces/animalia/nombres/jirafa.wav" }
  ],
  "ruta": { "palabra": ["M", "E", "L", "O", "D", "I", "A"], "acento_visual": { "I": "Í" },
            "senuelos": ["N", "F", "B", "Q"], "notas": ["do", "re", "mi", "fa", "sol", "la", "si"] },
  "regalos": { "maxi": "calcomania_huellita_dino", "nicole": "calcomania_pony", "sofia": "calcomania_toby" },
  "lineas_voz": { "…": "claves del §10.4" }
}
```

---

## 9. Cinemáticas: ganchos con tarjeta estática + voz

Mientras el video esté postergado (PO 05-Nov), cada cinemática es **una tarjeta ilustrada fija** (SVG,
1280 × 720) con 1-2 animaciones de tween baratas (rebote, temblor, fundido) y su voz. Se marcan vistas al
terminar (`<id_batalla>:<id>`, por familia). La coreografía fina es de `director-cinematicas`.

| Id | Cuándo | Tarjeta | Voces (§10) | Dura | Salto |
|---|---|---|---|---|---|
| `entrada` | Tras "¡Despegar!" | El Campamento con el desfile listo; el Coleccionauta en el aire con las 4 carrozas en burbujas atadas a su mochila | `entrada_01-03` | ≤ 12 s | desde la 2.ª |
| `pop_corralito`, `pop_laguna`, `pop_pradera`, `pop_toby` | Al ganar cada ronda | La burbuja de esa carroza tiembla, se infla y revienta; la carroza cae rebotando con sus animales | `pop_<carroza>` | ≤ 4 s | desde la 2.ª |
| `presenta_burbujeada` | Tras el toque al hito del jefe | El Coleccionauta enojado-chistoso con la varita de burbujas; la mochila de 3 pisos llena de animales en las ventanitas | `presenta_01-02` | ≤ 12 s | desde la 2.ª |
| `fin_oleada` | Al vaciar el piso de O1 y O2 | La anima el motor (§5.6) | `fin_oleada_1/2` | ≈ 5 s | desde la 2.ª |
| `gran_estornudo` | Al vaciar el piso de O3 | La anima el motor (§5.6) | `gran_estornudo_01-02` | ≈ 12 s | desde la 2.ª |
| `retomar_burbujeada` | Al retomar el jefe | La anima el motor (piso actual a la vista) | `retomar` | ≈ 5 s | desde la 1.ª |
| `cierre_a` | Tras la fiesta | El Coleccionauta al final de la fila del desfile, con una burbuja en la nariz | `cierre_01-04` | ≤ 20 s | desde la 2.ª |
| Partida: `llamada` | Paso 5 | Papá en la pantalla de la nave, con el Coleccionauta tarareando de fondo | `llamada_papa_01-02` | ≤ 12 s | desde la 2.ª |

---

## 10. Voces (encargo para `guionista`, HE-112)

Prefijos: `animalia_batalla_` (carpeta `voces/animalia/batalla/`) y `animalia_despegue_` (carpeta
`voces/animalia/despegue/`). Las voces del turno (`le_toca`, `porras_fin_maxi`, `te_toca_recordatorio`,
`sube_ventanita`, `turno_perfecto`, `rival_avanza/retrocede/resbala/vuelve`, `animo_hermanos`) **se
reutilizan** de `voces/nucleo/equipo/`. La cuenta regresiva reutiliza la de Arcoíris. Ninguna voz habla de
apuro ni de tiempo («¡último frasco!» está prohibido: GDD §1, sin presión de tiempo narrativa).

### 10.1 Mapa, entrada, rondas y pausas

| Id | Personaje | Texto breve |
|---|---|---|
| `hito_01` | Cometa | «¡Es el Coleccionauta! ¡Metió las carrozas del desfile en burbujas! Para ganarle necesitamos a los tres.» |
| `hito_02` | Cometa | «Las carrozas siguen en las burbujas… ¿vamos los tres?» |
| `entrada_01` | Coleccionauta | «¡Un desfile de animales! ¡Para mi colección!» |
| `entrada_02` | Toby | «¡Guau! ¡Se llevó las carrozas!» |
| `entrada_03` | Toby | «¡Están guardaditas ahí! ¡Las vamos a sacar juntos!» |
| `intro_coro` | Toby | «¡La carroza del corralito está cantando! ¡Toquen al que habla!» |
| `intro_escondite` | Toby | «¡Los de la laguna se escondieron! ¡Uno por turno, a buscarlos!» |
| `intro_casas` | Toby | «¡Cada animal a su casa! Lo que traza uno le sirve al otro.» |
| `intro_postas` | Toby | «¡Carrera de postas! Cada uno corre un tramo y le pasa el huesito al siguiente.» |
| `pop_corralito` | Coleccionauta | «¡Uy! ¡Se me reventó una burbuja!» |
| `pop_laguna` | Coleccionauta | «¡Mi burbuja de la laguna! Qué livianita quedó mi mochila…» |
| `pop_pradera` | Coleccionauta | «¿Otra más? ¿Cómo lo hacen?» |
| `pop_toby` | Coleccionauta | «¡Nooo, mi carroza favorita!» |
| `pausa_01` | Cometa | «¡Volvió la carroza del corralito! ¿Vamos por la de la laguna, o descansamos y volvemos después?» |
| `pausa_02` | Cometa | «¡Volvió la de la laguna! ¿Vamos por la de la pradera, o descansamos?» |
| `pausa_03` | Cometa | «¡Ya van tres! ¿Vamos por la carroza de Toby, o descansamos?» |
| `pausa_antes_jefe` | Cometa | «¡Volvieron las cuatro carrozas! Pero el Coleccionauta está tramando algo… ¿vamos ahora, o descansamos y volvemos después?» |
| `logro_coro` | Cometa | «¡Igual reconocimos a un montón de animales!» |
| `logro_escondite` | Cometa | «¡Los que encontramos se quedan encontrados!» |
| `logro_casas` | Cometa | «¡Los que llegaron a su casa ahí se quedan!» |
| `logro_postas` | Cometa | «¡Igual corrimos un montón de camino!» |
| `regalito_maxi` | Toby | «¡Maxi nos dejó un regalito!» |
| `repetir_ronda_<id>` (×4) | Cometa | La regla de la ronda en una frase + «le toca a…» (lo arma el gestor) |

### 10.2 Jefe: presentación, instrucciones y juego

| Id | Personaje | Texto breve |
|---|---|---|
| `presenta_01` | Coleccionauta | «¿Me sacaron las carrozas? ¡Entonces me llevo a los animales! ¡La Gran Burbujeada!» |
| `presenta_02` | Cometa | «¡Revienten las burbujas para liberarlos! Toquen o pasen el dedo.» |
| `instruccion_semilla` | Toby | «¡Maxi, toca donde quieras y la burbuja hace pop!» |
| `instruccion_brote` | Toby | «¡Nicole, pasa el dedo por las burbujas antes de que caigan!» |
| `instruccion_estrella` | Toby | «¡Sofía, revienta varias de una pasada! Pero el calcetín no.» |
| `presenta_calcetin` | Toby | «¡Ojo! Esa burbuja tiene el calcetín del Coleccionauta. ¡Esa no se toca!» |
| `presenta_combo` | Toby | «¡Combo! ¡Tres de una pasada! ¡Saqué uno más!» |
| `presenta_siesta` | Toby | «¡La burbuja de la siesta! Todo va despacito… ¡aprovecha!» |
| `presenta_trompeta` | Toby | «¡La burbuja trompeta! ¡Vienen muchas de una vez!» |
| `calcetin_toby_01` / `_02` | Toby | «¡Puaj! ¡Huele a queso!» / «¡Tengo un calcetín de sombrero!» |
| `calcetin_rival` | Coleccionauta | «¡Mi calcetín favorito! ¡Gracias!» |
| `escapo_01` / `_02` | Coleccionauta | «¡Sluuurp! ¡Para mi colección!» / «Este se queda conmigo… ¡por ahora!» |
| `fin_oleada_1` | Coleccionauta | «¡Se me vació un piso! … ¡Pero tengo más!» |
| `fin_oleada_2` | Coleccionauta | «¡Otro piso vacío! Me queda el de más arriba…» |
| `gran_estornudo_01` | Coleccionauta | «¡Aaa… aaa… ACHÚ!» |
| `gran_estornudo_02` | Cometa | «¡Lo lograron! ¡Todos los animales están libres!» |

### 10.3 Jefe: derrota, ayudas y retomar

| Id | Personaje | Texto breve |
|---|---|---|
| `derrota_burbuja_gorro` | Coleccionauta | «¡Ups! ¡Me burbujeé yo solito!» |
| `derrota_estornudo_jabon` | Coleccionauta | «¡Achú! ¡Se me empañaron las gafas! ¿Toby, eres tú?» |
| `derrota_calcetin_volador` | Coleccionauta | «¿Quién apagó la luz? … ¡Ah, era mi calcetín favorito!» |
| `derrota_cierre` | Cometa | «¡Casi! ¡Otra vez, todos juntos!» |
| `logro_burbujeada` | Cometa | «¡Igual liberamos a un montón!» |
| `logro_burbujeada_0` | Cometa | «Esta vez se nos escaparon, ¡pero ya sabemos cómo!» |
| `ayuda_jabon` | Toby | «¡Le pasé más jabón! Así sopla más burbujas y los liberamos a todos.» |
| `ayuda_toby` | Toby | «¡Yo también ayudo! ¡Pop, pop, pop!» |
| `ofrece_descanso` | Cometa | «¿Descansamos un ratito y volvemos? Lo que liberamos queda guardado.» |
| `retomar` | Cometa | «¡Seguimos donde quedamos! Todavía quedan animales en la mochila.» |
| `encontre_frascos` | Toby | «¡Encontré unos frascos más!» |
| `revancha_intro` | Cometa | «¡La Burbujeada otra vez! ¿Los liberamos a todos de nuevo?» |

### 10.4 Cierre y partida

| Id | Personaje | Texto breve |
|---|---|---|
| `cierre_01` | Coleccionauta | «¡Un desfile no cabe en una mochila!» |
| `cierre_02` | Toby | «¿Quieres desfilar con nosotros?» |
| `cierre_03` | Coleccionauta | «¿Yo? ¡Sí! … Y la próxima vez traigo una mochila con música. ¡Tirirí!» |
| `cierre_04` | Cometa | «¡Ganamos juntos! Ahora sí podemos preparar la nave.» |
| `despegue_hito` | Cometa | «¡La nave está lista para prepararse! ¿Vamos los tres?» |
| `despegue_tanque_pide` | Toby | «¡Maxi, bombero! ¡Llena el tanque con la manguera!» |
| `despegue_tanque_ayuda` | Toby | «¡Te ayudo con la patita!» |
| `despegue_tanque_lleno` | Toby | «¡Tanque lleno! ¡Gracias, bombero Maxi!» |
| `despegue_ala_floja` | Toby | «¡Miren, el ala se mueve! Hay que cerrar los broches.» |
| `despegue_broche_pide_pony` / `_gatito` / `_jirafa` | Toby | «¡El broche del pony!» (y así con cada uno) |
| `despegue_broche_recordatorio` | Toby | «¡Es el que está brillando!» |
| `despegue_ala_lista` | Toby | «¡Ala firme! ¡Ahora sí vuela!» |
| `despegue_ruta_pide` | Cometa | «Sofía, ¿adónde vamos? ¡Escribe la ruta con las estrellas: Melodía!» |
| `despegue_ruta_pista_<letra>` (×7) | Cometa | «Busca la… ¡M!» (M, E, L, O, D, I, A) |
| `despegue_ruta_lista` | Cometa | «¡Rumbo a Melodía! ¿Escucharon? ¡Las estrellas cantan!» |
| `despegue_regalo_maxi` | Toby | «¡Maxi, una huellita de dino para tu nave!» |
| `despegue_regalo_nicole` | Toby | «¡Nicole, un pony para tu nave!» |
| `despegue_regalo_sofia` | Toby | «¡Sofía, un Toby para que no me extrañes!» |
| `despegue_patita` | Toby | «¡Choca la patita!» |
| `despegue_llamada_papa_01` | Papá | «¡Vi el desfile desde aquí! El Coleccionauta pasó tarareando una canción… ¡creo que va a un planeta de música!» |
| `despegue_llamada_papa_02` | Papá | «¡Los quiero mucho! ¡Nos vemos pronto!» |
| `despegue_vuelo_rumbo_melodia` | Cometa | «¡Rumbo nuevo! ¡A Melodía!» |
| `despegue_vuelo_de_vuelta` | Cometa | «¡Nave lista y con las dos alas! ¡De vuelta a Melodía!» |
| `despegue_mapa_melodia_antes_01` | Cometa | «Melodía está lejos todavía… primero preparemos la nave en Animalia.» |
| `despegue_mapa_melodia_antes_02` | Cometa | «¡Se oye musiquita allá! Pero antes, los tres tenemos que ayudar en Animalia.» |

Total aproximado: **~95 líneas** (más las reutilizadas). El audio se genera con TTS local gratuito; la voz
de papá la decide y graba el PO (fuera del repo).

---

## 11. Arte (encargo para `disenador-personajes`, HE-114)

- **Coleccionauta**: accesorio **varita de burbujas** con manguera en espiral; **mochila-torre de 3 pisos con
  ventanitas** (y su versión con 4 burbujas atadas para las rondas y el hito); poses: inflar cachetes,
  soplar, sentarse, saltito "livianito", los 3 gags y flotar dentro de una burbuja. Siempre redondo, torpe
  y sonriente.
- **Burbujas**: tornasol con sellito de lupa (3 tamaños), la del calcetín (gris a rayas), la de la siesta
  (con almohadita) y la trompeta. Paraguas de hoja para los animales liberados.
- **Escena del jefe**: el Campamento con el pasto alto adelante (reutiliza el fondo de la zona 1).
- **4 carrozas del desfile** (corralito, laguna, pradera y Toby) y el mapa de batalla de 5 hitos.
- **Tarjetas de cinemática** (§9): 6 de la batalla + la video-llamada de la partida.
- **Partida**: manguera roja con boquilla grande, ala derecha con 3 broches de cara de animal, campo de
  estrellas con letras, y 3 calcomanías nuevas para el hangar (huellita de dino, pony y Toby).
- **Foto del desfile** (regalo del hangar): los tres hermanos con Toby, el desfile y el Coleccionauta al
  final de la fila.
- Los animales salen del catálogo compartido de Animalia (no se dibuja ninguno nuevo).

---

## 12. Datos: `datos/batallas/animalia_final.json`

Ya está en disco, con el mismo esquema que `arcoiris_final.json`. Resumen de lo que trae: 5 rondas (`coro`,
`escondite`, `casas`, `postas` y `burbujeada` con `jefe: true`, `revancha: true`, `presentacion` y
`momentos`), `epilogo: null`, `cinematica_antes_epilogo: null`, `recuerdo_momento: null`,
`regalo_hangar: "foto_desfile"`, `interludio` por ronda, y los informativos `resumen`, `duracion` y
`premio`. Rutas de los niveles: `res://datos/niveles/animalia/batalla/{topos,buscar,caminos,runner,burbujeada}_equipo.json`.

---

## 13. Cambios de contrato en el núcleo (para HE-121 y HE-122; todos genéricos)

| Pieza | Cambio | Por qué |
|---|---|---|
| `batalla.gd` | Acepta `"epilogo": null`: tras ganar la ronda `jefe`, va directo a la fiesta y a `cinematica_cierre`, y marca `epilogo: true` en `Progreso` | Animalia no tiene epílogo jugable (D3) |
| `batalla.gd` | Acepta `"cinematica_antes_epilogo": null` (no reproduce nada) | Ídem |
| `batalla.gd` | Acepta `"recuerdo_momento": null` (no llama a `Recuerdos.desbloquear`) y lee `"regalo_hangar"` (si existe, lo entrega al rincón de regalos del hangar por el mismo camino que los recuerdos de zona) | D9 |
| `batalla.gd` | `rondas[].interludio` (opcional): id del momento que se reproduce al ganar esa ronda. Sin el campo, lo de hoy (Arcoíris) | El interludio deja de depender de un "color" |
| `batalla.gd` | `rondas[].voz_pausa` = la voz de la pausa **antes** de esa ronda (como en la Torre), ahora en todas las rondas salvo la 1.ª (`null`, arranca sola) | 4 pausas (§3.4) |
| `GestorTurnos` | **Ninguno** | El jefe usa el modo sin pista tal cual |
| `minijuego_base.gd` | **Ninguno** (las virtuales de la Torre alcanzan) | — |
| `Progreso` | **Ninguno** (API de batallas, revanchas y partidas existente) | — |
| Partida | `partida.gd` + `datos/partidas/<planeta>.json` si HE-84 quedó atado a Arcoíris (§8.1) | Regla de oro 4 |
| `pista_rival.gd` | Variante de arte `"variante_rival": "burbujas"` (la mochila con las burbujas atadas que van desapareciendo con `rondas_ganadas`) | §3.3; solo dibujo |

---

## 14. Criterios de aceptación

**Ficha (HE-115)**

1. Esta ficha y `datos/batallas/animalia_final.json` en disco, sin preguntas abiertas.
2. UX (`experto-ux-parvulo`) sin bloqueantes sobre §3-§5 y §8.
3. Maqueta `docs/maquetas/cortar-v1.html` solo si el PO la pide; la calibración del §6.2 la necesita igual,
   así que se recomienda hacerla junto con HE-110.

**Batalla (HE-121)**

1. Los 3 hermanos (o 2 con el retrato del tercero) juegan las 4 rondas y el jefe por turnos con
   `GestorTurnos`; cada intento y cada oleada del jefe empiezan con Maxi y la última tanda es suya.
2. En cada ronda, cada hermano juega ≥ 2 turnos en una partida típica (cuentas del §4.2) y no se dibuja
   ningún dígito.
3. El turno de Maxi nunca falla: en el jefe, cualquier toque o trazo en la zona revienta su burbuja, y a
   los 20 s sin tocar la revienta Toby.
4. Todo lo tocable del motor `cortar` responde en < 100 ms (onda bajo el dedo ≤ 16 ms; pop ≤ 50 ms). Un
   trazo rápido que cruza 3 burbujas las revienta a las 3 (intersección por segmentos).
5. El calcetín: nunca en el turno de Maxi; en el de Nicole solo desde O2 y sin cortar el turno; en el de
   Sofía corta el turno. Su hitbox es menor que su dibujo.
6. Se puede perder: las rondas al ~80-90 % y las oleadas según el §6.1, verificado con el simulador antes de
   cerrar los datos. Cada derrota tiene su gag, «¡otra vez!» ≥ 160 × 160 px desde el segundo 0, y el
   reintento de un toque.
7. Las ayudas (13 frascos, Toby que ayuda, oferta de descanso) aparecen con las derrotas de la oleada, y al
   reintentar queda el 30 % de lo liberado.
8. Guardado: salir en cualquier momento y volver retoma la ronda u oleada guardada (nunca una ganada), con
   Maxi primero; salir en el `fin_oleada` vuelve a la oleada siguiente. Los frascos al retomar son 5, 9 o
   13.
9. Al ganar: 100 destellos una sola vez por hermano, la foto del desfile en el hangar, la revancha
   disponible, y el hito pasa a "hito de partida".
10. Cinemáticas como tarjetas con voz, saltables según su política, marcadas vistas por familia al terminar.
11. DoD 1-4 y arnés con guardado aislado (§16).

**Partida (HE-122)**

1. Con un hermano con el ala derecha y la batalla ganada, la ceremonia asegura el ala y `partida_hecha`
   queda en `true` para todos; cualquier hermano viaja a Melodía.
2. Los 5 pasos con sus reglas del §8.2 (ayudas automáticas incluidas); retomar en el primer paso que falte.
3. La llave de padres "Instalar el ala derecha sin la batalla" funciona sin consumir la ceremonia.
4. Melodía antes de la partida: lejana, sin candado, latido y voz alterna una vez por visita.
5. DoD 1-4.

---

## 15. Riesgos de usabilidad (para `experto-ux-parvulo`)

| # | Riesgo | Propuesta / qué mirar |
|---|---|---|
| R1 | **Nicole no se anima a "pasar el dedo"** y solo toca | Tocar también revienta: nunca queda trabada. Mirar si descubre el trazo sola; si no, `instruccion_brote` + una mano fantasma que traza en su 1.er turno |
| R2 | **El calcetín se toca sin querer** en un trazo largo de Sofía y lo siente injusto | Hitbox −8 px, presentación solo y despacio, nunca más de 1 por tanda en O1-O2. Medir en el playtest; si pasa más de 1 de cada 3 veces, el calcetín de Sofía pasa a "escapa el soplido" como el de Nicole |
| R3 | **Maxi toca a ráfagas o arrastra todo el rato** | Todo vale: el primer contacto revienta su burbuja y el resto solo hace ondas. Nunca hay error |
| R4 | **Dos dedos** (un hermano que "ayuda" tocando a la vez) | Se sigue solo el primer dedo; mirar si las peleas por la tablet suben en esta etapa |
| R5 | **Mucha cosa en movimiento** para Nicole (7-8 burbujas en O3) | Ella nunca tiene más de 4 en el aire por soplido; "menos movimiento" quita gotitas y bamboleo |
| R6 | **Perder 2 o 3 veces la oleada 3** cansa | Escalera con ayudas, oferta de descanso desde la 3.ª, y el guardado en cada piso. Medir frustración tras la 2.ª derrota |
| R7 | **"¡Se llevó a los animales!"** asusta o da pena | Siempre contentos en las ventanitas, voz de Toby de entrada («están guardaditos»), sorbete en vez de aspiradora y nunca "lloran". Respaldo: los animales de la batalla son "los del desfile de juguete" |
| R8 | **Duración de 26-34 min** | Pausas con pregunta tras cada carroza, guardado al vaciar cada piso; jugarla en 2-3 sesiones es lo normal |
| R9 | **El turno de 6 s de Sofía frente a un pase de 10 s** | Cada tanda tiene 2 soplidos; si el playtest muestra aburrimiento en el pase, la palanca es subir a 3 soplidos en Estrella (y recalibrar `meta`) |
| R10 | **Celos en la partida** (Nicole cierra los broches del ala que ganó otro) | Mismo patrón aprobado en Arcoíris: Toby encaja, Nicole asegura; cada hermano tiene su tarea y su calcomanía |

---

## 16. Para `tester-qa` (`qa_test_cortar.gd` y `qa_test_batalla_animalia.gd`, con guardado aislado)

- **Lógica pura** (`LogicaCortar`, con semilla fija): parábolas dentro de la zona; intersección
  segmento-círculo (un trazo de 2 muestras que cruza 3 burbujas las revienta a las 3; un trazo que pasa a
  9 px del borde dibujado del calcetín de Sofía no lo revienta); el pool devuelve los escapados; combo de
  ≥ 3 libera 1 extra; conservación del 30 % (redondeo abajo); rotación de gags sin repetir el anterior.
- **Reparto**: 9 frascos = M5 N2 S2 y 13 = M7 N3 S3; la última tanda siempre es de Maxi; cada intento y cada
  oleada empiezan con Maxi (`reiniciar_rival("maxi")`).
- **Maxi**: su burbuja no se escapa nunca; un toque en una esquina de la zona la revienta; a los 20 s la
  revienta Toby; nunca ve el calcetín ni power-ups.
- **Calcetín**: nunca en Semilla; en Brote, no antes de O2, y el turno sigue; en Estrella, corta el turno.
- **Derrota y ayudas**: sin frascos y con animales → `rival_llego` con Maxi al centro; 13 frascos tras la
  1.ª derrota de la oleada; Toby revienta 3 desde la 2.ª; oferta de descanso desde la 3.ª.
- **Guardado**: parcial en `turno_cerrado`, tras el gag, al empezar la oleada y al vaciar el piso; salir en
  `fin_oleada` vuelve a la oleada siguiente con caso B; frascos al retomar ∈ {5, 9, 13}; `oleada_iniciada`
  decide caso A/B.
- **Rondas**: ≥ 2 turnos por hermano en partidas típicas; tope por perfil; reintento que conserva lo logrado;
  `segundos_por_turno` cuenta el turno entero en Escondite y Casas; ningún dígito en pantalla.
- **Batalla**: aparece tras la zona 3 del primer hermano; rondas ganadas que no se pierden; destellos una
  sola vez; `epilogo: null` lleva a la fiesta y al cierre; foto del desfile en el hangar; revancha
  disponible solo con la partida hecha; revancha con dos sin estrellitas ni récord.
- **Partida y viaje**: sin la partida no se viaja a Melodía; con la partida viaja cualquier hermano (también
  sin ala derecha); llave de padres; los 3 estados del hito; Melodía lejana con voz alterna.

---

## 17. Hallazgos para otros roles (no bloquean)

1. **`disenador-niveles`**: armar los 5 niveles de `datos/niveles/animalia/batalla/` con los bloques del
   §4.6 y del §5.10, y la extensión `--cortar` del simulador (§6.2). El segundo tablero de Casas y los 10
   objetivos del Escondite son nuevos respecto del §12.2 de sus fichas de motor.
2. **`disenador-niveles` / ficha de zonas**: el §8 de `planeta-animalia-zonas.md` decía que las estaciones de
   equipo de casa, escondite y carrera "se suman con la batalla". Con esta ficha, los 4 motores quedan con el
   modo equipo hecho, así que esas estaciones (`nivel_equipo` en las zonas) se pueden agregar cuando
   implementen HE-116 a HE-119. **No se condicionan a ganar la batalla**: no hay candados.
3. **`dev-godot`**: el §13 junta todos los cambios de núcleo; ninguno toca `GestorTurnos` ni
   `minijuego_base`.
4. **`guionista`**: §10, con la regla de no nombrar el apuro.
5. **`director-cinematicas`**: §9 (tarjetas) y la coreografía del `gran_estornudo` y del `fin_oleada`, que
   anima el motor.
6. **`scrum-master`**: esta ficha suma el motor `cortar` (Fruit Ninja) al registro de mecánicas de
   referencia, en un solo lugar: el jefe de Animalia.
