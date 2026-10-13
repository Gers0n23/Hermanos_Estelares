# Validación UX — La Torre de la Colección (motor `lanzar` v2) y el cierre de Arcoíris

- **Auditor**: `experto-ux-parvulo`
- **Fecha**: 13-Oct-2026
- **Qué se auditó**:
  - `docs/fichas/motor-lanzar.md` v2 (completa);
  - `docs/fichas/modo-equipo.md` §14 completo, con foco en el §14.16;
  - `docs/guiones/cierre-arcoiris.md` v3;
  - `docs/cinematicas/cierre_arcoiris.md` v3;
  - contra el GDD §1, §5 y §6, `docs/perfil-jugadores.md` y mi validación
    `2026-10-06_ux-HE-66-batalla-arcoiris.md` (en especial la regla M7, ahora anulada por el PO).
- **Alcance**: solo diseño. No se corrigió ningún documento. Las decisiones del PO del 12 y 13-Oct se
  dan por tomadas: aquí solo se evalúa cómo se ejecutan.

## Veredicto: APROBADA CON CAMBIOS (2 bloqueantes)

La Torre es una buena etapa de jefe:

- la mecánica de Angry Birds escala bien por edad;
- la torre congelada entre tiros hace que la física sea justa;
- el charco convierte cada fallo en un aporte;
- las derrotas-gag las sufre él;
- el cierre en dos bloques tiene un ritmo cuidado.

**Pero hay dos bloqueantes que impiden cerrar la tarjeta de diseño (y empezar HE-69 en la Torre y en la
partida)**:

- el storyboard v3 no está conciliado con el guion v3;
- con la regla de la resortera tal como está escrita, un toque sin arrastre gasta un globo del equipo.

| Severidad | Cantidad |
|---|---|
| Bloqueante | 2 |
| Mayor | 11 |
| Menor | 11 |

---

## Hallazgos bloqueantes

### B1. El storyboard v3 está conciliado con el guion **v2**, que el guion v3 descartó

**Dónde**:

- `docs/cinematicas/cierre_arcoiris.md`: el encabezado («conciliada con el guion v2») y los §2, §4.2,
  §5.1, §6.3, §7, §8-§12 y §21;
- contra `docs/guiones/cierre-arcoiris.md` v3, encabezado y §10.

**Problema**: el guion v3 volvió a los ids de la v1 y retiró varias líneas, pero el storyboard sigue
usando los de la v2. Además de los ids, **cambian conductas que yo audito**, y con dos specs
contradictorias Dev va a implementar una u otra:

| Tema | Storyboard v3 | Guion v3 | Impacto UX |
|---|---|---|---|
| Cuenta regresiva (§12.1) | «En cualquier orden»; los que faltan saltan solos a los **25 s**; CR0 con «¿Rugidos?» | **Un retrato a la vez**, Sofía → Nicole → Maxi; recordatorio a los 8 s y salto solo a los **20 s**; el «¿Rugidos?» se quitó | Cambia cuánto espera Maxi y si alguien puede "robarle" su número a otro |
| Tarea de Nicole (§9.4) | Toca el moño, **arrastra el ala** hasta el hueco y gira los broches | **Coco encaja el ala** (NI0) y Nicole solo gira los 3 broches | Cambia la carga motriz de Nicole y quién "instala el ala" (equidad, ver M8 y m10) |
| Despedida de Coco (§10) | Recordatorio a los 6 s; a los 15 s Coco choca con Maxi; a los 20 s abraza a las hermanas con `coco_abrazo` | Recordatorio a los 8 s; a los 20 s Coco choca ella misma con cualquiera; `coco_abrazo` retirada | Tiempos de espera distintos |
| Llamada (§11) | V3 usa `papa_02` (retirada) y V4 usa `papa_animalia` | `papa_pista` + `papa_guatita` | Otro guion y otra duración en el tramo pasivo más largo |
| Pausa antes de la Torre (§2) | Usa `arcoiris_batalla_torre_pausa` (la línea de la 3.ª derrota) | `pausa_antes`, después de la presentación | Ver M6 |
| Pausa desde la 3.ª derrota (§7.1) | Texto «¿Vamos por la torre…?» | `pausa`: «¿Vamos otra vez…? ¡La torre no se va a ninguna parte!» | Promete algo distinto |
| Caída (§4.2) | C1 `cae_mochila`; C6 `la_botaron` (retirada) o `lo_bajamos` | C1 `cae_lenta`; C6 `cae_risa` | La fiesta máxima no tiene voz en el guion |
| Antes del epílogo (§5.1) | Línea de 3,5 s → **5,4 s** | Línea de 3 s → **4,95 s** | Decisión abierta 7 |
| Gags (§7) | `traje_dos_mas` y `nucleo_equipo_lanzar_logro_1/2` | `ayuda_globos_extra` y `nucleo_equipo_cajas_botadas_01/02` | Solo ids |
| Fin de cada tarea (§9.1) | «¡Tanque listo, bombero!», «artista», «capitana» | Retirados: «¡… listo! ¡Gracias, (nombre)!» | Las frases tienen que ser iguales para las hermanas |
| Bloque 2 completo | `arcoiris_partida_*` | `arcoiris_despegue_*` | Solo ids |
| Gigante (§7.6) | «Falta `gigante_turno_maxi` y `gigante_impacto`» | Ya existen | — |

**Corrección**: `director-cinematicas` saca un **storyboard v4 conciliado con el guion v3**, que manda en
textos e ids. Al hacerlo, debe aplicar las recomendaciones de este informe:

- cuenta regresiva: decisión 6;
- tarea de Nicole: m10;
- antes del epílogo: decisión 7;
- pausa: M6.

Hasta que exista la v4, no se implementan ni el bloque 2 ni los gags.

### B2. Con la resortera, un toque sin arrastre dentro del área de agarre gasta un globo

**Dónde**: `motor-lanzar.md` §5.2 (filas "Dedo abajo", "Soltar con estiramiento < 40 px" y "Toque sin
arrastre") y §4 (área de agarre de radio 120 px).

**Problema**: hay tres reglas que se contradicen.

- Al apoyar el dedo, la bolsa **salta al dedo**.
- El estiramiento se mide desde la bolsa en reposo.
- Un toque sin arrastre debería solo "mecer" la bolsa.

Si el dedo se apoya a 40 px o más del centro, el estiramiento ya es ≥ 40 px **sin haber arrastrado**, y
al soltar hay disparo. Eso pasa en el **89 % del área de agarre** (1 − (40/120)²). Casos reales:

- **Maxi (2 años)** toca la resortera o a Coco durante el turno de Sofía. Coco está **dentro** del
  círculo de agarre, entre x 163-225 e y 454-550. Resultado: sale el globo de Sofía, que solo tiene 2
  tiros por intento, gastado por su hermano.
- **Nicole (5 años)** toca el globo "para ver", con el dedo un poco corrido, y el tiro sale sin apuntar.

En un juego donde la canasta es el reloj, ese tiro es una pérdida visible y **atribuible** («¡Maxi me
gastó el globo!»). Es justo la pelea que el modo equipo existe para evitar (R2). Además, la regla de
40 px "hacia la torre" no dice qué pasa si el dedo **se apoya** ya del lado de la torre.

**Corrección** (`disenador-mecanicas`):

1. **Solo hay disparo después de un arrastre real**: el dedo se movió **≥ 40 px desde el punto de
   contacto** *y* el estiramiento final es ≥ 40 px. Si no, se cancela con "plop" (no se gasta nada) y
   la bolsa se mece.
2. Si el contacto cae del lado de la torre (x > 260), la bolsa no salta: solo se mece, y suena el "boing"
   con la flechita fantasma de "hacia atrás".
3. **Prioridad de toques**: dentro del círculo de agarre manda la resortera. Mejor todavía: correr a Coco
   a x ≤ 120 (pies en ≈ (105, 584)) para que su dibujo no quede bajo el círculo.
4. QA: un toque corto en cualquier punto del círculo de agarre **nunca** dispara (en una grilla de 20 px
   sobre todo el círculo).

---

## Hallazgos mayores

### M1. Nicole y Sofía nunca oyen cómo se tira antes de su primer tiro

**Dónde**: guion T.1-T.2 y ficha §5.2, §8.1 y §14 (`intro_ronda`, `carga`).

**Problema**:

- La intro corta dice «¡Torrecita!» y «¡Por turnos: un globo cada uno!».
- En su turno, Nicole y Sofía solo oyen «¡Globo cargado! ¡Rojo frutilla!».
- El gesto, **estirar hacia el lado contrario del blanco**, va contra la intuición a los 5 años (R1).
- Hoy la explicación solo existe en tres lugares, y en ninguno llega antes del primer tiro:
  - si tocan a Cometa;
  - la primera vez que arrastran al revés;
  - en la línea de Maxi, que lleva su nombre («¡Un globo para Maxi! Tira para atrás…»).

El GDD §6.2 pide que toda instrucción esté narrada.

**Corrección**:

- En el **primer turno de Nicole y en el primero de Sofía de cada sesión de Torre**, después de `carga`,
  suena `lanzar_repetir` en versión corta, sin la meta del resbalón: «¡Estira para atrás, apunta… y
  suelta!» (≤ 3 s, línea nueva del `guionista`).
- Mientras suena, **una manito fantasma** hace una vez el gesto desde la bolsa hacia atrás (0,8 s).
- **No bloquea**: si la niña empieza a arrastrar, la voz y la manito se cortan.

### M2. El tiro tiene que ser el que mostró el anillo (estabilizador)

**Dónde**: ficha §5.2 (el vector de tiro es el promedio de los últimos 80 ms) y §5.4 (el anillo de
impacto de Nicole).

**Problema**:

- Al levantar el dedo, un niño de 5 años lo **desliza** unos milímetros, casi siempre hacia adelante, y
  el centroide del contacto se corre 20-40 px lógicos.
- Promediar los últimos 80 ms **incluye ese desliz**.
- Con la sensibilidad que la propia ficha calcula (1 px ≈ 11 px de impacto), el globo cae lejos del
  anillo que Nicole veía al soltar.
- Para ella, que apuntó con la guía, eso no es reto: es "¡hizo trampa!".

**Corrección**: el vector de tiro es el del **último cuadro en que el dedo estaba quieto** (velocidad
< ≈ 150 px/s), descartando los 60 ms anteriores al `release`. **El anillo dibujado en ese cuadro es el
tiro que sale.** QA: el impacto real cae a ≤ 10 px del último anillo mostrado (los mismos cuerpos
congelados, sin otra física de por medio).

### M3. El tambaleo y el "agarre" se dibujan donde la física no está

**Dónde**: ficha §6.2.2 (tambaleo del sprite de ±1,5° a ±4°), §6.6 (el Coleccionauta se corre 60 px y el
trono se inclina hasta 18°, "solo en el sprite") y §6.1 (el `Area2D` del golpe directo).

**Problema**:

- Con una torre de 434 px, un tambaleo de ±4° corre la cima **± 30 px** respecto de los cuerpos
  congelados.
- La guía de Nicole (`intersect_ray` contra los cuerpos) y los choques reales ocurren donde el dibujo
  **no está**.
- Si el `Area2D` del Coleccionauta no sigue al sprite corrido, un globo que le pega en la cara no cuenta
  como golpe directo.
- Sofía, que apunta sin guía a un punto débil de 40 px, lo va a notar: «¡le pegué y no pasó nada!».
  Es R8, pero causado por el propio diseño.

**Corrección**:

1. **Los bloques no tambalean** mientras alguien apunta ni durante el vuelo. El tambaleo vive en el rig
   del Coleccionauta y del trono, como mucho ±1° en el resto, y vuelve a 0° en 0,2 s al empezar el
   arrastre.
2. **El `Area2D` sigue al sprite** del Coleccionauta, con su desplazamiento de hasta 60 px.
3. **La inclinación del trono** se aplica también a la pose del cuerpo congelado, o se limita a ±6° en
   el sprite.
4. QA: con la torre en el estado "colgando de un dedo", el anillo de Nicole cae sobre el dibujo del
   bloque que va a tocar.

### M4. Nicole tira 3 globos y Sofía 2, y el último globo de los intentos 1 y 2 es siempre de Nicole

**Dónde**: ficha §8.1, §10.2-§10.3 y §15.2 (orden `maxi_intercalado` con 10 y 12 globos). Decisión
abierta 4.

**Problema**:

- Con M → N → M → S y 10 globos, el 1er intento es **M5, N3, S2**.
- Los globos se ven y se cuentan, y Sofía es la que mejor cuenta.
- Sofía "siente celos de Nicole" (`perfil-jugadores.md`), y la regla del perfil es "recompensas siempre
  equivalentes, sin comparaciones". Que "sus tiros valgan más" es una justificación de adulto: lo que se
  ve es un turno menos.
- Peor todavía, el último turno es de Nicole en los dos primeros intentos:
  - el último globo del intento 1 es el turno 9 (9 mod 4 = 1 → **Nicole**);
  - el del intento 2 es el turno 21 (→ **Nicole**).
- Así, en el ≈ 66 % de las familias que pierden al menos una vez, **la derrota llega siempre después de
  un tiro de Nicole**, precedido además por «¡El último globo… con todo el cariño!».
- Es la receta exacta de R4: «perdimos por Nicole». La derrota en el pase no lo compensa, porque el
  último tiro se ve.

**Corrección** (es mi recomendación a la decisión 4):

- Mantener `maxi_intercalado`, pero con **9 globos de base y +4 tras la 1.ª derrota** (13), y **forzar
  que cada intento empiece con Maxi** (`reiniciar_rival(forzar_id)`, que ya existe).
  - Cada intento queda M N M S M N M S M (+ N M S M): **Nicole = Sofía siempre** (2 y 2; 3 y 3).
  - **El último globo es siempre de Maxi**, cuyo tiro bota algo seguro: la derrota nunca sigue a un
    fallo de nadie, y `ultimo_globo` («con todo el cariño») le queda tierno a él.
- El gigante sigue siendo el primer globo de cada intento ≥ 3.
- `disenador-niveles` recalibra `agarre` y `conservar_dano` con el simulador para mantener el 30-40 % y
  el ≥ 95 %.
- `ayuda_globos_extra` dice «dos globos más»: pasa a «¡más globos!», sin número.

### M5. Si Maxi deja el dedo apretado, su globo nunca sale y el turno queda colgado

**Dónde**: ficha §5.3 («al soltar, sale el tiro»; `semilla_auto_s` cuenta "sin ningún toque") y guion
T.2 (`maxi_globo_01`: «Tira para atrás... ¡y suelta!»).

**Problema**:

- A los 2 años, "tocar" muchas veces es **apretar y quedarse mirando**.
- Un niño de 2 años no conoce el concepto de "soltar para que pase".
- La instrucción «tira para atrás» invita a apretar y arrastrar.
- Mientras el dedo está abajo no corre `semilla_auto_s`, porque hay un toque: el turno puede quedar
  esperando indefinidamente, con las hermanas mirando.

**Corrección**:

1. En el turno de Maxi, si el dedo sigue abajo **1,2 s**, el globo sale solo, como si hubiera soltado.
   La goma ya está estirada, así que se siente "suyo".
2. La línea de Maxi debe pedir algo que él entienda: «¡Maxi, toca… y suelta!» o «¡Maxi, toca el globo!»
   (`guionista`). «Tira para atrás» queda para Nicole y Sofía.
3. QA: con el dedo abajo y sin moverse, el tiro sale a los 1,2 s ± 0,1 s.

### M6. La pausa antes de la Torre está en dos lugares distintos según el documento

**Dónde**:

- ficha §13.3: la pausa va en el mapa de batalla, **antes** de la presentación T.1;
- guion T.1: `pausa_antes` va **después** de la presentación, "no avanza sola";
- storyboard §2: va en el mapa, con la línea de la 3.ª derrota.

**Problema**: si Dev suma lo que dicen los tres documentos, hay **dos "¿seguimos o descansamos?"
seguidos**:

1. el toque del hito;
2. la presentación;
3. otra pausa con toque.

Además, ofrecer descansar **justo después** de mostrar el reto ("¡aquí está la torre!") hace que
descansar se sienta como rendirse.

**Corrección**: **una sola pausa, en el mapa de batalla, antes de T.1**, igual que entre las rondas 1-2
y 2-3 (un mismo patrón, M1.2 de HE-66), con la voz `pausa_antes`.

- La presentación arranca al tocar el hito y sigue directo a la intro.
- `guionista` ajusta el contexto de `pausa_antes` y `director-cinematicas` lo refleja en la v4 (B1).

### M7. En el gag 1, el rival celebra durante 5 s que "no lo botaron"

**Dónde**: guion T.7 (`derrota_1_coleccionauta`, 6 s) y storyboard §7.2 (G1b: el frasco se da vuelta en
el segundo paso, cerca del final).

**Problema**:

- La 1.ª derrota es la más frecuente (≈ 66 % de las familias la ven) y es la primera vez que Sofía pierde
  contra el jefe, después de 15 minutos de batalla.
- «¡No me botaron!» nombra el fracaso del equipo, y el baile de victoria dura ≈ 5 s antes del remate.
- Para una niña que "se frustra y llora rápido", eso es el rival burlándose. El gag funciona solo si **el
  castigo a su orgullo llega rápido**. Los gags 3 y 4 lo cumplen (≈ 2 s).

**Corrección**:

- Que el frasco se le dé vuelta **a los ≤ 2,5 s**.
- Cambiar «¡No me botaron!» por algo que no nombre al equipo: «¡Sigo arriba! ¡Baile de la torre!».
- El "¿Por qué llueve rosado?" queda como remate.
- Los retratos se ríen **en el remate**, no durante el baile.
- Playtest: observar la cara de Sofía en los primeros 3 s del gag.

### M8. Anular M7 deja un candado social sin red visible

**Dónde**: ficha §13.4 y `modo-equipo.md` §14.16 (fila del §14.7). Lo pidió el PO: evaluar las
consecuencias.

**Qué cambia**: el viaje al planeta 2, que es el centro del juego, ahora pasa por un evento de **tres
retratos** (la batalla) más una ceremonia de tres. Lo que M7 evitaba era que Sofía quedara esperando el
humor de Maxi. La decisión del PO lo mitiga bien:

- basta un ala;
- quien no la tiene igual viaja;
- existe la llave de padres.

Faltan cuatro piezas para que nadie quede esperando sin saber por qué:

1. **La llave tiene que encontrarse**: en la zona de padres, una línea de estado ("Arcoíris: la nave
   espera la batalla de los tres") **junto** a la llave. Si no, el papá no sabe que existe.
2. **Escribir que dos hermanos pueden jugar la batalla y la partida** usando el retrato del tercero (la
   regla "si Maxi no está, un hermano mayor juega su turno guiado", m8 de HE-66). Hoy está en el §14.7,
   pero ahora decide el viaje: tiene que estar también en el §13.4. Es la red que no necesita al papá.
3. **El hito de partida mantiene el tono de M7.3**: sin alertas, sin parpadeo y con voz como máximo una
   vez por visita. Ya está; QA lo verifica.
4. **La línea `009b`** («…¡y ahora **tú también** ayudaste a ganarla!») compara: dice que otro llegó
   antes. Si Sofía gana su ala **después** que Nicole, oye que su hermana le ganó.
   - Cambiarla por una sin "también": «¡La primera pieza! La nave ya lleva su ala… ¡y este trocito lo
     ganaste tú!».
   - Darle una celebración del **mismo tamaño** que la de `009a` (GDD §6.9): que el ala destelle, la
     nave haga un loop y salga el gesto canon del hermano. No una simple señal de Coco (storyboard §15).

### M9. No está escrito qué pasa al tocar Animalia antes de la partida

**Dónde**: ficha §13.4 (`viaje_siguiente_requiere`), storyboard §13 y guion §7
(`mapa_animalia_lejitos`, solo para la "rama A").

**Problema**: con la nueva regla, mientras la partida no esté hecha, Animalia aparece en el Mapa
Estelar, pero no se puede ir. No está especificado:

- cómo se ve;
- qué responde al tocarlo.

Las opciones fáciles para Dev (un candado, un "bup" o nada) violan el GDD §6.5 o se leen como castigo.

**Corrección**:

- Animalia se ve **lejana y desenfocada**, como en la rama A, sin candado.
- Al tocarla responde en < 100 ms (late) y Cometa dice una línea nueva: «¡Primero dejamos la nave lista,
  todos juntos! La nave espera en el Claro».
- Una flechita lleva a Arcoíris.
- Suena como máximo una vez por visita (`guionista`).

### M10. En la ruta de Sofía, las estrellas quedan pegadas a Cometa, a la casa y al mapa

**Dónde**: storyboard §9.5, layout de la pantalla de navegación (`Rect2(120, 100, 1040, 470)`).

**Medido**:

| Elemento | Separación con el campo de estrellas |
|---|---|
| Cometa, `Rect2(8, 4, 110, 96)`, termina en x 118 | **2 px** |
| Casa, `Rect2(1172, 8, 100, 96)` | **12 px** |
| Mapa de referencia (tocable), `Rect2(540, 12, 200, 80)`, termina en y 92 | **8 px** |

La regla de HE-66 pide ≥ 24 px. Un toque a la casa a mitad de la ruta saca de la partida y la ruta se
pierde, porque el guardado es por paso.

**Corrección**:

- Campo de estrellas en `Rect2(150, 128, 980, 440)`: ≥ 24 px de Cometa (y 104), de la casa y del mapa
  (con el mapa subido a y 8-88, o movido a una esquina inferior).
- Sin la barra, nada tocable por debajo de y 696.
- QA mide las tres separaciones.

### M11. Si Sofía traza la ruta arrastrando, cada señuelo que cruza le da "bup"

**Dónde**: storyboard §9.5 (SO2: «toca las estrellas en orden, **o arrastra el dedo** de una a otra»;
los señuelos están intercalados).

**Problema**: en una ruta en zigzag con 5 señuelos intercalados, la línea recta entre dos estrellas
correctas pasa a menudo por un señuelo. Si en el arrastre cada estrella que se cruza cuenta como toque,
Sofía oye "bup" por hacer bien la tarea. Es "frustración por la interfaz", no por el reto.

**Corrección**:

- **Con el dedo en arrastre, solo se registra la estrella correcta siguiente**. Las demás se iluminan
  apenas al pasar, sin "bup".
- El "bup" del señuelo es solo para un **toque directo**, es decir, un `press` sobre ella.

---

## Hallazgos menores

- **m1. El área de agarre se superpone con el ramo de globos de la canasta** (x 140-180, y 310-440; ficha
  §4). Hay que fijar que dentro del círculo manda la resortera, o achicar el ramo a x ≤ 120. Si se
  aplica B2, un toque ahí ya no dispara.
- **m2. «¡Y algunas ya no suben!» tiene que ser siempre verdad** (guion T.8, ficha §10.2). Con
  `round(0,30 × agarre_perdido)` y poco daño, el resultado puede ser 0 piezas en el suelo. Regla: si se
  botó al menos 1 pieza, **queda al menos 1 en el suelo**.
- **m3. Demasiada voz por turno** (ficha §8.1, guion T.2). `carga_0X` («¡Globo cargado! ¡Rojo
  frutilla!», 1,8 s) suena en cada uno de los 20-25 turnos, además de "le toca" y la voz del resultado.
  El GDD §5 pide ritmo rápido. Propuesta:
  - la frase completa solo la primera vez de cada color por sesión;
  - después, solo «¡Rojo!» (≤ 0,7 s) o solo el SFX;
  - **la entrada nunca espera a que termine la voz**: se puede estirar mientras Coco habla.
- **m4. El toque en vuelo del triple lo puede hacer cualquiera** (ficha §5.5). Un toque de Maxi divide el
  globo de Sofía antes de tiempo («¡me lo arruinó!»). Propuesta:
  - aceptar el toque solo dentro de la zona de juego (y 110-600, nunca en la barra donde están las manos
    de quienes miran);
  - y solo después de 0,15 s del lanzamiento.
  - En el playtest, registrar las divisiones antes del 30 % del vuelo.
- **m5. El choque de cinco puede "robarlo" otro hermano** (storyboard §10 D3: «cualquiera puede tocar la
  manopla»). La manopla se activa **cuando termina la voz del regalo**; un toque antes solo la hace
  menear. Así Maxi no le gana la mano a su hermana mientras Coco todavía le habla a ella.
- **m6. Bloque 1: ≈ 55 s pasivos seguidos** (cierres A y B y parte C, storyboard §6). Para Maxi, que "se
  aburre cuando hablan mucho", conviene que la parte C sea suya:
  - en M1 el papel destella y **espera un toque de cualquiera** (target ≥ 120 px);
  - al tocarlo, Coco lanza la lengua;
  - si nadie toca, sigue solo a los 6 s.
  - El storyboard ya dice que el papel "es la semilla para Maxi".
- **m7. Los retratos de la cuenta regresiva no caben en la barra** (storyboard §12.1: ≥ 160 px y ≥ 200 px
  para Maxi; la barra mide 110 px). Hay que fijar sus rects con ≥ 24 px entre ellos y respecto de la
  nave. Un toque sobre un retrato que **no** brilla lo hace saltar y reír (< 100 ms), sin "bup" y sin
  avanzar la cuenta.
- **m8. La ceremonia después de la llave de padres**: si la familia ya viajó a Animalia con la llave y
  después gana la batalla, el bloque 2 no puede volver a "despegar hacia Animalia" como si fuera la
  primera vez (ficha §13.4; storyboard §16.2, [CONCILIAR] 5). Propuesta:
  - se juegan los preparativos y la despedida de Coco;
  - el despegue cierra con «¡De vuelta a Animalia!»;
  - sin rama del Mapa Estelar (el rumbo ya está encendido).
- **m9. «Busca la… ¡A!» con tres A en pantalla** (guion §4.3). La voz de pista va siempre **junto** con el
  latido de la estrella correcta (storyboard §9.5). Si no, Sofía queda con tres candidatas y la pista no
  ayuda.
- **m10. La tarea de Nicole en la ceremonia es la más chica**: 3 toques, contra 6 de Maxi y la ruta con
  señuelos de Sofía. Recomiendo:
  - mantener la versión del guion v3 (**Coco encaja el ala**), que evita el «¡yo gané el ala y la puso
    Nicole!» cuando la primera ala fue de Sofía;
  - y darle a Nicole un objetivo a su medida: **los broches se giran por el color que nombra Coco**
    («¡el broche rojo!», después el amarillo y el azul, que son los colores que recuperaron), con un
    meneo sin voz si toca otro.
  - Es un objetivo a la vez y no tiene fallo.
- **m11. `arcoiris_batalla_cierre_coco` suena dos veces en el bloque 1**: como F1 después de la caída
  (guion §1) y en A5 (storyboard §6.1). C6 ya es la fiesta máxima. Hay que quitar F1 y F2 entre la caída
  y "antes del epílogo": así el tramo pasivo desde el tiro ganador hasta el epílogo baja a ≈ 19 s
  (anticipación 3,5 + caída 10,5 + antes del epílogo ≈ 5).

---

## Respuesta a los puntos pedidos

| Punto | Evaluación | Hallazgos |
|---|---|---|
| **Resortera para 2 años** | Maxi no usa la resortera: su control (tocar o arrastrar donde sea) es correcto. Hay dos riesgos: sus toques en los turnos de las hermanas (B2) y el dedo que se queda apretado en su propio turno (M5) | B2, M5 |
| **Resortera para dedos de 5 años** | El área de 240 px es generosa y está bien (el hitbox es mucho mayor que el globo de 52 px). Los 40 px de cancelación (≈ 7 mm en una tablet de 10") bastan para el temblor. Fallan dos cosas: que un toque dispare (B2) y el desliz al levantar el dedo (M2). Los 220 px de estiramiento máximo (≈ 3,7 cm) caben bien en la mano | B2, M2, M1 |
| **Legibilidad del "agarre"** | Bien resuelta sin números: 4 caras inequívocas, el corrimiento hacia el borde y "colgando de un dedo" se entienden a los 5 años, y el charco y las piezas en el suelo son la memoria del avance. El problema no es la lectura, es que el dibujo no coincide con la física (M3) | M3 |
| **Derrota y gags** | La estructura es correcta: él se jacta y le sale mal, nadie dice "perdimos", el logro es común y las ayudas llegan con el tic de Coco. Los gags 2, 3 y 4 dan risa sin humillar; el 3, que convierte un globo perdido en el remate, es excelente. El gag 1 se demora (M7). El riesgo real de culpa está en quién tira el último globo (M4) | M7, M4, m2 |
| **Esperas** | Ciclo M-N-M-S ≈ 78 s. Maxi tira cada ≈ 32-34 s (bien, con porras). Nicole y Sofía esperan ≈ 66 s entre tiros, y Sofía hace su primer tiro ≈ 1 min después de empezar. Para los 8 años es aceptable con las ventanitas de porra, pero Sofía tiene ≈ 24 s de acción en un intento de 3,3 min. Medirlo en el playtest; si se aburre, el primer recorte es el pase (puerta por toque en vez de arrastre tras Maxi), no sus tiros | M4 |
| **Duración** | Sesión típica de la Torre: ≈ 6 min de juego + ≈ 2,5 min del bloque 1 ≈ **8,5-10 min seguidos** (p80 ≈ 11). Está en el techo para Maxi y se acepta porque juega cada ≈ 30 s. Con la pausa antes de la Torre (M6) y la pausa entre bloques (decisión 2), la batalla completa queda en 3-4 sesiones naturales. Riesgo: los niños siempre eligen "¡vamos!" en las pausas, así que la ficha debería medir el tiempo continuo en el playtest | M6, m6, m11 |
| **Targets de la ceremonia** | Bien: boquilla ⌀ 220 y toda la pantalla para Maxi, broches ⌀ 110 con ≥ 30 px entre ellos, manopla ⌀ 200 y 150, nave de la pausa ≥ 300 × 200 y estrellas de 96 px. Fallan las separaciones de la ruta (M10), los retratos de la cuenta (m7) y el arrastre sobre señuelos (M11) | M10, M11, m7 |
| **Solo voz** | Todo está narrado y Cometa repite en todas partes. La excepción es el primer tiro de las hermanas (M1). Las letras de la ruta de Sofía son texto **con** apoyo de voz, en nivel Estrella: cumplen | M1, m9 |
| **Equidad entre hermanas** | Está bien: los aciertos de Nicole y Sofía no llevan nombre, los globos de Sofía se llaman "especiales" (no "de experta"), el rastro de una nunca se ve en el turno de la otra, las celebraciones de la ceremonia son iguales y los regalos tienen el mismo peso. Falla en: los turnos 3 contra 2 y el último globo (M4), `009b` (M8.4), quién instala el ala (m10), los récords de la revancha con dos (decisión 5) y el choque de cinco (m5) | M4, M8, m10, m5 |

---

## Recomendaciones sobre las decisiones abiertas del PO

1. **Globo gigante: variante A** (Coco lo infla tras la 2.ª derrota y Maxi lo tira con su tiro guiado; no
   gana solo), con dos condiciones:
   - **La victoria sigue siendo de los tres**. Con la B la gana Coco, y eso repite el "el juego jugó por
     mí" que corregimos en el Río (B3 de HE-66).
   - Le da a Maxi su gran momento sin darle a una hermana algo que la otra no tiene: el celo es entre
     Nicole y Sofía, no con Maxi.
   - **Condición 1**: el ≥ 95 % en ≤ 3 intentos tiene que demostrarlo el simulador con las distribuciones
     **del arnés**, no con las de la estimación a mano. Si el 3er intento queda bajo 99 %, se sube
     `gigante.agarre_min` antes que cualquier otra cosa: un 4.º intento después de ≈ 20 min es lo que más
     frustra a Sofía.
   - **Condición 2**: el vuelo del gigante lo celebran los tres retratos (inflan los cachetes, como en
     K1), para que el momento sea de Maxi pero el festejo sea de todos.
2. **Pausa entre el bloque 1 y el bloque 2: sí**, donde la propone el storyboard (§8.1, después de la
   parte C):
   - la nave brilla, nunca avanza sola y la casa está a la vista;
   - el mapa recién encontrado es el mejor gancho para volver.
   - Sin pausa son ≈ 6 min de cierre después de ≈ 6-10 min de Torre, y el bloque 2 trae el tramo pasivo
     más largo (la llamada, ≈ 28 s), justo cuando Maxi está más cansado.
   - Si salen, el hito de partida retoma en el primer paso pendiente.
3. **Terminar en el Mapa Estelar**, con Animalia encendida y la nave "en rumbo» («¡Cuando quieran,
   partimos!»), **sin encadenar el viaje tipo Galaga**:
   - el bloque 2 ya cierra una sesión larga, y el GDD §3 pide cerrar el capítulo en celebración;
   - el Galaga es un juego nuevo que merece atención fresca, y encadenarlo mete un reto, que se puede
     perder, en el momento de mayor cansancio;
   - la próxima vez, cualquier hermano toca Animalia y parte.
4. **Orden de turnos en la Torre: mantener `maxi_intercalado`, pero con 9 globos de base y +4 tras la 1.ª
   derrota**, forzando que cada intento empiece con Maxi:
   - Nicole y Sofía tiran siempre la misma cantidad;
   - el último globo es siempre el tiro seguro de Maxi.
   - Detalle y motivos en M4. Se descarta `ronda_completa`, porque Maxi esperaría ≈ 55 s entre tiros.
5. **Revancha con dos hermanos: sí, pero sin estrellitas ni récord**:
   - la revancha es un premio opcional y no debería depender de juntar a los tres (es la lógica de M7);
   - pero un récord o unas estrellitas de "Sofía y Maxi" frente a "Nicole y Maxi" es **una comparación
     directa entre las hermanas**;
   - con dos, la Torre se juega igual, con mini fiesta y caída, y los globos se calibran por composición
     para que cada una juegue ≥ 2 turnos;
   - estrellitas y récord familiar, solo con los tres.
6. **Cuenta regresiva Sofía → Nicole → Maxi, un retrato a la vez: sí**:
   - cumple "un foco por momento";
   - Sofía abre como capitana;
   - el «¡Uno!» y el despegue le tocan a Maxi, el clímax para el menor, que las hermanas aceptan bien.
   - **Condiciones**:
     - un toque a un retrato que no brilla responde (salta y se ríe) sin "bup" ni avance (m7);
     - el retrato que brilla mide ≥ 200 px en el caso de Maxi;
     - recordatorio a los 8 s y salto solo **a los 15 s para Maxi** y a los 20 s para las hermanas
       (Maxi es el último: que la nave no quede esperando a un niño de 2 años que se fue);
     - el storyboard v4 elimina el "en cualquier orden" (B1).
7. **"Antes del epílogo" (≈ 4,95 s contra un tope de 5 s): no vale la pena forzar el tope**:
   - lo pongo en **≤ 6 s medido con el audio real** (la grabación casera de papá va a variar, y el guion
     pide 0,5 s de silencio en los archivos, que hay que recortar);
   - se justifica porque él ya está en pantalla desde la caída y la pelusa-nubecita es un gancho visual;
   - **lo que sí importa** es el tramo completo sin tocar, desde el tiro ganador hasta el epílogo:
     quitando F1 y F2 (m11), queda en ≈ 19 s, aceptable para el clímax del planeta;
   - si en el playtest Maxi se distrae ahí, se recorta primero el aire del final de la caída (C4).

---

## Qué sí está bien (no tocar)

- **La torre dormida entre tiros**, determinista, y la caída **animada**. La excepción a la física queda
  acotada y justa.
- **El charco que crece con los tiros que no botan nada**, y «¡Plof! ¡Más pintura para el charco!»: ningún
  tiro se pierde.
- **La derrota solo en el pase**, con el retrato del siguiente al centro y voces en plural.
- **"¡Otra vez!" desde el segundo 0**, y que la ayuda llegue aunque se corte el gag (R1 del storyboard
  §7.5).
- **Lo que le cae encima se queda hasta la victoria**: es la memoria visible de "lo estamos logrando".
- **El gag 3**, que convierte un globo que salió de la pantalla en el remate.
- La escala por edad sacada de Angry Birds (tutorial, temprano y avanzado), con reto real para Sofía:
  sin guía, halo chico y globos con intención.
- La caída en el charco con la mochila en alto: tierna y chistosa, y nunca le cae nada encima, salvo
  la tapa blandita.
- El estado familiar en sí: "un ala basta" y "quien no la tiene igual viaja" protegen a la más avanzada.
- La pausa del bloque 1 sobre el mapa encontrado, y la ruta A-N-I-M-A-L-I-A que se vuelve perrito: reto
  de lectura real para Sofía, con sorpresa.

## Para cerrar la tarjeta

1. **B1 y B2 resueltos** en el storyboard v4 y en la ficha v3. Sin eso, la tarjeta no se cierra.
2. M1-M11 incorporados, o aceptados explícitamente por el PO para el playtest.
3. Re-auditoría corta de UX sobre los cambios (solo B1, B2, M2-M5 y M10).
4. Después de la implementación: auditoría sobre el build y playtest con los tres. Hay que medir:
   - si Nicole entiende "hacia atrás" al 2.º tiro;
   - si hay globos disparados sin querer;
   - las frases de culpa ("perdimos por…");
   - la cara de Sofía en el gag 1;
   - el tiempo continuo de la sesión y en qué momento se va Maxi.
