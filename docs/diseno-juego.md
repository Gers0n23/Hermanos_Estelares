# Los Hermanos Estelares — Documento de Diseño del Juego (GDD)

> **Fuente de verdad del diseño.** Cualquier implementación debe respetar lo que dice este documento.
> Si el diseño cambia (los niños crecen, un minijuego no funciona en la práctica), se actualiza aquí primero.

- **Última actualización**: 17-Jul-2026
- **Plataformas**: Táctil-primero (tablet Android), jugable también en PC con mouse
- **Motor**: Godot 4.x — 2D exclusivamente
- **Idioma del juego**: Español (narración por voz, mínimo texto en pantalla)
- **Estilo visual**: Cartoon vectorial — colores brillantes, formas redondas y amigables (referencia: Sago Mini, Toca Boca)

---

## 1. Premisa y guion

### La historia

Una noche, mientras los tres hermanos miran el cielo desde su jardín, una pequeña estrella cae
cerca de su casa. Se llama **Estelita**, y está triste: al caer perdió sus **destellos** —
las chispas de luz que hacían brillar su constelación.

Los hermanos deciden ayudarla. Estelita los convierte en los **Hermanos Estelares**
y los lleva en su nave-estrella a visitar **planetas divertidos**, donde los destellos
quedaron escondidos. En cada planeta viven aventuras, aprenden cosas nuevas y recuperan
destellos. Cada destello recuperado **enciende una estrella en el cielo de su casa**:
el mapa del progreso es literalmente el cielo nocturno iluminándose.

### El mensaje

El hilo narrativo enseña, sin sermones, que **ayudar a otros, intentarlo juntos y aprender
cosas nuevas hace que el mundo brille más**. Cada planeta refuerza además un tema concreto
(colores, números, emociones... ver §4).

### Tono

- Cálido, tierno y celebratorio. **Nunca hay derrota, castigo ni presión de tiempo** para los pequeños.
- Equivocarse siempre recibe ánimo ("¡casi! inténtalo otra vez") y acertar recibe fiesta (confeti, estrellitas, sonidos alegres).
- Humor físico simple: animales que estornudan, planetas que hacen cosquillas, rebotes exagerados.

---

## 2. Personajes

### Los tres hermanos (jugables)

| Personaje | Edad | Rol en la historia | Perfil de juego |
|---|---|---|---|
| **Maxi** | 2 años | El pequeño explorador valiente. Su curiosidad encuentra destellos donde nadie mira. | **Nivel Semilla** — tocar, arrastrar, causa-efecto. Sin fallo posible: toda interacción produce algo bonito. Cero texto, todo audio e íconos. |
| **Nicole** | 5 años | La artista del grupo. Con imaginación y color resuelve lo que parece imposible. | **Nivel Brote** — contar hasta 10-20, formas, memoria, clasificar, secuencias simples. Instrucciones 100% por voz. |
| **Sofía** | 8 años | La hermana mayor, líder e ingeniosa. Lee las pistas y guía la misión. | **Nivel Estrella** — lectura de palabras/frases cortas, sumas y restas, lógica, retos de habilidad suaves. Texto simple apoyado por voz. |

Cada personaje tiene **la misma aventura con distinta profundidad**: el minijuego es el mismo
en lo visual y narrativo, pero su dificultad se adapta al perfil seleccionado (ver §5).
Esto permite que los tres "jueguen lo mismo" y lo comenten entre ellos, y reduce muchísimo
el trabajo de desarrollo frente a hacer juegos separados por hijo.

**Diseño visual**: los tres con trajes espaciales del mismo diseño pero color propio
(a definir en la guía de estilo, tarjeta de Fase 0), cabezas grandes, ojos expresivos,
proporciones redondas. Cada uno con un gesto característico de celebración.

### Personajes de apoyo

- **Estelita** — la estrella guía. Narradora del juego: da instrucciones por voz, anima, celebra. Flota en pantalla como ayudante permanente; tocarla repite la instrucción.
- **Habitantes de los planetas** — un personaje anfitrión por planeta (ver §4), que da contexto a los minijuegos ("¡mis frutas se mezclaron, ayúdame a ordenarlas por color!").

---

## 3. Estructura del juego

```
Pantalla de título (tocar para empezar)
   └── Selección de personaje (3 retratos grandes — define el perfil de dificultad)
         └── Mapa Estelar (hub): la nave navega entre planetas
               ├── Planeta 1..6 (cada uno con 3-4 minijuegos + 1 escena de historia)
               │      └── Minijuego → celebración → destello recuperado → vuelta al mapa
               └── El cielo de casa (pantalla de progreso: estrellas encendidas)
Zona de padres (acceso con candado: ajustes, progreso por hijo, volumen)
```

- **Sesiones cortas**: un minijuego completo dura 2-5 minutos. Siempre se puede salir al mapa sin perder nada.
- **Progreso por perfil**: cada hermano tiene su propio avance (destellos y estrellas encendidas). Se guarda automáticamente, sin preguntar.
- **Desbloqueo generoso**: los planetas se desbloquean en orden pero con muy poca exigencia (1-2 destellos). La progresión motiva, no frustra.

---

## 4. Los planetas (mundos)

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
3. **Canta con Estelita** — canciones infantiles con animación (karaoke visual). Igual para todos; en E aparece la letra escrita.

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
(15-30 s, sin interacción) donde el anfitrión agradece y Estelita brilla más.
Son la recompensa narrativa y el "pegamento" del guion.

---

## 5. Sistema de niveles por edad

- El nivel lo define **el personaje seleccionado**, nunca un menú de dificultad.
- Técnicamente: cada minijuego recibe un parámetro `nivel` (`semilla` / `brote` / `estrella`) y ajusta cantidad de elementos, opciones, uso de texto y tolerancia. **Un solo código, tres experiencias.**
- Regla de oro por nivel:
  - **Semilla**: imposible perder, imposible trabarse. Todo lo tocable responde con algo agradable. Nada de texto ni menús intermedios.
  - **Brote**: se puede "no acertar" pero nunca perder; los errores dan pistas por voz. Máximo un objetivo a la vez.
  - **Estrella**: hay reto real y puntaje de 1-3 estrellitas para incentivar repetir, pero completar siempre es posible y siempre se celebra.
- En la zona de padres se podrá **ajustar el nivel de cada perfil** manualmente (los niños crecen: en un año Maxi puede pasar a Brote).

---

## 6. Diseño de interacción (UX para 2-8 años)

Reglas obligatorias para toda pantalla del juego:

1. **Objetivos táctiles enormes**: mínimo ~96 px lógicos para elementos que Maxi deba tocar; nada interactivo menor a 64 px.
2. **Todo se narra por voz**: ninguna instrucción depende de saber leer. Tocar a Estelita repite la instrucción.
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

- **Voz de Estelita**: idealmente grabada por papá/mamá — que la voz que los guía sea la de casa es parte del regalo. Alternativa: TTS en español de calidad como relleno durante el desarrollo, reemplazable después (las líneas de voz viven en archivos, listadas en un guion de grabación).
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
| P2 | ¿Grabar voces reales de la familia para Estelita y celebraciones? | Product Owner | Abierta |
| P3 | ¿Qué tablet Android concreta usarán? (define resolución y rendimiento objetivo) | Product Owner | Abierta |
| P4 | Herramienta MCP definitiva para generación de sprites (ver stack técnico) | Dev | Parcial — GodotPrompter + godot-mcp adoptados (stack §4); generación de imágenes se decide en HE-03 |
