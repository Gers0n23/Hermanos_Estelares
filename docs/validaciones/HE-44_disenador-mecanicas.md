# Validación HE-44 — `disenador-mecanicas`

- **Fecha**: 28-Sep-2026
- **Alcance**: game feel de la entrega de recuerdos del álbum "Las migas de papá"
  (`docs/fichas/album-recuerdos.md` §4 y §6). Implementación provisional revisada:
  `scripts/ui/entrega_recuerdo.gd`, más las llamadas desde `scripts/nucleo/mapa_planeta.gd`,
  `scripts/nucleo/viaje_estelar.gd` y `scripts/nucleo/seleccion_personaje.gd`. Del álbum
  (`album_recuerdos.gd`) solo miré la interacción básica.
- **Método**: lectura de la ficha y del código. **No ejecuté escenas.**
- **Decisiones**: el PO pidió avanzar sin consultarle. Los cambios son **PROPUESTA** de
  `disenador-mecanicas`.

## Veredicto

**APROBADO CON CAMBIOS: no hay bloqueantes.** La secuencia de la ficha §6 está implementada completa y
bien:
1. Un velo que baja suave.
2. El sobre-estrella de 260×190 que baja girando (0,9 s, `TRANS_BACK`) con una estrella que late.
3. Un toque en cualquier parte lo abre, o se abre solo.
4. La polaroid crece a 504 px de alto (70 %) con estallido y confeti.
5. La foto vuela al ícono del álbum, que rebota.

Además:
- El viaje estelar queda en pausa y después da invulnerabilidad.
- El mapa espera a que termine la voz de la celebración.
- La foto se guarda recién al mostrarse, así que nunca se pierde.
- Todo toque responde al instante con sonido y rebote.

Hay **3 hallazgos mayores**. Los tres cuidan lo mismo: que el momento más emotivo del juego (la voz real
de la familia) **no se lo salte un toque impaciente ni lo tape otra voz**.

---

## Hallazgos

**1. [MAYOR] Tocar varias veces seguidas se salta la foto y la voz de la familia.** En el estado `foto`,
cualquier toque después de `TOQUE_FOTO_DESDE` = 0,7 s guarda la foto. Maxi (2 años) toca repetidamente
cuando algo le gusta, así que la foto de bebé y la voz de mamá o papá duran 0,7 s en pantalla. Es el
corazón del regalo.
*Cambios*:
- Los toques **no cierran la foto hasta que termine el audio de la familia** (o hasta
  `MIN_FOTO_SIN_AUDIO`, si no hay audio).
- Antes de eso, cada toque es una **reacción juguetona**:
  - la foto hace squash (1,04/0,97, 0,2 s, como hoy);
  - salen 4 chispas desde el punto tocado;
  - suena un "clic" de cámara.
  Así no queda un toque "muerto".
- Una vez terminado el audio, un toque cierra la foto.
- **Semilla**: ni siquiera entonces. La foto se va sola (ver 3), porque a los 2 años el toque no es una
  decisión de seguir.

**2. [MAYOR] El sobre se abre solo y corta a Cometa.** `AUTO_ABRIR` = 3,0 s cuenta desde que el sobre
llega. Las líneas de Cometa ("¡Mira! ¡Otra foto de la billetera de papá!", la de `burbuja_atrapada` y la
de `primera`) pueden durar más, y al abrir el sobre `reproducir_voz_stream` pisa la voz en curso. Resultado:
Cometa queda cortado a mitad de frase y la voz de la familia entra encima.
*Cambios*:
- La apertura automática ocurre en `max(3,0 s desde que llega el sobre, fin de la línea de Cometa + 0,4 s)`,
  con un **tope de 6 s**.
- Si el niño toca antes, abre igual (su toque manda). En ese caso, la voz de Cometa baja a cero en
  **0,15 s** antes de que empiece la voz de la familia, en vez de cortarse en seco.
- La voz de la familia empieza **0,35 s después** de abrir el sobre, cuando la polaroid ya creció.

**3. [MAYOR] La foto se va apenas termina el audio.** Hoy la foto vuela al álbum en cuanto
`esta_hablando()` es falso (con un mínimo de 2,5 s). Queda la sensación de que "se la llevan" en la
última sílaba. Sin audio, 2,5 s no alcanzan para mirar una foto de bebé.
*Cambios*:
- `COLA_TRAS_AUDIO` = **1,5 s**: la foto sigue a la vista después de que termina el audio.
- `MIN_FOTO_SIN_AUDIO`: 2,5 → **4,5 s**.
- `MAX_FOTO`: se mantiene en 14 s.
- En Semilla, la foto se va sola con estas mismas reglas.

**4. [MENOR] Falta una invitación a tocar el sobre.** Maxi no sabe que tocar lo abre, y la apertura
automática le enseña a esperar, no a tocar.
*Cambio*: a los **1,5 s** sin toque, el sobre da un saltito de 18 px en 0,25 s (`TRANS_BACK`), suena una
campanita suave y su estrella se agranda a 1,15.

**5. [MENOR] La apertura podría tener más "momento de foto".**
*Cambio*: al abrir, un destello blanco de pantalla completa con alfa 0,35 que se apaga en 0,12 s (el
flash de la polaroid), antes del estallido que ya existe.

**6. [MENOR] El ícono del álbum desaparece muy rápido.** Con el ícono propio de la entrega, este se
desvanece 0,3 s después del rebote. El paso 5 de la ficha busca que el niño aprenda **dónde queda** la
foto.
*Cambio*: después del rebote, el ícono se queda **0,8 s** con un halo dorado que late una vez y recién ahí
se desvanece. Cuando el ícono es el botón real de la pantalla (selección de personaje), ese botón queda
con el brillo de "foto nueva" (ficha §7).

**7. [MENOR] Varios recuerdos seguidos.** Cuando hay cola (por ejemplo, zonas completadas antes de que
existiera el álbum), cada recuerdo repite la entrada completa: el velo baja y sube, y Cometa habla otra
vez.
*Cambios*:
- Entre recuerdos de la misma entrega, el velo se queda puesto.
- A partir del 2.º sobre, Cometa usa una línea corta de 1-2 s ("¡Y otra más!").
- Tope: **3 sobres por entrega**. El resto llega la próxima vez que se entre al mapa. Nada se pierde,
  porque `desbloquear` es idempotente y el guardado es al mostrarse.

**8. [MENOR] La entrega de solo marco dorado (Sofía) no necesita el sobre completo.** Esa foto ya la
tiene.
*Cambio*: la polaroid aparece directo a 70 % y un **marco dorado se dibuja a su alrededor** durante
1,2 s, con brillo que recorre el borde. Suena la línea `dorado`, cae confeti dorado y la foto vuela al
álbum. No hay sobre.

**9. [MENOR] En el viaje estelar, la burbuja no se atrapa tocándola.** La ficha §4 dice "tocándola o
chocándola con la nave", pero `viaje_estelar.gd` solo la atrapa por contacto con la nave o con Cometa.
El imán y el reaparecer cubren a Maxi, así que no es grave.
*Cambio*: tocar la burbuja (zona tocable de **96 px**, aunque se dibuje de 26 px) también la atrapa.

**10. [MENOR] En el mapa, la espera es una heurística.** `_entregar_recuerdos_zonas` espera 1,2 s y
hasta 8 s mientras haya voz. Si la animación de "vuelve el color" dura más que la voz, el sobre la tapa.
*Cambio*: que el mapa espere una señal o un estado `celebracion_zona_terminada`, con un tope de 10 s.

**11. [APROBADO] Álbum.** Tiene tapas de 250×340, celdas de 200×238, páginas que se pasan deslizando
(90 px mínimo) o con flechas, y huecos que dan una pista hablada. Todo es tocar y arrastrar. La auditoría
de detalle es de `experto-ux-parvulo`.

---

## Resumen de cambios para `dev-godot`

| Parámetro (`entrega_recuerdo.gd`) | Hoy | Propuesta |
|---|---|---|
| Qué hace un toque sobre la foto | la cierra desde los 0,7 s | reacción juguetona; cierra solo después del audio; en Semilla nunca |
| `AUTO_ABRIR` | 3,0 s desde que llega | máx(3,0 s, fin de la voz de Cometa + 0,4 s), tope 6 s |
| Transición de voz de Cometa → voz de la familia | corte seco | Cometa baja a cero en 0,15 s; la familia entra 0,35 s después de abrir |
| `COLA_TRAS_AUDIO` | 0 | 1,5 s |
| `MIN_FOTO` (sin audio) | 2,5 s | 4,5 s |
| Invitación a tocar el sobre | no hay | a los 1,5 s: saltito de 18 px + campanita |
| Flash de la polaroid | no hay | blanco, alfa 0,35, 0,12 s |
| Ícono tras el rebote | 0,3 s | 0,8 s con halo |
| Cola de recuerdos | velo y voz completos cada vez | velo continuo, línea corta, tope de 3 por entrega |
| Entrega de solo marco dorado | sobre completo | marco que se dibuja en 1,2 s, sin sobre |
| Burbuja del viaje | solo por choque | también al tocarla (96 px) |

## Qué deben validar después

- **`experto-ux-parvulo`**:
  - Que la reacción juguetona del hallazgo 1 no se lea como "no funciona".
  - Que la invitación del hallazgo 4 se entienda a los 2 años.
- **`tester-qa`**:
  - Tocar 10 veces por segundo durante toda la entrega: la voz de la familia debe sonar completa.
  - Cometa nunca queda cortado sin el fundido.
  - La cola de más de 3 recuerdos se reparte entre visitas sin perder ninguno.
  - Respuesta <100 ms a cada toque.
- **Playtest**: mirar la cara de los tres cuando suene la primera voz real. Si Maxi se aburre con fotos
  largas, bajar `COLA_TRAS_AUDIO` antes de tocar lo demás.
