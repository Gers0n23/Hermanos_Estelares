# Validación UX — HE-60: reto real en Parejas de Coco (racha, vistazo, vela, récord y estrellitas de Nicole)

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 07-Oct-2026
- **Objeto auditado** (pantalla implementada):
  - Spec: `docs/fichas/motor-emparejar.md` §10, §10.1, §10.1.1, §10.2 y §10.10 (implementación de
    `dev-godot`).
  - Código: `scripts/motores/emparejar/motor_emparejar.gd`, `carta_emparejar.gd`,
    `scripts/ui/celebracion.gd`, `barra_record.gd`, `racha_cresta.gd`, `vela_cupcake.gd`,
    `dibujo_cupcake.gd`; `scripts/base/minijuego_base.gd` (`_estrellitas_visibles`, récord) y
    `scripts/nucleo/mapa_planeta.gd` (estrellitas de Nicole en el mapa).
  - Datos: los 15 `datos/niveles/arcoiris/zona*/parejas_{semilla,brote,estrella}.json` (bloques `puntaje`,
    `vistazo`, `umbrales_puntaje`).
  - Capturas del dev (7): `nicole_inicio`, `nicole_record_pasa`, `nicole_record_final`,
    `nicole_celebracion`, `sofia_vistazo`, `sofia_racha4`, `sofia_vela_dormida`.
- **Contra qué**: GDD §6 (10 reglas), GDD §5 ("reto real"), `docs/perfil-jugadores.md`, la validación de
  HE-58 (M6, M7, m6, m10) y la regla de oro 2 del proyecto (Maxi suave; Nicole y Sofía con reto).
- **Escala usada**: bloqueante / mayor / menor (pedida para esta tarjeta).

---

## Veredicto: APROBADA CON CAMBIOS (1 bloqueante, 3 mayores, 7 menores)

La implementación es fiel a la ficha y, en lo que más importaba, está bien resuelta:

- **Maxi no ve presión**: con `mostrar: "solo_sonido"` y el corte por perfil
  (`_con_barra = ... and perfil != "semilla"`), no tiene número, barra, vela, vistazo ni "+N". Solo la
  cresta y el "ding" que sube de tono.
- **La barra no tapa cartas**: el tablero termina en x 1130 (`ZONA_TABLERO`) y el tubo de la barra está
  en x ≈ 1193-1227 (`Rect2(1168, 172, 84, 396)`). Quedan 63 px libres. Termina en y 568, 17 px sobre
  Cometa, pero la barra no es tocable (`MOUSE_FILTER_IGNORE`), así que no le roba toques.
- **Los "+N" nacen sobre las cartas ya destapadas del par** (m10). Se confirma en `sofia_racha4` y
  `nicole_record_pasa`.
- **La vela cumple M7 al pie de la letra**: mide 78 px, no tiene tic-tac, no parpadea, no cambia de
  color, no acelera y está fuera del tablero. Se pausa en el vistazo, en la mini-fiesta y en la
  derrota-gag. En Nicole solo aparece con récord previo y desde la zona 2 (zona 1 con
  `tiempo_par_s: null`, verificado en los datos).
- **El vistazo tiene las cantidades de M6**: Nicole ve 1 par con ≤ 10 cartas y 2 pares con 12-16, en
  3 s. Sofía ve `round(cartas/4)` cartas sueltas sin repetir grupo, en 2 s (`sofia_vistazo`: 6 de 24). No
  se puede saltar.
- **Las estrellitas de Nicole siguen el §10.1.1**: puntaje base sin la vela, mínimo 1, la celebración y
  el mapa sin huecos vacíos (`estrellitas_sin_huecos`, `mapa_planeta.gd` l. 1149-1153), y la misma
  animación para la 1 y para la 3.
- **El corte de racha no castiga**: no resta puntos, los nuditos se apagan de a uno y el contador se
  desvanece.

**HE-60 no puede cerrarse con B1 abierto.** Para cerrar alcanza con el respaldo de código que propone
B1. Las voces mismas pueden llegar con HE-67, pero **ningún playtest con los niños sin ellas**. Los
mayores M1-M3 son de código, cortos, y conviene corregirlos antes del playtest (HE-64).

---

## Hallazgos bloqueantes

### B1. Las mecánicas nuevas aparecen sin voz: la vela se presenta y se apaga en silencio

**Dónde**: no existe la carpeta `assets/audio/voces/arcoiris/emparejar/reto/` (HE-67 pendiente). El
motor tiene respaldos solo para la racha, "¡a la primera!" y las estrellitas de Nicole (§10.10). Todo lo
demás queda mudo:

- `vistazo_presenta` y `vistazo_mira`: las cartas se dan vuelta con un destello y sin el "¡mira!";
- `vela_presenta`: la vela aparece y se consume sin que nadie diga qué es;
- `vela_dormida`: la llama se apaga con `soltar.ogg` a pitch 0,6 (`_avanzar_vela`, l. 1538), sin la frase
  positiva de Coco que exige M7.3;
- `record_pasa`, `primer_record` y `record_nuevo`: solo confeti y SFX;
- `otra_estrellita`: muda.

**Por qué es bloqueante**: viola GDD §6.2 ("ninguna instrucción depende de saber leer": la vela es una
regla nueva y nadie la explica) y §6.5/§1 (el error o la pérdida nunca en silencio ni con un sonido feo).

- Nicole (5) ve un cupcake con una vela que se achica y no sabe si eso es bueno o malo. Es justo la
  ansiedad que M7 quería evitar.
- Sofía (8, se frustra rápido) ve morir la vela en silencio con un sonido grave: lo va a leer como "perdí
  algo".

**Corrección**:

1. **Respaldo de código (condición para cerrar HE-60)**: si no existen los wav de `vela_presenta` **y**
   de `vela_dormida`, el motor trata el nivel como `tiempo_par_s: null` y no muestra la vela. Una regla
   que no se puede explicar por voz no se muestra. Es un `if` en `_preparar_reto()` con `_voz_existe()`.
2. **Condición para el playtest (HE-64)**: HE-67 entrega como mínimo `vistazo_presenta`, `vistazo_mira`,
   `vela_presenta`, `vela_dormida`, `record_pasa`, `primer_record`, `record_nuevo_01/02` y
   `estrellitas_brote_1..3`. Sin el "¡mira!", Nicole no sabe que el vistazo es para memorizar, y eso deja
   sin sentido la ayuda de M6.
3. Mientras tanto, el `scrum-master` registra HE-67 como dependencia del playtest de HE-60.

---

## Hallazgos mayores

### M1. La barra se re-escala: la banderita del récord se mueve y el relleno "baja" después de un acierto

**Dónde**: `barra_record.gd`, `fijar_puntaje()` (l. 52-53): `if valor > tope * 0.92: tope = valor * 1.25`.

**Problema**:

- Cuando el puntaje pasa el 92 % del alto, el tope crece un 25 %. En el mismo cuadro, **la banderita
  baja** (su altura depende de `tope`) y el relleno, que estaba al 92 %, se dibuja al ≈ 74 % antes de
  que el tween suba al 80 %.
- Visto por una niña de 5 años: **formé un par y la barra bajó, y mi banderita se movió**. Contradice la
  regla "un fallo nunca resta puntos" (acá ni siquiera hubo fallo) y rompe la única referencia del
  récord que Nicole puede leer sin números, que es la altura.
- Las capturas son consistentes con esto: la banderita está en y ≈ 375 en `nicole_record_pasa` y en
  y ≈ 445 en `nicole_record_final`.
- Pasa justo en las mejores partidas (récord superado con margen) y también al cobrar la vela
  (`_cobrar_vela` sube la barra en 8 pasos).

**Corrección**:

1. **El tope se fija una sola vez por partida** en `preparar()` y no cambia más. Se calcula como
   `max(record × 1.3, tope_sugerido)`. El `tope_sugerido` incluye el bono máximo realista de la vela
   (`tiempo_par_s × bono_por_segundo × 0.5`) cuando hay vela.
2. **Si el puntaje supera el tope, la barra rebalsa en vez de re-escalar**: el relleno queda al 100 % y
   del borde de arriba salen burbujas arcoíris con un "blup" alegre en cada par siguiente. La banderita
   no se mueve nunca durante la partida.
3. `tester-qa`: caso "puntaje = 1,5 × tope", en el que la altura de la banderita debe ser la misma al
   principio y al final.

### M2. El vistazo se superpone a la voz de Coco y, en las rondas 2 y 3, siempre llega sin el "¡mira!"

**Dónde**: `_hacer_vistazo()` (l. 1312-1328) y `_iniciar_ronda()` (l. 1010-1013).

**Problema**:

- Solo la **primera vez** de cada hermano se espera a que Coco termine de hablar. Desde la segunda vez,
  el vistazo arranca ≈ 0,5-1 s después del reparto, y el "¡mira!" se omite si Coco está hablando.
- En cada ronda nueva, `_iniciar_ronda()` reproduce `intro_ronda` y enseguida llama a
  `_arrancar_tablero()`. Por eso el vistazo de las rondas 2 y 3 cae **siempre** encima de la consigna, y
  **siempre** sin "¡mira!".
- Nicole tiene una memoria de trabajo de ≈ 3 elementos: si escucha una consigna mientras ve 2 o 4 cartas
  durante 3 s, no retiene ninguna. A Sofía le pasa lo mismo con 6-9 cartas en 2 s, y para ella el
  vistazo es parte del reto: que dependa de si Coco calló es injusto.

**Corrección**: en `_hacer_vistazo()`, esperar **siempre** a que Coco termine de hablar
(`await _esperar_voz(SEGUNDOS_ESPERA_INTRO)`), no solo la primera vez, y reproducir siempre `vistazo`
("¡mira!") justo antes de dar vuelta las cartas. La espera suma ≈ 2 s por ronda: es tiempo bien gastado.

### M3. La vela corre mientras Coco presenta la vela, mientras habla y cuando el niño pide ayuda

**Dónde**: `_arrancar_tablero()` (l. 1289-1299) y `_avanzar_vela()` (l. 1531).

**Problema**:

- `_encender_vela()` se llama **antes** de los `await` de `otra_estrellita` y de `vela_presenta`. La
  primera vez que Nicole ve la vela, **la vela ya se está consumiendo mientras Coco le explica qué es**.
  El mensaje implícito es "apúrate", lo contrario de M7.
- La vela tampoco se detiene cuando el niño toca a Cometa para que le repita la instrucción
  (`_al_tocar_cometa`) ni cuando Sofía abre el globo de la pista. **Pedir ayuda cuesta tiempo**, y eso
  castiga justo la conducta que GDD §6.2 quiere fomentar.
- En Sofía la vela es ajustada (≈ 1,1 × mediana): unos segundos perdidos así deciden si se gana el bono.
- Tampoco se pausa al perder el foco de la app (`NOTIFICATION_APPLICATION_FOCUS_OUT` o `PAUSED` en la
  tablet).

**Corrección**:

1. Llamar a `_encender_vela()` **después** de las voces de presentación (`otra_estrellita`,
   `vela_presenta`) y de la consigna (`_esperar_voz`).
2. Agregar a la condición de pausa de `_avanzar_vela()` dos casos: "Coco o Cometa dicen una instrucción
   pedida por el niño" (desde `_al_tocar_cometa` hasta que termina la voz) y "el globo de la pista está
   abierto".
3. Pausar en `NOTIFICATION_APPLICATION_FOCUS_OUT` y `NOTIFICATION_APPLICATION_PAUSED`.

---

## Hallazgos menores

- **m1. Los toques durante el vistazo no suenan** (GDD §6.5, "animación **y** sonido"). `pulso_espera()`
  solo escala la carta. **Corrección**: en la rama `_en_vistazo` de `_al_tocar_carta`, sumar
  `reproducir_sfx(SFX_TOQUE, 1.0)` a volumen bajo, con un enfriamiento de 150 ms por carta para que un
  manotazo no haga ruido en ráfaga.
- **m2. El "puf" de la vela y el "fiuu" del corte de racha son `soltar.ogg` a pitch 0,6 y 0,75.** Un
  sonido más grave que el normal se lee como un "wah-wah" de derrota, y la ficha pide "puf suave" y
  "fiuu" **sin sonido de error**. **Corrección**: SFX propios cortos (un soplido y un silbido
  descendente suave) a pitch ≥ 1,0, o como mínimo `toque.ogg` a pitch 1,0 con volumen bajo.
- **m3. La vela de Sofía casi no se lee**: la cera va de 18 a 4 px de alto (`alto_vela := 4.0 + 14.0 ×
  fraccion`), un recorrido de 14 px. Para Nicole está bien que sea discreta. Para Sofía la vela es parte
  del reto real, y tiene que poder leerla de un vistazo. **Corrección**: subir el recorrido a ≈ 30 px
  (por ejemplo `6 + 30 × fraccion`) achicando el cupcake, sin pasar los 80 px de alto total y sin color
  ni parpadeo (M7 se mantiene).
- **m4. La vela y la barra no responden al toque** (`MOUSE_FILTER_IGNORE`), y un cupcake con vela es lo
  primero que un niño de 5 años toca. GDD §6.5 pide que todo lo tocado reaccione. **Corrección**: en las
  dos, un meneo de 0,2 s y un "ding" suave al tocar, sin efecto en el juego, sin voz y con un enfriamiento
  de 1 s. La vela queda a 16 px del botón salir: el hitbox del meneo no puede crecer hacia arriba.
- **m5. La estela dorada de "¡a la primera!" cruza cartas tapadas** (`nicole_record_pasa`: atraviesa dos
  cartas tapadas de la fila de arriba durante 0,8 s), y el trébol vuela a (120, 168), encima de la vela.
  No es un número, pero es el mismo riesgo que m10: tapa información del tablero. **Corrección**: dibujar
  la estela como un arco que pasa **por encima** de la grilla (punto de control en y < 122) o cambiarla
  por destellos en las dos cartas. El trébol debe aterrizar junto al contador "×N" (por ejemplo en
  (120, 330)), no sobre la vela.
- **m6. A "la estrella de terminar" le falta el momento de Coco** (§10.1.1 punto 2: Coco la atrapa con la
  lengua y se la pega en la cresta). Hoy cae igual que las demás. La equidad está bien, pero ese gesto era
  la salvaguarda contra el riesgo 10 ("¿la estrellita 1 se vive como logro?"). **Corrección**: agregarlo
  cuando Nicole gane exactamente 1 estrellita, o aceptar su ausencia de forma explícita para el playtest
  de HE-64.
- **m7. Maxi ve 5 huecos grises en la cresta de Coco y escucha el "fiuu" al cortarse la racha.** No es
  presión, pero es el único sonido con connotación negativa de su ruta. **Corrección**: en Semilla, los
  nuditos apagados no se dibujan (solo aparecen los encendidos) y `_cortar_racha()` no suena: los nuditos
  se apagan en silencio.

---

## Qué sí está bien (no tocar)

- Contador "×N" desde ×2 en 64 px, dorado con borde, sobre Coco y fuera de la grilla. Ojos de estrella
  desde ×3. La voz de racha **reemplaza** a `acierto_par`.
- "¡A la primera!" solo en tableros tapados. El vistazo y la ayuda de Coco cuentan como cartas ya vistas.
- La racha sigue entre rondas, y el tiempo par vale para toda la estación (coherente con el simulador).
- El récord se guarda antes de la fiesta, el primer récord "planta" la banderita (m6) y el trofeo-cupcake
  aparece sobre Coco. Nunca se muestra el récord de otro hermano.
- La celebración de Nicole muestra solo las estrellitas ganadas, y la voz habla del logro (con respaldo
  en `victoria_final`).
- La derrota-gag de Sofía no reinicia ni el puntaje ni la vela: "no pasa nada más".

## Qué observar en el playtest (HE-64)

1. Si Nicole mira la vela más que el tablero (M7.5). La palanca es `tiempo_par_s: null` en Brote.
2. La cara de Nicole cuando gana 1 estrellita (riesgo 10). La palanca es bajar `dos`.
3. Si alguna de las dos dice "¡bajó!" mirando la barra. Si pasa, M1 no quedó bien corregido.
4. Si, después del "¡mira!", Nicole va directo a alguna de las cartas del vistazo. Eso indica que lo usa.

## Para cerrar HE-60

- **B1, punto 1** (respaldo de la vela sin voz) implementado: **condición para cerrar**.
- M1-M3 corregidos antes de HE-64 (son cambios chicos en el motor y en `barra_record.gd`).
- m1-m7: a criterio de `dev-godot` en la misma pasada. m6 puede aceptarse de forma explícita.
- `tester-qa` suma al arnés `qa_test_parejas_reto.gd` los casos de M1 (banderita fija) y M3 (la vela no
  corre durante `vela_presenta` ni con Cometa hablando).
