# Ficha de motor — `hangar` ("El hangar estelar")

- **Autor**: `disenador-mecanicas`, 17-Oct-2026, a pedido directo del PO.
- **Estado**: PROPUESTA. Falta la decisión del PO sobre las preguntas de fondo (§19), la auditoría de
  `experto-ux-parvulo` sobre esta ficha y la maqueta, el guion de voces (`guionista`) y el arte
  (`disenador-personajes`). Nada de esto está implementado.
- **Maqueta**: `docs/maquetas/hangar-v1.html` (1280×720, táctil y mouse, sin dependencias).
- **Fuentes**: GDD §1 (tono), §3 (hangar estelar en la estructura), §5 (mecánicas probadas y reto real),
  §6 (UX obligatoria) y §8 (nada 3D, sin física compleja); `guia-estilo-generacion.md` §3 (HE-A6,
  nave-estrella: 6 piezas, estado 0, hueco fantasma, nido-hangar, estado final);
  `motor-lienzo-libre.md` §9-§11 (motor que se reutiliza); `album-recuerdos.md` (lo compartido entre
  perfiles); `modo-equipo.md` y `cinematicas/cierre_arcoiris.md` §9.4 (la partida y la regla "nadie
  instala el ala que ganó otro"); `perfil-jugadores.md` (celos Sofía↔Nicole, gustos).

## 0. Mecánica núcleo en una frase

**Una sola nave, que crece y se queda: cada hermano arrastra a su hueco brillante la pieza que ganó
(o su estrella, si la pieza ya está puesta), y después, si quiere, la personaliza por partes —pintura,
patrones, calcomanías y muebles adentro— en un espacio compartido donde nada se pierde.**

## 1. Lo que pidió el PO (decidido, no se reabre)

| Decisión | Cómo la toma esta ficha |
|---|---|
| Minijuego para personalizar la nave: piezas ganadas, stickers, pintura | Motor `hangar` (§3) |
| Botón del hangar en la pantalla principal | El botón `boton_hangar` del Mapa Estelar ya existe y hoy no navega (`mapa_estelar.gd`, `_tocar_hangar`). Se conecta ahí (§4.1) |
| Se dispara solo al recibir una pieza (tras HE-17 y los momentos de HE-47) | Modo `instalar`, corto (§5.3) |
| Sin 3D; vista por fuera y por dentro (corte tipo casa de muñecas) | Dos vistas 2D; la de adentro se abre como el frente de una casita (§8) |
| Una nave para los tres, cada uno pone lo que quiera, sin camarotes impuestos ni candados | Estado global de la nave (§14); rincones de color opcionales y sin candado (§8.3); autoría suave (§10) |
| Disparo corto (~20 s): arrastrar al hueco, se ilumina, fanfarria; decorar opcional y "¡lista!" para volver | §5.3, con línea de tiempo |

## 2. Mecánica de referencia (regla de oro 3)

| Referente | Qué se toma | Dónde vive en el hangar |
|---|---|---|
| **Animal Crossing: New Horizons** (la casa que crece con cada ampliación, personalizar un mueble por partes con colores y diseños, decorar habitaciones vistas de frente y la evaluación de la *Happy Home Academy* por series, temas y colores) | (1) La nave crece pieza a pieza y nunca se resetea: es "tu casa" que se va ampliando. (2) **Personalizar por partes**: cada parte de la nave (casco, franja, panza, toberas, cada pieza) se pinta por separado con un color o un patrón, como el cuerpo y la tela de un mueble. (3) **Interior decorable** con muebles que se apoyan en pisos y estantes. (4) **La cartilla de sellos de Cometa**, adaptación de la HHA: Cometa recorre la nave y premia combinaciones (serie de un color, simetría, un rincón por hermano), nunca castiga ni pone nota baja | Pintar (§6), interior (§8), cartilla (§11) |
| **Mario Kart 8 Deluxe** (el personalizador de karts: cada ranura —carrocería, ruedas, ala delta— tiene variantes y el cambio se ve al instante sobre el vehículo) | Cada **pieza instalada es una ranura con 3 estilos** que se cambian al vuelo, sin perder la pintura (las zonas tienen el mismo nombre en todas las variantes) | Variantes (§9) |

**Por qué no se pisa con el lienzo libre.** El lienzo ya usa Toca Boca/Sago Mini (stickers vivos que se
tocan), Labo Train y Race Craft (caminos con viajeros), Crayola (sellos) y sus objetivos obligatorios
por hoja. El hangar **no usa ninguna de esas mecánicas de referencia**: no hay caminos ni viajeros, los
stickers de afuera son calcomanías quietas pegadas al casco, no hay hojas que se descartan ni objetivos
obligatorios. La experiencia es otra: en Pinta se **crea una escena nueva** cada vez; en el hangar se
**cuida un objeto único y permanente** que se ve en el Mapa Estelar y que comparten los tres. Lo que sí se
reutiliza es **código** (paleta, dock, deshacer, gravedad de muebles, amigos), no mecánica de referencia.

## 3. Arquitectura y reutilización del motor `lienzo_libre`

### 3.1 Regla del núcleo

- El hangar es un **motor** (`scripts/motores/hangar/motor_hangar.gd`, escena
  `escenas/minijuegos/hangar/motor_hangar.tscn`) que extiende `minijuego_base.gd` y emite
  `completado(destellos)` al tocar "¡lista!".
- El núcleo lo **lanza por datos** (`datos/hangar/hangar.json` trae `escena`), igual que el mapa del planeta
  lanza minijuegos: el Mapa Estelar y el flujo de entrega de piezas no conocen la mecánica.
- **Lo que es del núcleo**: qué piezas ganó cada hermano (`piezas_nave`, ya existe), qué piezas están
  instaladas en la nave y con qué estrellas (`nave.piezas`, nuevo) y la miniatura de la nave para el Mapa
  Estelar. El motor avisa con señales genéricas (`pieza_instalada(pieza, hermano)`,
  `estrella_puesta(pieza, hermano)`) y el contenedor escribe en `Progreso`.
- **Lo que es del motor**: la decoración (pintura, patrones, stickers, muebles, variantes elegidas). El
  núcleo la guarda **opaca** con una API genérica nueva de `minijuego_base`:
  `obtener_estado_compartido(clave)` / `guardar_estado_compartido(clave, estado)` → `Progreso.compartido.<clave>`.
  No sabe qué hay adentro.

### 3.2 Qué se reutiliza, qué se parametriza y qué es nuevo

Para reutilizar sin que un motor dependa del otro, primero se **extraen componentes** del lienzo a
`scripts/comun/taller/` (tarjeta H6). El lienzo los sigue usando igual (regresión: `qa_test_lienzo`).

| Pieza del lienzo | En el hangar | Detalle |
|---|---|---|
| `colores_lienzo.gd` (paleta con nombre, mezcla RYB) | **Tal cual** | Paleta por perfil desde datos; el platito de mezcla de Sofía, igual que en la zona 3 |
| Dock de botones redondos + popups (uno abierto a la vez; se cierra al elegir o al tocar fuera y ese toque no pinta; Coco nombra el grupo la 1.ª vez → aquí **Cometa**) | **Tal cual**, extraído a `dock_popups.gd` | Grupos distintos (§4.2) |
| Historial de deshacer con fotos (§10.3: 20 pasos, ZSTD, reusa nodos, no deshace destellos ni sellos) | **Tal cual**, extraído a `historial_fotos.gd` | Vive **por sesión** (§10.4) |
| Botón "mantener 1,2 s" con anillo (escoba §10.4) | **Se parametriza** | Aquí no borra la nave: "vuelve a como estaba al entrar" (§10.4) |
| Catálogo de stickers + `sticker_vivo.gd` (dibujo vectorial, escala, giro, espejo, tinte con balde) | **Se parametriza** | Catálogo propio de calcomanías y muebles (§7, §16). Afuera, clase `calcomania` (quieta, pegada al casco); adentro, clase `mueble`. **Sin** comportamientos de `vivo` (no andan ni se suben a caminos) |
| Gravedad §10.1 (lo que pesa cae a la primera superficie con squash y "¡puff!"; lo que vuela se queda) | **Se parametriza** | Solo adentro: superficies = pisos, estantes y asientos. Afuera no hay gravedad: las calcomanías se pegan |
| Amigos y jinetes §11.3 y §11.9 (personajes como stickers que se sientan en montables con asientos) | **Se parametriza** | Adentro: los asientos de la cabina son "montables" con 1 asiento. Sentar a Maxi en su asiento es soltarlo encima (mismo código) |
| Dos dedos nunca pintan; el segundo deshace el trazo en curso | **Tal cual** | |
| Pincel, goma, balde, rasterizado en una `Image` | **Se parametriza** | El pincel va **enmascarado por zona** (no se sale de la parte donde empezó); una `Image` por capa (casco y cada pieza) en coordenadas locales |
| Pista fantasma (mano) y válvula de Maxi (§9.4) | **Se parametriza** | Solo en el modo `instalar` (§5.3) |
| Objetivos obligatorios, caminos, viajeros, combinaciones, sol, inspiración, lupa | **No se usan** | El hangar no tiene objetivos obligatorios |
| Zonas semánticas con nombre en cada pieza, huecos fantasma, encaje, estrellas-firma, variantes, vista de adentro con apertura de casita, cajitas por hermano, cartilla de sellos, guardado compartido, respaldos | **Nuevo** | §5-§14 |

## 4. Pantalla

### 4.1 Entradas

- **Desde el Mapa Estelar** (pantalla principal tras elegir hermano): `boton_hangar`, que hoy solo rebota. Modo
  `libre`. Si el hermano que entra tiene una pieza ganada **sin su estrella** (el disparo se interrumpió,
  se cerró la app), el hangar empieza por el momento de instalar (§5.3): **nunca se pierde**, igual que
  las burbujas-recuerdo (`album-recuerdos.md` §4).
- **Automático tras una entrega**: escena de entrega (HE-17) → foto familiar si es nueva (HE-47) →
  hangar en modo `instalar` → "¡lista!" → el flujo sigue donde iba (el contenedor decide).
- El botón del hangar en el Mapa Estelar **late** cuando hay una pieza o estrella pendiente.

### 4.2 Distribución (1280×720, lenguaje del menú de planetas)

Fondo: el **nido-hangar flotante** de HE-A6 (espacio violeta con estrellas, motas doradas, nave al centro
sobre un pedestal redondo de nubecitas). Botones como píldoras/esferas oscuras translúcidas con borde
dorado y brillo. Nada de pixel art. Los selectores son **popups que nacen del botón tocado**.

| Lugar | Qué hay |
|---|---|
| Arriba al centro | Guirnalda con los **6 iconitos de pieza** (HE-A6): a color con lacito los instalados, contorno punteado dorado los pendientes. Tocarlos: Cometa dice qué pieza es y en qué planeta está |
| Columna izquierda | **Dock**: deshacer arriba; luego Colores (balde con el color actual), Patrones (B/E), Pinceles (B/E), Cosas (calcomanías afuera, muebles adentro), Amigos (adentro) |
| Abajo a la izquierda | **Cajita** de guardados (estrella-caja) |
| Centro | La nave (≈ 560×420 px afuera). Los huecos fantasma de las piezas pendientes |
| Derecha | **"¡lista!"** (120 px, arriba), la **puerta** para entrar/salir (110 px, al medio), cartilla de sellos (B/E, 84 px), Cometa abajo en su burbuja (como Coco en Pinta §11.4) |

- Tamaños: Maxi, dock y popups de 100/96 px; Nicole y Sofía, 84 px y colores de 72 px. "¡lista!", puerta y
  cajita son iguales para todos (≥ 100 px).
- **Sin texto**: todo icono + voz. La maqueta muestra subtítulos solo para que el PO lea las voces.

## 5. Las piezas

### 5.1 Hueco fantasma (HE-A6)

Cada pieza pendiente se ve como su **silueta exacta** en contorno punteado dorado, relleno dorado
translúcido, 2-3 chispitas y los broches esperando. Late suave (escala 1,00 ↔ 1,03, 2 s). **Nunca**
metal roto, nunca gris triste, nunca candado. Tocarlo: se menea (0,2 s), "tilín", y Cometa dice "Aquí va
el motor de la música. ¡Está en el planeta Melodía!", con el disco del planeta asomando 1,5 s. Orden de
HE-A6: 1 ala izquierda (Arcoíris), 2 ala derecha (Animalia), 3 motor izquierdo (Melodía), 4 motor derecho
(Cuenta-Cuentas), 5 antena-mástil con banderines (Letralandia), 6 núcleo-corazón (Corazón, el último).

### 5.2 Equidad: una pieza, tres estrellas

Las piezas se ganan **por perfil** (`piezas_nave` ya es por hermano) y la nave es **una**. Regla:

- **Primer hermano que gana la pieza**: arrastra **la pieza** a su hueco. Encaja y la nave se ilumina.
- **Segundo y tercero**: la pieza ya está; cada uno arrastra **su estrella** (estrella grande de su color:
  Maxi `#4aa8ff`, Nicole `#ff5fae`, Sofía `#4fd8e0`, los del Mapa Estelar) a **su broche-estrella** en la
  pieza, que ya lo espera con su color en fantasma.
- **Mismo gesto, mismo tiempo, misma fanfarria, mismo barrido de luz por la nave**. La única diferencia
  es qué se arrastra. Así se respeta la regla del storyboard de la partida ("nadie instala lo que ganó
  otro", `cierre_arcoiris.md` §9.4): cada uno instala lo que él ganó.
- El primero también recibe su estrella, **automáticamente** al encajar (no tiene que hacer un segundo
  arrastre): todos terminan con una estrella en la pieza.
- **Cuando la pieza tiene las 3 estrellas**, sus franjas de color brillan una vez, y Cometa celebra al
  trío: "¡Los tres pusieron su estrella!". Celebra al grupo, nunca al último ni al primero.
- **Nunca se nombra el orden**. Cometa no dice "Sofía ya la puso"; dice "¡El ala te estaba esperando!
  Ponle tu estrella". No hay medalla de "primero".
- **Maxi** tiene su momento propio y completo (no guiado por otro): imán total, su gesto canon y su
  fanfarria. Las estrellas lo esperan aunque llegue meses después: el broche azul late cada vez que él
  entra al hangar.
- **El estado final (HE-A6)** pide los colores de los tres hermanos en los paneles de la nave armada: las
  estrellas-firma son exactamente eso. Una pieza con las 3 estrellas ya "se ve terminada".

### 5.3 El disparo automático (modo `instalar`, ~20 s)

Línea de tiempo (Nicole/Sofía; entre paréntesis lo de Maxi):

| t | Qué pasa | Voz | Sonido |
|---|---|---|---|
| 0,0-0,4 | Fundido desde la entrega al hangar; zoom 1,25 hacia el hueco. Dock, cajita y "¡lista!" ocultos | — | Acorde suave |
| 0,4-1,2 | La pieza (o la estrella) llega volando dentro de una **burbuja dorada** y se posa a la izquierda, grande (≥ 200 px), meciéndose | `hangar_pieza_llega_<pieza>` / `hangar_estrella_llega_<pieza>` (~3 s) | "Fiuuu" + "plop" |
| 1,2 → | **La entrada se habilita sin esperar la voz**. El hueco (o el broche) late fuerte y brilla | — | Zumbido mágico suave en loop |
| 4 s sin éxito (3 s) | Mano fantasma: arrastra una pieza translúcida de la burbuja al hueco. Se repite cada 6 s (5 s) | `hangar_pista_arrastrar` (solo la 1.ª vez) | "Tilín" |
| Arrastre | La pieza sale de la burbuja con "pop", sigue al dedo **en el mismo cuadro**, crece a 1,1 y se inclina con la velocidad. El hueco brilla más al entrar en el imán | — | "Uuu" que sube de tono al acercarse |
| Soltar | **Imán**: a ≤ 220 px del hueco (Maxi: **en cualquier parte**, si arrastró ≥ 40 px). Vuela al hueco en 0,35 s girando a su ángulo. Fuera del imán (B/E): vuelve flotando a la burbuja en 0,4 s con un "boing" simpático, sin voz | — | — |
| +0,35 | **Encaje**: "clic-clac" de 2 broches dorados (0,2 s cada uno, squash); la nave se aplasta y estira (1,00 → 1,06 → 0,98 → 1,00 en 0,4 s) | — | "Clic-clac" |
| +0,6 | **Barrido de luz** dorada que recorre toda la nave desde la pieza (0,8 s); las toberas sueltan chispitas de colores; el iconito de la guirnalda se pinta y le sale el lacito | — | Barrido "shiiing" |
| +1,4 | **Fanfarria** (3 s) + confeti + retrato del hermano con su **gesto canon** (Maxi 3 saltitos "¡siii!", Nicole corazón coreano, Sofía mano en la cintura y paz) | `hangar_encajo_<pieza>` | Fanfarria |
| +4,0 | (Si era la pieza) su estrella salta a su broche (0,5 s) | `hangar_tu_estrella_<hermano>` | "Tin" |
| +5,5 | Entran el dock (0,3 s) y **"¡lista!"** con rebote; "¡lista!" late | `hangar_decorar_invitacion` ("¿La decoramos? Cuando quieras, toca el botón") | — |

- Duración típica hasta "¡lista!": **10-14 s**; con pistas, ~18 s. Maxi con válvula: ≤ 20 s.
- **Maxi**: tocar la pieza sin arrastrar la hace **saltar un tercio del camino** hacia el hueco (causa-efecto);
  al 3.er toque llega sola y encaja. **Válvula**: tras 2 manos fantasma, su siguiente toque en cualquier
  parte la instala. Nunca hay fallo.
- **Brote y Estrella**: no hay válvula; a la 3.ª mano el imán crece a toda la pantalla. No es un reto: es
  la ceremonia.
- **Inactividad tras la fiesta**: a los 30 s sin toques, "¡lista!" brilla y Cometa pregunta una vez; a los
  60 s el hangar guarda y vuelve solo (el niño se fue). Decorar nunca se exige.
- **"¡lista!"**: la nave da un saltito, toberas "fiu", Cometa dice una de 3 despedidas, se guarda, se
  exporta la miniatura y fundido de 1 s.

### 5.4 Encaje con la partida de Arcoíris (choca con lo vigente — pregunta P1)

Hoy el ala se **gana** en la zona 3 (HE-17) pero se **instala** en la partida (HE-84): hasta entonces se ve
**envuelta** junto a la nave (N6, HE-75), y en la partida Coco la desenvuelve, la encaja floja y Nicole gira
3 broches (storyboard §9.4). El pedido nuevo del PO (arrastrar la pieza a su hueco al recibirla) choca con
eso. Propuesta recomendada (**opción A**):

- El disparo del hangar **encaja** el ala al recibirla, pero queda **floja**: cuelga 6° y se mece (el mismo
  gag del NI0), con sus 3 broches de piedrita (rojo, amarillo, azul) abiertos. Se lee como "puesta, falta
  asegurarla para volar". En el hangar libre se puede decorar igual.
- La partida conserva sus pasos: Maxi el tanque, **Nicole gira los 3 broches** y Sofía la ruta. Coco ya no
  trae el ala envuelta: tira de la punta para mostrar que está floja. Ese paso ya existe en HE-84 como
  variante "con la llave, solo los broches".
- Cambia: HE-17 (sin ala envuelta), N6 de HE-75 (ala floja en vez de envuelta, arte más barato), NI0 de
  HE-84 y el plano M7 del cierre.
- **Opción B**: el disparo deja el regalo **envuelto** junto a su hueco y cada hermano le pone su estrella
  al moño; el encaje sigue siendo de la partida. Respeta todo lo aprobado, pero no cumple "la nave se
  ilumina al poner la pieza".
- Planetas 2-6: no tienen partida diseñada todavía. Si la tienen, aplica el mismo patrón (encaja al
  recibir, se asegura en la partida).

### 5.5 Pieza 6, el núcleo

Al encajar el núcleo, la nave **cobra vida** (HE-A6): el núcleo late, los remiendos se convierten en
**paneles lisos** (sus zonas conservan la pintura que tenían), se encienden luces cálidas y aparece la
**placa "Hermanos Estelares" con el corderito** (la única excepción de texto aprobada para la nave
armada). El disparo puede durar ~30 s en este caso; la cinemática grande es de HE-39.

## 6. Pintar

### 6.1 Zonas semánticas

La nave se divide en **zonas con nombre** iguales en todas las variantes: `casco_arriba`, `franja`,
`panza`, `collar_cupula`, `ventanita_izq/der`, `remiendo_1..3`, `tobera_1..3` y, por pieza, `base`,
`franja_a/b/c`, `borde`. Adentro: `pared`, `piso`, `alfombra`, `cojin_maxi/nicole/sofia`, `marco_ventanas`,
`asiento_*`. La pintura es plana y encima va una **capa de sombreado y brillo no pintable** (multiply y
brillo), para que cualquier color conserve el volumen del estilo del menú de planetas.

### 6.2 Escala por perfil (inspirada en la personalización por partes de Animal Crossing)

| | **Semilla (Maxi)** | **Brote (Nicole)** | **Estrella (Sofía)** |
|---|---|---|---|
| Zonas | **Agrupadas** en 6 grupos grandes (casco, panza, cúpula, toberas, cada pieza entera): tocar cualquier parte del grupo lo pinta entero | ~16 zonas individuales (ventanitas y remiendos aparte) | Todas (~24 + 4 por pieza) |
| Balde | Sí. **Tocar una zona con el color que ya tiene pasa al siguiente color** (como el lienzo Semilla): todo toque cambia algo | Sí | Sí |
| Colores | 6 grandes (96 px) | 10 | 14 + **mezcla RYB** en el platito |
| Patrones | — (opcional: "pintura mágica" que deja brillitos, sin elegir) | 3: rayas, lunares, corazones; segundo color = blanco | 6: + estrellas, cuadros y degradado; **elige el segundo color** |
| Pincel | — | Grueso (24 px), **no se sale de la zona donde empezó** | Grueso y fino (10 px), enmascarado; **espejo**: lo que pinta en un lado se copia en el otro (zonas pares izq/der) |
| Goma | — | Para trazos de pincel | Para trazos de pincel |
| Profundidad | Causa-efecto pura | Elegir patrón + color, decorar con intención | Diseño completo: paleta propia mezclada, patrones de 2 colores, simetría, cartilla con combinaciones (§11) |

- **Respuesta**: al tocar con el balde, la pintura se expande como una **ola circular desde el dedo**
  (0,25 s) con "blup" a tono según el color. Pintar la misma zona del mismo color: ola + "blup" más
  agudo (nunca un toque muerto).
- Pintar las estrellas-firma o el contorno: **no se puede**; el toque hace brillar la estrella y Cometa
  dice de quién es (§10).

## 7. Calcomanías (afuera) y cosas

- **Afuera**: calcomanías que se **pegan al casco o a una pieza**. Se arrastran desde el popup "Cosas"; al
  soltar, la calcomanía se aplasta contra la superficie ("¡chap!") y queda inclinada siguiendo la curva.
  Si se suelta fuera de la nave, **vuela de vuelta** al punto del casco más cercano (0,3 s, "bloop"), sin
  voz: nunca se pierde, nunca se rechaza.
- Edición: Maxi solo mueve; Nicole agranda/achica; Sofía agranda, gira y espeja (la misma barra del lienzo).
- **Tocar una calcomanía**: salta (squash 0,2 s) y asoma 1 s la **estrellita del color de su autor**.
- **Tope**: 40 por vista. Al pasarlo, la más antigua **del mismo hermano** se va con un "puff" a su cajita.
  Nunca se bloquea.
- Catálogo por perfil (datos): Maxi 6 grandes (rayo, llamas, dino, estrella, ojos de nave, rueda de
  carreras); Nicole 12; Sofía 18 (§16). Los "ojos de nave" le ponen cara a la nave (gag tipo Sago Mini).

## 8. Interior (vista por dentro)

### 8.1 Pasar adentro sin texto

- **Puerta** (botón de 110 px a la derecha: puerta redonda de la nave con Cometa asomándose). Al tocarla,
  Cometa dice "¡Pasen, pasen!", el **frente del casco se abre como la tapa de una casita de muñecas**
  (gira sobre su borde izquierdo, 0,6 s, "crec" de bisagra suave) y la cámara se acerca hasta que el corte
  llena la pantalla (0,4 s). Volver: el mismo botón, ahora con la nave pequeña afuera; la tapa se cierra
  con "clonc".
- La decoración de afuera se conserva en la tapa abierta (se ve de canto).

### 8.2 Qué hay adentro

| Lugar | Qué hay | Interacción |
|---|---|---|
| **Cabina** (arriba, bajo la cúpula) | Asiento de piloto de Cometa, panel de mando con 3 botones grandes de colores y la cúpula con estrellas | Tocar a Cometa: da una vuelta y dice algo. Los botones del panel: luces, bocina, "modo noche" (las ventanas se oscurecen y salen estrellas) |
| **Sala** (abajo) | 3 ojos de buey con estrellas pasando, alfombra, 2 estantes, escalera a la cabina | Pintar pared, piso, alfombra; poner muebles |
| **3 rincones de color** (opcionales) | Un cojín grande y un asiento por hermano, del color de su traje | Ver §8.3 |
| **Rincón de regalos** | Los **regalos de Coco** de cada zona (pincel rojo, etc., `planeta-arcoiris-zonas.md`) cuelgan de ganchos | Tocar uno: Coco lo nombra (voz existente) |
| **Pared de obras** | 6 marcos. Cometa cuelga solo los dibujos de "Decora el ala" de cada hermano (`ala_nave.png`), con la estrellita de su autor | Tocar: se agranda 2 s |
| **Lo que trae cada pieza** | Al instalar: ala → ventana grande con el ala vista desde adentro; motor izq → bocina con notas; motor der → ventanitas numeradas que se encienden; antena → banderines en el techo; núcleo → corazón latiendo al centro | Tocar: reacciona con su sonido |

- **Muebles** (popup "Cosas" adentro): lo que pesa cae a la primera superficie (gravedad del lienzo §10.1,
  más lenta para Maxi, con "¡puff!"); lo que vuela (estrella colgante, móvil de planetas, guirnalda de
  luces) se queda donde se suelta.
- **Amigos** (Nicole/Sofía: grupo propio; Maxi: dentro de "Cosas"): los mismos personajes del lienzo
  §11.3. Soltar un hermano sobre un asiento lo **sienta** (código de jinetes §11.9). Papá incluido, como en
  Pinta.

### 8.3 Rincones personales: opcionales y sin candado

- Cada hermano tiene un cojín y un asiento **de su color por defecto**, que es solo un punto de partida.
  Cualquiera puede pintarlos y decorarlos. No hay candado ni aviso que impida tocar el de otro.
- Cometa, si alguien decora el rincón de un hermano, lo celebra como regalo: "¡Qué lindo le dejaste el
  rincón a Nicole!". Convierte el "tocar lo del otro" en un gesto de cariño (perfil de Nicole: solidaria).

## 9. Variantes de piezas (ranuras tipo Mario Kart)

- Cada pieza instalada tiene **3 estilos**: el canónico de HE-A6 y 2 alternativos ligados a gustos
  reales. Ejemplo para el ala izquierda: franjas pastel (canon), **ala de mariposa-pony** (Nicole/Sofía) y
  **aleta de dino** con puntas redondas (Maxi).
- Se abre con una **etiqueta-estrella** de 72 px que cuelga de la pieza instalada (tocar la pieza con el
  balde la pinta; por eso hace falta la etiqueta). Popup con los 3 estilos (≥ 120 px). Al elegir, la pieza
  hace "puff" y cambia; **la pintura se conserva** porque las zonas se llaman igual; las estrellas-firma
  siguen en su lugar.
- Cualquiera puede cambiarla (es reversible y está en el historial).
- **Costo de arte**: 2 SVG extra por pieza (12 en total), cada uno con sus zonas y sus puntos de broche.
  Se producen **por capítulo**: 2 SVG para el ala izquierda en el capítulo 1. Ver P2.

## 10. Espacio compartido: autoría, borrar y deshacer

### 10.1 Autoría suave

- Cada calcomanía, mueble y zona pintada guarda `por` (quién lo hizo). **No se muestra todo el tiempo**
  (no ensucia la nave): al tocar o levantar algo asoma 1 s una **estrellita del color de su autor**.
  Cometa lo nombra como mucho una vez cada 20 s: "¡Esto lo puso Maxi!".
- Las **estrellas-firma de las piezas** son lo único permanente e intocable: no se pintan, no se mueven,
  no se borran.

### 10.2 Quitar algo: la cajita, nunca la basura

- No hay goma para calcomanías ni muebles. Para quitar algo se **arrastra a la cajita** (abajo a la
  izquierda, estrella-caja de 100 px).
- Si es **propio**: entra con "puff" a la cajita propia.
- Si es **de otro hermano**: va a **la cajita de ese hermano**. Cometa dice: "Esto lo puso Nicole. Lo
  guardo en su cajita, por si lo quiere". La próxima vez que Nicole entra, su cajita brilla
  ("¡Volvió algo a tu cajita!") y puede sacarlo arrastrando. **Nada desaparece**.
- La cajita guarda hasta 30 cosas por hermano; pasado eso, lo más viejo vuelve al catálogo (solo se
  pierde la posición, no el sticker).

### 10.3 Pintar encima de lo de otro

- **Se permite** (es pintura, capa común, como un mural familiar), con tres redes: deshacer de la sesión,
  "volver a como estaba al entrar" y los respaldos de padres (§10.4). Ver P3.

### 10.4 Deshacer y reiniciar en un espacio compartido

- **Deshacer**: historial de fotos del lienzo, 20 pasos, **solo de la sesión actual**: ningún hermano
  puede deshacer lo que otro hizo en otra sesión.
- **Escoba "mantener 1,2 s"** (mismo componente que Pinta): **no deja la nave en blanco**. Devuelve la
  nave a **como estaba al entrar** en esta sesión, con su "¡fuuush!". Si un hermano chico desordenó todo,
  se arregla sin tocar lo que había antes.
- **Respaldos de padres**: al tocar "¡lista!" se guarda un respaldo del estado anterior (los últimos 5). En
  la Zona de padres, "Volver la nave a como estaba" muestra miniaturas con fecha. Es la red para el caso
  "Maxi pintó encima de la nave de Sofía". Nunca lo ven los niños.
- Ni deshacer ni escoba quitan piezas, estrellas, sellos ni destellos.

## 11. Destellos y la cartilla de sellos

- **Decorar libremente no da destellos.** La recompensa es la nave misma, que además se ve en el Mapa
  Estelar. Así nadie "farmea" destellos pintando, y el hangar no compite con los minijuegos.
- **Instalar** no da destellos aparte: la pieza ya es el premio de la escena de entrega.
- **La cartilla de sellos de Cometa** (adaptación de la HHA de Animal Crossing) es el **reto real
  opcional** para Nicole y Sofía y el juego de descubrimiento de Maxi:
  - **Por perfil** (no compartida), con **12 sellos cada uno y 10 destellos por sello**. El tope es el mismo
    para los tres (120): equidad.
  - Cometa revisa al tocar "¡lista!" y también en vivo: un sello nuevo hace "¡chap!", vuela a la cartilla y
    suena una fanfarria corta. **Nunca** se dice que algo está mal ni se puntúa bajo.
  - **Sofía** (combinaciones tipo HHA, se ven sus siluetas en la cartilla para planificar): serie de un
    color (4 zonas iguales), arcoíris (6 zonas de 6 colores distintos), simetría perfecta (izq = der en
    color y patrón), 3 patrones distintos, un color mezclado por ella en 3 zonas, tripulación completa
    (los 4 sentados), un rincón para cada uno (los 3 cojines con el color de su dueño), sala decorada (5
    muebles en 2 superficies distintas), etc.
  - **Nicole** (de a una, dicha por Cometa: "¿Le pones lunares a algo?"): pinta 3 partes, un patrón, 3
    calcomanías, una planta adentro, sienta a alguien, decora el rincón de un hermano, etc.
  - **Maxi** (descubrimientos, sin pedírselos): tocar a Cometa en la cabina, la bocina, el modo noche,
    pintar 3 veces seguidas, una calcomanía de ojos, sentar a Maxi en su asiento… Se ganan solos.
  - El contenido exacto lo cierra `disenador-niveles` (H10).

## 12. Interacciones y respuesta (< 100 ms siempre)

| Toque | Respuesta inmediata (≤ 1 cuadro) | Después |
|---|---|---|
| Zona con balde | Ola de color desde el dedo + "blup" | Si da sello, "¡chap!" |
| Zona con pincel | El trazo aparece en el mismo cuadro, enmascarado | — |
| Calcomanía/mueble | Salto + estrellita del autor | Voz de autor (≤ 1 cada 20 s) |
| Arrastre de calcomanía | Sigue al dedo, crece 1,1 y deja sombra | Al soltar: "¡chap!" o "bloop" de regreso al casco |
| Mueble soltado en el aire | Cae con estirón | "¡Puff!" al aterrizar |
| Hueco fantasma | Meneo + "tilín" | Voz: qué pieza y dónde está |
| Estrella-firma | Brilla + "tin" | "¡Es la estrella de Sofía!" |
| Puerta | Botón se hunde | La tapa se abre (0,6 s) |
| Cajita | Se abre con rebote | Popup con lo guardado del hermano |
| "¡lista!" | Botón se hunde y la nave salta | Despedida y salida |
| Dos dedos | Nada pinta | El segundo deshace el trazo en curso |

## 13. Contrato de datos (`datos/hangar/hangar.json`)

| Campo | Uso |
|---|---|
| `escena` | Ruta del motor (la usa el núcleo para lanzarlo) |
| `piezas[]` | `{id, planeta, orden, hueco: [x, y, ángulo], zonas[], broches_estrella: {maxi: [x,y], nicole: [...], sofia: [...]}, variantes[], aparece_dentro, voz_hueco, voz_llega, voz_encajo}` |
| `vistas.fuera` / `vistas.dentro` | `zonas` (nombre → polígono), `grupos_semilla` (nombre → lista de zonas), `pares_espejo`, `superficies` (adentro: pisos, estantes, asientos), `gravedad` (false afuera) |
| `perfiles.<semilla|brote|estrella>` | `paleta`, `herramientas`, `patrones`, `agrupar_zonas`, `pinceles`, `espejo`, `mezcla`, `boton`, `catalogo_fuera`, `catalogo_dentro`, `amigos`, `cartilla` |
| `instalar` | `iman_px` (220), `iman_semilla` (`"pantalla"`), `minimo_arrastre_semilla` (40), `saltos_por_toque_semilla` (3), `pista_s` ([4, 6]; Semilla [3, 5]), `valvula_manos` (2) |
| `topes` | `calcomanias_por_vista` (40), `cajita` (30), `historial` (20), `respaldos` (5) |
| `tiempos` | `inactivo_recordar_s` (30), `inactivo_salir_s` (60), `autor_voz_cada_s` (20) |
| `cartillas.<hermano>` | `[{id, tipo, params, voz, icono}]`, tipos: `serie_color`, `colores_distintos`, `simetria`, `patrones_distintos`, `mezcla_usada`, `sentados`, `rincones`, `muebles_superficies`, `poner`, `tocar` (descubrimiento) |
| `lineas_voz` | Patrones por evento (§15) |

El núcleo inyecta al lanzar: `modo` (`instalar` | `libre`), `pieza` y `hermano`.

## 14. Guardado

`Progreso` sube a **versión 4** con migración (los arneses respetan `progreso.json`: guardado aislado,
respaldo y md5, como siempre). La nave es **global**, igual que `recuerdos_encontrados`:

```json
"nave": {
  "piezas": {
    "ala_izquierda": {"instalada": true, "por": "sofia", "fecha": "2026-10-20", "estrellas": ["sofia", "maxi"]}
  },
  "miniatura": "user://nave/miniatura.png",
  "respaldos": ["user://nave/respaldos/2026-10-20_1830.json"]
},
"compartido": {
  "hangar": {
    "variantes": {"ala_izquierda": "aleta_dino"},
    "zonas": {"fuera": {"panza": {"color": "rosado", "patron": "lunares", "color2": "blanco", "por": "nicole"}}, "dentro": {}},
    "capas_pincel": {"casco": "user://nave/casco.png", "ala_izquierda": "user://nave/ala_izquierda.png"},
    "cosas": {"fuera": [{"id": "rayo", "pos": [612, 410], "escala": 1.0, "giro": 0, "espejo": false, "color": "amarillo", "capa": "casco", "por": "maxi"}], "dentro": []},
    "cajitas": {"maxi": [], "nicole": [], "sofia": []},
    "obras": {"maxi": "user://dibujos/maxi/ala_nave.png"}
  }
},
"perfiles": {"<id>": {"hangar": {"sellos": ["serie_color"], "vio_intro": true}}}
```

- `nave.piezas` es del núcleo (lo leen el Mapa Estelar, el viaje y la partida); `compartido.hangar` es
  opaco para el núcleo.
- Pintura de pincel: un PNG por capa en coordenadas locales de la capa (sobrevive a cambiar de variante).
- Se guarda al tocar "¡lista!", al salir por inactividad y cada 30 s en segundo plano (GDD §6.8: cerrar la
  app no pierde nada).

## 15. Voces de Cometa (listado; los textos son del `guionista`)

Provisionales con el TTS gratuito de Windows. **No se usan APIs pagadas** para esto; las oficiales
siguen el camino normal (`--estimar` y OK del PO sobre el costo).

| Grupo | Ids | Cantidad |
|---|---|---|
| Entrada | `hangar_intro_primera`, `hangar_entrada_1..3` | 4 |
| Instalar | `hangar_pieza_llega_<pieza>`, `hangar_estrella_llega_<pieza>`, `hangar_encajo_<pieza>` (6 c/u), `hangar_pista_arrastrar`, `hangar_tu_estrella_<hermano>` (3), `hangar_tres_estrellas`, `hangar_ala_floja` (opción A) | 23 |
| Núcleo | `hangar_nucleo_vida` | 1 |
| Huecos | `hangar_hueco_<pieza>` (qué pieza y en qué planeta) | 6 |
| Decorar | `hangar_decorar_invitacion`, `hangar_lista_recordatorio`, `hangar_lista_salida_1..3`, `hangar_grupo_<colores/patrones/pinceles/cosas/amigos/cajita/estilos>` (7), `hangar_patron_<id>` (6) | 18 |
| Compartido | `hangar_autor_<hermano>` (3), `hangar_cajita_mia`, `hangar_cajita_de_<hermano>` (3), `hangar_cajita_volvio`, `hangar_rincon_regalo_<hermano>` (3), `hangar_nave_llenita`, `hangar_escoba_mantener`, `hangar_escoba_listo` | 14 |
| Adentro | `hangar_puerta_entrar`, `hangar_puerta_salir`, `hangar_dentro_primera`, `hangar_asiento_<hermano/cometa>` (4), `hangar_cometa_toque_1..3`, `hangar_panel_<luces/bocina/noche>` (3) | 13 |
| Variantes | `hangar_estilo_<pieza>_<estilo>` (6 × 3) | 18 |
| Cartilla | `hangar_cartilla_intro_<nicole/sofia>` (2), `hangar_sello_<id>` (36), `hangar_sello_logrado_1..3` | 41 |
| **Total** | | **≈ 138** |

Se reutilizan sin grabar de nuevo: nombres de colores (`voces_colores` del lienzo), nombres de amigos
(`stickers/<id>`) y los regalos de Coco.

## 16. Arte necesario (`disenador-personajes`, SVG en `assets/fuentes_svg/hangar/`)

1. **Nave por capas** (estado incompleto de HE-A6): contorno, casco dividido en sus zonas pintables
   (`casco_arriba`, `franja`, `panza`, `ventanita_izq/der`, `remiendo_1..3`, `collar_cupula`, `tobera_1..3`),
   capa de sombreado y brillo no pintable, cúpula de vidrio (capa aparte), antenita base, pedestal de
   nubes. La **tapa frontal** separable para la apertura de casita.
2. **6 piezas canónicas** con sus zonas (`base`, `franja_a/b/c`, `borde`), puntos de broche y de estrellas;
   **6 huecos fantasma** (silueta punteada + 2 broches); los 6 iconitos de la guirnalda en 2 estados (ya
   existen en el ancla del hangar v2: se vectorizan).
3. **Ala floja** (opción A): la misma ala con 3 broches de piedrita abiertos. Reemplaza "ala envuelta" (N6).
4. **Estrellas-firma**: estrella llena y broche fantasma en los 3 colores.
5. **Estado núcleo encendido**: paneles lisos sobre los remiendos, luces, placa con corderito.
6. **Interior en corte**: cáscara, pared, piso, cabina con asiento de piloto y panel de 3 botones, 3
   asientos y 3 cojines de color, escalera, 3 ojos de buey, 2 estantes, ganchos de regalos, pared de 6
   marcos, y los 5 agregados por pieza (ventana del ala, bocina, ventanitas, banderines, corazón).
7. **Variantes**: 2 por pieza (12 en total), por capítulo. Capítulo 1: mariposa-pony y aleta de dino.
8. **Calcomanías nuevas** (~18): rayo, llamas, estrella, corazón, huellita, burbujas, 3 pares de ojos de
   nave, pestañas, lazo, cuernito de unicornio, alitas, dino, pony, bandera de Chile, corderito, rueda de
   carreras.
9. **Muebles** (~16): cojín, puf, alfombra redonda, lámpara, planta, pecera, estante con libros, peluches
   (dino, pony, gatito), guirnalda de luces, móvil de planetas, mesita, hamaca, pizarra, parlante.
10. **Patrones** (tiles): rayas, lunares, corazones, estrellas, cuadros, degradado.
11. **UI**: balde con color, patrones, pinceles, cosas, amigos, cajita (cerrada/abierta/brillando),
    deshacer, escoba, puerta entrar/salir, "¡lista!", cartilla y etiqueta de estilos. Estilo píldora oscura
    translúcida con borde dorado.
12. **Cartilla**: 36 sellos (silueta y logrado).

Prioridad para el capítulo 1: 1, 2 (solo ala izquierda + 5 huecos), 3, 4, 6 (sin agregados 2-6), 8 y 9
reducidos a ~10 cada uno, 10, 11. El resto con cada capítulo.

## 17. Riesgos de usabilidad (para `experto-ux-parvulo` y `tester-qa`)

1. **Maxi arrastrando la pieza**: ¿descubre el arrastre o se queda tocando? Están el salto por toque y la
   válvula. Medir en el playtest cuántos segundos tarda y si entiende que "la pieza es suya".
2. **Celos en la instalación**: ¿Nicole siente que "poner la estrella" vale menos que "poner la pieza"?
   Observar si alguna pide "yo quiero poner el ala". Mitigación: mismo tiempo y fiesta, sin nombrar el
   orden; si hace falta, la estrella podría llevar también una franja de su color en la pieza.
3. **Conflictos por pintar encima** (Maxi sobre lo de Sofía, que se frustra rápido): la escoba y los
   respaldos lo arreglan, pero el llanto ocurre antes. Es la pregunta P3.
4. **Modo de herramienta**: con el balde elegido, ¿tocar una calcomanía la pinta o la levanta? Regla
   propuesta: tocar una calcomanía siempre la **levanta**; el balde solo pinta zonas. Validar que no
   confunda a Nicole cuando quiere teñir una calcomanía (para eso arrastra una nueva con el color elegido:
   las calcomanías salen del color actual).
5. **"¡lista!" ambiguo**: ¿se entiende como "terminé, me voy"? Icono propuesto: nave chiquita con check y
   estela. Probar contra una casita.
6. **La puerta**: ¿entienden que entrar no borra lo de afuera? La tapa abierta sigue visible de canto.
7. **Zonas chicas** para Nicole: ventanitas y remiendos (~60-70 px). Su área táctil se agranda a ≥ 64 px
   aunque el dibujo sea menor.
8. **Cajita**: ¿la viven como pérdida? Debe brillar y "devolver" visiblemente.
9. **Autoría que ensucia**: confirmar que la estrellita de 1 s no genera peleas de "eso es mío" (o que
   sean juguetonas).
10. **Rendimiento** en la tablet con 80 cosas + capas de pincel + sombreado: medir FPS en el teléfono del PO.
11. **Duración real del disparo**: QA debe cronometrar 20 disparos por perfil (meta: 90 % ≤ 20 s).
12. **Inactividad**: que la salida a los 60 s no corte a un niño que solo está mirando la fiesta.

## 18. Decisiones por delegación del PO

- La entrada principal es el botón que ya existe en el Mapa Estelar (es la pantalla principal tras elegir
  hermano y la autoría necesita saber quién juega). Si el PO quiere además un botón en el título, es
  trivial.
- Orden tras la entrega: escena → foto familiar (si es nueva) → hangar.
- Una pieza ganada sin estrella se recupera al entrar al hangar: nunca se pierde el momento.
- Equidad por estrellas-firma (§5.2); el primero recibe la suya sola al encajar.
- Imán 220 px (Maxi: pantalla completa tras 40 px de arrastre); salto de un tercio por toque en Maxi;
  válvula a las 2 manos.
- Inactividad: recordar a los 30 s, salir sola a los 60 s.
- Decorar libre no da destellos; cartilla por perfil, 12 sellos × 10 destellos, igual para los tres.
- Zonas agrupadas en 6 para Maxi; sin patrones ni pincel para Maxi.
- Las calcomanías salen del color elegido (como el balde de Pinta tiñe stickers).
- Quitar = arrastrar a la cajita; lo ajeno va a la cajita de su autor.
- Deshacer por sesión; la escoba restaura "como estaba al entrar"; respaldos de padres (últimos 5).
- Tope 40 calcomanías por vista; lo más viejo del mismo hermano va a su cajita.
- Los dibujos de "Decora el ala" se cuelgan en la pared de obras del interior, uno por hermano, en vez de
  "pintados sobre el ala" (`planeta-arcoiris-zonas.md`): con una sola nave no caben tres dibujos en un ala
  sin pisarse. Si el PO prefiere, una variante "ala-lienzo" podría mostrar uno elegido.
- Papá puede estar en la nave como amigo (igual que en Pinta: es su imaginación).
- La voz del hangar es Cometa (su nave); Coco solo nombra sus regalos con voces que ya existen.

## 19. Preguntas de fondo para el PO

- **P1. La partida de Arcoíris (§5.4).** El pedido nuevo choca con lo aprobado en HE-17, HE-75 (N6) y
  HE-84 (el ala llega envuelta y se instala en la partida). **Recomiendo la opción A**: el hangar encaja el
  ala al recibirla, pero queda floja; la partida conserva sus pasos y Nicole la asegura con los broches.
  La opción B deja el regalo envuelto junto al hueco hasta la partida.
- **P2. Variantes de piezas.** ¿Se hacen 3 estilos por pieza (2 SVG extra por capítulo) o una sola forma
  canónica y la personalización va solo por pintura y calcomanías? Recomiendo sí, empezando con el ala
  izquierda.
- **P3. Pintar encima de lo de otro.** ¿Libre (con escoba, deshacer y respaldos de padres) o protegido (la
  zona pintada por un hermano solo la cambia él)? Recomiendo libre: un candado contradice "cada uno pone
  lo que quiera" y la red de seguridad lo vuelve reversible. Pero conoces las peleas reales en casa.

## 20. Tarjetas propuestas para el backlog (las registra el `scrum-master`)

Ids provisionales H1-H12.

| # | Tarjeta | Depende de | Rol |
|---|---|---|---|
| H1 | Revisión del PO de la ficha y la maqueta `hangar-v1.html`; decisiones P1-P3 | — | PO |
| H2 | Auditoría UX de la ficha y la maqueta (§17), 0 bloqueantes | H1 | experto-ux-parvulo |
| H3 | Conciliar la opción elegida en P1 con HE-17, HE-75 (N6), HE-84 (NI0) y el plano M7 del storyboard del cierre | H1 | director-cinematicas + guionista |
| H4 | Guion de voces del hangar (§15, ≈ 138 líneas) + TTS gratuito provisional | H1 | guionista |
| H5 | Arte del hangar, capítulo 1 (§16, prioridad cap. 1): nave por capas, ala y huecos, estrellas, interior base, ~10 calcomanías, ~10 muebles, patrones y UI; SVG en `assets/fuentes_svg/hangar/` | H1 | disenador-personajes + PO |
| H6 | Extraer del lienzo a `scripts/comun/taller/` el dock con popups, el historial de fotos, el botón de mantener y la base de stickers y gravedad, sin regresión (`qa_test_lienzo` completo con guardado aislado) | — | Dev |
| H7 | Núcleo: `Progreso` v4 con migración (`nave`, `compartido`, `perfiles.<id>.hangar`), API `obtener/guardar_estado_compartido` en `minijuego_base`, señales `pieza_instalada`/`estrella_puesta`, lanzador por datos desde `boton_hangar` (que late si hay pendientes) y enganche tras HE-17/HE-47; respaldos (5). Arnés con guardado aislado y md5 | H1 | Dev |
| H8 | Motor `hangar` v1, vista de afuera: zonas y balde por perfil, patrones, pincel enmascarado, espejo, calcomanías, cajitas, autoría, deshacer y escoba de sesión, guirnalda, huecos, modo `instalar` (pieza y estrella) con línea de tiempo §5.3, "¡lista!", miniatura. `qa_test_hangar.gd` | H6, H7, H5 (puede partir con arte en código) | Dev |
| H9 | Motor `hangar` v2, vista de adentro: apertura de casita, muebles con gravedad, amigos sentados, panel de cabina, rincones, regalos de Coco y pared de obras | H8 | Dev |
| H10 | Contenido de las cartillas (12 sellos por hermano) + motor de sellos y destellos | H8 | disenador-niveles + Dev |
| H11 | Zona de padres: "Volver la nave a como estaba" (miniaturas de respaldos) | H7, HE-12 | Dev |
| H12 | Playtest del hangar con los tres (preguntas del §17) | H8, H9 | PO + tester-qa |
| (por capítulo) | Variantes de la pieza del capítulo + agregado interior (si P2 = sí) | H5, H8 | disenador-personajes + Dev |
