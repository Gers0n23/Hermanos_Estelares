# Plan de mejoras de Animalia tras el feedback de los niños (15-Nov-2026)

> Origen: feedback del PO (Gerson) tras jugar Animalia con Maxi, Nicole y Sofía. Afecta a tres de los cuatro
> juegos: «¿Quién habla?» (`topos`, HE-116), «Escondite animal» (`buscar`, HE-118) y «Carrera de Toby»
> (`runner`, HE-119). «Cada quien a su casa» (`caminos`, HE-117) no recibió quejas; solo hereda el cambio de arte.
> Este documento es la propuesta para trabajar; las tarjetas las crea `scrum-master` en `docs/TABLERO.md`.

## 0. Lo que dijeron los niños y la causa en el código

| Juego | Feedback | Causa encontrada |
|---|---|---|
| ¿Quién habla? | Excesivamente largo | Brote y Estrella juegan **2 rondas × 60 s** (`duracion_s: 60`, `rondas: 2`), más intro y celebración: ~2,5-3 min de lo mismo. |
| ¿Quién habla? | Los sonidos no calzan con los animales | **No hay sonidos reales**: `scripts/motores/topos/sonidos_animales.gd` los **sintetiza con ondas** (seno, cuadrada, sierra). Los `.ogg` que piden los niveles (`sfx/animalia/animales/*.ogg`) no existen, así que siempre suena el sintetizado. Un «cua» de onda cuadrada no se parece a un pato. |
| ¿Quién habla? | Solo es presionar de a uno | La única regla es «toca al que sonó». Ya existen `similares` y `pedido_escrito`, pero solo cambian *a quién* se toca, no *cómo se piensa*. |
| Escondite animal | El más fome; feo; se gana tocando lo que está a la vista | Arte **procedural en código** (decisión provisional del 05-Nov para no esperar HE-114). Los animales cumplen un `visible_min` alto (75-80 %): están a simple vista. Tocar es la única acción, no hay razonamiento. |
| Carrera de Toby | Bueno pero predecible: solo saltar | La ficha copia al dinosaurio de Chrome **a propósito**: «un solo gesto», «agacharse no existe», «sin doble salto» (`motor-runner.md` §1, §2, §6.1), por la regla GDD §6 n.º 4 («sin dobles toques, sin gestos complejos»). Esa regla se pensó para Maxi y hoy limita a Nicole y Sofía. |

**Lección de proceso**: el 05-Nov se saltaron las maquetas HTML (HE-110) y la auditoría sobre fichas (HE-111)
para llegar rápido a Godot, y se aceptó arte procedural. El resultado fue jugable pero no gustó. En este plan,
cada rediseño pasa por una **prueba corta con los niños antes de pulir** (maqueta o build mínima, 10 minutos).

---

## 1. Base común: biblioteca de animales CC0 (arte + sonidos reales)

Es lo primero porque destraba los tres juegos y además mejora `caminos` y el mapa.

**Arte**
- Reemplazar el dibujo procedural de animales y escenarios por un **pack CC0 único y coherente** (no mezclar
  estilos). Candidatos a evaluar, con licencia verificada en `assets/terceros/LICENCIAS.md`:
  - **Kenney** (ya usado en el proyecto, CC0): *Animal Pack Redux* (~30 animales cartoon redondos) y packs de
    escenario (granja, naturaleza, plataformas 2D para el runner).
  - **OpenGameArt.org** filtrando por CC0: packs de animales de granja y tilesets de granja/bosque.
  - Criterio de elección: animales de **cuerpo entero** (no solo cabezas), mismo grosor de línea y paleta,
    estable/estanque/árbol/gallinero/pradera disponibles, y que admitan **variantes** (accesorios encima).
- Los accesorios para distinguir animales de la misma especie (moño, sombrero, lentes, bufanda, campana,
  manchas) se dibujan **una sola vez como capas SVG** sobre el animal CC0: así sale «el pato con moño rojo»
  sin redibujar al pato.
- Todo se copia a `assets/sprites/animalia/animales/` y `assets/sprites/animalia/escenarios/`, con su crédito.

**Sonido**
- Grabaciones **reales** de animales con licencia CC0 (Freesound filtrando por CC0; BigSoundBank). 2-3
  variantes por animal, recortadas a ≤ 1 s, normalizadas, en OGG.
- **Prueba de oído obligatoria**: una página simple con cada animal y su sonido; papá y los niños marcan
  «se reconoce / no se reconoce». Ningún sonido entra al juego sin pasar esa prueba. Así no se repite el problema.
- `sonidos_animales.gd` queda solo como respaldo si falta un archivo (y se registra como error en QA).

**Datos**: una tabla única `datos/animales/animalia.json` con los atributos de cada animal (color, patas,
alas, plumas/pelo, sonido, dónde vive, qué come, tamaño). La usan los tres juegos (pistas, señuelos, variantes).

---

## 2. «¿Quién habla?» v2 — más corto y que obligue a fijarse

**Mecánica de referencia** (regla de oro 3): sigue siendo **topos (Whac-a-Mole)**, ahora con la regla de
**«Simón dice» / Go-No-Go** (tocar solo al que cumple la orden y aguantarse con los demás), que es la mecánica
que entrena la atención que el PO pide.

### 2.1 Más corto
- **Una sola ronda, por pedidos y no por tiempo**: Semilla 6 pedidos, Brote 10, Estrella 12. Duración objetivo:
  **60-90 s** con intro incluida. El temporizador queda solo como presión por pedido (cada animal se esconde).
- Récord y estrellitas por **aciertos seguidos y rapidez**, no por aguante.

### 2.2 Tipos de pedido (escalan dentro de la partida y entre zonas)

| Pedido | Ejemplo (voz de Toby) | Qué entrena |
|---|---|---|
| A. Por sonido | «¿Quién hace *cua cua*?» → hay 1 pato | Asociar sonido (el actual) |
| B. Por rasgo | «¡Toca al **pato del moño rojo**!» → salen 3 patos: moño rojo, moño azul, sin moño | Fijarse en el detalle |
| C. Sonido + rasgo | «El que hace *muu* y tiene **campana**» → 2 vacas, solo una con campana | Combinar dos pistas |
| D. Prohibido | «¡**No** toques a los gatos dormilones!» (salen gatos con gorro de dormir entre otros) | Control de impulso (Go/No-Go) |
| E. Todos los que… | «¡Toca a **todos** los que tienen alas!» (pato, gallina, búho entre vaca y perro) | Clasificar |
| F. Trueque (Estrella) | Los animales **se cambian de madriguera** antes de asomarse, como el juego de los vasitos | Seguir con la vista |

Tocar al equivocado: Maxi no pierde nada (el animal dice su nombre y su sonido, sirve de repaso); Nicole y Sofía
pierden la racha y una parte del tiempo del pedido. Los «prohibidos» restan una vida en Estrella (derrota real, HE-124).

### 2.3 Escala por hermano

| | Maxi (Semilla) | Nicole (Brote) | Sofía (Estrella) |
|---|---|---|---|
| Pedidos | A, y desde z3 B con colores muy distintos | A → B → D; C desde z3 | B, C, D, E; F desde z3 |
| Animales a la vez | 2-3, grandes | 3-4 | 4-6, con «primos» (pato/ganso, burro/caballo) |
| Variantes | 1 rasgo muy visible (color del moño) | 1 rasgo (moño, sombrero, lentes) | 2 rasgos («moño **azul** y **lentes**») |
| Vidas | sin derrota práctica (versión suave) | 3 | 3 y los prohibidos cuentan |

---

## 3. «Escondite animal» v2 — «¿Quién es? con la lupa de Toby» (tipo Adivina Quién)

**Mecánica de referencia**: **Adivina Quién** (Guess Who: pistas que descartan candidatos) + **búsqueda con
linterna/lupa** (escena oscura o tapada que solo se revela bajo el lente, como los libros «linterna mágica» y las
escenas de linterna de juegos de objetos ocultos). Reemplaza al Wally / Hidden Folks actual.

### 3.1 Bucle
1. Toby: «Estoy buscando a un amigo… **tiene alas**». Aparece una tarjeta con la silueta en gris.
2. El escenario es una **lámina ilustrada grande** (granja: establo, estanque, árbol, gallinero, pradera) donde
   los animales están **tapados** (detrás de un arbusto, en la sombra del establo, bajo el agua, entre la paja).
   Sin lupa no se ven.
3. El niño **arrastra la lupa** por la escena. Bajo el lente se ve lo escondido (y se oye su sonido suave).
   Al soltar la lupa sobre un animal, se **descubre**.
4. Si es el correcto: celebración y la tarjeta muestra el animal con todas sus pistas (repaso). Si no: el animal
   sale, saluda y dice **por qué no es**: «Yo tengo alas, pero **no soy amarilla**, soy blanca». Queda descartado
   (como bajar una ficha en Adivina Quién), así el error enseña.
5. **Botón de pista** (hueso de Toby): da la siguiente pista. Las pistas van **de la más vaga a la más evidente**:

| Orden | Tipo | Ejemplo (pato) |
|---|---|---|
| 1 | Grupo / cuerpo | «Tiene alas» |
| 2 | Color | «Es amarillo» |
| 3 | Sonido | «Hace *cua cua*» (se oye) |
| 4 | Lugar | «Le encanta el agua» |
| 5 | Rescate | Toby olfatea y la escena brilla cerca del estanque |

### 3.2 Lo que lo hace difícil de verdad
- **Señuelos con rasgos compartidos**: para el pato, también hay pollito (amarillo, alas), canario (amarillo,
  alas), gallina (alas) y ganso (alas, agua). Cada pista descarta a algunos. El generador de niveles elige los
  señuelos desde la tabla de atributos para que **ninguna pista sola alcance** hasta la 3.ª (Estrella).
- Puntaje y estrellitas: **menos pistas y menos descubrimientos equivocados = más estrellas**. Sofía tiene un
  límite de lupazos por animal (derrota real: «¡Se puso el sol!» se mantiene).
- 3 animales por partida (Semilla 2), 2-3 min en total.

### 3.3 Escala por hermano

| | Maxi | Nicole | Sofía |
|---|---|---|---|
| Primera pista | Directo la 3 (sonido) + silueta a color | Pista 2 (color) | Pista 1 (la más vaga) |
| Señuelos | 1-2 muy distintos | 3-4 con 1 rasgo en común | 5-6 con 2 rasgos en común |
| Lupa | Grande, el animal «tira» de la lupa (imán) | Normal | Más chica |
| Escondite | Medio tapado | Tapado | Tapado y en sitios lógicos pero no obvios (el pato **bajo** el agua, solo asoma la cola) |

### 3.4 Coordinación
- La lupa de Pinta (`lienzo_libre`) es un **zoom**; esta es un **revelador**. Se puede compartir el control
  (`scripts/ui/lupa_zoom.gd`) pero la mecánica de «descubrir bajo el lente» vive solo en `buscar`.
- Las pistas son líneas de voz por animal (TSV de `guionista`), generadas desde la tabla de atributos.

---

## 4. «Carrera de Toby» v2 — de dinosaurio de Chrome a corredor de plataformas

**Mecánica de referencia nueva**: **Rayman Jungle Run / Super Mario Run** — corredores automáticos *para
tablet* con niveles diseñados a mano, habilidades que se **desbloquean por zona** y power-ups. Encaja mejor que
Chrome con lo que pide el PO y sigue siendo de una mano.

### 4.1 Controles (necesita decisión del PO: excepción a GDD §6 n.º 4 para Brote y Estrella)
- **Maxi**: igual que hoy, tocar en cualquier parte = saltar (salto imantado). Nada nuevo que aprender.
- **Nicole y Sofía**: **dos botones grandes** en las esquinas inferiores: derecha **saltar** (tocar de nuevo en
  el aire = **doble salto**), izquierda **agacharse / deslizar** (mantener). Botones visibles con ícono son más
  fáciles para niños que los deslizamientos.

### 4.2 Habilidades por zona (cada zona trae algo nuevo, como Rayman)

| Zona | Novedad | Obstáculos nuevos |
|---|---|---|
| z1 Campamento | salto + **doble salto** | troncos altos, cajas apiladas |
| z2 Laguna | **agacharse/deslizar** | ramas bajas, pájaros a la altura de la cabeza, nenúfares que se hunden |
| z3 Pradera | **abismos** y plataformas a dos alturas | zanjas, puentes que se caen |
| z4 Árbol de los nidos | **planear** (mantener salto: Toby abre las orejas) | abismos anchos, viento |
| z5 Valle de los dinos | todo combinado + camino secreto | huevos que ruedan, géiseres |

Abismo = pierde un corazón y reaparece en la última **banderita** (checkpoint), nunca vuelve al inicio.

### 4.3 Gadgets (power-ups tipo Mario, con duración corta y sonido propio)

| Gadget | Efecto |
|---|---|
| Hueso dorado | **Imán** de huesitos 8 s |
| Burbuja del casco (ya existe) | Escudo: aguanta un choque |
| Botas resorte | Súper salto 8 s (alcanza huesitos altos y atajos) |
| Patineta | Velocidad e invencible 5 s (la «estrella» de Mario) |
| Globo | Flota por encima de un abismo |

### 4.4 Niveles hechos a mano, no al azar
- Cada zona se arma con **tramos diseñados** (`disenador-niveles`): calma → reto → recompensa, con un camino
  alto (más huesitos, más riesgo) y uno bajo (seguro). Esto quita lo predecible sin volverlo injusto.
- Largo de nivel: 60-90 s. Meta: llegar a la carpa; estrellitas por huesitos y por **3 huesos especiales**
  escondidos por nivel (motivo para repetir).

---

## 5. Orden de trabajo propuesto (para que `scrum-master` lo pase al tablero)

Prioridad por impacto en los niños y por dependencias. IDs provisionales (M1-M10); `scrum-master` asigna los
HE- definitivos.

| # | Tarjeta | Responsable | Depende de |
|---|---|---|---|
| M1 | **Arreglo rápido de «¿Quién habla?»**: 1 ronda por pedidos (60-90 s) solo cambiando datos. Se puede jugar esta semana | dev-godot | — |
| M2 | **Biblioteca CC0 de animales**: elegir un pack de arte, curar sonidos reales, prueba de oído con los niños, tabla `datos/animales/animalia.json` | disenador-personajes + dev-godot + PO | — |
| M3 | Ficha «¿Quién habla?» v2 (tipos de pedido A-F, variantes con accesorios, escala) | disenador-mecanicas + disenador-niveles | M2 (tabla) |
| M4 | Implementar «¿Quién habla?» v2 | dev-godot | M2, M3 |
| M5 | Ficha «Escondite» v2 «¿Quién es?» (lupa reveladora, pistas ordenadas, señuelos por atributos) + **maqueta HTML** para probar con los niños | disenador-mecanicas + guionista (pistas) | M2 (tabla) |
| M6 | Láminas de escenario de las 5 zonas con arte CC0 y escondites | disenador-personajes + disenador-niveles | M2, M5 |
| M7 | Implementar «Escondite» v2 | dev-godot | M5, M6 |
| M8 | Ficha «Carrera de Toby» v2 (controles, habilidades por zona, gadgets, tramos) + decisión del PO sobre GDD §6 n.º 4 | disenador-mecanicas + disenador-niveles + experto-ux-parvulo | PO |
| M9 | Implementar «Carrera de Toby» v2 (tileset CC0 de plataformas) | dev-godot | M2, M8 |
| M10 | QA + UX de los tres juegos v2 y **mini playtest con los niños** (antes del playtest de capítulo HE-23) | tester-qa + experto-ux-parvulo + PO | M4, M7, M9 |

Orden sugerido: **M1 y M2 ya** (arreglo rápido + base de arte/sonido) → **Escondite** (M5-M7, el que peor les
fue) → **¿Quién habla?** (M3-M4) → **Carrera** (M8-M9) → M10. M3 y M8 son diseño y pueden avanzar en paralelo.

Impacto en el tablero: HE-116, HE-118 y HE-119 pasan a «v1 entregada, v2 en rediseño» en vez de cerrarse;
HE-114 (arte de Animalia) cambia de alcance a «curar CC0 + accesorios» (M2/M6); HE-120 (mapa) puede reutilizar el
arte CC0 de M2.

## 6. Decisiones del PO (Gerson, 15-Nov-2026)

1. **Controles del runner: SÍ.** Dos botones grandes (saltar / agacharse) y doble salto para Nicole y Sofía,
   como excepción a la regla GDD §6 n.º 4. Maxi sigue con un solo toque. Objetivo del PO: «que se diviertan y
   lo rejueguen» (rejugabilidad: huesos especiales, caminos alternativos, récords).
2. **Arte CC0: SÍ, y ampliado.** Los animales usan el estilo del pack gratuito (Toby sigue siendo el nuestro).
   **Además, toda la naturaleza** (árboles, rocas, flores, arbustos, pasto, agua, cercas, establo y escenario en
   general) sale de packs CC0 en vez de dibujarse por código: «no es necesario reinventar todas esas cosas que
   son repetitivas». Alcance de M2 y M6 ampliado; aplica también a `caminos`, al runner y al mapa (HE-120).
3. **Lupazos limitados: Nicole y Sofía.** Descubrir al animal equivocado gasta un lupazo en los dos perfiles;
   **Nicole tiene más lupas** que Sofía. Maxi no gasta lupas (solo escucha por qué no es).
   Valores de partida: Nicole 5 lupazos por animal, Sofía 3 (los calibra `disenador-niveles`).
4. **Duración: 90 s por juego como meta.** El PO cree que lo largo es sobre todo **lo repetitivo**: la
   variedad de pedidos (v2) importa tanto como el tiempo.

## 7. Hecho el 15-Nov-2026: M1 (arreglo rápido de «¿Quién habla?»)

- `herramientas/generar_niveles_topos.py`: Brote y Estrella pasan de 2 rondas × 60 s a **1 ronda × 75 s**
  (~90 s con intro y celebración); Semilla de 45-60 s a 40-50 s. Metas y umbrales de estrellitas escalados en
  proporción al tiempo. 15 niveles `topos_*.json` regenerados (el modo equipo no cambia).
- `herramientas/qa_test_topos.gd`: el arnés exige ahora 1 ronda y ≤ 75 s en los tres perfiles.
- **Pendiente**: correr el arnés y recalibrar metas con `herramientas/simular_topos.gd` en un equipo con Godot
  (en la sesión en la nube no hay Godot instalado). Los sonidos siguen siendo sintetizados hasta M2.
