# Auditoría UX — HE-40: mapa del Planeta Arcoíris por zonas, mecánicas v3 de Sofía y minijuegos nuevos

- **Fecha**: 28-Sep-2026
- **Auditor**: `experto-ux-parvulo`
- **Documentos revisados**: `docs/diseno-juego.md` §1, §5 y §6; `docs/perfil-jugadores.md` (los tres);
  `docs/fichas/planeta-arcoiris-zonas.md` (§2-§6).
- **Código y datos revisados**:
  - Mapa: `scripts/nucleo/mapa_planeta.gd`, `datos/planetas/arcoiris/mapa.json`.
  - Encajar v3: `scripts/motores/encajar/motor_encajar.gd`, `scripts/motores/encajar/pieza_encajar.gd`,
    `escenas/minijuegos/encajar/motor_encajar.tscn`, `datos/niveles/arcoiris/*/formas_*.json` y
    `zona5_cima/formas_estrella_dorado.json`.
  - Mezclar, el taller de pinturas que hoy reemplaza la Lluvia de Sofía: `scripts/motores/mezclar/motor_mezclar.gd`,
    `escenas/minijuegos/mezclar/motor_mezclar.tscn`, `datos/niveles/arcoiris/*/mezcla_estrella.json`.
  - Pinta con Coco: `scripts/motores/lienzo_libre/motor_lienzo_libre.gd`, `lienzo.gd`,
    `sticker_vivo.gd`, `escenas/minijuegos/lienzo_libre/motor_lienzo_libre.tscn`, `pinta_*.json`.
  - Lluvia de colores: `scripts/motores/clasificar/motor_clasificar.gd`, `gota_clasificar.gd`,
    `charco_clasificar.gd`.
- **Método**: lectura de código y escenas, con medidas en px lógicos sobre la base de 1280×720. No
  ejecuté las escenas, así que los tiempos salen de las constantes y los tweens del código.
- **Perfil que manda en cada pantalla**: el mapa lo usan los tres, así que se audita para Maxi (96 px).
  Los botones del reto dorado, la pista, el espejo y el taller de mezclas son solo de Sofía (64 px).
  Las láminas y los stickers se auditan para el perfil que los recibe.

---

## Veredicto: **RECHAZADA**

La tarjeta no cierra por **1 hallazgo bloqueante**, R1: hay una mariposa en la ruta de Nicole, y a
Nicole le dan miedo los bichos. La corrección es trivial y sale de los datos. Además quedan
**5 hallazgos mayores**. Tres son trampas de interacción en el reto real de Sofía: tocar una pieza
puesta la saca del marco, elegir una pieza para el espejo la gira, y un toque puede tomar la pieza
de al lado. El frasco del taller se vacía entero con una sola gota equivocada, y también hay
mariposas en la ruta de Sofía. Hay **11 menores**.

Lo que está bien:

- **Mapa**:
  - Los hitos de zona tienen una zona tocable de 160×160 px, separada ≥50 px entre zonas.
  - Las tarjetas de estación miden 196×196 px, con 18 px entre ellas.
  - Volver mide 96 px, Cometa 116 px y el botón dorado 96 px.
  - Las zonas dormidas nunca muestran candado: menean, suena la voz de Coco y siguen tocables.
  - Salir es seguro, porque el progreso se deriva de `Progreso`.
  - Cometa lleva a Maxi a la siguiente estación con un solo toque (riesgo 5 de la ficha).
- **Lluvia de colores (clasificar)**:
  - Los charcos miden ≥130 px incluso con 6 colores.
  - La gota tiene un radio tocable mínimo de 48 px.
  - La derrota-gag de Nicole (Coco estornuda un arcoíris) conserva las gotas, y Coco regala un
    acierto tras 2 derrotas.
  - El reloj amable de Sofía solo afecta las estrellitas.
  - En este motor no encontré hallazgos nuevos.
- **Pinta con Coco**: no hay fallo en ningún perfil. Las herramientas miden 96 px para Maxi y 90 px
  para el resto, y la bolsa de stickers usa botones de 88 px.

---

## Hallazgos

### Bloqueantes

**R1. Hay una mariposa en la ruta de Nicole (Formas traviesas, zona 3).**
`datos/niveles/arcoiris/zona3_chupetines/formas_brote.json:258` (`"id": "mariposa"`, en el pool de rondas).
La tabla de la ficha la incluye en `docs/fichas/planeta-arcoiris-zonas.md:216`. `docs/perfil-jugadores.md:57`
y `:88` dicen que a Nicole le dan miedo los bichos y los prohíben "en ningún nivel, fondo o
transición donde juegue Nicole". La misma ficha ya había cambiado la mariposa en Pinta por esa
razón (§3.4, Z4). Viola la regla "nada asusta" y el perfil.
**Corrección**:
- Sacar `mariposa` del pool Brote de la zona 3 y reemplazarla por una figura de sus gustos, como
  pony, corona o gatito con moño. `herramientas/figuras_formas.py` ya tiene varias.
- Regenerar con `--escribir` y corregir la fila 3 de la tabla de la ficha.
- Agregar al validador de `figuras_formas.py` una lista negra de bichos para los perfiles
  `brote` y `estrella`, para que no vuelva a pasar.

### Mayores

**R2. Hay mariposas en los murales del taller de pinturas de Sofía.**
Aparecen en:
- `scripts/motores/mezclar/motor_mezclar.gd:61`: `DIBUJOS_MURAL` incluye `"mariposa"` como valor por defecto.
- `motor_mezclar.gd:1063` y `:1101`: las regiones de ese dibujo.
- `datos/niveles/arcoiris/zona2_charcos/mezcla_estrella.json:29`.
- `datos/niveles/arcoiris/zona5_cima/mezcla_estrella.json:40`.

`docs/perfil-jugadores.md:116` y `:144` dicen que Sofía siente rechazo por los bichos (no es fobia) y
piden "evitar arañas y bichos en cualquier nivel donde ella juegue".
**Corrección**: sacar `mariposa` de `DIBUJOS_MURAL` y de los dos niveles. En su lugar, usar dibujos
de sus gustos: pony, gatito cachorro, corona o un corazón kawaii al estilo de My Melody, sin copiar
IP. Lo mismo vale para cualquier dibujo nuevo del motor.

**R3. En el reto dorado 6×10, tocar un pentominó ya puesto lo saca del marco, lo gira y lo manda a la bandeja.**
`motor_encajar.gd:922-931` (`_al_tomar`) llama a `_quitar_colocada` apenas se presiona una pieza
puesta en modo `marco`, y `pieza.liberar()` deja `colocada = false`. Cuando el dedo se levanta sin
moverse, `_al_tocar_pieza` (`:1020-1039`) ya no ve la pieza como puesta. Por eso no entra en la rama
del "saltito" de `:1024-1028`, que queda como código muerto, sino que la **gira 90°** y
`volver_a_casa()`. Un toque accidental sobre una pieza bien puesta deshace el avance de Sofía y le
cambia el giro, cuando justo ella "se frustra y llora rápido". El comentario de `:1025` dice que
debería pasar lo contrario.
**Corrección**: en `_al_tomar`, no liberar la pieza al presionar. Hay que liberarla recién en
`_al_mover`, cuando el arrastre supera `UMBRAL_TOQUE_PX`. Así un toque sin movimiento sobre una
pieza puesta solo da el saltito, como promete `:1024`.

**R4. Para usar el espejo hay que elegir la pieza, y elegirla con un toque la gira.**
`motor_encajar.gd:1031-1039`: el toque llama a `_elegir(pieza)` y enseguida, con
`rotacion_por_toque`, gira la pieza 90°. Para espejar sin girar, Sofía tendría que arrastrar la
pieza un poco y soltarla fuera del marco, un camino que nadie le explica, o dar 3 toques más para
devolverla a su giro. `espejo_sin_pieza` (`:1605-1608`) solo avisa cuando no hay ninguna pieza elegida.
**Corrección**, con una de dos opciones:
- (a) Con `boton_espejo` activo, el primer toque sobre una pieza no elegida solo la elige, con un
  halo y un sonido. Recién los toques siguientes sobre la pieza ya elegida la giran. No es un doble
  toque cronometrado, porque cada toque tiene su propio efecto inmediato.
- (b) Mantener tocar = girar y **mostrar el espejo sobre la propia pieza elegida**: un mini botón
  de 64 px pegado a ella mientras está en la bandeja, así no hace falta elegirla aparte.

En cualquiera de las dos, la voz de la intro del reto dorado debe explicar el gesto.

**R5. En la bandeja, el círculo tocable de una pieza delgada le roba el toque a la pieza vecina.**
`pieza_encajar.gd:129-133`: `_has_point` acepta el polígono agrandado (`MARGEN_TOQUE` 14 px) **o**
un círculo de 48 px de radio alrededor del centro. En las bandejas a escala real de Sofía hay piezas
de 22-28 px de ancho, como las columnas de la iglesia de Castro o los pilotes de los palafitos. Ahí
el paso entre centros es de unos 50 px (`_medida_bandeja` +12 y `RELLENO_BANDEJA` 16), así que los
círculos se tapan entre sí. Godot entrega el toque al nodo que está arriba: si Sofía toca el dibujo
visible de la pieza A y la pieza B está encima, se levanta B. Es tomar una pieza que no quería justo
en el reto de "distinguir tamaños parecidos".
**Corrección**: resolver el toque en dos pasadas desde el motor, o desde el tablero con `_input`.
Primero, cualquier pieza cuyo **polígono** contenga el punto. Solo si ninguna lo contiene, la de
**círculo** más cercano. Una alternativa es subir `RELLENO_BANDEJA` para que el paso entre centros
sea ≥96 px cuando haya piezas con lado menor de 48 px.

**R6. Una sola gota equivocada vacía el frasco entero del taller de pinturas.**
`motor_mezclar.gd:438-458`: `_ensuciar` llama a `_vaciar_frasco`, y `_capas.clear()` borra también
las gotas **correctas** ya atrapadas. Las recetas de las zonas 4 y 5 piden 3 o 4 gotas (café,
turquesa, verde oliva, chocolate). Hay 3 gotas en el aire a la vez, un 50 % inútiles, una gris del
12-20 % y una caída de 130-145 px/s. En ese contexto, perder 3 gotas buenas por una que cayó donde
estaba el frasco castiga de más a una jugadora que se frustra rápido. El gag del "¡puaj!" está muy
bien. Lo que duele es perder lo que ya había logrado.
**Corrección**: con el "¡puaj!", **solo la gota equivocada salta fuera del frasco**, y las capas
correctas se quedan. El fallo sigue contando para las estrellitas, así que el reto no baja. Si se
quiere conservar el vaciado total como regla de dificultad, que empiece recién en la zona 5 y se
decida en el playtest.

### Menores

**R7. El botón dorado del mapa tapa la estrella de "completada" y se mete debajo de la tarjeta vecina.**
`mapa_planeta.gd:421`: `dorado.position = (LADO_TARJETA - 70, -34)` con 96 px de lado ocupa x 126…222
de una tarjeta de 196 px. Sobresale 26 px, y el hueco entre tarjetas es de 18 px, así que invade
8 px de la tarjeta siguiente. Esa tarjeta se dibuja encima y se queda con los toques de esa franja.
Además tapa por completo la estrella de completada, dibujada en (166, 30) con radio 24 en `:993`.
**Corrección**: centrar el botón dorado sobre el borde superior de la tarjeta, en
`position = (LADO_TARJETA/2 - 48, -56)`. Así queda dentro del ancho de su tarjeta, sin invadir la
vecina, y la estrella de completada vuelve a verse.

**R8. Entrar al reto dorado suena igual que entrar al juego normal.**
`mapa_planeta.gd:678-699`: `_tocar_dorado` llama a `lanzar_estacion(..., 0.0, true)`, y eso
reproduce `juegos.<juego>.voz`, la misma voz de la tarjeta normal. Sofía no sabe qué abrió hasta
que carga la escena.
**Corrección**: agregar una voz `voces.dorado_entrar` ("¡El reto dorado! Solo para expertas...") y
usarla cuando `dorado == true`, con un destello dorado en el botón.

**R9. El botón dorado del mapa no reacciona al apretarlo.**
`mapa_planeta.gd:416-446`: el `Button` dorado solo cambia de tono en `pressed` y la acción ocurre al
soltar. Los demás botones del mapa sí hacen el aplastado inmediato en `button_down` (`:557-560`).
Falla la regla 5 de §6 (<100 ms con animación).
**Corrección**: conectar el mismo tween de `button_down` que usa `_boton()`, con escala 0.9 y
rebote, y sumar `SFX_TOQUE` al presionar.

**R10. La paleta numerada de los mosaicos de 7 colores queda a 4 px de Cometa.**
`motor_lienzo_libre.gd:559-568`: con el mosaico, la paleta va en 1 columna. Con 7 colores,
`alto = clamp((490 - 48)/7, 64, 96) = 64`, lo que da un total de 7×64 + 6×8 = 496 px desde y = 84 y termina en y = 580. Cometa empieza en
y = 584 (`motor_lienzo_libre.tscn`, `boton_cometa`). Pasa en los mosaicos de las líneas 323, 456 y
490 de `zona2_charcos/pinta_estrella.json`.
**Corrección**: con más de 6 colores de mosaico, usar 2 columnas de 99 px de ancho, que superan
los 64 px, o bajar la separación a 4 px y limitar el total a `RECT_PALETA.size.y - 24`.

**R11. En la barra de edición del sticker, "borrar" queda a 8 px de "agrandar", sin forma de deshacer.**
`motor_lienzo_libre.gd:1255-1287`: Nicole tiene botones de 72 px y Sofía de 64 px, separados por
`sep = 8.0`. Borrar va al final, justo al lado del botón de agrandar. Un toque corrido borra el
sticker sin vuelta atrás. No es grave, porque volver a estampar es fácil, pero es fricción evitable
a los 5 años.
**Corrección**: separar "borrar" del resto con ≥24 px y un color distinto (ya es rosado), o
agregar un "deshacer" que devuelva el último sticker borrado durante 3 s.

**R12. La pista de Sofía cobra una estrellita sin avisar antes del primer uso.**
`motor_encajar.gd:1472-1478`: el primer toque ya descuenta. `pista_usada` suena **después**. Si la
intro no lo dice, se entera cuando ya perdió la estrellita, y eso puede picarla.
**Corrección**: que la intro de Sofía de cada motor con pista de pago (encajar, clasificar,
mezclar con la libreta) diga en una frase que la estrella dorada ayuda pero cuesta una
estrellita. No se pide confirmación, para no introducir un doble toque.

**R13. Riesgo latente: las medallas de ronda pueden quedar sobre el botón de pista.**
`motor_encajar.gd:372-389`: las medallas van de x 976 a 1266 con `z_index` 30. El botón de pista
está en x 1164-1260 (`:2134`). Hoy Sofía juega 2 rondas, así que la 2.ª medalla termina en x 1112
y no se tocan. Con 3 o más rondas, la 3.ª queda centrada en x 1152 y se dibuja encima de la pista.
**Corrección**: cuando la pista está visible, anclar las medallas a la izquierda de x 1150, o
bajar la pista a (1164, 120).

**R14. Tocar a Cometa en el mapa no repite la instrucción, como pide la regla 2 de §6: lanza un juego.**
`mapa_planeta.gd:663-675`. La decisión está justificada por el riesgo 5 de la ficha (Maxi) y en el
mapa la instrucción la repite Coco (`:654-659`). El problema es que en todas las demás pantallas
Cometa repite, y aquí "hace otra cosa".
**Corrección**: dejarlo, pero registrar la excepción en GDD §6.2 ("en los mapas, Cometa lleva al
siguiente juego; Coco repite"). Además, que `cometa_vamos` diga el nombre del juego antes de
lanzarlo, así el niño entiende qué pasó.

**R15. F4 abre todo el mapa y se queda activo mientras dure la sesión, también en la tablet.**
`mapa_planeta.gd:64` y `:139-146`: la variable es `static var todo_abierto` y no se limita a
depuración. Con un teclado Bluetooth, o si el PO la olvida activa, los niños verían todas las zonas
abiertas y los retos dorados disponibles (`:189`).
**Corrección**: envolver el atajo con `if OS.is_debug_build():` y reponer `todo_abierto = false` al
volver al Mapa Estelar.

**R16. Falta verificar que el sonido de "zona dormida" sea suave.**
`mapa_planeta.gd:36` y `:629`: la zona dormida usa `sfx/ui/no_es_este.ogg`. El GDD pide que el
"todavía no" nunca suene feo. No pude escucharlo.
**Corrección**: si es un buzzer o un tono descendente seco, cambiarlo por un "bloop" suave o por
unas campanitas de sueño, que calzan con los "zzz" de la carita dormida.

**R17. La Lluvia de Sofía ya no es el motor `clasificar`, y la ficha de zonas sigue describiéndola así.**
`datos/planetas/arcoiris/mapa.json:60-65`: `escenas.sofia` = `motor_mezclar.tscn` con el ícono
`taller`. En cambio, `docs/fichas/planeta-arcoiris-zonas.md` §3.1 (tablas y notas del 27-Sep)
describe las mezclas de Sofía dentro de `clasificar`. No es un problema del niño, pero las próximas
auditorías y el playtest se harán con la ficha equivocada.
**Corrección**: devolverla a `disenador-niveles` y `disenador-mecanicas` para que actualicen §3.1
con una remisión a `docs/fichas/motor-mezclar.md`.

---

## Qué verificar en el playtest (no son hallazgos)

- **Maxi en el mapa**: ¿descubre solo que Cometa lo lleva a jugar? ¿Toca las zonas dormidas una y
  otra vez? Si insiste, alargar la voz de Coco.
- **Sofía en el reto dorado**: con R3 a R5 corregidos, medir si el imán de 60 px y las piezas de la
  bandeja a ~0,53 de escala (celdas de ~29 px) le alcanzan para distinguir los pentominós.
- **Sofía en el taller**: velocidad de 145 px/s y receta visible solo 6 s en la zona 5. Si llora, se
  baja la zona (ficha §6.4), nunca la celebración.
- **Nicole en la zona 3 de Formas**: confirmar que ya no queda ningún bicho después de R1.

## Resumen de severidades

- **Bloqueantes: 1**. R1: mariposa en la ruta de Nicole (Formas, zona 3). **Impide cerrar HE-40.**
- **Mayores: 5**:
  - R2: mariposas en los murales de Sofía.
  - R3: tocar una pieza puesta la saca del marco.
  - R4: elegir una pieza para el espejo la gira.
  - R5: el círculo tocable roba el toque a la pieza vecina en la bandeja.
  - R6: el frasco se vacía entero por una gota.
- **Menores: 11**, de R7 a R17.
