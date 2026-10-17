# Ficha de motor — `rio` («Río de pintura», tipo Zuma)

> **Decisiones del PO (17-Oct-2026)**, tomadas al jugar la maqueta `docs/maquetas/rio-v2.html`
> (publicada en https://claude.ai/artifact/Fy4rnavTvTPcRhjcXMnAF7):
>
> 1. **Ríos más largos y grupos más largos por hermano**, para que se vea fácil dónde disparar (sobre todo
>    Maxi). Nuevo campo `grupo: [min, max]` (§5.1).
> 2. **Retroceso espectacular, como en Zuma**: los extremos que coinciden brillan y se atraen; al chocar,
>    "¡clac!", destello y temblor suave (§6). **El combo (aciertos seguidos) y la cadena (retrocesos que
>    revientan) se separan** (§7).
> 3. **Gota arcoíris salvavidas** como munición, con frecuencia por hermano (§9).
> 4. **Batidora sobre un puente** (idea del PO), solo para Nicole y Sofía. **Ya no hay mezcla dentro del
>    río** (§10).
> 5. **Nicole**: un solo secundario (verde) y batidora de 2 espacios. **Maxi** no mezcla (§11).
> 6. **Sofía, etapas difíciles**: colores de **2 + 1**, pocos y sueltos, batidora de 3 espacios y el
>    **café** como peligro (§5.3, §10.5).
> 7. **Munición que ayuda**: pesa por los colores presentes, con triple peso cerca del remolino (§8).
>
> Las cifras de este documento son las de la maqueta (tabla y `PERFILES`): **son la propuesta inicial,
> no la calibración**. Las fija `disenador-niveles` con el simulador y el arnés (§16).

- **Autor**: `disenador-mecanicas`
- **Versiones**:
  - **v1** (06-Oct-2026): no hubo ficha propia. La v1 es `docs/roadmap-rio-de-pintura.md` §5-§9 más el
    mockup `rio-de-pintura.html`, implementada en el hito H1 (`scripts/motores/rio/`).
  - **v2** (17-Oct-2026): esta ficha. Formaliza la maqueta `rio-v2.html` y las decisiones del PO de hoy.
    **Manda sobre el roadmap §5, §6 y §10**, que quedan marcados como reemplazados donde corresponde.
- **Estado**: propuesta para auditoría de `experto-ux-parvulo` (§17) y calibración de `disenador-niveles`
  (§16). **Implementada en Godot por `dev-godot` (HE-91, 17-Oct-2026)** con los valores provisionales de §11
  y arte dibujado por código; ver §14.1 para lo que se decidió al implementar.
- **Código actual (v1)**: `scripts/motores/rio/logica_rio.gd` (reglas), `motor_rio.gd` (dibujo y
  entrada), `recorrido_rio.gd`; escena `escenas/minijuegos/rio/motor_rio.tscn`; arnés
  `herramientas/qa_test_rio.gd`.
- **Fuentes**: GDD §1, §5, §6 y §8; `docs/perfil-jugadores.md`; `docs/stack-tecnico.md`;
  `docs/roadmap-rio-de-pintura.md`; `docs/fichas/modo-equipo.md` (Río de la batalla).

**Marcas**:

- **[PO]**: decisión del PO del 17-Oct-2026.
- **[Maqueta]**: comportamiento de `rio-v2.html` que se adopta tal cual.
- **[Propuesta]**: de `disenador-mecanicas` (decisión menor, por delegación del PO; se puede revertir).
- **[Abierta]**: necesita una decisión del PO (§18).

---

## 0. Problemas verificados de la v1 y cómo los resuelve la v2

| # | Problema (verificado el 17-Oct) | Causa | v2 |
|---|---|---|---|
| 1 | Maxi ve casi todas las gotas sueltas y casi no hay jugadas de retroceso | `reiniciar()` promete grupos de 1-3, pero `repetidas < 2` corta en 2. En 3.000 ríos: 56 % de grupos de 1, 44 % de 2, **0 % de 3** | Generador por grupos con `grupo: [min, max]` por hermano (§5.1) |
| 2 | El retroceso funciona pero casi no se nota | Grupos cortos y una vuelta de ~0,3 s sin sonido ni efecto propio | Brillo y atracción, "¡clac!", destello y temblor (§6) |
| 3 | Sofía mezcla sin querer | La mezcla ocurre dentro del río, con la vecina de adelante, no con la gota a la que apuntó. ~30 de 60 gotas son secundarias y ~12 están solas. Las recetas son un dibujo fijo. La "mezcla guiada" del roadmap §10 nunca se hizo | **Sin mezcla en el río**. Se mezcla en la batidora del puente (§10). Recetas vivas (§10.7) |
| 4 | "¡Cadena x2!" aparece sin retroceso | `cadena` cuenta a la vez los aciertos seguidos y los retrocesos (`maxi(1, cadena + 1)` en un acierto directo) | Dos contadores: `combo` y `cadena` (§7) |

| Tema | v1 (H1) | v2 |
|---|---|---|
| Grupos | 1-2 (error) | `grupo: [min, max]`: Maxi 3-4, Nicole 2-3, Sofía 1-3 |
| Largo del río | 36 / 36 / 60 | 50 / 50 / 70 (z1) / 80 (etapa difícil) |
| Mezcla | En el río, al tocarse dos primarios distintos | En la batidora, con palanca que sirve 2 disparos |
| Secundarios en el río | Sofía: 3 de 6 colores, al azar (~50 %) | Nicole: verde ~16 %; Sofía: 3 secundarios ~35 % |
| Colores de 2 + 1 | — | Sofía, etapa difícil: 5 sueltos por río, 3 tipos |
| Munición | Al azar entre colores presentes | Ponderada: ×3 las 12 de la cabeza; componentes ×0,6 |
| Gota arcoíris | Solo en el roadmap | Munición al azar, mín. 6 disparos entre una y otra |
| Retroceso | 520 px/s, sin efecto | 420 px/s, brillo, atracción, "¡clac!", destello, temblor |
| Combo / cadena | Un solo contador | Separados |

---

## 1. La mecánica en una frase y las referencias

**Coco, al centro, dispara gotas de pintura con la lengua a un río de gotas que avanza hacia el remolino;
tres iguales juntas revientan, y si los extremos del corte coinciden, el río se cierra en cadena.**

| Referencia (regla de oro 3) | Qué tomamos |
|---|---|
| **Zuma** (PopCap) | Inserción, reventón de 3+, retroceso en cadena, munición justa, **túneles** donde la bola pasa escondida |
| **Luxor** / bubble shooters | **Comodín arcoíris** como munición, más frecuente cuando el río está cerca del final ("seguro") |
| Juegos de cocina tipo Toca Kitchen (licuadora) | El recipiente que muestra la mezcla en vivo y se sirve con un botón grande. Es la parte propia del tema "colores" |

Escala de dificultad, como en Zuma: velocidad, largo del río, tamaño de los grupos, número de colores,
ayuda de puntería y frecuencia del comodín. La mezcla agrega la palanca propia de Nicole y Sofía.

---

## 2. Reglas que no se rompen

1. **Solo tocar y arrastrar** (GDD §6): tocar o arrastrar apunta, soltar dispara, tocar a Coco
   intercambia, tocar la palanca sirve. Sin doble toque. Entrada unificada táctil + mouse.
2. **Todo responde en < 100 ms**, incluso lo "incorrecto": un disparo que rebota en la batidora, un toque a
   la palanca vacía, una gota que se inserta sin reventar.
3. **Nada se pierde**: una gota rechazada vuelve a Coco; servir no borra la gota arcoíris que Coco tenía
   (§8.3).
4. **Perder es un gag**: "¡Glu glu glu!", Coco chorreada de gris y reintento de un toque (GDD §1).
5. **Sin voces entre disparos** (roadmap §2 y §11). Las pistas de la batidora son flechas, no voz.
6. La lógica (`LogicaRio`) sigue sin pantalla y determinista con semilla, para el arnés.
7. El motor nunca conoce el tema: colores, recetas, recorrido y batidora llegan del archivo de nivel.

---

## 3. La escena (zona 1, 1280 × 720)

Las posiciones salen del recorrido de la zona 1 (espiral `z1_espiral.json`, centro ≈ (640, 372)).

| Elemento | Dónde | Notas |
|---|---|---|
| Nube gris (entrada) | abajo a la izquierda (≈ 160, 690) | se le inflan los cachetes cuando hay gotas esperando |
| Cauce de galleta | espiral desde la izquierda hasta el remolino | ancho = diámetro + 26 px |
| Remolino | fin del recorrido (≈ 880, 372) | pulso rojo sobre el 82 % (`PELIGRO`) |
| Coco en su plato | centro (640, 366) | órbita de la gota cargada 86 px; zona de toque 72 px de radio |
| **Puente y batidora** | última vuelta, abajo: ángulo 2,5π, ≈ 61 % del recorrido; batidora en ≈ (640, 586) | solo si el nivel trae `batidora` (§10.1) |
| **Palanca** | 92 px bajo la batidora, ≈ (640, 678) | dibujo de 72 px; zona de toque de 96 px (§10.6; riesgo R1 en §17) |
| Puntaje y récord | píldora arriba al centro (470, 14, 340 × 74) | |
| Cuánto río queda | barra arriba a la derecha (1040, 34, 200 × 20) | se llena a medida que el río se vacía |
| **Recetas** | caja a la derecha (x 1062-1264, desde y 92) | una fila de 46 px por receta (§10.7; riesgo R7) |

Entre Coco y la batidora no pasa el río (la vuelta interior va por arriba), así que **cualquier disparo
hacia abajo, dentro de unos ±15°, le pega a la batidora**.

---

## 4. Interacciones (tiempos y feedback)

| Acción del niño | Respuesta | Tiempo | Feedback |
|---|---|---|---|
| Tocar o arrastrar fuera de Coco y de la palanca | Coco gira hacia el dedo (si está a > 30 px del centro) | inmediato | ojos y cabeza siguen el dedo; guía de puntería (Maxi, Nicole) hasta la gota o la batidora donde pegaría, con anillo punteado que gira |
| Soltar | Disparo | inmediato; enfriamiento 0,22 s | lengüetazo 0,12 s (sale 44 px), "slurp"; la mano pasa su gota a la boca (0,16 s) |
| Tocar a Coco | Intercambio boca ↔ mano | inmediato | giro de Coco, sonido de "cambio" |
| La bala toca una gota | Inserción delante o detrás según el lado del impacto | vuelo de la bala a 1150 px/s; la gota entra en 0,12 s | "plic"; si revienta, §12.1 |
| La bala toca la batidora | Captura o rebote (§10.3-§10.4) | instantáneo | captura: "glug", 10 gotitas, la batidora tiembla 0,35 s y el líquido cambia; rebote: §10.4 |
| La bala sale de la pantalla | Nada que castigar | — | Coco hace "ups" con la mano en la boca (H2) |
| Tocar la palanca | Sirve 2 disparos del color mezclado (§10.6) | presión visible inmediata; vuelo de 0,38 s a Coco | "fiuuu" ascendente, anillo del color en Coco, Coco salta |
| Tocar la palanca sin nada que servir | Nada | inmediato | la batidora tiembla 0,4 s y suena un "¿mm?" suave (nunca un zumbido de error) |
| Perder | Reintento | el cartel acepta el toque en cualquier parte | §12.3 |

**PC**: espacio dispara, Tab intercambia, **S sirve**. Son atajos de prueba; el juego se diseña para el
dedo.

---

## 5. El río

### 5.1 Generador por grupos [PO, Maqueta]

`gotas[0]` es la cabeza (la más cerca del remolino); la última es la cola. El río se arma **por grupos**:

```
mientras falten gotas:
    candidatos = secundarios  si hay secundarios y azar < p_secundario
                 colores      si no
    quitar de candidatos el color del grupo anterior
    (si quedó vacío: colores sin el anterior)
    color = uno al azar de candidatos
    n     = entero uniforme en [grupo.min, grupo.max]
    agregar n gotas de ese color
```

- **Dos grupos seguidos nunca son del mismo color**: el tamaño de grupo que se ve es el que se pidió.
- `p_secundario` es **por grupo**; como el tamaño no depende del color, también es aproximadamente la
  fracción de gotas.
- **Último grupo [Propuesta]**: nunca se corta por debajo de `grupo.min`. Si faltan menos gotas que el
  mínimo, el grupo sale entero y el total real supera `gotas` en hasta `min − 1`. La barra de "cuánto río
  queda" usa el total real. Así Maxi nunca termina con una gota suelta en la cola.
- **Sin `grupo` en el nivel**: se usa el **generador v1 tal cual** (incluido su tope de 2), para no
  descalibrar el Río de la batalla (`rio_equipo.json`), que se simuló con él. `disenador-niveles` decide
  si lo migra (§16).

### 5.2 Avance, inserción y reventón (sin cambios de fondo respecto de la v1)

- Entrada rápida (420 px/s) hasta `entrada_rapida_hasta` (28 %); después, `velocidad`, que sube hasta
  `velocidad × (1 + subida)` en los primeros 90 s.
- **La cola empuja**: si el río se corta, la parte de adelante queda quieta y la de atrás sigue
  empujando. Cuando la de atrás alcanza a la de adelante **no se evalúa** (como en Zuma): solo el
  retroceso (§6) y la inserción revientan.
- **Inserción**: la gota entra delante o detrás de la gota tocada según el lado del impacto, abre espacio
  con un empuje elástico (0,12 s) y se evalúa. Con 3 o más iguales contiguas, revientan.
- **Ya no hay mezcla dentro del río [PO]**: un primario insertado junto a otro primario distinto se queda
  como está. Se borra la señal `mezclaron` y la regla de `insertar()` que convertía a las vecinas.
- Un primario disparado contra un grupo secundario se inserta como cualquier gota (y estorba): es parte
  del reto de Sofía.

### 5.3 Colores de 2 + 1 (Sofía, etapas difíciles) [PO, Maqueta; colocación: Propuesta]

Seis tipos posibles, cada uno con su receta (el color que va dos veces manda):

| id provisional | Receta | Hex (maqueta) |
|---|---|---|
| `rojo_naranja` | rojo + rojo + amarillo | `#F2582B` |
| `amarillo_naranja` | amarillo + amarillo + rojo | `#FFAA2E` |
| `amarillo_verde` | amarillo + amarillo + azul | `#AFD13A` |
| `azul_verde` | azul + azul + amarillo | `#1FA39A` |
| `azul_violeta` | azul + azul + rojo | `#5A5FD8` |
| `rojo_violeta` | rojo + rojo + azul | `#C93E8E` |

- Los nombres para los niños los define `guionista` (§16); los `id` del código no se muestran.
- **Cantidad por río**: `terciarios.cantidad` (maqueta: 5) de `terciarios.tipos` tipos distintos (maqueta:
  3), sorteados por río.
- **Colocación [Propuesta, cambia la maqueta]**: la maqueta **reemplaza** una gota cualquiera, y eso puede
  partir un grupo en dos (un grupo de 3 queda en 1 + 2+1 + 1). La v2 los **inserta en el borde entre dos
  grupos**, así ningún grupo se rompe. Reglas: nunca entre las primeras `desde_gota` (12) de la cabeza,
  separados por al menos `separacion_min` (8) gotas, y nunca dos juntos. Cuentan dentro de `gotas`.
- **Siempre sueltos**: para reventar uno hacen falta 2 más del mismo, y **la palanca sirve justo 2**
  (§10.6). Un servido bien hecho = un 2 + 1 menos. Es una amenaza a propósito: cuesta 5 disparos (3 a la
  batidora y 2 al río) más un toque de palanca, mientras el río avanza.
- **Se reconocen por su receta en puntitos**: tres puntitos blancos con el color de cada ingrediente sobre
  la gota (accesibilidad y lectura: Sofía no tiene que distinguir "rojo anaranjado" de "naranja" solo por
  el tono).

---

## 6. El retroceso espectacular [PO, Maqueta]

Cuando el río queda cortado y **el último de la parte de adelante y el primero de la de atrás son del
mismo color**, la parte de adelante vuelve hacia atrás hasta chocar. Así funciona desde la v1; lo nuevo
es que se vea y se oiga.

| Momento | Qué pasa | Detalle |
|---|---|---|
| **Atracción** (desde que existe el par) | Las dos gotas de los extremos **brillan**: halo blanco a 1,25-1,4 × el radio, que late (alfa 0,55-0,85, ~3 Hz) | Así el niño ve **antes** que va a pasar algo. El brillo se calcula en cada cuadro: si el par se deshace (una inserción en medio), se apaga |
| **Vuelta** | La parte de adelante retrocede a **420 px/s** [Maqueta; la v1 usaba 520] | Arranca con una rampa de 0,1 s (ease-in) [Propuesta], para que se lea como "se atraen", no como un salto. Sonido de **cuerda elástica que se estira** mientras se mueve (roadmap §11) |
| **Choque** | "**¡clac!**" seco, anillo blanco que crece de 8 a 70 px en 0,3 s en el punto de contacto, y **temblor suave** de pantalla (0,14) | El "¡clac!" y el anillo suenan y se ven **aunque no revienten** (dos A que se juntan y son solo 2): el choque es su propio premio |
| **Si revienta** | Reventón con `es_cadena`: texto grande "**¡Cadena ×N!**" que rebota sobre Coco (naranja, 50 px, 1,4 s), temblor 0,3 y giro de Coco; el tono del reventón sube un semitono por eslabón | Coco: se agarra las mejillas "¡¿uuuh?!" y aplaude (roadmap §3.3, H2) |
| **Y sigue** | Si el reventón deja otro par que coincide, vuelve a empezar: ×3, ×4… | Como hoy: todos los cortes que coinciden vuelven a la vez, y se resuelve un choque por cuadro (el más cercano a la cabeza) |

- **Temblor desactivable**: se respeta una opción de "menos movimiento" (zona de padres); con ella, el
  temblor es 0 y el resto queda igual.
- Probado en la maqueta con el botón "Armar jugada de cadena": `AA BB AA` + disparo `B` → revientan 3 B,
  la parte de adelante vuelve, chocan las A y revientan 4 A con **¡Cadena ×2!**

---

## 7. Combo y cadena: dos contadores [PO]

| | **Combo** | **Cadena** |
|---|---|---|
| Qué cuenta | **Disparos seguidos que revientan** (acierto directo, incluida la gota arcoíris) | **Reventones por retroceso** que salen de **un mismo disparo** |
| Sube | +1 por cada disparo que revienta | +1 por cada retroceso que revienta |
| Se reinicia | con un disparo que **se inserta sin reventar** | **al insertar cada disparo** (vale 1 en el reventón directo) |
| No lo tocan [Propuesta] | los disparos a la batidora (capturados o rebotados), servir y las balas que salen de la pantalla: son **neutros**. Si mezclar cortara el combo, Sofía aprendería a no mezclar | — |
| Puntos | bono de `combo × 10` desde el 2.º | multiplica el reventón: `gotas × 10 × cadena` |
| Se ve | "Combo N" chico y verde junto a Coco (30 px); en el HUD mientras dure | "¡Cadena ×N!" grande y naranja, solo con retroceso |
| Se oye | el reventón sube un semitono por combo | y otro semitono por eslabón (tope total: 12) |
| Coco (H2) | un nudito más de la cresta por acierto; con 3+, ojos de estrella | mejillas y aplauso |

- **El error de la v1** (problema 4) desaparece porque un acierto directo **nunca** sube la cadena.
- **Compatibilidad con la batalla** (`modo-equipo.md` §5, `cadena_vale_aciertos`): el gestor de turnos
  debe contar como cadena **solo los reventones con `es_cadena`**. Con el contador viejo, dos aciertos
  directos seguidos se contaban como cadena: es el mismo error, también en la batalla. `dev-godot` lo
  revisa al implementar y el arnés de la batalla lo cubre (§15).
- La **cresta** (roadmap §7) se alimenta de los dos: acierto = 1 nudito, cadena = 2.

---

## 8. Munición

### 8.1 Munición que ayuda (ponderada) [PO, Maqueta]

Cada vez que se carga una gota nueva (que no sea arcoíris, §9):

```
para cada gota del río (i = 0 es la cabeza):
    peso = peso_cabeza (3)   si i < gotas_cabeza (12)
           1                 si no
    si su color está en `colores`:          w[color] += peso
    si no (secundario o 2 + 1) y hay batidora:
        para cada ingrediente distinto de su receta: w[ingrediente] += peso × peso_componente (0,6)
elegir un color con probabilidad proporcional a w
```

- Sale más seguido lo que **urge** (lo que está cerca del remolino). Es el "seguro" de Zuma sin regalar la
  partida.
- Si no hay ningún peso (río vacío o sin colores conocidos), sale un color al azar de `colores`.

### 8.2 Munición justa (de la v1, ampliada)

- Después de cada reventón, si la gota de la boca o de la mano **ya no sirve** (no queda en el río ni
  como ingrediente de algo que esté en el río), se cambia por una nueva (§8.1).
- **La gota arcoíris y las gotas servidas no se cambian solas**: son armas que el niño ganó.
- **Servida que quedó sin destino [Propuesta]**: si al cargarse en la boca su color ya no está en el río
  (lo limpió un retroceso), **se evapora** con un "puf" de chispitas y se carga la siguiente. Sin esto,
  Coco dispararía una gota inútil que además ensucia el río.

### 8.3 Nada se pierde: la cola de munición [Propuesta]

La maqueta pisa la boca y la mano al servir y al recibir un rebote: puede borrar una gota arcoíris. La v2
usa una **cola**: boca → mano → pendientes → munición nueva (§8.1).

- **Servir**: las 2 servidas pasan a boca y mano; lo que había en boca y mano **se guarda al frente de
  pendientes** y vuelve después, en el mismo orden.
- **Rebote** (§10.4): la gota rechazada vuelve a la boca; la de la boca pasa a la mano; la de la mano, al
  frente de pendientes.
- Los pendientes no se ven (solo boca y mano). Lo que no sirve se descarta al salir de la cola, con la
  regla de §8.2 (salvo arcoíris, que nunca se descarta).

---

## 9. La gota arcoíris [PO, Maqueta]

| Regla | Valor |
|---|---|
| Cómo llega | Como munición nueva, al azar: con probabilidad `1 / arcoiris.uno_cada` en cada carga |
| Mínimo entre dos | `arcoiris.minimo_entre` = **6 disparos** desde la última (nunca dos seguidas) |
| En peligro | probabilidad × `multiplicador_peligro` (**2,5**) cuando la cabeza pasó `umbral_peligro` (**60 %**) |
| Frecuencia (`uno_cada`) | Maxi **9**, Nicole **14**, Sofía z1 **20**, Sofía difícil **22** |
| Al pegar | Toma el color de la gota que tocó, se inserta y **revienta ese grupo aunque sea de 1 gota** (forzado). Vale con primarios, secundarios, 2 + 1 y rosado |
| Batidora | **Pasa por encima**: no la captura ni rebota. Sigue de largo hasta el río |
| Túnel | Tampoco puede pegarle a las gotas escondidas (§10.1) |
| Cuenta como | Acierto de combo. Su reventón puede abrir un retroceso y una cadena |
| Se ve | Gota con 6 gajos de color que giran y aro blanco que late; en la boca, Coco con baño de franjas (roadmap §3.2) |
| Al pegar se ve y se oye | 6 anillos de colores escalonados (0,04 s) que crecen de 10 a 90 px y un arpegio ascendente de 4 notas |

**Ojo con la frecuencia real** (para `disenador-niveles`): `uno_cada` es la probabilidad por carga, no el
promedio. Con el mínimo de 6, el promedio real entre dos arcoíris es ≈ **5 + `uno_cada`** disparos:

| `uno_cada` | Promedio normal | Promedio en peligro (× 2,5) |
|---|---|---|
| 9 (Maxi) | ≈ 14 | ≈ 8,6 |
| 14 (Nicole) | ≈ 19 | ≈ 10,6 |
| 20 (Sofía z1) | ≈ 25 | ≈ 13 |
| 22 (Sofía difícil) | ≈ 27 | ≈ 13,8 |

El contador cuenta **disparos** (la maqueta cuenta cargas, y una carga por munición justa no es un
disparo). Así el mínimo de 6 se cumple en lo que el niño vive.

---

## 10. La batidora sobre el puente (Nicole y Sofía) [PO]

### 10.1 El puente y el túnel

- **Dónde**: en la última vuelta de la espiral, abajo: ángulo **2,5π**, a **≈ 61 %** del recorrido, lejos
  del remolino. Lo marca el **recorrido** (`puente_batidora`, §13.2), no el nivel, porque es geometría.
- **Túnel**: las gotas que están a menos de **66 px** (en distancia sobre el recorrido) del centro del
  puente **pasan escondidas por debajo**: no se dibujan y **no se les puede pegar** (como los túneles de
  Zuma). Siguen empujando, insertándose y retrocediendo normalmente.
- Si un retroceso revienta un grupo bajo el puente, el reventón se ve **sobre** el puente (partículas,
  "+N"): nada pasa sin feedback.
- **Bocas del túnel** a cada lado (galleta oscura) y el puente es una galleta con glaseado punteado. El arte
  final es de `disenador-personajes` (§16).
- Sin batidora en el nivel (Maxi), **no hay puente ni túnel**: el río se ve entero.

### 10.2 Qué se le dispara

| Lo que llega | Resultado |
|---|---|
| Primario (`rojo`, `amarillo`, `azul`) con espacio y sin pasarse de repetidos | **Captura** |
| Rosado, secundario, 2 + 1 o una gota servida | **Rebote** (no es primario) |
| Cualquier primario con la batidora llena | **Rebote** |
| Batidora de 2: un primario que ya está adentro | **Rebote** (repetido sin espacio: 2 iguales no hacen nada) |
| Batidora de 3: un primario que ya está 2 veces | **Rebote** |
| Cualquier cosa durante el eructo de café | **Rebote** |
| Gota arcoíris | Pasa por encima (§9) |

Zona de impacto: círculo de **56 px de radio** alrededor de la batidora.

### 10.3 Captura

- La gota cae al vaso con "glug", 10 gotitas saltan hacia arriba, la batidora tiembla 0,35 s y las aspas
  giran.
- **Se guarda a la vista**: un puntito por espacio en la base del motor (vacío = crema; lleno = su color).
- **El líquido muestra el resultado en vivo**: con un ingrediente, su color; con dos o tres, la mezcla.
  El nivel del líquido sube con los espacios ocupados, con una ola suave.

Resultado de la mezcla (`mezcla_de(contenido)`):

| Contenido | Resultado |
|---|---|
| 1 primario, o 2-3 iguales | ese primario (no se sirve) |
| 2 distintos | su secundario (amarillo + azul = verde; rojo + amarillo = naranja; rojo + azul = violeta) |
| 2 iguales + 1 distinto | el 2 + 1 correspondiente (§5.3) |
| 3 distintos | **café** (§10.5) |

### 10.4 Rebote: "¡esto no va aquí!"

- La batidora se sacude 0,5 s (como diciendo que no con la cabeza) y la gota **vuelve en arco** (60 px de
  alto, 0,32 s) **a la boca de Coco** (§8.3). No se pierde.
- Sonido: un "**boing**" chistoso, **nunca un zumbido de error** (la maqueta usa una onda cuadrada de
  180 Hz que suena a "error": se cambia).
- Coco la atrapa con la boca y parpadea (H2).

### 10.5 El café (Sofía, batidora de 3) [PO]

- Con los **3 primarios distintos** adentro, el líquido se vuelve café con burbujas, suena un "puaj" grave
  y la batidora **eructa**: 1,2 s de temblor y aspas a toda velocidad. Después se vacía con 14 burbujas
  café que suben y desaparecen.
- Durante el eructo todo lo que se le dispara rebota.
- **Es un peligro, no un castigo**: cuesta 3 disparos y 1,2 s mientras el río avanza, y da risa (Coco se
  tapa la boca y se ríe). No resta puntos ni corta el combo.
- Con 2 espacios no puede salir café (2 primarios distintos siempre dan un secundario).

### 10.6 La palanca: servir 2 disparos

- **Cuándo se puede**: hay 2 o más ingredientes, el resultado **no** es un primario ni café, y no hay
  eructo. Con 3 espacios, se puede servir con 2 (un secundario) o seguir agregando para un 2 + 1.
- **Cómo se ve lista**: el botón pasa de gris a dorado, **late** con un halo (46-52 px) y muestra adentro
  una gotita del resultado.
- **Al tocarla**: el botón se hunde (respuesta inmediata), la batidora se vacía, **2 gotas** del color
  salen en arco (0,38 s) hacia Coco y quedan **una en la boca y otra en la mano** (§8.3). Anillo del
  color en Coco y saltito. Después se apunta normal.
- **Tamaño**: dibujo de 72 px de diámetro, zona de toque de **96 px** (radio 48). `experto-ux-parvulo`
  valida que sea ≥ 64 px y su posición (§17, R1).
- Tocar el botón **siempre** es seguro: si no hay nada que servir, solo tiembla.

### 10.7 Recetas vivas (caja de la derecha) [PO]

- Una fila por receta: los secundarios del nivel siempre; los 2 + 1, **solo los que están en el río**
  (aparecen cuando entra el primero).
- Cada fila: ingredientes en gotitas con "+", "=" y el resultado en grande. Los 2 + 1 muestran sus 3
  ingredientes.
- **Se encienden según la batidora**:
  - **dorado fuerte** si el resultado actual de la batidora es esa receta;
  - **dorado suave** si lo que hay adentro es el comienzo de esa receta (por ejemplo, un amarillo enciende
    suave el verde y el naranja).
- **Se atenúan** (30 % de opacidad) cuando ese color ya no está en el río.
- **Nicole**: mientras no haya usado la batidora en el río, la fila del verde tiene un borde dorado que
  late.

### 10.8 Pistas sin voz [PO]

1. **Flecha punteada de Coco a la batidora**: aparece cuando hay a la vista (fuera del túnel) una gota que
   necesita mezcla y la batidora todavía no se usó. Se apaga con la primera captura.
2. **Flecha a la palanca**: la primera vez que hay algo para servir. Se apaga al primer servido.

- Además, la batidora late con un halo amarillo mientras no se haya usado y haya colores mezclados en el
  río.
- **Cuándo se muestran [Propuesta]**: campo `batidora.pistas`: `"siempre"` (en cada río; por defecto en
  Nicole), `"primera_vez"` (solo hasta el primer uso de ese perfil, guardado en `Progreso`; por defecto en
  Sofía) o `"no"`. Para Sofía, una flecha en cada río sería "dificultad de bebé" (playtest 03-Oct).

---

## 11. Reglas por perfil (propuesta de la maqueta, sin calibrar)

| Parámetro | Maxi · Semilla | Nicole · Brote | Sofía · Estrella z1 | Sofía · etapa difícil |
|---|---|---|---|---|
| `gotas` | 50 | 50 | 70 | 80 |
| `grupo` | [3, 4] | [2, 3] | [1, 3] | [1, 3] |
| `colores` (munición) | rojo, amarillo, azul, rosa | rojo, amarillo, azul, rosa | rojo, amarillo, azul | rojo, amarillo, azul |
| `secundarios` | — | verde | verde, naranja, violeta | verde, naranja, violeta |
| `p_secundario` | 0 | 0,16 | 0,35 | 0,35 |
| `terciarios` | — | — | — | 5 gotas de 3 tipos |
| `batidora.espacios` | sin batidora | 2 | 2 | 3 (café posible) |
| `batidora.pistas` | — | siempre | primera_vez | no |
| `radio` | 26 | 26 | 22 | 22 |
| `velocidad` (px/s) | 13 | 24 | 42 | 48 |
| `subida` | 0,35 | 0,35 | 0,6 | 0,7 |
| `arcoiris.uno_cada` | 9 | 14 | 20 | 22 |
| `guia` | completa | completa | no | no |
| `tiempo_par` (s) | 170 | 120 | 125 | 150 |

- **Maxi**: con grupos de 3-4, **cualquier disparo del color correcto junto a un grupo lo revienta**. Es
  causa-efecto inmediato y la guía muestra dónde va a pegar. No hay batidora, puente ni túnel. La
  munición ponderada y el arcoíris frecuente son su red. Su río **sí puede llegar al remolino**
  (roadmap §14.4, pendiente del PO): el gag es corto y el reintento, de un toque.
- **Nicole**: un objetivo a la vez. El verde es poco (≈ 16 %), así que la mayoría del río se juega como
  Maxi y la batidora aparece como "la novedad". La guía también apunta a la batidora (anillo punteado
  sobre ella).
- **Sofía**: decide **cuándo** conviene mezclar mientras el río avanza. En la etapa difícil, los 2 + 1 y
  el café le piden planificar 3 ingredientes en orden.
- Los **colores de 2 + 1 entran en la "etapa difícil"**: qué zona o qué río es lo decide
  `disenador-niveles` (§16; pregunta al PO en §18).

> Ojo con el largo: con 50-80 gotas, **el río no cabe entero en el cauce** (la espiral mide ≈ 3.100 px;
> 50 gotas de Nicole ocupan 2.600 px y 80 de Sofía, 3.520 px). La cola espera en la nube, que se infla.
> Por eso importa la barra de "cuánto río queda" (§17, R6).

---

## 12. Celebración y derrota-gag

### 12.1 Cada reventón

- `gotas × 5` partículas del color salen disparadas con gravedad (0,6-1,1 s), anillo del color que crece
  de 1 a 2,6 radios en 0,35 s, "+N" flotante y saltito de Coco (más alto si es cadena).
- Pop con tono que sube por combo y por eslabón (§7).
- H3: las manchas salpican el paisaje (roadmap §4.3).

### 12.2 Victoria: "¡Río limpio!"

- 140 papelitos de confeti desde Coco, el remolino **florece** en una flor de 6 pétalos de colores con
  centro dorado, Coco salta y aplaude, fanfarria de 5 notas.
- Estrellas por tiempo (como la v1): ≤ par → 3; ≤ par × 1,35 → 2; si no, 1. Récord personal con
  "¡Nuevo récord!".
- La victoria se asegura antes del resumen (GDD §6 regla 8, como en la v1).

### 12.3 Derrota-gag: "¡Glu glu glu!" (sin cambios)

- La cabeza llega al remolino → "¡Glu glu!", el remolino se traga el resto en ≈ 2 s, Coco queda chorreada
  de gris con cara de "¿en serio?" y se sacude como perrito.
- Cartel con puntaje, récord y la flecha circular grande; **tocar en cualquier parte del cartel**
  reintenta.

### 12.4 Gags chicos que no son derrota

- Rebote en la batidora (§10.4), eructo de café (§10.5), palanca vacía (§10.6), gota que sale de la
  pantalla ("ups").

---

## 13. Contrato de datos

### 13.1 Nivel (`datos/niveles/arcoiris/<zona>/rio_<perfil>[_n].json`)

```jsonc
{
  "id_nivel": "arcoiris_z1_lluvia_brote",      // se conserva el de la v1 (no se pierde avance)
  "motor": "rio",
  "perfil": "brote",
  "recorrido": "res://datos/recorridos/arcoiris/z1_espiral.json",
  "gotas": 50,
  "grupo": [2, 3],                              // NUEVO. Sin él: generador v1 (§5.1)
  "colores": ["rojo", "amarillo", "azul", "rosa"],  // munición y gotas "básicas"
  "secundarios": ["verde"],                     // NUEVO. Colores que solo salen de la batidora
  "p_secundario": 0.16,                         // NUEVO. Probabilidad por grupo
  "terciarios": {                               // NUEVO. Solo Sofía, etapa difícil
    "cantidad": 5, "tipos": 3, "separacion_min": 8, "desde_gota": 12
    // opcional: "tipos_fijos": ["rojo_naranja", "azul_verde", "amarillo_verde"]
  },
  "batidora": {                                 // NUEVO. Ausente o null: sin batidora, puente ni túnel
    "espacios": 2,                              // 2 | 3 (con 3 existe el café)
    "servir": 2,                                // gotas que entrega la palanca
    "pistas": "siempre"                         // siempre | primera_vez | no
  },
  "arcoiris": {                                 // NUEVO. Ausente: sin arcoíris
    "uno_cada": 14, "minimo_entre": 6,
    "umbral_peligro": 0.6, "multiplicador_peligro": 2.5
  },
  "municion": {                                 // NUEVO. Estos son los valores por defecto
    "gotas_cabeza": 12, "peso_cabeza": 3, "peso_componente": 0.6
  },
  "radio": 26, "velocidad": 24, "subida": 0.35,
  "entrada_rapida_hasta": 0.28,
  "guia": "completa", "guia_largo": 1280,
  "tiempo_par": 120,
  "lineas_voz": {}
}
```

- **`mezclas` queda obsoleto**: el motor lo ignora y avisa con `push_warning` si viene en `true` sin
  `batidora`. La mezcla dentro del río no existe más.
- Los colores de `secundarios` y `terciarios` no se cargan nunca como munición directa: solo salen de la
  palanca.
- Las recetas viven en el motor (`RECETAS`: 3 secundarios + 6 de 2 + 1). Los colores (hex) también; los
  nombres para los niños los pone `guionista`.

### 13.2 Recorrido (`datos/recorridos/...`)

```jsonc
"puente_batidora": { "angulo": 7.854, "tunel_px": 66, "palanca_offset": [0, 92] }
// o bien "fraccion": 0.61 si el recorrido no es una espiral
```

- Va en el recorrido porque depende de la geometría (que entre Coco y la batidora no pase el río).
- Se llama `puente_batidora` para **no confundirlo con el puente de la zona 5** (el río que pasa sobre sí
  mismo, roadmap §4.4).
- Validación (herramienta de recorridos o arnés): ninguna parte del río a menos de 1 diámetro del
  segmento Coco–batidora, la palanca dentro de la pantalla con su zona de toque completa (§17, R1) y el
  puente lejos del 82 % de peligro.

### 13.3 Señales de `LogicaRio` (propuesta para `dev-godot`)

| Señal | Cambio |
|---|---|
| `reventaron(cantidad, centro, color, cadena, puntos, es_cadena)` | suma `es_cadena` |
| `combo_cambio(combo)` | nueva |
| `retroceso_atrae(id_a, id_b)` / `retroceso_choco(posicion, revienta)` | nuevas (brillo, "¡clac!", temblor) |
| `batidora_capturo(color, contenido, resultado)` / `batidora_rechazo(color, motivo)` | nuevas; `motivo`: `no_primario`, `llena`, `repetido`, `cafe` |
| `batidora_cafe()` / `batidora_sirvio(color, cantidad)` | nuevas |
| `arcoiris_cargada()` / `arcoiris_pego(posicion, color)` | nuevas |
| `mezclaron` | **se borra** |

---

## 14. Riesgos de implementación conocidos (para `dev-godot`)

- La maqueta cuenta las cargas para el mínimo del arcoíris; la v2 cuenta disparos (§9).
- La maqueta pisa boca y mano al servir y al rebotar; la v2 usa la cola (§8.3).
- La maqueta coloca los 2 + 1 reemplazando gotas; la v2 los inserta entre grupos (§5.3).
- La maqueta usa un sonido de error para el rebote; la v2 pide un "boing" (§10.4).
- La batalla (`rio_equipo.json`) pasa a `grupo` y `arcoiris` por decisión del PO (17-Oct-2026, §18.3),
  sin `batidora`; además lleva el arreglo de combo/cadena (§7). Hay que re-simularla (`disenador-niveles`).

---

### 14.1 Implementación (HE-91, `dev-godot`, 17-Oct-2026)

- Todo lo de §5-§10 vive en `LogicaRio` (señales de §13.3, más `batidora_se_vacio`, `palanca_vacia` y
  `servida_evaporada`); el motor solo dibuja y atiende la entrada. `qa_test_rio` cubre los 13 puntos de §15.
- `puente_batidora.angulo` va **en radianes** (como el ejemplo de §13.2), a diferencia de `angulo_inicio` y
  `angulo_fin` de la espiral, que van en múltiplos de π. Está en `z1_espiral.json`.
- **Por delegación**: la servida sin destino (§8.2) se evapora siempre que llega a la boca **o** cuando un
  reventón limpia su color, también en el instante de servir (si se sirve un color que no está en el río,
  "puf" y vuelve lo que Coco tenía). Así Coco nunca dispara una gota que ensucia el río.
- **Por delegación**: la gota rebotada y las servidas se aplican a la cola en el instante; el vuelo en arco
  (0,32 s y 0,38 s) es solo visual, y durante ese tiempo no se puede disparar.
- `zona3_chupetines/rio_estrella.json` (etapa difícil de Sofía) existe como datos y en el arnés, pero
  **no está en el mapa**: las zonas 2-5 siguen con la Lluvia hasta tener sus ríos (roadmap H5). Usa la
  espiral de la zona 1 hasta que exista el recorrido de la zona 3.
- Río de la batalla: `grupo: [2, 3]` y arcoíris cada 14 (valores de Nicole, provisionales hasta HE-92). El
  modo equipo del Río todavía no está cableado al motor (HE-70); para cuando lo esté,
  `LogicaRio.aciertos_por_reventon(es_cadena, cadena_vale_aciertos)` da la regla corregida de §7.
- Pendiente: la opción "menos movimiento" no existe aún en `Progreso`; el motor la lee si aparece un método
  `menos_movimiento()`. Los SFX propios del Río (clac, boing, glug, fiuuu, puaj, arpegio, cuerda elástica)
  son provisionales: se reusan los de la interfaz con otro tono.

## 15. Qué debe probar el arnés `herramientas/qa_test_rio.gd`

Todo con semilla fija y sin pantalla, salvo lo marcado como escena.

1. **Generador con `grupo: [min, max]`**: en 3.000 ríos por perfil, ningún grupo fuera de `[min, max]`,
   **aparecen todos los tamaños del rango** (el 3 incluido, regresión del error 1), dos grupos seguidos nunca son del mismo color, el
   último grupo no baja de `min` y la fracción de secundarios queda en `p_secundario` ± 5 puntos. Sin
   `grupo`: el río sale idéntico al de la v1 con la misma semilla.
2. **2 + 1**: exactamente `cantidad`, de `tipos` tipos, ninguno entre las primeras 12, separados ≥ 8,
   siempre entre dos grupos y nunca partiendo uno.
3. **Retroceso**: `AA BB AA` + `B` → revientan 3 B, luego 4 A con `es_cadena` y `cadena == 2`; `retroceso_atrae`
   antes del choque y `retroceso_choco` en el choque; un par que coincide pero suma 2 choca sin reventar.
4. **Combo frente a cadena**: dos aciertos directos seguidos → `combo == 2` y `cadena == 1` (nunca "Cadena
   ×2"); un disparo sin reventón → `combo == 0`; disparos a la batidora y balas que salen no tocan el
   combo; puntos = `gotas × 10 × cadena` + bono de combo.
5. **Arcoíris**: nunca dos con menos de 6 disparos entre ellas; frecuencia media dentro de lo esperado
   (§9) antes y después del 60 %; revienta un grupo de 1; pasa por encima de la batidora; no se cambia
   por munición justa; no se pierde al servir ni con un rebote.
6. **Batidora — captura**: un primario válido entra y el resultado en vivo es el correcto para todas las
   combinaciones de la tabla de §10.3.
7. **Batidora — rechazo**: rosado, secundario, 2 + 1, servida, llena, repetido (2 espacios), tercer igual
   (3 espacios) y durante el café → rebote con su `motivo`, y la gota vuelve a la boca.
8. **Batidora — café**: rojo + amarillo + azul con 3 espacios → café, todo rebota 1,2 s y después queda
   vacía. Con 2 espacios nunca sale café.
9. **Servir 2**: con resultado servible, la palanca entrega 2 gotas a boca y mano, lo anterior queda en
   pendientes y vuelve en orden; sin resultado servible no cambia nada; la servida sin destino se evapora
   (§8.2).
10. **Túnel no golpeable**: una bala que cruza el túnel no inserta en las gotas escondidas; las gotas
    escondidas sí empujan y retroceden; sin batidora no hay túnel.
11. **Munición ponderada**: en 10.000 cargas con un río fijo, la frecuencia de cada color se acerca a su
    peso (×3 en las 12 de la cabeza, ×0,6 para ingredientes); un color que no está en el río nunca sale.
12. **Simulación por perfil** (como hoy): jugador automático con y sin batidora, % de victorias, tiempo
    medio, disparos por arcoíris, servidos por río y cafés por río (datos para §16).
13. **Escena**: tocar la palanca (presionar y soltar dentro de los 96 px) sirve; tocar a Coco intercambia;
    un toque en la palanca no dispara; perder y reintentar; ganar y `completado`.

Y en el arnés de la batalla (`qa_test_gestor_turnos` o el que cubra el Río de equipo): dos aciertos
directos seguidos **no** cuentan como cadena para `cadena_vale_aciertos`.

---

## 16. Pedidos a otros roles

| Rol | Pedido |
|---|---|
| **`disenador-niveles`** | Calibrar con el simulador y el arnés: `gotas`, `grupo`, `velocidad`, `subida`, `p_secundario`, `arcoiris.uno_cada` (con la frecuencia **real** de §9), `terciarios.cantidad` (nTer) y tipos, `tiempo_par`, y **en qué zona o etapa entran los colores de 2 + 1** y la batidora de 3. Decidir si el Río de la batalla migra a `grupo` o se queda con el generador v1. Rehacer la tabla de zonas 2-5 del roadmap §10 con los ríos más largos |
| **`disenador-personajes`** | Arte de la **batidora** (vaso con líquido que cambia de color y nivel, motor con puntitos por espacio, aspas, sacudida, eructo de café), el **puente** de galleta, las **bocas del túnel** y la **palanca** (estado gris, dorado con halo y hundido). Que todo se lea a 72 px y combine con la Isla de los Dulces |
| **`guionista`** | **Nombres para los niños de los 6 colores de 2 + 1** (que Sofía pueda decirlos; sin texto obligatorio). Llevar al PO la decisión pendiente **"naranja" o "naranjo"** (afecta la receta del HUD y las voces). Línea corta de Coco para el primer río con batidora y para el primer café, si el PO las quiere (fuera de los disparos) |
| **`experto-ux-parvulo`** | Validar la **palanca** (≥ 64 px, posición junto al borde inferior) y el **rebote** (que se entienda como "esto no va aquí" y no como error), más los riesgos de §17 |
| **`dev-godot`** | Implementar sobre `LogicaRio` con las señales de §13.3, sin romper la batalla (§14) |
| **`tester-qa`** | Ampliar `qa_test_rio.gd` con §15 |

---

## 17. Riesgos de usabilidad (para que audite `experto-ux-parvulo`)

| # | Riesgo | Propuesta / qué mirar |
|---|---|---|
| R1 | **Palanca junto al borde inferior**: centro en y ≈ 678; su zona de 96 px llega a y ≈ 726, fuera de los 720, junto a la barra de gestos de Android | Probar en la tablet. Si molesta: palanca al costado de la batidora (por ejemplo, 110 px a la derecha) o subir el puente |
| R2 | **El rebote se lee como "me equivoqué"** | "Boing" chistoso, la batidora dice que no con la cabeza, la gota vuelve a la boca (no se pierde) |
| R3 | **Dos pasos para Nicole** (2 disparos a la batidora + palanca) con memoria de trabajo de 5 años | Flechas, recetas encendidas, palanca dorada que late. Medir en el playtest si sirve sola o si necesita a un adulto |
| R4 | **Disparar hacia abajo cuando lo que quería era el río** cerca del puente | El anillo de la guía (Nicole) se dibuja sobre la batidora; Sofía no tiene guía: es parte del reto |
| R5 | **Gotas escondidas en el túnel**: el niño "pierde" un color de vista | Solo ~2,5 gotas escondidas; Maxi no tiene túnel |
| R6 | **Ríos largos**: Maxi con 50 gotas a 13 px/s puede jugar ~3 min seguidos; la cola no se ve | Medir la atención de Maxi; la barra de "cuánto río queda" debe leerse sin números |
| R7 | **La caja de recetas** con 6 filas (Sofía difícil) llega a y ≈ 384 y roza el cauce de la derecha (x ≈ 1040-1062, y ≈ 372) | Verificar en captura; si choca, recetas en 2 columnas o más arriba |
| R8 | **Distinguir los 2 + 1** de su primario y su secundario (rojo / rojo anaranjado / naranja) | Receta en puntitos sobre la gota; revisar con daltonismo simulado |
| R9 | **El café frustra** a Sofía si sale seguido | Es su peligro elegido por el PO; medir cafés por río en el simulador y el playtest |
| R10 | **Servir cambia lo que Coco tenía** en boca y mano | La cola (§8.3) lo devuelve después; validar que no confunda |
| R11 | **Temblor de pantalla** en tablet | Suave (0,14 y 0,3) y desactivable |

---

## 18. Preguntas abiertas para el PO

1. **[Resuelta por el PO, 17-Oct-2026] Etapa difícil de Sofía**: los colores de 2 + 1 y la batidora de 3
   entran **desde la zona 3**.
2. **[Abierta] "Naranja" o "naranjo"**: sigue pendiente (la lleva `guionista`).
3. **[Resuelta por el PO, 17-Oct-2026] Río de la batalla**: **también pasa a grupos largos y gota
   arcoíris**. `rio_equipo.json` gana `grupo` y `arcoiris`, y `disenador-niveles` lo re-simula (el
   calibrado v1 deja de valer). Batidora y 2 + 1 en la batalla: no se pidieron; queda sin batidora.
4. **[Resuelta por el PO, 17-Oct-2026] Maxi y el remolino**: **el río de Maxi no se detiene; Maxi también
   puede perder**. La suavidad viene de los grupos de 3-4, la velocidad baja y el arcoíris, no de un tope.

La maqueta `docs/maquetas/rio-v2.html` quedó **aprobada por el PO** (17-Oct-2026: "funciona correctamente").
Su único error de retroceso (dos grupos iguales que chocaban sin reventar) ya está corregido en
`LogicaRio` (`_chocar()` y `_atraidas`); HE-91 parte de esa lógica, no de la maqueta.

Decisiones tomadas por delegación en esta ficha (se pueden revertir): §5.1 último grupo; §5.3 2 + 1
entre grupos; §6 rampa de 0,1 s; §7 disparos a la batidora neutros para el combo; §8.2 servida sin
destino se evapora; §8.3 cola de munición; §9 el mínimo cuenta disparos; §10.4 "boing" en vez de
zumbido; §10.8 `pistas` por perfil; §13.2 `puente_batidora` en el recorrido.
