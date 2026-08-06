# Los Hermanos Estelares — Documento de Diseño del Juego (GDD)

> **Fuente de verdad del diseño.** Cualquier implementación debe respetar lo que dice este documento.
> Si el diseño cambia (los niños crecen, un minijuego no funciona en la práctica), se actualiza aquí primero.

- **Última actualización**: 06-Ago-2026 (HE-D3 — §4 catálogo de planetas validado contra gustos reales: se mantienen los 6 planetas, sus anfitriones y su orden 1-6, planeta 1 = Arcoíris confirmado; HE-D2 — §1-§2 personalizados con los hallazgos de `docs/perfil-jugadores.md`: personalidad y gestos de celebración reales de los tres hermanos)
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
sale **Cometa** *(nombre y ficha visual aprobados por el PO en HE-A1, 18-Jul-2026 —
la reacción real de los niños al nombre sigue pendiente: requiere un playtest presencial,
no se puede validar desde una sesión de escritorio; ver nota en §2)*, un alien
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

**La lección de la cooperación** *(aprobada por el PO, 18-Jul-2026; enriquecida con los
hallazgos de HE-D1, 06-Ago-2026)*: la misión final la vuelve jugable. La primera vez que
los hermanos intentan la prueba del Coleccionauta, cada uno quiere hacerlo a su manera,
discuten... y todo sale mal **de forma cómica** (el plan se desarma, la nave estornuda,
el Coleccionauta se ríe). Cometa les hace notar que separados no funciona: la prueba
solo se supera **cooperando**, usando la habilidad de cada hermano en secuencia — Sofía
(la líder, mini-mamá de sus hermanos) lee la pista y arma el plan, Nicole (la más
sociable y solidaria de los tres) se hace amiga del Coleccionauta compartiendo algo
suyo con él — un gesto pequeño que le enseña, sin sermón, que así es como se hacen los
amigos —, y Maxi (el valiente, nada lo asusta) encuentra lo que nadie más ve. Cuando
pelean, las cosas salen mal; cuando cooperan, avanzan y rescatan a papá.

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

*(Roles y personalidad actualizados en HE-D2, 06-Ago-2026, con los hallazgos de la
sesión de descubrimiento — `docs/perfil-jugadores.md`.)*

| Personaje | Edad | Personalidad | Rol en la historia | Perfil de juego |
|---|---|---|---|---|
| **Maxi** | 2 años | Muy despierto, bueno para bailar, actitud muy valiente. Nada lo asusta. | El pequeño explorador valiente. Nada lo asusta: encuentra piezas y secretos donde nadie mira. | **Nivel Semilla** — tocar, arrastrar, causa-efecto. Sin fallo posible: toda interacción produce algo bonito. Cero texto, todo audio e íconos. |
| **Nicole** | 5 años | Extrovertida, adorable y siempre contenta; muy solidaria, comparte sin dudar; hace amigos con facilidad y sin miedo al ridículo; mucha imaginación, ama dibujar y pintar. | La embajadora artista y solidaria: se hace amiga de los habitantes de cada planeta sin ningún miedo, comparte lo que tiene con quien lo necesita, y dibuja los recuerdos del viaje. | **Nivel Brote** — contar hasta 10-20, formas, memoria, clasificar, secuencias simples. Instrucciones 100% por voz. |
| **Sofía** | 8 años | Muy inteligente, líder natural, buena para leer y resolver desafíos; cuida a sus hermanos chicos como una "mini-mamá"; se frustra rápido, por eso el fracaso nunca castiga. | La líder de la misión y hermana mayor que cuida a los otros dos: lee las pistas, arma el plan y guía a sus hermanos hasta papá. | **Nivel Estrella** — lectura de palabras/frases cortas, sumas y restas, lógica, retos de habilidad suaves. Texto simple apoyado por voz. |

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
proporciones redondas.

**Gesto de celebración canon (validado en HE-D1, 06-Ago-2026)**: cada hermano celebra
con su gesto real de la vida — así la animación de victoria del juego es, literalmente,
"ellos mismos" ganando. No son placeholders: son la referencia definitiva para
`disenador-personajes` (poses de celebración) y `dev-godot` (animación de victoria).

- **Maxi**: grita «¡¡siiii!!» y da unos 3 saltitos con el puño derecho arriba.
- **Nicole**: el corazón coreano (dedos índice y pulgar cruzados) con expresión tierna.
- **Sofía**: mano en la cintura, piernas levemente flectadas hacia un lado, el otro
  brazo estirado en signo de la paz, guiño de ojo y cabeza levemente ladeada.

### Personajes de apoyo

- **Cometa** *(nombre y ficha visual de diseño, aprobados por el PO en HE-A1, 18-Jul-2026)* — el alien guía (no es parte de la familia: es el personaje mágico del juego imaginado). Pequeño, redondito y muy entusiasta; aterriza (siempre dando tumbos, siempre riéndose de sí mismo) en el living, les entrega los trajes con estrellas de poder y pilotea la nave. **Conoce al Coleccionauta de toda la vida** — se criaron en el mismo planeta y de chicos armaron naves juntos — por eso sabe exactamente cómo tratarlo, qué le gusta y cómo funciona su tecnología (la misma que ahora usan los hermanos). Se alejó de él hace tiempo porque a Cometa no le gustaba coleccionar *cosas*: a él le gusta coleccionar **amigos** (guarda un "álbum de abrazos" con un recuerdo de cada amigo nuevo, nunca objetos en cajas) — un guiño juguetón a la lección final del juego. Narrador del juego: da instrucciones por voz, anima, celebra, nunca regaña ni apura. Flota/rebota en pantalla como ayudante permanente; tocarlo repite la instrucción. **Pendiente**: el nombre "Cometa" es la decisión de diseño/PO vigente; falta la validación real con Maxi, Nicole y Sofía (mostrarles el arte, decirles el nombre, ver su reacción) — eso solo se puede hacer en un playtest presencial, no en esta revisión de guion, así que **queda anotado como ítem abierto** para la próxima sesión con ellos.
- **El Coleccionauta** *(nombre y ficha visual de diseño, aprobados por el PO en HE-A3, 18-Jul-2026)* — el alienígena coleccionista. Chistoso, torpe y para nada malvado: colecciona «las cosas más increíbles del universo» y se llevó a papá para su colección porque le pareció increíble (y porque está solito). En el final aprende a pedir las cosas y se vuelve amigo de la familia. **Pendiente**: mismo caso que Cometa — el nombre está aprobado por el PO pero su validación real con los niños queda para el próximo playtest presencial.
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

> ✅ **Catálogo validado contra los gustos reales** *(HE-D3, 06-Ago-2026 — PO + `disenador-niveles`,
> con las fichas de `docs/perfil-jugadores.md` ya completas)*: se contrastó cada uno de los 6
> planetas contra los gustos documentados de Maxi, Nicole y Sofía (detalle debajo de la tabla).
> Conclusión: **se mantienen los 6 planetas, sus temas, sus nombres y sus anfitriones tal como
> estaban** — ninguno resultó tan desconectado como para justificar reemplazarlo, y el modelo de
> "motores de mecánica + contenido por niño" (§2 y §5) es precisamente lo que permite que un
> planeta de tema universal (colores, animales, música...) se sienta propio de cada hermano vía
> sus variantes de contenido en `datos/`, sin necesitar un planeta dedicado por gusto. **El orden
> 1-6 tampoco cambia** — se evaluó adelantar Corazón, pero el orden actual ya está atado a un
> costo hundido aprobado que lo justifica mejor (ver nota bajo la tabla). El **planeta 1
> confirmado es Arcoíris**. Lo que queda abierto no es el catálogo en sí sino el
> detalle fino de las fichas de nivel por hermano dentro de cada planeta — trabajo normal de
> diseño de niveles (tarjetas de contenido), no un bloqueo de esta tarjeta. Responde también a
> la pregunta abierta P5 del §9 (marcada resuelta abajo).

Seis planetas, cada uno con un tema de aprendizaje, un anfitrión y 3-4 minijuegos.
Se desarrollan en este orden (el orden es también el del roadmap):

| # | Planeta | Tema de aprendizaje | Anfitrión | Paleta dominante | Por qué conecta con los tres *(HE-D3)* |
| --- | --- | --- | --- | --- | --- |
| 1 | **Planeta Arcoíris** | Colores y formas | Camaleona Coco (cambia de color) | Multicolor pastel | **Planeta 1.** Nicole: pintar/dibujar es su gancho más seguro y ya vive aquí (`Pinta con Coco`); sus colores favoritos (rosa) y los de Sofía (rosa/turquesa) caben naturalmente en la paleta "multicolor pastel". Sofía: mezclar colores (azul+amarillo=verde) es un reto real, no "de bebés". Maxi: la mecánica de causa-efecto inmediata (tocar y que pase algo bonito al instante) es ideal a los 2 años aunque Coco no sea su animal favorito — lo que lo engancha a esta edad es la respuesta sensorial, no el personaje. Es además el tema más elemental para abrir el juego (ninguna habilidad previa requerida), coherente con "primer nivel = victoria fácil" (ver principios). |
| 2 | **Planeta Animalia** | Animales, sus sonidos y hábitats | Perrito astronauta Toby | Verdes selva | La conexión más fuerte de los seis, y con los tres a la vez: caballos/jirafas/gatitos (Nicole), ponys/gerbos/**perritos**/gatitos cachorros (Sofía — Toby es literalmente su animal favorito), y "dinosaurios" + "animales" en general, ficha explícita (Maxi). Es el hogar natural de la variante de dinosaurios de Maxi (ver nota debajo de la tabla). |
| 3 | **Planeta Melodía** | Música, ritmo y sonidos | Pulpo DJ Octavio (8 brazos, 8 instrumentos) | Morados y neón suave | Bailar y cantar conecta con los tres: Maxi "bueno para bailar" (ficha), Sofía "muy buena para bailar y cantar" (ficha), y la paleta morado/neón ya evoca la estética que Nicole y Sofía comparten (guerreras k-pop / Rumi) sin copiar ninguna IP. |
| 4 | **Planeta Cuenta-Cuentas** | Números y conteo | Búho contador Profesor Plumas | Azules noche | Tema académico sin anfitrión-mascota favorito de ninguno de los tres, pero necesario para el reto real que pide Sofía (sumas/restas, "lo fácil le parece de bebés") y el conteo de Nicole (hasta 10-20). `El tren numérico` es además una variante natural para el gusto de Maxi por los vehículos/trenes (ver nota debajo). |
| 5 | **Planeta Letralandia** | Letras, palabras y lectura | Dragoncita lectora Lila | Naranjas cálidos | Entrena la habilidad que Sofía usa para liderar la prueba cooperativa final ("Sofía lee la pista y arma el plan", §1) — llega justo antes de Corazón, así que el jugador la trae fresca. El dragón y los cuentos ilustrados también dan pie a variantes de fantasía/escuela de magia que resuenan con su gusto por Harry Potter, sin copiar la IP. |
| 6 | **Planeta Corazón** | Emociones, empatía y valores | Nube Mimi (cambia con las emociones) | Rosas y celestes | Último planeta antes de la prueba final — y a propósito: la solidaridad de Nicole ("muy solidaria, le gusta compartir") y la fragilidad emocional de Sofía ("es llorona, se frustra rápido") lo hacen directamente relevante para ambas, y entrena justo el tema del clímax (aprender que los amigos no se coleccionan, se hacen; Nicole "se gana la confianza" del Coleccionauta, §1). Coincide además con que su pieza de nave — el "corazón del motor/núcleo central" — ya está diseñada y aprobada (HE-A6) explícitamente como la **última** pieza, la que enciende toda la nave justo antes del planeta final: moverlo de posición habría exigido retrabajar esa ficha ya aprobada sin necesidad real. |

### Por qué Arcoíris sigue siendo el planeta 1 *(HE-D3)*

- **Onboarding ideal**: colores y formas no requieren ninguna habilidad previa (ni contar, ni
  leer, ni reconocer animales) — es el tema más fácil de convertir en "victoria fácil que enseña
  la mecánica sin explicarla" (principio de diseño), válido a la vez para Maxi, Nicole y Sofía.
- **Conecta de verdad con al menos dos de los tres** (ver tabla): "Pinta con Coco" es el gancho
  más seguro de Nicole documentado en su ficha, y el reto de mezclar colores es genuinamente un
  desafío para Sofía, no relleno. Para Maxi la conexión es de mecánica (respuesta sensorial
  inmediata), no de personaje-favorito — válido a los 2 años, donde eso es lo que importa.
- **Costo hundido real, no placeholder**: la ficha de Camaleona Coco (HE-A4a) y el ambiente del
  Planeta Arcoíris (HE-A7a) ya están diseñados y generados (varias iteraciones de arte cada uno,
  ver `docs/guia-estilo-generacion.md` §3), marcados "provisional hasta que HE-D3 confirme el
  orden" — esta tarjeta **confirma ese orden**, así que ese trabajo deja de ser provisional y
  puede pasar a aprobación formal del PO sin rehacerse.
- **Ningún otro planeta superaba a Arcoíris por margen suficiente para justificar tirar ese
  trabajo**: Animalia conecta más fuerte con los tres gustos-animal específicos, pero por eso
  mismo rinde más como "planeta 2 que dispara el enganche" que como plantilla de onboarding
  (su primer minijuego ya pide reconocer sonidos y hábitats, más carga cognitiva que tocar un
  color). Melodía conecta con el baile/canto de los tres, pero su anfitrión no tiene el mismo
  anclaje directo a un gusto ya declarado (a diferencia de "pintar" para Nicole). Con los tres
  candidatos razonablemente parejos en conexión, el costo hundido de Arcoíris inclina la balanza.

### Por qué el orden 2-6 no cambia (se evaluó y se descartó adelantar Corazón)

Al validar conexiones, Corazón parecía un buen candidato para adelantarse (conecta fuerte con
Nicole y Sofía, entrena la empatía que la prueba final necesita) — pero moverlo chocaría con un
costo hundido real: la ficha de la nave-estrella (HE-A6, **aprobada por el PO 19-Jul-2026**,
`docs/guia-estilo-generacion.md` §3) ya define sus 6 piezas modulares una por planeta, y ata
explícitamente la pieza 6 — el "corazón del motor / núcleo central" — a ser la **última**, la que
enciende toda la nave justo antes de la prueba cooperativa ("encaja narrativamente con que sea la
última pieza justo antes del planeta final: la nave cobra vida del todo antes de la prueba
cooperativa"). Ese diseño ya aprobado logra el mismo objetivo narrativo que se buscaba al
adelantar Corazón (el planeta de las emociones preparando el clímax emocional del juego) sin
tocarlo. **Se mantiene el orden original 1-6**; el único ajuste real de esta tarjeta es confirmar
el planeta 1.

### Gustos fuertes sin planeta dedicado: dinosaurios y autos de Maxi

Verificado explícitamente (pedido de la tarjeta): los **dinosaurios** de Maxi (tiranosaurio rex,
spinosaurio, carnotauro — el gusto más fuerte y repetido de su ficha) y su interés por **autos y
vehículos** (Cars, Sonic, Tayo el autobús) no son hoy el tema central de ningún planeta.

**Decisión: no ameritan un planeta propio, quedan como contenido de ruta personalizada** (§5):

- **Dinosaurios → Planeta Animalia.** Un dinosaurio es, para efectos de diseño, un animal más:
  encaja sin forzar en "¿Quién habla?" (rugidos de dino como variante de sonido para la ruta de
  Maxi), "Cada quien a su casa" (dino → volcán/selva prehistórica) y "Escondite animal". No hace
  falta un séptimo planeta — el GDD §8 además pone un techo explícito de 6 planetas. Esta
  variante ya estaba insinuada en `docs/perfil-jugadores.md` ("dinosaurios... como temas de sus
  variantes de contenido"); esta tarjeta la deja explícita en el GDD para que no se pierda al
  implementar.
- **Autos/vehículos → "El tren numérico" (Planeta Cuenta-Cuentas).** Ese minijuego ya es, en
  esencia, una fila de vehículos para ordenar — la variante de Maxi puede reskinearlo como una
  carrera de autitos/camioncitos en vez de vagones de tren, sin tocar la mecánica.
- **Nota para el guionista y `disenador-personajes`**: Sonic, Cars, Toy Story, Tayo el autobús y
  Blippi son personajes/IP con dueño — se usan solo como *referencia de inspiración* para el papá
  al describir el gusto de Maxi (velocidad, autitos de colores, un autobús simpático), nunca se
  reproducen ni se nombran en el juego (mismo criterio ya aplicado a Nicole y Sofía con Disney/
  My Little Pony/Harry Potter/k-pop en `docs/perfil-jugadores.md`).
- Si en un playtest futuro Maxi reacciona con muchísima más emoción a los dinosaurios que al
  resto del contenido, la opción de "ascender" dinosaurios a un planeta propio queda abierta para
  una fase posterior (no se cierra la puerta, pero hoy no hay evidencia suficiente para gastar uno
  de los 6 cupos de planeta en eso).

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
2. **El tren numérico** — ordenar vagones con números. S: tocar los vagones y oír los números. B: ordenar 1-10. E: completar secuencias con huecos (2, 4, _, 8) y ordenar hasta 20. *(variante de contenido para Maxi: reskin como carrera de autitos/camioncitos en vez de vagones — ver "Gustos fuertes sin planeta dedicado" arriba.)*
3. **Mercado espacial** — "comprar" con monedas estelares. B: pagar cantidades exactas contando. E: sumar precios y calcular vuelto simple. (S no tiene este juego; ve una animación de la tienda con sonidos.)

#### Planeta Letralandia
1. **Sopa de burbujas** — tocar burbujas con la letra que dice Lila. S: tocar burbujas y oír letras. B: encontrar su inicial y las vocales. E: formar palabras cortas (SOL, LUNA).
2. **La primera letra** — unir dibujos con su letra inicial. B: 3-4 pares con voz. E: escribir la palabra completa con teclado de letras en pantalla.
3. **Cuentos de Lila** — cuentos ilustrados cortos narrados por voz, con objetos tocables en cada página. S/B: escuchar y tocar. E: la letra resaltada sigue la narración (fomento de lectura); variante de contenido de "escuela de magia" para Sofía (sin copiar IP — ver nota arriba).

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
| P2 | ¿Grabar voces reales de la familia para Cometa y celebraciones? | Product Owner | **Resuelta (06-Ago-2026)** — se usa voz sintética (TTS) como placeholder durante el desarrollo; la grabación con la familia real queda para más adelante, antes de la pasada final de voces (HE-28), decisión del PO |
| P3 | ¿Qué tablet Android concreta usarán? (define resolución y rendimiento objetivo) | Product Owner | Abierta |
| P4 | Herramienta MCP definitiva para generación de sprites (ver stack técnico) | Dev | Parcial — GodotPrompter + godot-mcp adoptados (stack §4); generación de imágenes se decide en HE-03 |
| P5 | Catálogo de niveles temáticos por hermano (¿6 planetas universales o menos planetas con misiones personalizadas?) — requiere fichas completas de HE-D1 | PO + Dev | **Resuelta (HE-D3, 06-Ago-2026)** — se mantienen los 6 planetas universales tal como estaban (temas, nombres, anfitriones y orden 1-6), con contenido personalizado por hermano dentro de cada uno (motores + variantes, §4-§5); planeta 1 confirmado = Arcoíris. Abierto solo el detalle fino de fichas de nivel por hermano (trabajo normal de diseño, no de negocio). |
| P6 | Diseño detallado de la prueba final cooperativa y del modo misión familiar (flujo de turnos, UI de "le toca a...") | PO + Dev | Abierta |
| P7 | Nombres "Cometa" y "El Coleccionauta" — aprobados por el PO en HE-A1/HE-A3 (diseño) y confirmados definitivamente por el PO el 06-Ago-2026 (ya no son provisionales). La reacción espontánea de Maxi, Nicole y Sofía al verlos/oírlos en el juego real queda como observación natural del primer playtest, no como aprobación pendiente | PO | Cerrada (nombres definitivos) |
