# Auditoría UX — HE-44: álbum de recuerdos "Las migas de papá" y momento de entrega

- **Fecha**: 28-Sep-2026
- **Auditor**: `experto-ux-parvulo`
- **Documentos revisados**: `docs/fichas/album-recuerdos.md` (§1-§8, incluida la "Implementación
  provisional"), `docs/diseno-juego.md` §1 y §6, `docs/perfil-jugadores.md`.
- **Código y datos revisados**:
  - Pantallas y componentes: `escenas/nucleo/album_recuerdos.tscn`, `scripts/nucleo/album_recuerdos.gd`,
    `scripts/ui/entrega_recuerdo.gd`, `scripts/ui/boton_album.gd` y `scripts/ui/foto_recuerdo.gd`.
  - Autoload y catálogo: `scripts/autoloads/recuerdos.gd` y `datos/recuerdos/catalogo.json`.
  - Integraciones: `scripts/nucleo/seleccion_personaje.gd` con su `.tscn` (botón del álbum y primera
    apertura), y `scripts/nucleo/mapa_planeta.gd:300-350` (entrega al completar una zona).
- **Método**: leí el código y las escenas y medí en px lógicos sobre la base de 1280×720. No
  ejecuté nada. Revisé en disco qué audios existen.
- **Perfil que manda**: el álbum lo abre cualquiera de los tres sin elegir perfil, y la entrega le
  llega a cualquiera de ellos. Por eso todo se audita **para Maxi (2 años)**: objetivos de ≥96 px,
  cero lectura y aguante al "tocar muchas veces seguidas".

---

## Veredicto: **RECHAZADA**

La tarjeta no cierra por **1 hallazgo bloqueante**, R1: el álbum y la entrega son **mudos**, porque
no existe ninguna línea de voz de Cometa para los recuerdos. Además hay **3 mayores**, todos del
momento de entrega:

- R2: Maxi puede saltarse la foto tocando varias veces.
- R3: la entrega puede desaparecer si al mismo tiempo se lanza un juego.
- R4: el marco dorado de Sofía no se puede conseguir.

Hay **7 menores**.

El diseño visual y de tamaños está **muy bien resuelto**:

- **Álbum**:
  - Las tapas miden 250×340 y están separadas 40 px.
  - Las polaroids de la página miden 200×238, con 70 px de separación horizontal y 52 px vertical.
  - Las flechas miden 120 px, volver 112 px y cerrar 120 px.
  - El progreso se muestra con estrellitas, sin números.
  - Los huecos nunca dicen "no": se menean y, gracias a `pista_respaldo`, dan una pista hablada.
- **Entrega**:
  - El sobre mide 260×190 y cualquier toque lo abre. Si nadie lo toca, se abre solo a los 3 s.
  - La foto crece hasta el 70 % de la pantalla y cae confeti.
  - Todo toque responde al instante con sonido y rebote.
- **Botón del álbum**: mide 150×132 en la selección y late cuando hay una foto nueva.
- **Seguridad y privacidad**: el álbum funciona sin conexión, no tiene enlaces externos y las fotos
  y voces de la familia quedan fuera del repositorio.

---

## Hallazgos

### Bloqueantes

**R1. El álbum y la entrega no tienen voz: falta toda la carpeta de líneas de Cometa de los recuerdos.**
`datos/recuerdos/catalogo.json:62-109` apunta a `res://assets/audio/voces/recuerdos/`, que **no
existe en disco**. Por eso `Recuerdos.elegir_linea()` (`recuerdos.gd:358-367`) devuelve `""` para
todas las líneas: `entrega`, `primera`, `generica`, `familiar`, `dorado`, `album_invitacion`, `tapa`,
`album_vacio` y `album_nueva`. Eso tiene tres consecuencias:

- **Entrega** (`entrega_recuerdo.gd:140`): el sobre baja sin el "¡Mira! ¡Otra foto de la billetera
  de papá!" de la ficha §6.1. Un niño de 2 años ve un sobre que cae y no sabe qué es ni por qué pasó.
- **Foto sin audio de la familia**, que es el caso de todas las fotos placeholder y de cualquier
  foto que el PO no haya grabado todavía. Tampoco hay línea genérica, así que la foto dura
  `MIN_FOTO` = 2,5 s en silencio (`:181`) y se va volando.
- **Álbum** (`album_recuerdos.gd:71`, `:218-220`, `:357`): no hay invitación, las tapas no se nombran
  y el álbum vacío no se explica. Solo los huecos hablan, gracias a `pista_respaldo`.

Esto viola la regla 2 de §6 (todo se narra por voz) y deja el momento más emotivo del regalo en
silencio.
**Corrección**:
- Producir las líneas de `docs/guiones/recuerdos.md` con la voz oficial de Cometa y dejarlas en
  `assets/audio/voces/recuerdos/<id sin prefijo>.ogg`. Generarlas con TTS pagado requiere el OK
  explícito del PO sobre el costo.
- Como mínimo para cerrar se necesitan `entrega_*`, `primera_*`, `generica_*`, `album_invitacion`,
  `tapa_*` y `album_vacio`.
- Mientras no existan, `elegir_linea` debería caer en una línea de Cometa ya grabada que sirva, igual
  que hace `ruta_pista` con `pista_respaldo`, y no en el silencio.

### Mayores

**R2. Maxi puede saltarse la foto en menos de 1,5 s si toca varias veces seguidas.**
`entrega_recuerdo.gd:38` (`TOQUE_FOTO_DESDE := 0.7`), `:181` y `:201`. Un toque durante la bajada
abre el sobre apenas llega (`:206-209`). En la foto, cualquier toque después de 0,7 s llama a
`_guardar_foto()` y la foto se va volando. A los 2 años es muy común tocar la pantalla una y otra
vez. El resultado sería un sobre, un destello y una foto que se escapa antes de que suene la voz de
mamá o papá.
**Corrección**: en el estado `"foto"`, que un toque solo **haga rebotar la foto y repita el
audio**, sin sacarla, hasta que se cumpla alguna de estas dos condiciones:

- (a) el audio de la familia terminó, o
- (b) pasaron `MIN_FOTO`, con un mínimo de 3 s si no hay audio.

Recién después, un toque la guarda. La ficha §6.6 ("al terminar el audio o con un toque") se
cumple igual, porque el toque que la cierra llega cuando la foto ya se vio.

**R3. La entrega de la zona completa puede aparecer justo cuando se está lanzando un juego y desaparecer con la escena.**
`mapa_planeta.gd:320-349` hace esto:

1. Espera 1,2 s.
2. Espera a que termine la voz, con un máximo de 8 s.
3. Llama a `desbloquear()`, que **guarda** el recuerdo.
4. Monta la entrega como hija del mapa.

Esa función nunca revisa `_lanzando`. Si el niño tocó una estación y la voz del juego ya terminó,
lo que pasa cuando el audio es corto o falta, la entrega se monta en la ventana de 0,9 s de
`lanzar_estacion` (`:701-718`). El `queue_free()` del mapa se la lleva por delante. La foto queda
registrada, porque se verá como "nueva" en el álbum, pero **el niño no vive el momento de la
entrega**, y la ficha §4 dice que "cada recuerdo siempre se entrega".
**Corrección**: en `_entregar_recuerdos_zonas`, justo antes de `desbloquear`, salir si `_lanzando`
es verdadero. La foto llegará en la próxima visita, sin perder nada. Además, mientras la entrega
esté activa (`entrega.esta_activa()`), `_tocar_estacion`, `_tocar_cometa` y `_volver_al_mapa_estelar`
deben ignorar los toques. Hoy ya los tapa la capa 60, pero conviene blindarlo.

**R4. El marco dorado de Sofía no se puede conseguir.**
`mapa_planeta.gd:310-312`: `perfecta` exige que **todas** las estaciones jugables de la zona sean de
nivel `estrella` con `estrellitas >= 3`. Pinta con Coco nunca da estrellitas, porque
`motor_lienzo_libre.gd:1712` llama a `celebrar(..., 0, ...)` y la ficha de zonas §3.4 dice que no
hay fallo ni puntaje. Por eso `perfecta` siempre es `false`. La recompensa que la ficha §4 le
promete a Sofía ("marco dorado") nunca llega. La ficha de zonas §2.2 ya dice "estaciones **con
puntaje**".
**Corrección**: filtrar las estaciones sin puntaje antes del `all(...)`. Hay dos formas:

- con un campo `"puntua": false` por estación en `mapa.json`, o
- dejando fuera las estaciones cuyo nivel no trae `umbrales_estrellitas`.

Agregar un caso de QA: Sofía con 3 estrellitas en Lluvia, Formas y Parejas debe recibir la entrega
`_solo_dorado`.

### Menores

**R5. Con la foto abierta en el álbum, tocar fuera de la foto no hace nada, y el botón volver se ve pero no responde.**
`album_recuerdos.gd:137-141`: el velo tiene `MOUSE_FILTER_STOP` sin handler, así que se traga el
toque en silencio y no cumple la regla 5 de §6. El `_boton_volver` (`:133`) queda debajo del velo al
82 %: se ve, pero no responde.
**Corrección**: conectar el velo a `cerrar_foto()`, con `SFX_CERRAR`. Tocar fuera de la foto para
cerrarla es un patrón que los niños ya conocen. También se puede ocultar `_boton_volver` mientras
`vista == "foto"`.

**R6. Un deslizamiento que empieza sobre una foto la abre en vez de cambiar de página.**
`album_recuerdos.gd:312-317`: las celdas actúan **al presionar** y marcan el evento como manejado,
así que `_al_deslizar` (`:321-330`) nunca recibe el gesto. Como las celdas cubren casi toda la
página, deslizar casi nunca funciona y lo que el niño ve es "se abrió una foto". No es dañino,
porque las flechas de 120 px existen, pero es una fricción evitable.
**Corrección**: en las celdas, actuar **al soltar** si el dedo se movió menos de 20 px. Si se movió
más de `DESLIZAR_MIN`, pasar de página. La respuesta inmediata al presionar se mantiene con un
rebote leve de la celda.

**R7. El botón del álbum queda a 18 px de la tarjeta de Sofía en la selección de personaje, una pantalla que usa Maxi.**
`seleccion_personaje.gd:26`: `RECT_ALBUM` = (930, 578, 150, 132). La tarjeta de Sofía termina en
y = 560 (`seleccion_personaje.tscn:308-312`). Las regiones no se tocan, pero 18 px entre dos
objetivos de acciones muy distintas es poco para un dedo de 2 años. Además, el botón del álbum
queda a 68 px de "volver al título".
**Corrección**: bajar a `Rect2(930, 596, 140, 120)`, que deja ≥36 px de separación, o moverlo a la
esquina inferior izquierda, lejos de "volver".

**R8. En el mapa del planeta, la foto vuela a un ícono de álbum que no está donde vive el álbum de verdad.**
`entrega_recuerdo.gd:107-109`: como el mapa no pasa `destino`, la entrega dibuja su propio ícono en
(1170, 96), arriba a la derecha, y después lo desvanece. El botón real está abajo a la derecha de la
selección de personaje, en (1005, 644). La ficha §6.5 quiere que la foto vuele al álbum "para que el
niño aprenda dónde queda", y dos lugares distintos confunden.
**Corrección**: que el ícono propio aparezca en la misma zona de pantalla que el botón real, abajo
a la derecha, sobre el panel de estaciones, que es solo una capa visual. La otra opción es aceptar
la diferencia y que la línea `generica` o la de `entrega` diga "la guardé en tu álbum de fotos".

**R9. La edad al pie de la foto se escribe pero no se lee en voz alta.**
`foto_recuerdo.gd:141-145` dibuja la `edad` con `draw_string`. La ficha §7 pide un pie de foto
"dibujado y narrado". Hoy es un extra para quien sabe leer, sin voz.
**Corrección**: al abrir la foto en el álbum, si existe `edad` y no hay audio de la familia, que
Cometa la diga, con una línea por tramo de edad o con TTS del catálogo.

**R10. El álbum no tiene un Cometa que repita la instrucción, como pide la regla 2 de §6.**
`album_recuerdos.gd`: en la portada, la única voz es la invitación inicial (`:71`). En la página, la
cabecera repite la línea de la tapa (`:352-357`). Un niño que llegó tarde o no entendió no tiene
dónde tocar para volver a oírla.
**Corrección**: agregar el botón de Cometa de 116 px abajo a la derecha, igual que en los
minijuegos, que repita `album_invitacion` en la portada y `tapa` en la página.

**R11. La entrega de la zona puede empezar mientras Coco todavía está celebrando.**
`mapa_planeta.gd:333-338` espera como máximo 8 s de voz. Cuando se juntan
`voz_completada` + `zona_abierta` + `dorado_disponible` (`:278-297`), las voces pueden pasar de 8 s.
La entrega entonces empieza encima, y su línea de Cometa corta a Coco. La ficha §6.1 pide "sin
cortar la celebración anterior".
**Corrección**: exponer desde `_decir_en_orden` una bandera `_celebrando` (o el `_id_voces` en curso)
y esperar a que termine la secuencia completa, no solo el clip que suena, con un tope de 15 s.

---

## Qué verificar en el playtest (no son hallazgos)

- **Maxi**: con R2 corregido, ¿se queda mirando la foto? ¿Reconoce a su familia en una foto de bebé?
- **Sofía y Nicole**: ¿el marco dorado de Sofía (una vez corregido R4) genera celos en Nicole cuando
  mira el álbum de su hermana? La ficha de Sofía pide cuidar la equidad. Si pasa, conviene darle a
  Nicole un adorno equivalente en su álbum por constancia.
- **Los tres juntos**: ¿el álbum familiar se abre entre todos, como busca la ficha §3?

## Resumen de severidades

- **Bloqueantes: 1**. R1: el álbum y la entrega no tienen voz porque falta `assets/audio/voces/recuerdos/`.
  **Impide cerrar HE-44.**
- **Mayores: 3**:
  - R2: tocar varias veces salta la foto en menos de 1,5 s.
  - R3: la entrega se pierde si en ese momento se lanza un juego.
  - R4: el marco dorado de Sofía no se puede conseguir porque Pinta no da estrellitas.
- **Menores: 7**, de R5 a R11.
