# Los Hermanos Estelares — Documento de Diseño del Juego (GDD)

> **Fuente de verdad del diseño.** Cualquier implementación debe respetar lo que dice este documento.
> Si el diseño cambia (los niños crecen, un minijuego no funciona en la práctica), se actualiza aquí primero.

- **Última actualización**: 19-Jul-2026
- **Plataformas**: Táctil-primero (tablet Android), jugable también en PC con mouse
- **Motor**: Godot 4.x — 2D exclusivamente
- **Idioma del juego**: Español (narración por voz, mínimo texto en pantalla)
- **Estilo visual**: Cartoon vectorial — colores brillantes, formas redondas y amigables (referencia: Sago Mini, Toca Boca)

---

## 1. Premisa y guion

### La historia

Una tarde cualquiera, los tres hermanos juegan en el **living de su casa** — y en su
imaginación, donde todo es posible, comienza la aventura: una navecita diminuta entra
dando tumbos por la ventana y aterriza (mal, entre risas) en la alfombra. De adentro
sale **Cometa** *(nombre provisional — validar con los niños en HE-D2)*, un alien
pequeño, redondito y muy simpático, y trae una noticia increíble: el **Coleccionauta**,
un alienígena chistoso que recorre la galaxia coleccionando «las cosas más increíbles
del universo», acaba de llevarse a **papá** — le pareció el papá más increíble de todos
y quiere quedárselo para su colección. Cometa lo sabe de primera mano: él y el
Coleccionauta se conocen de toda la vida (juntos armaron su primera nave, de chicos, en
el mismo planeta) y sabe exactamente cómo es, qué le gusta y dónde guarda las cosas.

Cometa los convierte en los **Hermanos Estelares**: les entrega trajes espaciales con
estrellas de poder y su nave-estrella — con la tecnología que él ya conoce de memoria —
a la que le faltan piezas para un viaje tan largo.
Para llegar al lejano planeta del Coleccionauta deberán visitar **planetas divertidos**,
aprender nuevas habilidades en cada uno (colores, números, letras, música, emociones) y
ganarse la **pieza de la nave** que cada mundo guarda. Los minijuegos otorgan **destellos**,
la energía estelar que hace brillar los trajes y volar la nave.

En el planeta final no hay batalla: los hermanos descubren que el Coleccionauta no es
malo — solo está solito y nunca aprendió a pedir las cosas. Le enseñan que **los amigos
no se coleccionan: se hacen**, rescatan a papá entre risas y vuelven a casa con un amigo
nuevo que promete visitarlos. Y en el living, papá los abraza y los llama a comer: la
aventura queda lista para jugarse otra vez.

### El mensaje

El hilo narrativo enseña, sin sermones, que **juntos son capaces de cosas enormes**:
tres hermanos que se organizan, aprenden y no se rinden pueden cruzar la galaxia y
rescatar a su papá. Y de regalo, la lección del final: los amigos se hacen pidiendo,
compartiendo y jugando. Cada planeta refuerza además un tema concreto (colores,
números, emociones... ver §4).

**La lección de la cooperación** *(aprobada por el PO, 18-Jul-2026)*: la misión final
la vuelve jugable. La primera vez que los hermanos intentan la prueba del Coleccionauta,
cada uno quiere hacerlo a su manera, discuten... y todo sale mal **de forma cómica**
(el plan se desarma, la nave estornuda, el Coleccionauta se ríe). Cometa les hace
notar que separados no funciona: la prueba solo se supera **cooperando**, usando la
habilidad de cada hermano en secuencia — Sofía lee la pista y arma el plan, Nicole se
gana la confianza del Coleccionauta, Maxi encuentra lo que nadie más ve. Cuando pelean,
las cosas salen mal; cuando cooperan, avanzan y rescatan a papá.

### Tono

- Cálido, celebratorio y **de aventura empoderadora**: los niños son los héroes, nunca las víctimas.
- **El secuestro jamás da miedo**: todo ocurre en su propio juego imaginado, el Coleccionauta es
  cómico y torpe, y papá aparece en video-llamadas divertidas durante el viaje, siempre tranquilo
  y haciendo chistes («¡estoy bien! aunque este alien no se sabe ninguna adivinanza…»).
- **Se puede perder — pero perder siempre da risa** *(ajuste del PO, 18-Jul-2026)*: en los
  niveles de Nicole y Sofía la derrota existe y es un **gag** (el cohete hace *pffft* y aterriza
  en un charco, el personaje queda cubierto de pintura, los animales se ríen contigo). Risa
  primero, botón gigante de «¡otra vez!» inmediato y **cero progreso perdido**. La dificultad se
  ajusta a cada edad para que nunca sea imposible. Para Maxi (nivel Semilla) el fallo sigue sin
  existir: a los 2 años ni la derrota más chistosa se procesa bien.
- **Sin castigo ni presión de tiempo narrativa**: la misión avanza al ritmo de ellos — jamás un
  «apúrate que papá espera».
- Equivocarse siempre recibe ánimo ("¡casi! inténtalo otra vez") y acertar recibe fiesta (confeti, estrellitas, sonidos alegres).
- Humor físico simple: animales que estornudan, planetas que hacen cosquillas, rebotes exagerados.

---

## 2. Personajes

### Los tres hermanos (jugables)

| Personaje | Edad | Rol en la historia | Perfil de juego |
|---|---|---|---|
| **Maxi** | 2 años | El pequeño explorador valiente. Nada lo asusta: encuentra piezas y secretos donde nadie mira. | **Nivel Semilla** — tocar, arrastrar, causa-efecto. Sin fallo posible: toda interacción produce algo bonito. Cero texto, todo audio e íconos. |
| **Nicole** | 5 años | La embajadora artista: se hace amiga de los habitantes de cada planeta sin ningún miedo, y dibuja los recuerdos del viaje. | **Nivel Brote** — contar hasta 10-20, formas, memoria, clasificar, secuencias simples. Instrucciones 100% por voz. |
| **Sofía** | 8 años | La líder de la misión: lee las pistas, arma el plan y guía a sus hermanos hasta papá. | **Nivel Estrella** — lectura de palabras/frases cortas, sumas y restas, lógica, retos de habilidad suaves. Texto simple apoyado por voz. |

**Rutas personalizadas** *(decisión del PO, 18-Jul-2026 — reemplaza al modelo anterior de
"mismo minijuego, tres dificultades")*: la temática no escala con la dificultad — a Sofía
la aburriría un mundo que se siente "de bebés" y a Maxi no le dice nada un tema de niñas
grandes. Por eso **cada hermano tiene su propia ruta de niveles**, curada para sus gustos
(según sus fichas de `docs/perfil-jugadores.md`) y escalando de a poco: pocos niveles,
pero entretenidos y memorables. Las **mecánicas son motores compartidos** (emparejar,
contar, ordenar, buscar, ritmo...) y lo que cambia por niño es el contenido y el tema,
data-driven desde `datos/` — un motor, N niveles temáticos. Cualquiera puede jugar los
niveles de los otros hermanos (todo desbloqueado, sin castigo). En la historia, los tres
viajan juntos pero **cada uno tiene su propia misión en cada planeta** según su rol:
Sofía lidera y lee, Nicole hace amigos y dibuja, Maxi explora y encuentra.

**Diseño visual**: los tres con trajes espaciales del mismo diseño pero color propio
(a definir en la guía de estilo, tarjeta de Fase 0), cabezas grandes, ojos expresivos,
proporciones redondas. Cada uno con un gesto característico de celebración.

### Personajes de apoyo

- **Cometa** *(nombre provisional — validar con los niños en HE-D2)* — el alien guía (no es parte de la familia: es el personaje mágico del juego imaginado). Pequeño, redondito y muy entusiasta; aterriza (siempre dando tumbos, siempre riéndose de sí mismo) en el living, les entrega los trajes con estrellas de poder y pilotea la nave. **Conoce al Coleccionauta de toda la vida** — se criaron en el mismo planeta y de chicos armaron naves juntos — por eso sabe exactamente cómo tratarlo, qué le gusta y cómo funciona su tecnología (la misma que ahora usan los hermanos). Se alejó de él hace tiempo porque a Cometa no le gustaba coleccionar *cosas*: a él le gusta coleccionar **amigos** (guarda un "álbum de abrazos" con un recuerdo de cada amigo nuevo, nunca objetos en cajas) — un guiño juguetón a la lección final del juego. Narrador del juego: da instrucciones por voz, anima, celebra, nunca regaña ni apura. Flota/rebota en pantalla como ayudante permanente; tocarlo repite la instrucción.
- **El Coleccionauta** *(nombre provisional — validar con los niños en HE-D2)* — el alienígena coleccionista. Chistoso, torpe y para nada malvado: colecciona «las cosas más increíbles del universo» y se llevó a papá para su colección porque le pareció increíble (y porque está solito). En el final aprende a pedir las cosas y se vuelve amigo de la familia.
- **Papá** — el secuestrado más feliz de la galaxia. Aparece en video-llamadas cómicas desde la colección del alien, siempre tranquilo y bromista; su rescate es la gran escena final. *(Idealmente con la voz real de papá — ver P2.)*
- **Habitantes de los planetas** — un personaje anfitrión por planeta (ver §4), que da contexto a los minijuegos ("¡mis frutas se mezclaron, ayúdame a ordenarlas por color!") y guarda la pieza de la nave de su mundo.

---

## 3. Estructura del juego

### Lanzamiento por capítulos (seasons) *(decisión del PO, 18-Jul-2026)*

El juego se construye y se entrega **de a un planeta por vez**, como capítulos de una serie:

- **Capítulo 1**: desde la cinemática del secuestro de papá hasta completar todas las misiones
  del planeta 1 y ganar su pieza de la nave. Se construye la **maqueta del juego completo**
  (título, selección, mapa con todos los planetas visibles, hangar estelar, zona de padres),
  pero **solo el planeta 1 es jugable** — y ese planeta se define y pule hasta el último
  detalle para los tres niños: nada de su contenido queda genérico ni placeholder.
- **Capítulos siguientes**: cada actualización agrega un planeta y desarrolla la historia.
  La reacción de los niños a cada capítulo reordena el backlog del siguiente (regla de oro 5).
- **Los planetas aún no jugables jamás se sienten como un muro**: no hay candados ni
  «próximamente» — se ven en el mapa brillando «todavía muy lejos», y Cometa explica que
  la nave necesita más piezas para llegar tan lejos. Es un tease ilusionante, no un bloqueo.
- **Cada capítulo cierra en celebración, nunca en corte**: termina con la fiesta de la pieza
  conseguida y la video-llamada de papá que deja el gancho del siguiente planeta.
- **El capítulo 1 ya incluye las 3 rutas personalizadas** (§5) dentro del planeta 1, así el
  primer playtest valida el modelo completo.
- Matiz de arquitectura: lo bespoke es el **contenido**; los **motores** de mecánica se
  construyen reutilizables igual (regla de oro 3) — es lo que hace barato el capítulo 2.
- Requisito técnico derivado: **guardado versionado desde el día uno** — agregar planetas por
  actualización jamás puede borrar el progreso (registrado en el stack técnico).

```
Pantalla de título (tocar para empezar)
   └── Selección de personaje (3 retratos grandes — define la ruta personalizada)
         └── Mapa Estelar (hub): la nave navega entre planetas, rumbo al planeta del Coleccionauta
               ├── Planeta 1..N (misiones/niveles de la ruta de cada hermano + 1 escena de historia)
               │      └── Nivel → celebración → destellos ganados → vuelta al mapa
               │      └── Planeta completado → escena de historia → pieza de la nave
               ├── El hangar estelar (pantalla de progreso: la nave armándose pieza a pieza)
               └── Planeta final: la prueba cooperativa y el rescate de papá (se abre al reunir las piezas)
Modo misión familiar (turnos: cada hermano juega un nivel de su ruta desde el mismo dispositivo)
Zona de padres (acceso con candado: ajustes, progreso por hijo, volumen)
```

- **Sesiones cortas**: un nivel completo dura 2-5 minutos. Siempre se puede salir al mapa sin perder nada.
- **Progreso por perfil**: cada hermano avanza por su propia ruta (destellos y piezas de la nave). Se guarda automáticamente, sin preguntar.
- **Desbloqueo generoso**: los planetas se desbloquean en orden pero con muy poca exigencia (1-2 destellos). La progresión motiva, no frustra. El planeta final se abre al reunir las piezas de la nave.
- **Modo misión familiar** *(nuevo, decisión del PO 18-Jul-2026)*: modo por turnos en el mismo
  dispositivo — cada hermano juega un nivel de **su** ruta mientras los demás miran, apoyan y
  celebran; el avance de la misión es colectivo. Es la lección de cooperación hecha modo de
  juego. 100% local y offline (no viola el alcance negativo del §8: no es multijugador en línea).
  Se diseña como capa sobre los niveles existentes, no como contenido aparte. La **prueba final
  cooperativa** del planeta del Coleccionauta es el nivel pensado para jugarse así los tres.

---

## 4. Los planetas (mundos)

> ⚠️ **Sección en revisión** *(18-Jul-2026)*: con la decisión de rutas personalizadas (§2 y §5),
> los "minijuegos con 3 niveles S/B/E" de abajo pasan a leerse como **motores de mecánica** con
> ejemplos de escalado. El catálogo definitivo de niveles temáticos por hermano (y si siguen
> siendo 6 planetas de temas universales o menos planetas con misiones personalizadas dentro)
> se rediseñará al cerrar HE-D1, con las fichas de gustos de los tres completas.

Seis planetas, cada uno con un tema de aprendizaje, un anfitrión y 3-4 minijuegos.
Se desarrollan en este orden (el orden es también el del roadmap):

| # | Planeta | Tema de aprendizaje | Anfitrión | Paleta dominante |
|---|---|---|---|---|
| 1 | **Planeta Arcoíris** | Colores y formas | Camaleona Coco (cambia de color) | Multicolor pastel |
| 2 | **Planeta Animalia** | Animales, sus sonidos y hábitats | Perrito astronauta Toby | Verdes selva |
| 3 | **Planeta Melodía** | Música, ritmo y sonidos | Pulpo DJ Octavio (8 brazos, 8 instrumentos) | Morados y neón suave |
| 4 | **Planeta Cuenta-Cuentas** | Números y conteo | Búho contador Profesor Plumas | Azules noche |
| 5 | **Planeta Letralandia** | Letras, palabras y lectura | Dragoncita lectora Lila | Naranjas cálidos |
| 6 | **Planeta Corazón** | Emociones, empatía y valores | Nube Mimi (cambia con las emociones) | Rosas y celestes |

### Minijuegos por planeta (con su adaptación por nivel)

Cada minijuego lista su mecánica base y cómo escala en los tres niveles
(**S** = Semilla/Maxi, **B** = Brote/Nicole, **E** = Estrella/Sofía).

#### Planeta Arcoíris
1. **Lluvia de colores** — caen gotas de colores, hay que tocarlas/arrastrarlas al charco del mismo color. S: tocar cualquier gota hace magia de color. B: emparejar color correcto. E: mezclas (azul+amarillo=verde).
2. **Formas traviesas** — encajar formas en siluetas (tipo tablero de encaje). S: 3 formas grandes con imán generoso. B: 6-8 formas. E: figuras compuestas (una casa hecha de triángulo+cuadrado).
3. **Pinta con Coco** — lienzo libre para pintar con dedos/mouse; Coco imita los colores usados. Igual para todos (juego de expresión, sin objetivo). Se puede guardar el dibujo.

#### Planeta Animalia
1. **¿Quién habla?** — suena un animal, hay que tocar cuál fue. S: 2 opciones, ambas celebran pero se refuerza la correcta. B: 4 opciones. E: 6 opciones + animales menos comunes.
2. **Cada quien a su casa** — arrastrar animales a su hábitat (pez→agua, pájaro→nido...). S: 2 animales. B: 5. E: 8 + hábitats menos obvios (pingüino→hielo).
3. **Escondite animal** — escena llena de detalles donde encontrar animales escondidos (tipo "buscar y encontrar"). S: animales visibles que hacen ruido al tocarlos. B: encontrar los 5 de la lista (por voz). E: encontrar por pista leída ("busca al que tiene rayas").

#### Planeta Melodía
1. **La banda de Octavio** — tocar instrumentos que suenan de verdad (caja de sonidos). S: libre, todo suena bonito. B: repetir secuencias de 2-3 sonidos (tipo "Simon" muy suave). E: secuencias de 4-6 y ritmos.
2. **Sigue el ritmo** — tocar burbujas al compás de la música. S: las burbujas explotan al tocarlas, sin compás. B: compás lento y generoso. E: compás real con puntaje de estrellas.
3. **Canta con Cometa** — canciones infantiles con animación (karaoke visual). Igual para todos; en E aparece la letra escrita.

#### Planeta Cuenta-Cuentas
1. **Cosecha contada** — recolectar N frutas que pide el Profesor Plumas. S: tocar frutas y oír el conteo (1, 2, 3...). B: recolectar exactamente la cantidad pedida (hasta 10). E: sumas/restas ("recoge 5 y quita 2").
2. **El tren numérico** — ordenar vagones con números. S: tocar los vagones y oír los números. B: ordenar 1-10. E: completar secuencias con huecos (2, 4, _, 8) y ordenar hasta 20.
3. **Mercado espacial** — "comprar" con monedas estelares. B: pagar cantidades exactas contando. E: sumar precios y calcular vuelto simple. (S no tiene este juego; ve una animación de la tienda con sonidos.)

#### Planeta Letralandia
1. **Sopa de burbujas** — tocar burbujas con la letra que dice Lila. S: tocar burbujas y oír letras. B: encontrar su inicial y las vocales. E: formar palabras cortas (SOL, LUNA).
2. **La primera letra** — unir dibujos con su letra inicial. B: 3-4 pares con voz. E: escribir la palabra completa con teclado de letras en pantalla.
3. **Cuentos de Lila** — cuentos ilustrados cortos narrados por voz, con objetos tocables en cada página. S/B: escuchar y tocar. E: la letra resaltada sigue la narración (fomento de lectura).

#### Planeta Corazón
1. **¿Cómo se siente Mimi?** — Mimi muestra una emoción y hay que reconocerla. S: tocar a Mimi y ver/oír emociones. B: elegir la carita correcta entre 3. E: elegir "qué la haría sentir mejor" (escenarios de empatía).
2. **Ayudantes estelares** — mini-escenas de ayudar (regar una planta triste, compartir un juguete, abrigar a un amigo con frío). Interacción de arrastrar, igual para todos; los escenarios de E tienen decisiones.
3. **Respira con Mimi** — juego de calma: inflar/desinflar a Mimi siguiendo una respiración guiada. Igual para todos. Pensado como cierre de sesión ("antes de dormir").

### Escena de historia por planeta

Al recuperar todos los destellos de un planeta, se reproduce una **escena animada corta**
(15-30 s, sin interacción) donde el anfitrión agradece, entrega la **pieza de la nave**
de su mundo y, de regalo, llega una video-llamada cómica de papá desde la colección.
Son la recompensa narrativa y el "pegamento" del guion.

---

## 5. Rutas personalizadas y niveles por edad

*(Actualizado 18-Jul-2026 — decisión del PO: reemplaza al modelo "mismo contenido, parámetro de dificultad".)*

- La ruta la define **el personaje seleccionado**, nunca un menú de dificultad.
- **Arquitectura: motores compartidos + contenido por niño.** Cada mecánica (emparejar, contar,
  ordenar, buscar, ritmo...) es un motor reutilizable que carga niveles data-driven desde
  `datos/`: un archivo de nivel define tema, elementos, cantidades, uso de texto y tolerancia.
  La ruta de cada hermano es una secuencia curada de esos niveles, con temas de **sus** gustos
  (fichas de `docs/perfil-jugadores.md`) y escalando de a poco. **Un solo código por motor,
  tres rutas de contenido.**
- **Todo desbloqueado entre hermanos**: cualquiera puede entrar a los niveles de los otros,
  sin castigo ni bloqueo (jugar la ruta de otro no rompe el progreso propio).
- Regla de oro por perfil (aplica a los niveles de la ruta de cada uno):
  - **Semilla (Maxi)**: imposible perder, imposible trabarse. Todo lo tocable responde con algo agradable. Nada de texto ni menús intermedios.
  - **Brote (Nicole)**: se puede "no lograrlo" con derrota-gag y reintento suave inmediato; los errores dan pistas por voz. Máximo un objetivo a la vez.
  - **Estrella (Sofía)**: se puede perder de verdad — siempre con derrota chistosa, nunca imposible para su edad — y hay puntaje de 1-3 estrellitas para incentivar repetir; completar siempre es posible y siempre se celebra.
- **Perder nunca frustra** (ver §1 Tono): la derrota es un gag que da risa, reintento inmediato
  con botón gigante y cero progreso perdido.
- En la zona de padres se podrá **ajustar el perfil de cada niño** manualmente (los niños crecen: en un año Maxi puede pasar a Brote).

---

## 6. Diseño de interacción (UX para 2-8 años)

Reglas obligatorias para toda pantalla del juego:

1. **Objetivos táctiles enormes**: mínimo ~96 px lógicos para elementos que Maxi deba tocar; nada interactivo menor a 64 px.
2. **Todo se narra por voz**: ninguna instrucción depende de saber leer. Tocar a Cometa repite la instrucción.
3. **Sin texto para navegar**: navegación por íconos universales (casa, flecha, estrella) + audio.
4. **Sin dobles toques, sin gestos complejos**: solo tocar y arrastrar. En PC: clic y arrastrar con mouse (mismo código de entrada).
5. **Respuesta inmediata**: todo elemento tocado reacciona en <100 ms con animación y sonido, aunque sea "incorrecto".
6. **Sin publicidad, sin compras, sin enlaces externos, sin internet requerido.** Juego 100% offline.
7. **Zona de padres protegida**: con "candado adulto" (ej: mantener presionado 3 s y resolver 3+4). Ahí viven ajustes, volumen, progreso e (importante) el botón de salir del juego en tablet.
8. **Salir siempre es seguro**: cerrar el juego en cualquier momento no pierde progreso.
9. **Feedback de celebración generoso**: confeti, estrellas, bailecito del personaje y frase de ánimo al completar cualquier cosa.
10. **Volumen y música ajustables por separado** (música / efectos / voz), recordados por perfil.

---

## 7. Arte y audio

### Arte (cartoon vectorial)

- **Guía de estilo** (entregable de Fase 0): paleta maestra, grosor de contorno, proporciones de personajes, 3 poses base por hermano (idle, caminar, celebrar) — todo lo demás la referencia.
- Sprites en SVG (fuente) exportados a PNG de alta resolución; escenas pensadas para resolución base **1280×720** con escalado `canvas_items` (se ve bien en tablet y PC).
- Animación por **esqueleto simple / cutout en Godot** (Skeleton2D o AnimationPlayer sobre partes del cuerpo): ideal para vectorial, evita dibujar cuadro a cuadro.
- Producción de assets asistida por herramientas MCP/generación (ver stack técnico §Assets) + retoque manual.

### Audio

- **Voz de Cometa**: idealmente grabada por papá/mamá — que la voz que los guía sea la de casa es parte del regalo. Alternativa: TTS en español de calidad como relleno durante el desarrollo, reemplazable después (las líneas de voz viven en archivos, listadas en un guion de grabación).
- **Música**: una pieza suave por planeta + tema del mapa. Fuentes CC0 (Kenney, FreePD) o generada.
- **Efectos**: biblioteca CC0 (Kenney Audio) — pops, campanitas, aplausos, sonidos de animales reales.

---

## 8. Qué NO es este juego (alcance negativo)

Para proteger el proyecto de crecer hasta no terminarse nunca:

- ❌ Nada 3D, nada multijugador en línea, nada procedural.
- ❌ Sin sistema de vidas, energía, monetización ni cuentas.
- ❌ Sin física compleja: los minijuegos usan tocar/arrastrar/animar, no simulaciones.
- ❌ Sin más de 6 planetas ni más de 4 minijuegos por planeta en la v1.0.
- ✅ El éxito se mide en una sola métrica: **que Maxi, Nicole y Sofía pidan jugarlo de nuevo.**

## 9. Preguntas abiertas

| # | Pregunta | Responsable | Estado |
|---|---|---|---|
| P1 | Colores/diseño definitivo de cada hermano (¿los eligen los propios niños?) | Product Owner (papá + hijos) | Abierta |
| P2 | ¿Grabar voces reales de la familia para Cometa y celebraciones? | Product Owner | Abierta |
| P3 | ¿Qué tablet Android concreta usarán? (define resolución y rendimiento objetivo) | Product Owner | Abierta |
| P4 | Herramienta MCP definitiva para generación de sprites (ver stack técnico) | Dev | Parcial — GodotPrompter + godot-mcp adoptados (stack §4); generación de imágenes se decide en HE-03 |
| P5 | Catálogo de niveles temáticos por hermano (¿6 planetas universales o menos planetas con misiones personalizadas?) — requiere fichas completas de HE-D1 | PO + Dev | Abierta |
| P6 | Diseño detallado de la prueba final cooperativa y del modo misión familiar (flujo de turnos, UI de "le toca a...") | PO + Dev | Abierta |
