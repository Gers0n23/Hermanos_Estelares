# Ficha de motor — `mezclar` ("Taller de pinturas de Coco")

- **Autor**: Dev, a pedido directo del PO (27-Sep-2026): "la mezcla de gotas es extremadamente
  fácil, aburrida y no tiene propósito". Reemplaza el modo `mezcla` de `clasificar` **solo para
  Sofía**. Maxi y Nicole siguen con su Lluvia de colores.
- **Estado**: implementado y verificado en Godot 4.7.1 (headless y en ventana). **Pendiente de
  validación**: `disenador-mecanicas` (reglas y game feel), `disenador-niveles` (curva de las 5
  zonas y umbrales, que hoy son propuesta de Dev), `guionista` (46 voces TTS provisionales),
  `experto-ux-parvulo` (auditoría sobre la build) y playtest con Sofía.
- **Código**: `scripts/motores/mezclar/motor_mezclar.gd` y `escenas/minijuegos/mezclar/motor_mezclar.tscn`.
- **Niveles**: `datos/niveles/arcoiris/<zona>/mezcla_estrella.json`, generados con
  `herramientas/generar_niveles_mezcla.py`. Reutilizan el `id_nivel` de `lluvia_estrella` para
  que Sofía no pierda el avance del mapa.
- **Mapa**: la estación `lluvia` tiene `escenas: {"sofia": …}` e `iconos: {"sofia": "taller"}`.
  El mapa sigue sin conocer motores concretos (regla de oro 3).
- **Voces**: `assets/audio/voces/arcoiris/mezclar/lineas_tts.tsv` (TTS de Windows, provisional).
  Reutiliza los datos curiosos y las victorias de la Lluvia.
- **QA**: `herramientas/qa_test_mezclar.gd` (headless, los 5 niveles completos) y
  `herramientas/capturar_mezclar.gd` (ventana real + pantallazos).

---

## 1. El bucle en una frase

Coco quiere pintar un **mural** y pide **3 latas**. Por cada lata, Sofía **memoriza una receta con
proporciones**, **atrapa con el frasco** solo las gotas que la forman, lo **agita** para mezclar y
obtiene la lata. Con las 3 latas, Coco pinta el mural frente a ella.

## 2. Fases de cada lata

| Fase | Qué ve y hace Sofía | Reglas |
|---|---|---|
| Receta | Tarjeta grande: lata del color = gotas agrupadas por pigmento (🟡🟡 + 🔵). Coco la lee en voz alta | Se cierra con el visto bueno (≥ 96 px). En z5 se esconde sola: un solcito de 6 s que parte cuando Coco termina de leerla |
| Atrapar | Caen gotas de colores. Arrastra el frasco, o toca donde quiere que vaya (PC: también flechas) | Una gota que falta: entra y se ve como capa. Una gota que no va (otro color, **una de más** o la gris): gag de "¡puaj!" |
| Agitar | El frasco se tapa, aparecen flechas y un círculo dorado | Se llena sacudiendo de lado a lado (cambiar de sentido rinde más) o manteniendo apretado. Las capas se funden en el color final |
| Lata | La lata vuela al pedido de Coco | La primera vez de cada color con dato curioso, Coco lo cuenta |

- **Libreta** (arriba a la derecha): vuelve a mostrar la receta de la lata en curso. **Cuesta una
  estrellita** (`libreta_cuesta_estrellita`). Mientras se ve, el juego se pausa.
- **Gag de "¡puaj!"** (gota equivocada): la mezcla se pone color barro y burbujea, Coco se ríe y el
  frasco se vacía. **Solo se reinicia la lata en curso**. Las latas hechas y el mural nunca se
  pierden, y el nivel nunca termina en derrota (GDD §6, regla de oro 2). Cuenta un fallo para las
  estrellitas.
- **Dejar pasar** gotas nunca castiga: se aplastan en el suelo.
- **Gotas justas**: si pasan 2 gotas seguidas que no sirven, la siguiente es una que falta. Así
  nunca hay esperas largas.

## 3. Recetas (modelo RYB + blanco, proporciones)

| Color | Receta | Color | Receta |
|---|---|---|---|
| verde | 1 amarilla + 1 azul | rosado | 1 roja + 2 blancas |
| naranja | 1 roja + 1 amarilla | celeste | 1 azul + 2 blancas |
| violeta | 1 roja + 1 azul | durazno | 1 roja + 1 amarilla + 1 blanca |
| verde limón | 2 amarillas + 1 azul | café | 1 roja + 1 amarilla + 1 azul |
| verde azulado | 1 amarilla + 2 azules | lila | 1 roja + 1 azul + 1 blanca |
| mango | 1 roja + 2 amarillas | verde clarito | 1 amarilla + 1 azul + 1 blanca |
| rojo tomate | 2 rojas + 1 amarilla | turquesa | 1 amarilla + 2 azules + 1 blanca |
| fucsia | 2 rojas + 1 azul | verde oliva | 1 roja + 2 amarillas + 1 azul |
| añil | 1 roja + 2 azules | chocolate | 2 rojas + 1 amarilla + 1 azul |

Los pares "invertidos" (verde limón / verde azulado, mango / tomate, fucsia / añil) son el corazón
del desafío: los mismos dos colores dan otro resultado según **cuántas** gotas de cada uno.

**Variabilidad**: los 3 pedidos de un mural salen de un mazo barajado del pool del nivel. Nunca se
repiten dentro de un mural, y se evitan los 2 últimos colores hechos.

## 4. Curva de Sofía (propuesta de Dev)

| Zona | Recetas | Frasco muestra cuántas | Receta visible | Caída | Gris | Murales |
|---|---|---|---|---|---|---|
| 1 · Claro | verde, naranja, violeta + verde limón | sí | hasta el visto bueno | 105 px/s, 2 gotas | no | 2 (flor, casa) |
| 2 · Charcos | las 6 de proporción 2+1 | sí | hasta el visto bueno | 120 ±15 %, 3 gotas | no | 2 (pez, pony) |
| 3 · Chupetines | blanco: rosado, celeste, durazno + 2+1 | sí | hasta el visto bueno | 130 ±35 % | 20 % | 2 (cohete, arcoíris) |
| 4 · Islotes | 3 y 4 gotas: café, lila, verde clarito, turquesa, oliva, chocolate, durazno | **no** | hasta el visto bueno | 135 ±30 % | 12 % | 2 (casa, pez) |
| 5 · Cima | las 15 | no | **6 s** tras la lectura | 145 ±35 % | 15 % | 3 (pony, cohete, arcoíris) |

Duración estimada: 6 latas por nivel (9 en z5), unos 30 a 40 s por lata, o sea ~4 min por
estación. **Hay que confirmarlo en el playtest.**

## 5. Puntaje

- **Estrellitas**: 3 si los fallos (gotas equivocadas) son ≤ `umbrales_estrellitas.tres`, 2 si son
  ≤ `dos` y si no, 1. Cada uso de la libreta resta una. Ganar siempre da al menos 1.
- **Destellos**: 8 por lata, 10 por mural y 5 extra por mural sin fallos.

## 6. Contrato de datos del nivel

```jsonc
{
  "id_nivel": "arcoiris_z2_lluvia_estrella", "motor": "mezclar", "perfil": "estrella",
  "pedidos": ["verde_limon", "verde_azulado", "mango"],   // pool de colores (con receta)
  "recetas": {},                     // agrega o cambia recetas: {"color": {"rojo": 2, "azul": 1}}
  "pigmentos": [],                   // gotas que caen (por defecto: los de las recetas del pool)
  "paleta": {},                      // sobreescribe colores hex
  "velocidad_caida": 120, "variacion_velocidad": 0.15,
  "elementos_simultaneos": 3, "intervalo_gotas_s": 1.1,
  "probabilidad_util": 0.55,         // chance de que caiga una gota que falta
  "gota_distractora": {"probabilidad": 0.2},
  "ranuras_visibles": true,          // la etiqueta del frasco muestra cuántas gotas lleva la receta
  "memorizar_s": 0,                  // > 0: la receta se esconde sola N s después de leerla
  "murales": 2, "dibujos_mural": ["flor", "casa"],  // flor | casa | cohete | pez | pony | arcoiris
  "tamano_gota": 84,
  "libreta_cuesta_estrellita": true,
  "umbrales_estrellitas": {"tres": 2, "dos": 5},
  "lineas_voz": {
    "intro", "pista", "pista_agitar", "memoriza", "a_atrapar"[], "bien"[], "sucio"[], "gris"[],
    "a_mezclar", "lata_lista"[], "revisar", "mural_pedido"[], "entregar", "mural_listo"[],
    "victoria_final"[], "prefijo_recetas", "prefijo_datos"
  }
}
```

## 7. Decisiones frente al pedido original del PO

- "Perder un intento o reiniciar el proceso" → se reinicia **solo la lata en curso**, con un gag
  gracioso, y cuenta para las estrellitas. No hay vidas ni derrota (GDD §6, regla de oro 2).
- "Botón de ayuda con penalización de tiempo o puntos" → la libreta cuesta **una estrellita**,
  la misma moneda que ya usan las pistas de Sofía. No hay reloj que apure.
- "Agitar con el mouse o mantener presionado" → se aceptan las dos (GDD §6.4: solo tocar y
  arrastrar).
- "Entregar las latas a un NPC para pintar una pared" → Coco recibe las latas y pinta el mural
  frente a Sofía. Desbloquear zonas ya lo hace el mapa al completar estaciones.

## 8. Pendientes

- Voces oficiales de Coco (fal.ai): 46 líneas. Hay que estimar el costo con `--estimar` y pedir el
  OK del PO antes de generarlas.
- SFX propios (plip de gota, burbujeo, agitado): hoy se reutiliza el set de UI de Kenney.
- Idea para después: mostrar los murales terminados en el mapa del planeta (tocaría el núcleo; se
  diseña aparte).
- Validar en el playtest: velocidad de caída, umbrales, si 6 s de memoria en z5 son justos y si
  la libreta se entiende sin explicación.

## Validación HE-40 — disenador-mecanicas (28-Sep-2026, PROPUESTA)

**Aprobado con cambios** (`docs/validaciones/HE-40_disenador-mecanicas.md`, hallazgos 13-15):

- `separacion_min_gotas_px: 190`, para no atrapar gotas sin querer.
- `fallos_para_reiniciar_lata: 2`: con la 1.ª gota equivocada, el frasco la escupe y se quedan las capas
  buenas.
- Mantener apretado para agitar: 0,4 por segundo, con vibración.
- La libreta usa el medidor de estrellitas y el globo de confirmación del hallazgo 4.

## Implementación dev-godot 28-Sep-2026 (validaciones HE-40, PROVISIONAL)

- `separacion_min_gotas_px: 190` (si no hay lugar, la gota espera) y `fallos_para_reiniciar_lata: 2`: la 1.ª gota equivocada sale escupida (voz `escupe`), las capas buenas se quedan y cuenta un fallo; la 2.ª vacía el frasco.
- Umbrales: z1 2/5, z2 3/6, z3 3/7, z4 4/8, z5 5/10. Pista de Cometa por zona (`pista_z2..z5`). Mural "pony" en lugar de la mariposa (z2 y z5). Mantener apretado agita a 0,4/s.
- Libreta con medidor y globo de confirmación (`pista_con_costo.gd`).
