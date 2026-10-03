# Ficha de motor — `clasificar` ("Lluvia de colores")

- **Autor**: Dev (implementación del 27-Sep-2026, a pedido del PO). Formaliza el motor que
  `docs/fichas/planeta-arcoiris.md` §1 dejaba especificado dentro de la ficha de nivel, más los
  campos nuevos que pide `docs/fichas/planeta-arcoiris-zonas.md` §3.1 y §4.
- **Estado**: implementado y verificado en Godot 4.7.1 (headless y en ventana). **Pendiente de
  validación**: `disenador-mecanicas` (reglas y game feel), `disenador-niveles` (los 15 niveles, las
  tandas y los umbrales de estrellitas son una propuesta de Dev), `guionista` (123 voces TTS
  provisionales), `experto-ux-parvulo` (auditoría sobre la build) y playtest con los tres.
- **Sofía ya no juega aquí** (PO, 27-Sep-2026): su estación abre el motor `mezclar`
  (`docs/fichas/motor-mezclar.md`). El modo `mezcla` y los niveles `lluvia_estrella.json` quedan
  en el código y en `qa_test_clasificar`, pero el mapa no los usa.
- **Código**: `scripts/motores/clasificar/` (`motor_clasificar.gd`, `gota_clasificar.gd`,
  `charco_clasificar.gd`) y `escenas/minijuegos/clasificar/motor_clasificar.tscn`.
- **Niveles**: `datos/niveles/arcoiris/<zona>/lluvia_<semilla|brote|estrella>.json` (5 zonas × 3 perfiles).
- **Voces**: `assets/audio/voces/arcoiris/lluvia/` (lista en `lineas_tts.tsv`, TTS de Windows).
- **QA**: `herramientas/qa_test_clasificar.gd` (headless, las 15 variantes jugadas completas) y
  `herramientas/capturar_clasificar.gd` (ventana real, clics y arrastres con `push_input` + pantallazos).

---

## 1. La mecánica en una frase

Caen (o esperan quietas) **gotas** de un color. El niño las toca o las arrastra hasta un **charco**
("imán" generoso), y el motor compara el color de la gota con lo que pide el charco. Es el mismo
esqueleto que después sirve para "cada animal a su casa" (Animalia): un motor, muchos temas.

## 2. Cuatro formas de jugar (por datos)

| Modo | Perfil | Regla | Variantes (campos) |
|---|---|---|---|
| `libre` | Semilla | Cualquier charco hace magia de color. Nunca hay "no", ni límite, ni derrota | gota quieta (`velocidad_caida: 0`), caída lenta (tocar la gota la hace saltar al charco más cercano), `charco_llama` (doble fiesta en el charco de su color), `gotas_divisibles`, `arcoiris_cielo` (sin charcos) y `sorpresa_dino` |
| `directo` | Brote | Cada gota va a su charco del mismo color. Un objetivo a la vez | `decoraciones` (flor, jirafa), `charcos_moviles`, `gota_especial` (gota-jirafa) y colores claro/oscuro |
| `directo` + `nombrar_color_por_voz` | Brote | Coco nombra un color y su charco de contorno brilla. Se elige la gota de ese color entre 3 | `charcos_contorno`, `opciones_por_pedido` |
| `mezcla` | Estrella | Cada charco pide un color que sale de 2 o 3 componentes. El primero tiñe a medias; el último completa la mezcla con una explosión de color y un dato curioso | `guia_receta`, `gota_distractora` (gota gris), `paleta_gotas` (con blanco), `pedidos_encadenados` y `reloj_estrellitas` |

## 3. Entrada (táctil y mouse, un solo camino)

- **Tocar una gota**: en `libre` salta al charco más cercano. En `directo` y `mezcla` la gota queda
  **elegida** (halo dorado, deja de caer) y el siguiente toque sobre un charco la lleva.
- **Tocar un charco**: lleva la gota elegida. En `libre` lleva la gota más cercana. En `directo`, si
  hay una sola gota, la lleva. En Nicole z5 el charco que brilla repite el color pedido.
- **Arrastrar**: la gota sigue al dedo y el charco bajo el dedo brilla. Al soltar dentro de
  `iman_tolerancia_px` del borde del charco, cuenta. En `libre`, soltar en la mitad de abajo va
  siempre al charco más cercano. Si se suelta lejos, una gota que cae sigue cayendo desde ahí y una
  quieta vuelve a su lugar. Nada de eso cuenta como fallo.
- Toda gota tiene una zona tocable de al menos 96 px de diámetro, y los charcos miden al menos 150 px.
  Todo responde al presionar (menos de 100 ms), con un pulso y un sonido.
- **Una gota que llega al suelo nunca se pierde**: vuelve a caer desde arriba. En la mezcla de Sofía
  se aplasta y cae otra, y dejar pasar la gris es justo lo correcto.

## 4. Contrato de datos del nivel

```jsonc
{
  "id_nivel": "arcoiris_z3_lluvia_estrella",
  "motor": "clasificar",
  "perfil": "estrella",                 // semilla | brote | estrella
  "planeta": "arcoiris", "zona": "zona3_chupetines",
  "variante": "texto informativo",
  "modo": "mezcla",                     // libre | directo | mezcla
  "velocidad_caida": 58,                // px/s; 0 = gotas quietas
  "variacion_velocidad": 0.5,           // ± fracción: gotas a velocidades distintas
  "elementos_simultaneos": 3,           // gotas a la vez (con divisibles: gigantes)
  "iman_tolerancia_px": 90,
  "tamano_gota": 96,                    // por defecto: Semilla 130, Brote 112, Estrella 96
  "limite_intentos": 10,                // null = sin límite. Cuenta fallos POR TANDA
  "umbrales_estrellitas": {"tres": 3, "dos": 8},   // fallos totales para 3 y para 2 estrellitas
  "rondas": 6, "por_ronda": 3,          // tandas y aciertos (o mezclas) por tanda
  "ayuda_tras_fallos": 2,               // Brote: gota y charco brillan + pista de Cometa
  "ayuda_idle_s": 6,                    // quieto N s: la gota da un saltito y brilla (sin voz)
  "regalo_tras_derrotas": true,         // tras 2 derrotas Coco regala un acierto
  "pistas_cuestan_estrellita": true,    // botón estrella dorada (Sofía)
  // libre / directo
  "colores": ["rojo", "azul", "amarillo"],   // un charco por color (posiciones barajadas)
  "pool_gotas": ["..."],                // colores de gotas (por defecto = colores)
  "decoraciones": {"rosado": "flor", "amarillo": "jirafa"},
  "charco_llama": false, "gotas_divisibles": false, "arcoiris_cielo": false,
  "charcos_moviles": false,
  "sorpresa_dino": {"cada_min": 6, "cada_max": 10},
  "gota_especial": {"tipo": "jirafa", "color": "amarillo", "ronda": 1},
  "nombrar_color_por_voz": false, "charcos_contorno": 4, "opciones_por_pedido": 3,
  // mezcla
  "pedidos": ["verde", "naranja", "violeta"],   // pool de colores pedidos (se baraja)
  "paleta_gotas": ["rojo", "azul", "amarillo", "blanco"],
  "recetas": {},                        // agrega o cambia recetas (hay recetas reales por defecto)
  "guia_receta": false,
  "gota_distractora": {"probabilidad": 0.25},
  "pedidos_encadenados": false,         // un charco a la vez; el siguiente aparece al lograrlo
  "reloj_estrellitas": {"segundos_por_pedido": 24},
  "paleta": {},                         // sobreescribe colores hex
  "lineas_voz": {
    "intro": "…", "pista": "…", "acierto": ["…"], "no_es_este": ["…"], "ayuda": "…",
    "nueva_ronda": ["…"], "victoria_final": ["…"], "derrota_gag": "…", "regalo": "…",
    "pista_usada": "…", "especial": "…", "especial_aparece": "…", "doble_fiesta": ["…"],
    "dividir": ["…"], "arcoiris_completo": ["…"], "charcos_bailan": "…",
    "componente": ["…"], "mezcla_lograda": ["…"], "gris": ["…"], "dejaste_pasar": "…",
    "a_tiempo": "…", "dato_final": "…",
    "prefijo_colores": "voces/arcoiris/lluvia/colores/",    // + <color>.wav ("¡Rosado!")
    "prefijo_pedidos": "voces/arcoiris/lluvia/pedidos/",    // Nicole z5
    "prefijo_datos": "voces/arcoiris/lluvia/datos/",        // Sofía: dato curioso por mezcla
    "prefijo_necesito": "voces/arcoiris/lluvia/necesito/"   // Sofía z5: pedido encadenado
  }
}
```

Colores con nombre: `rojo`, `azul`, `amarillo`, `rosado`, `verde`, `naranja`, `violeta`, `celeste`,
`blanco`, `cafe`, `lila`, `verde_claro` y `gris`. Recetas por defecto: verde = azul + amarillo,
naranja = rojo + amarillo, violeta = rojo + azul, rosado = rojo + blanco, celeste = azul + blanco,
café = rojo + amarillo + azul, lila = rojo + azul + blanco y verde clarito = azul + amarillo + blanco.

## 5. Tandas, rejugabilidad y duración

- Cada nivel se juega en **tandas** (`rondas` × `por_ronda`). Entre tandas hay una mini-fiesta:
  confeti, Coco baila, los charcos brillan y suena la voz de "¡otra lluvia!". Arriba, la barra muestra
  una gotita por acierto de la tanda (se llena con su color) y una estrella por tanda. No hay números
  ni texto.
- Al rejugar nada se repite igual: el orden de colores se baraja (parejo, nunca 3 iguales seguidos),
  los charcos cambian de lugar en cada tanda y los pedidos de Sofía salen de un pool.
- Duración estimada por estación, en la primera pasada: Maxi ~3 min (40 a 50 toques), Nicole ~3 min
  (35 gotas, o 24 pedidos en z5) y Sofía ~4 min (15 a 18 mezclas). El arnés juega cada nivel "perfecto"
  en 40 a 90 s de juego. El resto sale del tiempo de reacción estimado de cada edad. **Hay que
  confirmarlo en el playtest.**

## 6. Resultado al soltar, por perfil

| Al soltar… | Semilla (`libre`) | Brote (`directo`) | Estrella (`mezcla`) |
|---|---|---|---|
| en el charco correcto | magia (+ doble fiesta si `charco_llama`) | acierto, voz con el nombre del color | componente: tiñe a medias. Si era el último, mezcla lograda + dato curioso (la primera vez de cada color) |
| en otro charco | **igual hace magia** (la pintura se tiñe con el color de la gota) | "todavía no" amistoso, la gota vuelve y cuenta un fallo si hay límite | "todavía no" (color que no está en la receta o que ya echó), cuenta un fallo |
| gota gris en un charco | — | — | "¡la gris no tiene color!", cuenta un fallo |
| lejos de todo charco | vuelve o sigue cayendo | igual, **no cuenta** | igual, **no cuenta** |

- **Derrota-gag** (solo con límite, al agotar los fallos de la tanda):
  - **Nicole**: las gotas vuelan a Coco, que se tiñe de sus colores y **estornuda un arcoíris**.
  - **Sofía**: los charcos se desbordan y salpican todo el tablero, y **Coco queda cubierta de
    manchas** y se sacude riendo.

  En los dos casos aparece el botón gigante "¡otra vez!". Lo logrado se queda, las gotas de la tanda
  vuelven a la cola y los fallos de la tanda vuelven a cero. Tras 2 derrotas, Coco regala un acierto
  (Sofía: una mezcla completa).
- **Pista de Sofía** (botón estrella dorada, arriba a la derecha): la receta de un pedido se ve 3,5 s
  y brilla una gota que sirve (si no hay ninguna, cae una). Cuesta una estrellita.
- **Reloj amable** (Sofía z5): es un solcito en el globo del pedido que se va poniendo. Si la mezcla
  sale antes, gana una estrellita dorada en el globo. Si el sol se duerme, no pasa nada más. Se detiene
  mientras Coco habla.
- **Destellos**: 3 por gota y 8 por mezcla, más 5 por tanda sin fallos (solo con límite y sin derrota).
- **Estrellitas** (Estrella), regla PROVISIONAL:
  - Con `umbrales_estrellitas`: 3 si los fallos totales son ≤ `tres`, 2 si son ≤ `dos`, 1 si son más.
  - Tras una derrota-gag, 1.
  - Con reloj, además se toma el mínimo con la fracción de pedidos a tiempo: ≥80 % da 3 y ≥40 % da 2.
  - Cada pista resta una. Ganar siempre da al menos 1.
- Tocar a **Cometa** repite la instrucción (en Nicole z5, el color pedido; en Maxi, además, la gota
  salta). Tocar a **Coco** repite la intro. F3 (PC) muestra el panel de depuración.

## 7. Momentos memorables

- **Maxi**: dinosaurio de pintura sorpresa (z3 y z4, cada 6 a 13 gotas) que ruge bajito y se
  deshace en chispas. En z5, cada arcoíris completo del cielo crece y explota en fuegos de colores.
- **Nicole**: la gota-jirafa (z3, en la segunda tanda) cruza un arcoíris y Coco le da las gracias
  por ayudarla.
- **Sofía**: un dato curioso real por cada color nuevo y, al final, el **mural arcoíris** que ilumina
  todo el tablero con el dato del orden de los colores del arcoíris.

## 8. Pendientes

- Arte final de gotas, charcos y del dino (HE-13): hoy todo se dibuja en código con el estilo
  "peluche pintado" de `figura_vectorial.gd`.
- SFX propios (salpicadura, rugido de dino, estornudo): hoy se reutiliza el set de UI de Kenney.
- Voces oficiales de Coco y Cometa (hoy TTS de Windows, provisionales).
- Validar en el playtest la duración, la velocidad de caída de Sofía z3 y z5, los umbrales de
  estrellitas y la carga de Nicole z4 (rojo/rosado y azul/celeste).

## Validación HE-40 — disenador-mecanicas (28-Sep-2026, PROPUESTA)

**Aprobado** (`docs/validaciones/HE-40_disenador-mecanicas.md`, hallazgos 16-18). Cambios menores:

- En modo `directo`, tocar un charco sin gota elegida hace una onda, dice el color y hace saltar la gota
  de ese color más cercana.
- Los charcos móviles nunca se mueven mientras haya una gota elegida o en arrastre.
