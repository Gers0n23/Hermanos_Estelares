# Roadmap — «Río de pintura» (Zuma), primer juego del Planeta Arcoíris

> **Decisión del PO (06-Oct-2026)**: después de probar los mockups jugables, el PO elige el
> tipo Zuma como **primer juego del Planeta Arcoíris** para los tres hermanos: "es perfecto para
> nuestro caso de uso". Reemplaza a la estación «Lluvia de colores» (motor `clasificar`) y al
> «Taller de pinturas» de Sofía (motor `mezclar`), que fallaron en el playtest del 03-Oct-2026
> por fáciles, repetitivos y lentos. **Maxi también lo juega (PO, 06-Oct-2026): el mismo juego
> que Nicole, solo que más lento** (ver §10).
>
> - **Mockup de referencia**: https://claude.ai/artifact/ECHQe9t5pnJeFDjYpTJD2Q (archivo
>   `rio-de-pintura.html`). Todo lo que este documento llama "como el mockup" sale de ahí.
> - **Referencias de mecánica (regla de oro 3)**:
>   - **Zuma / Zuma's Revenge** (PopCap): cadena, inserción, retroceso, bonos y jefes.
>   - **Luxor**: gotas comodín y poderes que se activan al reventarlos.
>   - **Marble Shooter / Marble Legend** (móvil): poderes vistosos, ayudas antes de jugar,
>     obstáculos y estrellas por nivel.
> - **Estado**: propuesta para validar. Ningún diseñador la ha revisado y nada está en el
>   tablero. Las tarjetas de §13 las crea `scrum-master` cuando el PO lo apruebe.

---

## 1. La idea en una frase

Una **nube gris** destiñe el planeta y deja caer un río de gotas de pintura por un cauce de
galleta hacia un **remolino gris** que se las traga. **Coco**, sentada en un plato giratorio al
centro, las atrapa y las dispara con su lengua de camaleona: con tres iguales juntas, la pintura
**salpica de vuelta al paisaje**. Al vaciar el río, el escenario quedó pintado de nuevo.

**Por qué funciona para nosotros:**
- **La historia es la mecánica**: "devolverle los colores al planeta" se ve en cada disparo.
- **Coco es protagonista de verdad**: sin ella no se juega. La ficha se diseñó pensando en
  Nicole.
- **Hay reto real** de velocidad, récord y estrellas, y la escala de dificultad ya viene probada
  en Zuma.

---

## 2. Pilares (todo lo que se agregue se mide contra esto)

1. **Reto real, nunca castigo.** El río apura de verdad. Perder es cómico, nunca triste, y el
   reintento está a un toque.
2. **Se entiende sin palabras en 5 segundos.** Colores bien distintos, el remolino se lee como
   peligro y los poderes llevan íconos grandes. Sin voces entre disparos.
3. **Coco reacciona a todo.** Cada disparo, combo, poder y susto tiene su gesto.
4. **El mundo se pinta.** Cada reventón salpica el paisaje, y el avance se ve en el escenario,
   no en una barra.
5. **Siempre hay algo nuevo.** Cada zona trae un poder, un obstáculo y una forma de río nueva,
   como en Zuma, donde ningún mundo se juega igual que el anterior.

---

## 3. Camaleona Coco: biblia de animación

Fuente visual: ficha HE-A4a en `docs/guia-estilo-generacion.md` §3 y ancla
`assets/anclas/camaleona_coco_referencia.png` (v5 aprobada). **Reglas que no se rompen:**

- Ojos siempre mirando juntos hacia el mismo lado.
- Piel base lavanda: el cambio de color es un baño, no un recolor permanente.
- Florcita rosa fija junto a la base de la cresta.
- Nada de garras.

### 3.1 Cómo dispara (lo que la hace única frente a la rana de Zuma)

- **La gota cargada va en la boca**: se ve asomando entre los labios, con brillo.
- **La gota de reserva va en la punta de la cola-brocha**, que en la ficha ya es una brocha de
  pintor: la cola en espiral la sostiene arriba, visible.
- **Disparo = lengüetazo**:
  - La lengua sale estirada (squash & stretch) unos 60 px hacia donde apunta y lanza la gota.
  - Luego vuelve con un "slurp".
  - Duración total: 0,12 s. Nunca frena el ritmo; el enfriamiento del mockup (0,22 s) lo cubre.
- **Recarga**: la cola mueve la gota de reserva a la boca (arco de 0,15 s), y una gota nueva
  "brota" en la brocha.
- **Intercambio** (tocar a Coco): la cola y la boca cambian de gota con un malabar rápido.
  Coco guiña un ojo.
- **Apuntar**:
  - Coco gira entera sobre su **plato giratorio**, un pastel en su base de torta que hace juego
    con la Isla de los Dulces. Gira con suavizado: sigue el dedo con un pequeño retraso
    elástico, nunca un giro seco.
  - La cabeza se adelanta un poco al cuerpo y los ojos se adelantan a la cabeza (jerarquía de
    anticipación).

### 3.2 Cambio de color (el truco del camaleón)

- Al cargar una gota, una **ola de color recorre a Coco de la cola a la cabeza** en 0,25 s y la
  piel queda teñida a un 35% del color de la gota sobre el lavanda.
- El **nudito de la cresta** del mismo color se enciende fuerte; los demás quedan suaves.
- Con la gota arcoíris, la ola es de franjas que se mueven sin parar.
- Implementación: shader de tinte por máscara (vientre y hocico crema no se tiñen) más
  modulate del nudito. Se puede reutilizar la lógica de `scripts/motores/lienzo_libre/cresta_coco.gd`.

### 3.3 Catálogo de estados y animaciones

| Estado | Cuándo | Animación | Duración |
|---|---|---|---|
| **Reposo** | sin tocar | Respira (torso ±3%), parpadea cada 2-5 s al azar, la cola se enrosca y desenrosca lento, los nuditos laten en ola | bucle |
| **Sigue el dedo** | dedo en pantalla | ojos y cabeza siguen el dedo; brillo en la gota de la boca | continuo |
| **Disparo** | soltar | lengüetazo §3.1, retroceso del cuerpo 4 px, pestañeo | 0,12 s |
| **Acierto** (3+) | reventón | cabeceo feliz; el nudito del color salta | 0,3 s |
| **Combo** (2.º acierto seguido o más) | racha | cada acierto enciende un nudito más; con 3+, ojos como estrellas | 0,4 s |
| **Cadena** (retroceso que revienta) | reacción en cadena | se agarra las mejillas con las manoplas, "¡¿uuuh?!", y al reventar aplaude | 0,8 s |
| **Fallo** (no revienta) | gota insertada sin match | nada: no se castiga el tiro | — |
| **Gota rebotó afuera** | disparo que no toca el río | la mira irse haciendo "ups" con la mano en la boca | 0,4 s |
| **Peligro** | cabeza del río a más del 80% | cresta parpadea, gotita de sudor, mira al remolino de reojo; nunca llora | bucle |
| **Poder activado** | §6 | gesto propio de cada poder | 0,5-1 s |
| **Súper listo** | cresta llena (§7) | todos los nuditos brillan arcoíris; la cola-brocha chispea | bucle |
| **Ganar** | río vacío | salta del plato, aplaude con las manoplas, giro con la cola, la cresta arcoíris al máximo, gran sonrisa | 2 s |
| **Glu glu** (perder) | río tragado | la salpica la ola gris, queda gris y chorreada con cara de "¿en serio?", se sacude como perrito y vuelve a lavanda | 1,5 s |
| **Aburrida** | 8 s sin tocar | bosteza, se lame el ojo (los camaleones lo hacen, es chistoso) y atrapa con la lengua una chispita que pasaba | 2 s |
| **Bienvenida** | inicio del río | entra rodando por el cauce hasta su plato y saluda | 1,2 s |

### 3.4 Rig

- **Cutout por partes** según el stack §5, punto 4.
- **Piezas**: cabeza con casquete y flor, mandíbula, lengua en 3 segmentos para el estirón,
  torso, vientre (máscara), 2 bracitos-manopla, 2 patitas, cola en 4 segmentos para el
  enrosque, brocha de la punta y 6 nuditos de cresta como sprites aparte (para encenderlos uno
  por uno).
- **Ojos**: aparte (pupila móvil más párpado) para mirar y parpadear.
- **Costo**: el despiece se genera con la herramienta del pipeline (API de pago). **Hay que
  estimarlo con `--estimar` y pedir el OK del PO sobre el costo antes de generar.**

---

## 4. Escenario 2D

### 4.1 Capas (de atrás hacia adelante)

1. **Cielo**: degradado amanecer de algodón de azúcar. El **arcoíris del planeta** cruza el cielo
   con las franjas de los colores ya recuperados (se conecta con la cresta de Coco y el mapa del
   planeta, ficha de zonas §2.2).
2. **Fondo de zona**: el hito dulce de la zona (§4.4), con parallax suave (2-4 px según la
   inclinación o el dedo).
3. **Cauce**: el camino del río es un **canal de galleta con borde de glaseado de menta**, y las
   gotas ruedan dentro. El cauce marca el recorrido completo, así el niño ve por dónde viene el
   río.
4. **Gotas** (la acción).
5. **Decoración viva**: plantitas-pincel, hongos a lunares y gomitas que se mecen cuando pasa una
   gota cerca, y se sacuden cuando revienta un grupo al lado.
6. **Frente**: alguna hoja o nube de borde con desenfoque leve, para dar profundidad.

### 4.2 La entrada y el remolino

- **Entrada**: la **nube gris** asoma en el borde y gotea las gotas al cauce. Si llueve mucho,
  se le inflan los cachetes.
- **Remolino gris**:
  - Gira lento y se acelera según lo cerca que esté la cabeza del río.
  - Sobre el 80% tira chispitas grises y suena un "glu" grave cada tanto.
  - Al ganar se **cierra y florece** en una flor arcoíris.
  - El color gris se usa **solo** para el enemigo y los obstáculos, para que se lea como "lo
    malo" sin asustar.

### 4.3 El mundo se pinta (la barra de progreso es el paisaje)

- El escenario parte **desaturado al 70%**.
- Cada reventón lanza **manchas de pintura** del color de las gotas hacia el paisaje. Caen sobre
  árboles, hongos y suelo, y se quedan (decals).
- La saturación global sube a medida que se vacía el río. Con el río vacío todo está a color, y
  esa imagen final es el premio visual.
- **Técnica**: un `SubViewport` de "pintura acumulada" que se multiplica sobre la capa gris, más
  un shader de saturación sobre el fondo.
- **Rendimiento**: el número de manchas tiene un tope (rotan las más viejas). Verificar en tablet
  (HE-31).

### 4.4 Un escenario por zona, con su propia forma de río

| Zona | Escenario | Forma del río | Novedad de recorrido (referencia) |
|---|---|---|---|
| 1 · Claro del Trébol | Frutilla gigante, trébol de gomita, la nave de los hermanos estacionada | Espiral simple (como el mockup) | — |
| 2 · Charcos Saltarines | Gelatina de limón que tiembla y charcos de miel | Doble S | **Túnel**: el río pasa por debajo de la gelatina y las gotas se ven borrosas y temblando a través de ella (Zuma: túneles) |
| 3 · Bosque de Chupetines | Tres chupetines de espiral | El río **es** la espiral de un chupetín gigante | **Coco salta entre 2 plataformas** (hojas-galleta): tocar la otra la hace saltar (Zuma's Revenge: la rana cambia de nenúfar) |
| 4 · Islotes Flotantes | Malvaviscos y rodajas de naranja sobre una laguna de soda | Dos cauces | **Dos ríos** que vienen de dos nubes hacia el mismo remolino |
| 5 · Cima del Arcoíris | Torta de tres pisos con cereza | El río sube en espiral por los pisos de la torta, con un **puente** sobre sí mismo | **Jefe final: la Nube Gris** (§8) |

Los recorridos se dibujan como `Curve2D` y se guardan en datos (§12), así `disenador-niveles`
puede crear ríos nuevos sin tocar código.

---

## 5. Mecánica núcleo (lo del mockup, formalizado)

- **Cadena**:
  - Entra rápido hasta el 28% del recorrido y después avanza a la velocidad del nivel.
  - La **última gota empuja** a todas las de adelante.
  - Si se corta, la parte de adelante se queda quieta y la de atrás sigue empujando.
- **Inserción**: la gota disparada entra en el punto de impacto, abre espacio con un empuje
  elástico (0,1 s) y se evalúa: con 3 o más iguales contiguas, revientan.
- **Retroceso**:
  - Si quedan dos tramos cortados cuyos extremos son del mismo color, el tramo de adelante
    **retrocede** a 520 px/s, choca y vuelve a evaluar.
  - Eso produce **cadenas** ×2, ×3…, con multiplicador.
- **Mezcla (solo Sofía, como el mockup)**:
  - Coco solo escupe primarios.
  - Si un primario toca a otro primario **distinto** al insertarse, los dos se vuelven el
    secundario (rojo + azul = morado).
  - Así se fabrican los verdes, naranjos y morados que pide el río.
  - Es la palanca de dificultad propia de Sofía, y la que justifica el tema "colores".
- **Munición justa** (como en Zuma): Coco solo carga colores que **siguen en el río**. Si un color
  se acaba, deja de salir.

---

## 6. Gotas especiales (los poderes)

En el río aparecen **gotas con ícono**, como en Zuma: brillan y llevan un dibujito encima. Se
activan al **reventar el grupo** que las contiene. Solo la gota arcoíris se recibe como munición,
como el comodín de Luxor. Cada poder tiene su gesto de Coco y su sonido. **Se presentan de a uno**:
la primera vez que aparece un poder, el río se detiene 1,5 s, el ícono se agranda con un brillo y
Coco hace el gesto. Sin voz larga, y se puede saltar con un toque.

| Poder | Referencia | Qué hace | Cómo se ve | Coco | Desde |
|---|---|---|---|---|---|
| **Gota arcoíris** | comodín de Luxor | Munición: encaja con **cualquier** color y revienta el grupo donde cae | gota con franjas que giran | baño arcoíris, ojos de estrella | Z1 (B y E) |
| **Destellos voladores** | monedas de Zuma | Un destello cruza la pantalla 4 s; dispararle da puntos extra | estrellita dorada con estela | lo sigue con los ojos | Z1 |
| **Gota de miel** | Slow de Zuma | El río va a **la mitad de velocidad** 6 s | la miel chorrea sobre el cauce y las gotas ruedan pegajosas | se chupa los dedos | Z2 |
| **Gota de gelatina** | Reverse de Zuma | El río **retrocede** 3 s | el cauce tiembla y las gotas rebotan hacia atrás como resorte | rebota en su plato | Z2 |
| **Ojo de camaleón** | Accuracy de Zuma | 8 s de **mira láser** hasta la gota exacta y disparo más rápido | los ojos de Coco brillan y sale un rayo punteado arcoíris | un ojo gira (solo aquí y por 0,3 s, como chiste: luego vuelven juntos) | Z3 |
| **Gota chispa** | bomba de Zuma | Explota y **revienta todo en un radio** de 2 gotas | chispas de confeti | se tapa los ojos y se ríe | Z3 |
| **Gota helada** | Freeze (Marble Shooter) | El río **se congela** 4 s | escarcha de helado sobre el cauce; las gotas quedan como paletas | tirita y sopla las manoplas | Z4 |
| **Brochazo** | rayo de Zuma's Revenge y Luxor | La cola-brocha pinta un trazo que **revienta todas las gotas de ese color** que haya en pantalla | brochazo grande del color | gira la cola como un lazo | Z4 |
| **Gota camaleona** | Color bomb de Luxor | **Pinta del color** de la gota camaleona a las 4 vecinas de cada lado y luego evalúa | ondas de color que se contagian | cambia de color 3 veces muy rápido | Z5 |
| **Lengua triple** | Cannon de Zuma's Revenge | Los próximos 3 disparos salen en abanico de 3 gotas | tres lengüitas | hace muecas de esfuerzo | Z5 |

**Reglas de aparición** (las ajusta `disenador-niveles`):
- Como máximo, 1 gota especial visible por cada 15 gotas.
- Nunca 2 especiales seguidas.
- Los poderes de ayuda (miel, gelatina, helada) salen más cuando la cabeza del río pasa del 60%:
  es el "seguro" de Zuma que mantiene la tensión sin injusticia.
- **Nicole recibe ayudas más seguido y Sofía más poderes de puntaje.**

---

## 7. Habilidad de Coco: la cresta de ánimo (súper)

Copia de la barra de habilidad cargable de los Marble Shooter, montada sobre el rasgo de la ficha:

- Cada **acierto** enciende un nudito de la cresta y cada **cadena** enciende dos. Cuando están
  los 6, la cresta queda arcoíris y Coco brilla ("súper listo").
- **Tocar la cresta** (o a Coco con doble toque) activa el **Lengüetazo arcoíris**:
  - La lengua se vuelve un rayo arcoíris en la dirección donde apunta.
  - Revienta todas las gotas que cruza.
  - Sigue requiriendo apuntar: es habilidad, no un regalo.
- La cresta se **vacía al usarla**, no al fallar. No se pierde nada por equivocarse.
- **Nicole**: carga con 6 aciertos. **Sofía**: necesita combos y cadenas para llenarla (los
  aciertos sueltos cuentan medio).

### 7.1 Ayudas antes del río (los "boosters" de Marble Shooter)

- Antes de cada río, la mochila de Coco ofrece **elegir 1 de 3 ayudas**:
  - empezar con una gota arcoíris;
  - empezar con el Ojo de camaleón;
  - un río más corto (−5 gotas).
- Se desbloquean de a una al completar las zonas 1, 2 y 3.
- **Sin compras ni monedas**: son gratis y opcionales.
- **Decisión pendiente (§14)**: si usarlas baja el máximo de estrellas. En Marble Shooter no lo
  baja, pero los récords quedarían en duda.

---

## 8. El jefe: la Nube Gris (zona 5)

Toma el modelo de los jefes de Zuma's Revenge, que se dañan disparando por los huecos del río.

- La Nube Gris es grande, regordeta y gruñona-chistosa, con cara de berrinche. Flota en lo alto
  y **lanza el río**.
- Cada vez que el niño revienta un grupo, la pintura **salta hacia la nube** y la mancha.
- Con 5 manchas, la nube estornuda arcoíris, se vuelve una nube de colores feliz y le pide
  disculpas a Coco. Se gana aunque quede río en el cauce, y el río se vuelve pintura feliz.
- A mitad de pelea la nube se esconde detrás de la cereza de la torta y hay que esperar a que
  asome. Es ritmo, no velocidad pura.
- **Narrativa**: el `guionista` define quién es la Nube Gris: si es un invento del Coleccionauta
  ("me presta sus colores para mi colección") o un personaje propio del planeta. **Pregunta
  abierta para el PO.**

---

## 9. Bonus, puntaje, récords y estrellas

| Bono | Referencia | Cuándo | Feedback |
|---|---|---|---|
| **Combo** | combo de Zuma | aciertos seguidos sin fallar | contador que crece cerca de Coco; el tono del reventón **sube un semitono** por acierto |
| **Cadena ×N** | chain de Zuma | retrocesos que revientan | texto grande "¡Cadena ×2!" que rebota; temblor suave de pantalla |
| **¡Por un pelito!** | gap shot de Zuma | la gota pasó por un hueco entre dos tramos del río | estela dorada y +puntos |
| **Destello volador** | monedas de Zuma | §6 | sonido de campanita y +puntos |
| **Desfile final** | barrido final de Zuma | al vaciar el río | una chispa recorre el cauce vacío desde la nube hasta el remolino; cada tramo suma puntos y se ilumina de colores |
| **Río limpio** | — | ganar sin que el río pase del 50% | sello de florcita junto al puntaje |

- **Estrellas por río**: 1 por ganar, 2 por ganar bajo el tiempo par y 3 por superar el puntaje
  meta. Los valores los fija `disenador-niveles`.
- **Récord personal por río**, guardado en `Progreso`, con celebración "¡Nuevo récord!" en que
  Coco sostiene un trofeo-cupcake.
- **Nada de rankings entre hermanos**: cada uno compite contra su propio récord.

---

## 10. Escala por edad y por zona

**Base del mockup**:
- **Maxi** *(PO, 06-Oct-2026: "el mismo juego, pero más lento solamente")*: los parámetros de
  Nicole zona por zona, con **la velocidad del río a la mitad** (≈13 px/s en la zona 1). Nada
  más cambia: mismas gotas, colores, guía, poderes y escenarios. Si en el playtest se traba, la
  primera palanca es bajar más la velocidad, no cambiar la mecánica.
- **Nicole**: R 26, 36 gotas, 4 colores, 26 px/s, línea de guía.
- **Sofía**: R 22, 60 gotas, 6 colores, 46 px/s, sin guía, con mezclas.

La tabla da la curva propuesta, que `disenador-niveles` valida con playtest.

| Zona | Nicole · Brote | Sofía · Estrella |
|---|---|---|
| 1 · Claro | 30-36 gotas, 3→4 colores, guía completa; gota arcoíris | 50-60 gotas, 4 colores + mezclas guiadas (al apuntar se ve qué color saldría al mezclar) |
| 2 · Charcos | 40 gotas, 4 colores, túnel corto; miel y gelatina | 60-70, 5 colores, mezclas sin pista; túnel largo |
| 3 · Chupetines | 45, 4 colores, la guía se acorta a 300 px; salto entre plataformas opcional | 70, 6 colores, salto entre plataformas obligatorio (una vista no alcanza todo el río); chispa y Ojo de camaleón |
| 4 · Islotes | 2 ríos lentos de 25; helada y brochazo | 2 ríos de 40, más rápidos; **gota de caramelo** (hay que darle 2 veces) |
| 5 · Cima | 50, 5 colores; jefe Nube Gris con 3 manchas | 80, 6 colores; **gota gris** (no se revienta por color: solo con chispa, brochazo o súper) y **gota misteriosa** (muestra su color al acercarse a Coco); jefe con 5 manchas |

**Ríos por estación**: se proponen **3 ríos por zona** (como los niveles de cada mundo de Zuma):
15 por hermano.
- La **estación se marca completada al ganar el río 1**, así nadie se traba en el mapa.
- Los ríos 2 y 3 se abren en cadena y son reto, estrellas y récord.
- **Pendiente**: decisión del PO (§14).

**Palancas de dificultad**, tomadas de Zuma en este orden: velocidad, largo del río, número de
colores, forma del recorrido (curvas cerradas cerca del remolino), ayuda de puntería y
frecuencia de ayudas.

---

## 11. Sonido y música

- **Música**: un bucle alegre por zona, con instrumentación "de dulces" (marimba, glockenspiel,
  ukelele).
  - Una **capa de tensión** (percusión que acelera) entra de forma gradual cuando el río pasa
    del 70%.
  - Al ganar, cierre en fanfarria corta.
  - Sin ritmo jugable: el ritmo es de Melodía (regla de oro 3).
- **SFX clave**:
  - lengüetazo ("slurp" corto);
  - inserción ("plic");
  - reventón tipo burbuja de pintura, con tono que sube por combo;
  - retroceso (cuerda elástica);
  - cadena (campanitas en escala);
  - un sonido propio para cada poder;
  - "glu glu" del remolino;
  - el estornudo arcoíris de la Nube Gris.
  - Fuente: CC0 (pipeline stack §5).
- **Voz** (solo en estos momentos, nunca entre disparos):
  - una línea de Coco al empezar el primer río de cada zona;
  - presentación de cada poder nuevo (una palabra: "¡Miel!");
  - ganar, nuevo récord y "glu glu".
  - Las escribe el `guionista` (§13, H5).

---

## 12. Arquitectura (para `dev-godot`)

- **Motor nuevo `rio`** en `scripts/motores/rio/` y escena `escenas/minijuegos/rio/motor_rio.tscn`.
  - Extiende `minijuego_base.gd`, recibe `nivel` y emite `completado(destellos)` (regla de
    oro 4).
  - Coco, el escenario y los poderes son nodos hijos intercambiables.
- **La cadena no usa un `PathFollow2D` por gota**:
  - Es un arreglo de offsets sobre la `Curve2D` (distancia en el recorrido) que se dibuja con
    `MultiMeshInstance2D` o `_draw()`.
  - Así la física del empuje y del retroceso es la del mockup: simple y determinista.
- **Datos por río**: `datos/niveles/arcoiris/<zona>/rio_<perfil>_<n>.json`. Borrador:
  ```json
  {
    "id_nivel": "arcoiris_z1_rio_brote_1",
    "recorrido": "datos/recorridos/arcoiris/z1_espiral.json",
    "gotas": 36, "colores": ["rojo", "amarillo", "azul", "rosa"],
    "radio": 26, "velocidad": 26, "entrada_rapida_hasta": 0.28,
    "mezclas": false, "guia": "completa",
    "especiales": { "arcoiris": 0.04, "destello": 0.02 },
    "obstaculos": {},
    "cresta_aciertos": 6,
    "estrellas": { "tiempo_par": 70, "puntaje_meta": 1800 }
  }
  ```
- **Recorridos**: un JSON de puntos de control de la `Curve2D` más marcas de túnel y puente.
- **Herramienta para dibujar recorridos**: una escena de editor (`herramientas/editor_recorridos.tscn`)
  donde se arrastran puntos y se exporta el JSON, así `disenador-niveles` no edita números a mano.
- **`Progreso`**: estrellas y récord por río, más el estado de la estación. **Requiere una
  migración de versión** del JSON (HE-07). Los qa_test deben respaldar `progreso.json` (ver
  memoria del proyecto).
- **Mapa**: en `datos/planetas/arcoiris/mapa.json`, la estación "Lluvia" de los tres apunta
  a `motor_rio` (Maxi con `rio_semilla_<n>.json`). Los niveles `lluvia_semilla`, `lluvia_brote`,
  `lluvia_estrella` y `mezcla_estrella` quedan como legado, como ya pasó con el Taller.
- **Arnés de QA**: `herramientas/qa_test_rio.gd` simula disparos y verifica inserción,
  retroceso, cadenas, mezclas, poderes y fin del río. Usa semilla fija y es determinista.

---

## 13. Roadmap por hitos

El orden protege lo importante: primero **comprobar en Godot que el núcleo engancha a las niñas
en la tablet**, y después invertir en arte y poderes. Cada hito cierra con su revisión, y H1 y
H5 con playtest real.

### H0 · Decisión y fichas (diseño, sin código)
- Se registra la decisión en el GDD §4 (ya hecho en este cambio) y se crean las tarjetas en el
  tablero (`scrum-master`).
- **`disenador-mecanicas`**: ficha `docs/fichas/motor-rio.md` a partir de §5-§9 y del mockup.
  Incluye game feel, números de física, reglas de poderes y cresta.
- **`disenador-niveles`**: curva de los 15 + 15 ríos de Nicole y Sofía (los 15 de Maxi se derivan de Nicole con la velocidad a la mitad) (§10) y primeros recorridos de la zona 1.
- **`experto-ux-parvulo`**: audita la ficha. Puntos a revisar: lectura del peligro, tamaño de
  gotas, intercambio con un toque, que perder no frustre a Nicole.
- **Sale**: ficha aprobada por el PO.

### H1 · Núcleo jugable en Godot (gris, sin arte final) → 🧒 mini-playtest
- **`dev-godot`**: motor `rio` con recorrido `Curve2D`, cadena, inserción, retroceso, cadenas,
  mezclas, munición justa, ganar o perder, estrellas y récord en `Progreso` (con migración).
  Más el arnés `qa_test_rio.gd`.
- Coco provisional (`coco_base.png` girando, tinte simple) y escenario de la zona 1 con el
  paisaje actual.
- Tres ríos jugables de la zona 1 (Maxi, Nicole y Sofía), conectados al mapa del planeta.
- **`tester-qa`** en headless y **mini-playtest en la tablet**.
- **Sale**: las niñas piden "otra vez" (métrica de GDD §8). Si no pasa, se ajusta acá, antes
  del arte.

> **Estado H1 (06-Oct-2026, Dev, PROVISIONAL, falta mini-playtest)**: implementado y verificado.
> - **Código**:
>   - motor `rio` en `scripts/motores/rio/`: `recorrido_rio.gd`, `logica_rio.gd` (las reglas,
>     sin pantalla) y `motor_rio.gd`;
>   - escena `escenas/minijuegos/rio/motor_rio.tscn`.
> - **Datos**: recorrido `datos/recorridos/arcoiris/z1_espiral.json` y un río por hermano en
>   `datos/niveles/arcoiris/zona1_claro/rio_<perfil>.json`.
> - **Mapa**: la primera estación de la zona 1 abre el río para los tres, con ícono nuevo `rio.svg`.
>   Reutiliza los `id_nivel` de la Lluvia, así nadie pierde avance. Las zonas 2 a 5 siguen con la
>   Lluvia hasta tener sus ríos.
> - **Récord**: queda en `Progreso` (`records`, campo opcional, sin migración).
> - **Audio**: `Audio.reproducir_sfx` acepta `tono`, y el reventón sube un semitono por eslabón de
>   la cadena.
> - **Cambio respecto del mockup**: el remolino se traga el río en unos 2 s, sea del largo que sea.
>   Antes eran 8 s, demasiado para un gag.
> - **Coco provisional**: sprite canon con tinte del color cargado, lengua que sostiene la gota,
>   reserva en la mano, plato giratorio, salto al reventar, sudor en peligro y chorreada gris al
>   perder.
> - **Verificación**:
>   - `herramientas/qa_test_rio.gd` en verde;
>   - capturas en ventana real con `herramientas/capturar_rio.gd`.
>   - Jugador automático (5 semillas), primeros datos para la curva:

>     | Hermano | Gana con buena puntería | Promedio | Sin disparar, el río llega al remolino a los |
>     |---|---|---|---|
>     | Maxi | 5/5 | 68 s | 143 s |
>     | Nicole | 5/5 | 38 s | 78 s |
>     | Sofía | 5/5 | 55 s | 45 s |

### H2 · Coco viva
- **`disenador-personajes`**: despiece de Coco para el rig de §3.4. **Costo de API: estimar y
  pedir el OK del PO antes de generar.**
- **`dev-godot`**: rig cutout, el catálogo completo de estados (§3.3), lengüetazo, cola con
  reserva, plato giratorio y shader de cambio de color.
- **Sale**: el PO revisa a Coco en movimiento; idealmente, Nicole también.

### H3 · Escenario y "el mundo se pinta"
- **`disenador-personajes`**: los 5 escenarios por zona (§4.4), cauce de galleta, nube de
  entrada, remolino (y su flor), plantitas reactivas.
- **`dev-godot`**: capas con parallax, manchas de pintura acumuladas, desaturación a saturación,
  decoración reactiva, túnel de gelatina y puente de la torta.
- **Sale**: captura de cada zona en estado gris y a todo color, revisada por el PO y por UX.

### H4 · Poderes, súper y bonus
- **`dev-godot`**: los 10 poderes de §6 con sus animaciones y gestos de Coco, la presentación
  del poder nuevo, la cresta y el Lengüetazo arcoíris (§7), los bonus de §9 (combo con tono que
  sube, cadena, por un pelito, destellos, desfile final, río limpio) y la mochila de ayudas
  (§7.1).
- Obstáculos de Sofía: caramelo, gris y misteriosa.
- **`tester-qa`**: el arnés cubre cada poder.
- **Sale**: un río de prueba con todos los poderes, revisado por el PO.

### H5 · Contenido completo → 🧒 playtest del juego
- **`disenador-niveles`**: los 45 ríos en datos y sus recorridos.
- **`dev-godot`**: integración de las 5 zonas, salto entre plataformas (Z3), dos ríos (Z4) y el
  jefe Nube Gris (Z5).
- **`guionista`**: líneas de voz (§11) y personaje de la Nube Gris (§8). **Costo de TTS:
  estimar y pedir OK.**
- Sonido y música (§11).
- **`experto-ux-parvulo`** + **`tester-qa`**, y después **playtest con Maxi, Nicole y Sofía**: su
  reacción reordena el ajuste fino.
- **Sale**: las 3 rutas completas, sin bloqueantes UX.

### H6 · Pulido y tablet
- Ajuste de números con lo observado en el playtest, rendimiento en tablet (manchas, partículas,
  MultiMesh; cruza con HE-31) y accesibilidad (paleta distinguible: cada color lleva además una
  forma o carita en la gota, por si alguna niña confunde tonos).
- **Sale**: entra a la entrega del capítulo 1 (HE-32 y HE-18).

### Tarjetas propuestas para el tablero (las crea `scrum-master`)

| ID sugerido | Tarjeta | Depende de | Responsable |
|---|---|---|---|
| HE-57 | Ficha del motor `rio` (Zuma) | — | disenador-mecanicas |
| HE-58 | Curva y recorridos de los 45 ríos | HE-57 | disenador-niveles |
| HE-59 | Motor `rio` núcleo + Coco provisional + 2 ríos Z1 + arnés QA + mini-playtest | HE-57, HE-10 | dev-godot + tester-qa + PO |
| HE-60 | Coco: despiece, rig cutout y catálogo de animaciones | HE-59 | disenador-personajes + dev-godot |
| HE-61 | Escenarios de las 5 zonas y "el mundo se pinta" | HE-59 | disenador-personajes + dev-godot |
| HE-62 | Poderes, cresta súper, bonus, ayudas y obstáculos | HE-59 | dev-godot |
| HE-63 | Contenido de las 5 zonas + jefe Nube Gris + voces + sonido | HE-58, HE-60, HE-61, HE-62 | dev-godot + guionista |
| HE-64 | Auditoría UX/QA + playtest del Río de pintura | HE-63 | experto-ux-parvulo + tester-qa + PO |

Estas tarjetas reemplazan la Lluvia de colores (los tres perfiles) que hoy cuelga de
HE-14 y HE-43; `scrum-master` decide si las anota ahí o como épica propia.

---

## 14. Decisiones pendientes del PO

1. **Ríos por estación**: 3 por zona, con la estación completa al ganar el río 1 (propuesta), o
   un solo río por zona.
2. **Ayudas antes del río (§7.1)**: si bajan el máximo de estrellas o no.
3. **La Nube Gris**: si es invento del Coleccionauta o un personaje propio del planeta (§8).
4. ~~**Maxi**~~ *Resuelta (06-Oct-2026)*: juega el mismo río que Nicole, más lento (§10).
   Ojo: el GDD §5 dice que en Semilla "nunca se pierde", y el río sí puede llegar al remolino.
   El "glu glu" es cómico y el reintento es de un toque; si en el playtest le molesta, se puede
   hacer que su río se detenga antes del remolino (pendiente de confirmar por el PO).
5. **Nombre del juego frente a los niños**: "Río de pintura" (provisional) u otro que elijan
   ellas.
