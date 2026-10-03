# Guion de voz — Las migas de papá (álbum de recuerdos)

> Guion de la épica "Las migas de papá" (HE-44, validación de diseño, parte del `guionista`).
> Solo texto: ninguna línea tiene audio todavía.
> Fuentes de verdad: `docs/fichas/album-recuerdos.md` (ficha de la épica), `docs/diseno-juego.md`
> §1 (tono), §2 (Cometa, Coleccionauta, papá) y §3 ("Las migas de papá"),
> `assets/audio/voces/guion_voces.md` (formato de la tabla de grabación).

- **Personajes**: Cometa (casi todo), papá y el Coleccionauta (solo en el esbozo del final).
- **Prefijo de id / carpeta de audio**: `recuerdos_XXX` → `assets/audio/voces/recuerdos/`
  (el archivo va sin el prefijo: `recuerdos_entrega_01` → `recuerdos/entrega_01.ogg`, igual que
  `cometa_saludo_01` → `cometa/saludo_01.ogg`).
- **Las voces de cada foto** (lo que graba la familia) **no** están en esta tabla: viven en
  `assets/recuerdos/voces/<id_foto>.ogg`, fuera del repo (ficha §8). Ver §6 de este guion.
- **Revisión 28-Sep-2026 (HE-44)**: se suman la entrega tras el regalo del anfitrión (§1.2b, 2
  líneas) y los pies de foto narrados (§8, 34 líneas), y se reescriben las 8 pistas de zona (§4.2)
  por la regla de zona completa. Falta copiar estas filas a `assets/audio/voces/guion_voces.md` y
  sumar las claves `entrega_zona` y `pie` al catálogo (`dev-godot`).
- **Estado de todas las líneas**: pendientes de audio. Van con la voz oficial de Cometa cuando el
  PO lo decida (y apruebe el costo). Este guion no genera audio.

## Salvaguardas de tono (recordatorio explícito)

- **Las fotos no se "perdieron" en un sentido triste**: se volaron en un momento chistoso y ahora
  son un juego de búsqueda. Nadie dice que papá está triste sin sus fotos.
- **Cero presión**: ninguna línea une las fotos con "llegar antes a papá". Se juntan para mirarlas
  y para mostrárselas a papá cuando se vean, no para rescatarlo más rápido.
- **Nada se pierde**: si una burbuja se escapa, "ya vuelve a pasar". Las pistas terminan siempre
  en "aparece solita", nunca en "tienes que...".
- **Sin comparar hermanos** (Sofía siente celos de Nicole, GDD §2): las tapas se presentan con el
  mismo cariño; la foto familiar que encuentra uno "es de los tres"; el marco dorado de Sofía se
  celebra solo con ella, sin mencionar a los otros.

---

## 0. Decisión narrativa: por qué se volaron las fotos

La ficha dice que "a papá se le cayeron las fotos de la billetera" cuando se lo llevaron. Para que
eso no suene a forcejeo ni a caída, este guion le pone una causa **cómica**, a tono con el
Coleccionauta torpe:

> El rayo del Coleccionauta hace **cosquillas**. Papá se rió tanto que, **¡pffft!**, se le volaron
> todas las fotos de la billetera. **La primera cayó en la alfombra del living** y las demás se
> fueron flotando detrás de la nave del Coleccionauta, por toda la galaxia.

Esto resuelve además un problema de coherencia (ver Observaciones, punto 2): el secuestro ocurre
en el living, así que la primera foto se encuentra en casa y el resto aparece "en el camino".

---

## 1. Entrega de un recuerdo

**Acotación**: todo se detiene suave; baja girando el sobre-estrella (ficha §6). Cometa dice una
de estas líneas **antes** de que se abra el sobre. Al abrirse suena el audio de la familia; Cometa
no habla encima de ese audio.

### 1.1 La primera foto de todas (familiar, "antes del secuestro")

Suenan seguidas: `_01` al aparecer el sobre y `_02` cuando la foto ya voló al ícono del álbum.
**Dónde suena**: ver Observaciones, punto 1. Recomiendo que sea justo al terminar la intro (tras la
video-llamada de papá, antes de "¿Listos para volar?"), no al abrir el juego por primera vez.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| recuerdos_primera_01 | Cometa | «¡Miren lo que quedó en la alfombra! Papá se rió tanto con las cosquillas del rayo del Coleccionauta, que ¡pffft!, se le volaron todas las fotos de la billetera.» | divertido, contándolo como chiste; el "pffft" bien soplado |
| recuerdos_primera_02 | Cometa | «Las demás andan flotando por la galaxia. ¡Las vamos a ir encontrando en el camino, y se las mostramos a papá cuando lo veamos!» | ilusionado, sin apuro |

### 1.2 Variantes de cada entrega (el motor elige una al azar)

| id | Personaje | Línea | Intención |
|---|---|---|---|
| recuerdos_entrega_01 | Cometa | «¡Mira! ¡Otra foto de la billetera de papá!» | sorpresa feliz (línea de la ficha) |
| recuerdos_entrega_02 | Cometa | «¡Uuuh, una estrella-recuerdo! ¿Quién saldrá en esta foto?» | curioso, en secreto |
| recuerdos_entrega_03 | Cometa | «¡Plin! Otra fotito que se le voló a papá. ¡Ábrela, ábrela!» | saltarín, impaciente de gusto |
| recuerdos_entrega_04 | Cometa | «¡Miren quién sale aquí! Una foto más para el álbum.» | cálido, orgulloso |

### 1.2b Entrega que sigue al regalo del anfitrión (zonas 2 y 4)

*(Agregado 28-Sep-2026, HE-44.)* Cuando la foto llega al completar una zona, antes sonaron
`zona_<n>_completada` y `zona_<n>_regalo` de Coco (`docs/guiones/zonas_arcoiris.md` §1). Estas
variantes reemplazan a las de §1.2 en ese momento: enlazan las dos sorpresas sin que se encimen
("y eso no es todo") y dejan claro que la foto no es otro regalo de Coco, sino algo que trajo el viento.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| recuerdos_entrega_zona_01 | Cometa | «¡Y eso no es todo! El viento trajo algo más... ¡una foto de papá!» | sorpresa en dos tiempos, pausa antes de "¡una foto!" |
| recuerdos_entrega_zona_02 | Cometa | «¡Esperen, esperen! ¡Viene bajando una estrella-recuerdo!» | emocionado, mirando hacia arriba |

### 1.3 Relleno cuando la foto todavía no tiene audio de la familia

La ficha (§8) usa "una línea de Cometa genérica en vez del audio" si falta el `.ogg` de la foto.
Suenan **después** de abrir el sobre, en el lugar del audio de la familia.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| recuerdos_generica_01 | Cometa | «¡Qué foto más linda! Esta va directo al álbum.» | tierno |
| recuerdos_generica_02 | Cometa | «¡Mira qué caritas! Un recuerdo calentito, calentito.» | tierno, como abrazando la foto |

### 1.4 Marco dorado (solo Sofía, estrellitas máximas en la zona)

Suena cuando la foto de esa zona se gana el marco dorado (ficha §4). Juego de palabras suave con
su nivel Estrella. Nunca menciona a los otros hermanos.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| recuerdos_dorado_01 | Cometa | «¡Marco dorado! Esta foto es de nivel... ¡Estrella!» | admirado, con guiño cómplice |

---

## 2. Recuerdo familiar encontrado por un hermano

**Acotación**: reemplaza a la variante de §1.2 cuando la foto es del álbum familiar y la desbloquea
el hermano que está jugando. La idea de compartir va en la acción ("es de los tres"), sin
explicarla.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| recuerdos_familiar_maxi_01 | Cometa | «¡Maxi encontró una foto de la familia! ¡Y es para los tres!» | fiesta grande, como para un explorador |
| recuerdos_familiar_nicole_01 | Cometa | «¡Nicole encontró una foto de la familia! ¡Y es para los tres!» | fiesta grande, cariñoso |
| recuerdos_familiar_sofia_01 | Cometa | «¡Sofía encontró una foto de la familia! ¡Y es para los tres!» | fiesta grande, orgulloso |

> Las tres líneas son idénticas salvo el nombre, a propósito: ningún hermano "vale más".
> Digo "de la familia" y no "de toda la familia" porque algunas fotos del álbum familiar son de
> dos o tres hermanos, sin papá ni mamá (ficha §3).

---

## 3. El álbum

**Acotación**: el botón libro-álbum está en la pantalla de título o de selección (ficha §7). La
línea de foto nueva suena **una vez** al entrar a esa pantalla si hay fotos sin ver; no se repite
en bucle para no competir con `titulo_bienvenida_01`.

| id | Personaje | Línea | Intención | Dónde suena |
|---|---|---|---|---|
| recuerdos_album_nueva_01 | Cometa | «¡Psst! Hay una foto nueva esperando en el álbum.» | susurrando, cómplice | Título/selección, con el brillo pulsante del botón |
| recuerdos_album_invitacion_01 | Cometa | «¡El álbum de las fotos de papá! Toca una tapa y vamos a mirar.» | invitando, contento | Al abrir el álbum (portada con las 4 tapas) |
| recuerdos_tapa_maxi_01 | Cometa | «¡El álbum de Maxi! De chiquitito... ¡a grandote!» | "chiquitito" bajito, "grandote" con voz grande | Al tocar la tapa de Maxi |
| recuerdos_tapa_nicole_01 | Cometa | «¡El álbum de Nicole! Cuidado, que aquí hay sonrisas por todos lados.» | con risa | Al tocar la tapa de Nicole |
| recuerdos_tapa_sofia_01 | Cometa | «¡El álbum de Sofía! La capitana... desde que era una capitanita.» | admirado y tierno a la vez | Al tocar la tapa de Sofía |
| recuerdos_tapa_familia_01 | Cometa | «¡El álbum de la familia! Aquí caben todos... ¡bien apretaditos!» | con risa, apretujando la voz al final | Al tocar la tapa Familia |
| recuerdos_album_vacio_01 | Cometa | «Este álbum está esperando sus fotos. ¡Van a ir llegando solitas mientras juegan!» | tranquilo, prometiendo | Al abrir un álbum sin ninguna foto |

---

## 4. Pistas de los huecos

**Acotación**: al tocar un hueco (silueta de marco con estrella y signo de interrogación), Cometa
dice dónde está la foto. Todas terminan tranquilizando: la foto llega sola jugando.

**Por qué una línea por planeta y no una frase con el nombre pegado**: pegar "...en el Planeta"
+ "Animalia" suena cortado con voz casera o TTS. Son pocas líneas; conviene grabarlas enteras.
Solo existen las de planetas con zonas ya creadas (ficha §5: sin zonas no hay hueco visible).

### 4.1 Viaje estelar

| id | Personaje | Línea | Intención | Momento (`momento.id`) |
|---|---|---|---|---|
| recuerdos_pista_viaje_despegue_01 | Cometa | «Esta foto anda flotando en el primer viaje de la nave. ¡Ya la vamos a ver pasar!» | ilusionado | `viaje` / `primer_despegue` |
| recuerdos_pista_viaje_final_01 | Cometa | «Esta foto anda flotando en el viaje al planeta del Coleccionauta. ¡Ya la vamos a ver pasar!» | ilusionado | `viaje` / viaje al planeta final |

### 4.2 Zona de un planeta

Capítulo 1 con el nombre de la zona (el planeta está pulido al detalle); los demás con el
planeta. `recuerdos_pista_zona_arcoiris_01` queda de respaldo por si el reparto de zonas cambia.

*(Reescritas 28-Sep-2026, HE-44.)* Antes terminaban en "¡Aparece solita cuando juegues ahí!". Con
la regla del PO del 27-Sep la foto llega al completar **todos** los juegos de la zona. Un niño que
juega uno solo y no ve la foto sentiría que la promesa no se cumplió. Ahora dicen "cuando juegues
todos los juegos de ahí", que es cierto y sigue sin exigir desempeño.

| id | Personaje | Línea | Intención | Momento |
|---|---|---|---|---|
| recuerdos_pista_zona_arcoiris_charcos_01 | Cometa | «Esta foto está escondida en los Charcos Saltarines del Planeta Arcoíris. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` arcoiris, zona 2 |
| recuerdos_pista_zona_arcoiris_islotes_01 | Cometa | «Esta foto está escondida en los Islotes Flotantes del Planeta Arcoíris. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` arcoiris, zona 4 |
| recuerdos_pista_zona_arcoiris_01 | Cometa | «Esta foto está escondida en el Planeta Arcoíris. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` arcoiris (respaldo) |
| recuerdos_pista_zona_animalia_01 | Cometa | «Esta foto está escondida en el Planeta Animalia. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` animalia |
| recuerdos_pista_zona_melodia_01 | Cometa | «Esta foto está escondida en el Planeta Melodía. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` melodia |
| recuerdos_pista_zona_cuentacuentas_01 | Cometa | «Esta foto está escondida en el Planeta Cuenta-Cuentas. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` cuentacuentas |
| recuerdos_pista_zona_letralandia_01 | Cometa | «Esta foto está escondida en el Planeta Letralandia. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` letralandia |
| recuerdos_pista_zona_corazon_01 | Cometa | «Esta foto está escondida en el Planeta Corazón. ¡Aparece solita cuando juegues todos los juegos de ahí!» | cómplice | `zona_completa` corazon |

### 4.3 Pieza de la nave (álbum familiar)

El anfitrión "guarda" la foto junto con la pieza: le da personaje al hueco.

| id | Personaje | Línea | Intención | Momento |
|---|---|---|---|---|
| recuerdos_pista_pieza_arcoiris_01 | Cometa | «Esta foto la guarda Coco, en el Planeta Arcoíris. ¡Llega junto con la pieza de la nave!» | cómplice | `pieza_nave` arcoiris |
| recuerdos_pista_pieza_animalia_01 | Cometa | «Esta foto la guarda Toby, en el Planeta Animalia. ¡Llega junto con la pieza de la nave!» | cómplice | `pieza_nave` animalia |
| recuerdos_pista_pieza_melodia_01 | Cometa | «Esta foto la guarda Octavio, en el Planeta Melodía. ¡Llega junto con la pieza de la nave!» | cómplice | `pieza_nave` melodia |
| recuerdos_pista_pieza_cuentacuentas_01 | Cometa | «Esta foto la guarda el Profesor Plumas, en el Planeta Cuenta-Cuentas. ¡Llega junto con la pieza de la nave!» | cómplice | `pieza_nave` cuentacuentas |
| recuerdos_pista_pieza_letralandia_01 | Cometa | «Esta foto la guarda Lila, en el Planeta Letralandia. ¡Llega junto con la pieza de la nave!» | cómplice | `pieza_nave` letralandia |
| recuerdos_pista_pieza_corazon_01 | Cometa | «Esta foto la guarda Mimi, en el Planeta Corazón. ¡Llega junto con la pieza de la nave!» | cómplice | `pieza_nave` corazon |

### 4.4 Rescate final

| id | Personaje | Línea | Intención | Momento |
|---|---|---|---|---|
| recuerdos_pista_rescate_01 | Cometa | «Esta es la última foto. ¡La guardamos para el final, cuando estemos todos juntos!» | tierno, prometiendo | `rescate_final` |

---

## 5. La burbuja-recuerdo del viaje estelar

**Acotación**: una burbuja con una foto adentro cruza la pantalla del modo Galaga, lenta y grande.
Se atrapa tocándola o chocándola con la nave. Sonido de *plop* al reventar (SFX, no voz).
Singular ("tócala") porque pilotea un hermano a la vez.

| id | Personaje | Línea | Intención | Dónde suena |
|---|---|---|---|---|
| recuerdos_burbuja_aviso_01 | Cometa | «¡Mira, una burbuja-recuerdo! ¡Tócala o chócala con la nave!» | emocionado, señalando | Al aparecer la burbuja |
| recuerdos_burbuja_aviso_02 | Cometa | «¡Ahí viene una foto flotando! ¡Atrápala!» | emocionado | Variante de `aviso_01` |
| recuerdos_burbuja_atrapada_01 | Cometa | «¡Plop! ¡La atrapaste! Otra foto para el álbum.» | fiesta; "plop" bien sonoro para Maxi | Al atraparla (antes del sobre-estrella) |
| recuerdos_burbuja_atrapada_02 | Cometa | «¡Burbuja reventada, foto encontrada!» | rimando, cantadito | Variante de `atrapada_01` |
| recuerdos_burbuja_vuelve_01 | Cometa | «¡Uy, se fue dando botes! Tranqui, ya vuelve a pasar.» | con risa, cero drama | Si la burbuja sale de la pantalla sin atraparla |

---

## 6. Guía para la grabación familiar

Esto **no** son líneas de Cometa: es lo que el PO graba con los niños, papá y mamá, un audio por
foto, que suena cuando la foto se abre (ficha §6 paso 4 y §7 "foto abierta").

### 6.1 Formato sugerido (3-10 segundos por foto)

Una fórmula simple que funciona casi siempre:

1. **Quién o qué** (opcional si la foto lo dice sola): "Aquí Maxi tenía tres semanitas".
2. **Un detalle chiquito y concreto**: algo que se ve o que pasó ese día.
3. **Un cariño o una risa** al final.

Si la foto va con pie de foto narrado ("Maxi, 3 meses", ficha §7), **inclúyelo en el mismo audio**
al comienzo. Así no hace falta una segunda grabación.

### 6.2 Ejemplos por tipo de foto

Son ejemplos para inspirarse, no para leer tal cual: lo que sirve es la manera de hablar de la
casa.

**Bebé (recién nacido, primer baño, primera sonrisa)**, mejor con papá o mamá:

- «Aquí Maxi tenía tres semanitas. Dormía con los brazos arriba, como celebrando un gol.»
- «El primer baño de Nicole. Lloró un ratito... y después no se quería salir.»
- «¡La primera sonrisa de Sofía! Tu papá casi se desmaya de la emoción.»

**Primeros pasos y primeras veces (pasos, primer cumpleaños, primer día de jardín)**:

- «Mira, Nicole dando sus primeros pasos. Tres pasitos... ¡y a la alfombra, pum!»
- «Primer cumpleaños de Maxi. Se comió la torta con las dos manos. Y con la cara.»
- «Sofía en su primer día de colegio. Mochila más grande que ella.»

**Familia (los cinco, o hermanos juntos)**, idealmente las voces de varios, cada uno una frase:

- Papá: «¡Los cinco en la playa!» · Nicole: «¡Yo hice el castillo!» · Maxi: «¡Aguaaa!»
- Mamá: «Los tres hermanos, con pijamas iguales.» · Sofía: «Idea mía, obvio.»
- Papá: «Esta la sacamos justo antes de... un tremendo estornudo de Maxi.» (risas)

**Del propio niño sobre su foto** (el más lindo de todos, aunque salga cualquier cosa):

- Maxi: «¡Ese soy yo!» / «¡Guagua!»
- Nicole: «Aquí yo tenía un vestido de princesa y un pony.»
- Sofía: «Aquí era chiquitita y ya mandaba.»

### 6.3 Cómo grabar con niños de 2 a 8 años

- **Muéstrales la foto de verdad mientras graban** (en el teléfono o impresa). Lo mejor sale
  cuando reaccionan a la foto, no cuando repiten una frase.
- **Sesiones cortas**: 10-15 minutos, 4-5 fotos por sesión. Con Maxi, 2-3 fotos y a jugar.
- **Máximo dos intentos por frase**. Si al tercero no sale, se deja para otro día. Si dicen otra
  cosa distinta a la pensada y es tierna o chistosa, **esa es la buena**.
- **Maxi (2 años)**: no le pidas frases; pregúntale "¿quién es ese?" o "¿qué está haciendo?" y
  graba lo que responda. Una risa o un "¡guagua!" ya es un audio perfecto. Graba de más y se
  recorta después.
- **Nicole (5)**: le encanta contar. Pregúntale "¿qué pasó ese día?" y deja que hable; después
  se elige el mejor pedacito de 3-10 s.
- **Sofía (8)**: puede leer una frase corta o inventarla. Dale el rol de "narradora del álbum" en
  algunas fotos de sus hermanos: le calza con ser la líder.
- **Nunca "otra vez, lo dijiste mal"**. Si hay que repetir: "¡me encantó! ¿lo decimos una vez más
  con voz de astronauta?".
- **Lugar**: una pieza chica con cortinas, cojines o ropa colgada (un clóset abierto sirve). Nada
  de tele, lavadora ni ventana abierta.
- **Teléfono**: a 20-30 cm de la boca, en modo avión, apoyado (no en la mano de un niño). Deja un
  segundo de silencio antes y después de hablar.
- **Tono**: en presente y alegre, como mirando un álbum en el sillón. Nada de "papá desapareció"
  ni referencias al juego: estos audios son de la casa, no de la aventura.
- **Nombre del archivo**: el id de la foto en el catálogo, por ejemplo `maxi_01.ogg` o `.wav`
  (el pipeline convierte). Estos archivos no se suben a GitHub (ficha §8, privacidad).
- **Extra que vale oro**: graba sueltas unas risas de cada uno y un "¡te quiero, papá!" de cada
  hermano. Sirven para el final (§7) y para la cápsula del tiempo (ficha §9, idea 6).

---

## 7. Esbozo del final (insumo para HE-39)

> Solo un esbozo. La escena final es de HE-39 (`director-cinematicas` y `guionista`) y encaja en
> `docs/guiones/prueba_final_cooperativa.md`, entre el rescate (Beat 6) y "¿puedo ir a
> visitarlos?" (`final_036`). Ids **provisionales**: se renumeran en HE-39 y no se agregan todavía a
> `guion_voces.md`.

**Acotación**: los hermanos le muestran a papá el álbum (sale flotando de la nave, abierto). Papá
lo hojea; las fotos brillan una por una. El Coleccionauta mira por encima del hombro de papá, con
su caja con candados bajo el brazo.

| id provisional | Personaje | Línea | Intención |
|---|---|---|---|
| final_rec_01 | Papá | «¡Mis fotos! ¿Las juntaron todas? Y yo que creía que se me habían volado para siempre... ¡Miren, Maxi con su primer diente!» | feliz, emocionado sin ponerse triste; chiste de papá al final |
| final_rec_02 | Coleccionauta | «Yo las habría guardado en una caja con siete candados... Pero así, mirándolas todos juntos, brillan muchísimo más.» | grandilocuente al comienzo, sorprendido y suave al final |
| final_rec_03 | Coleccionauta | «¡Ya sé! Los recuerdos no se guardan en cajas: ¡se comparten! ...Oigan, ¿esa idea puedo ponerla en mi colección?» | "descubre" la lección él solo y se equivoca en chico al final |

La lección la dice el Coleccionauta, que la descubre él solo y se enreda con ella. No la dicen
Cometa ni papá, así no suena a sermón. Rima con `final_038` de Cometa ("los amigos son la mejor
colección").

---

## 8. Pies de foto narrados (HE-44, 28-Sep-2026)

**Acotación**: la ficha (§7, "Foto abierta") propone un pie opcional con la edad ("Maxi, 3 meses"),
dibujado y narrado. Lo dice Cometa, corto (1-2 s) y tierno, **antes** del audio de la familia.

**Decisiones**:

- **Sin nombre en el pie.** La tapa del álbum ya dijo de quién es (`recuerdos_tapa_*`). Pegar
  "Maxi" + "tres meses" suena cortado (mismo motivo de §4). Además, con "Aquí tenía..." sirve la
  misma línea para los tres, sin problemas de nacido/nacida.
- **Diminutivos en las edades de guagua** ("mesecito", "añito"); edades de grande, dichas sin
  diminutivo, para que Sofía no sienta que la tratan de chica.
- **Edades raras, redondeadas para el oído**: "1 año y 3 meses" → "un año y un poquito"; "1 año y
  9 meses" → "casi dos años". Es como se dice en la casa.
- **Cuándo suena** (propuesta para `dev-godot`): en la foto abierta del álbum y en la entrega,
  antes del audio de la familia. Si ese audio ya trae el pie grabado por la familia (§6.1), el
  catálogo marca `pie_en_audio: true` y el pie de Cometa no suena. Si no hay audio familiar, suena
  el pie y después `recuerdos_generica_*`.
- **Dato nuevo en el catálogo**: campo `pie` en cada recuerdo, con el id de la línea (data-driven;
  la tabla de abajo da la correspondencia con el campo `edad` actual). La ruta sigue la convención
  del autoload: `recuerdos_pie_X` → `assets/audio/voces/recuerdos/pie_X.wav` (u `.ogg`).

### 8.1 Pies por edad (álbumes de Maxi, Nicole y Sofía)

| id | Personaje | Línea | Intención | `edad` del catálogo | Ruta sugerida |
|---|---|---|---|---|---|
| recuerdos_pie_recien_nacido | Cometa | «¡Aquí recién llegaba al mundo!» | maravillado, bajito | recién nacido / recién nacida | `voces/recuerdos/pie_recien_nacido.wav` |
| recuerdos_pie_1_mes | Cometa | «Aquí tenía un mesecito.» | tierno | 1 mes | `voces/recuerdos/pie_1_mes.wav` |
| recuerdos_pie_3_meses | Cometa | «Aquí tenía tres mesecitos.» | tierno | 3 meses | `voces/recuerdos/pie_3_meses.wav` |
| recuerdos_pie_5_meses | Cometa | «Aquí tenía cinco meses.» | tierno | 5 meses | `voces/recuerdos/pie_5_meses.wav` |
| recuerdos_pie_6_meses | Cometa | «Aquí tenía seis meses. ¡Medio añito!» | tierno, con risa al final | 6 meses | `voces/recuerdos/pie_6_meses.wav` |
| recuerdos_pie_8_meses | Cometa | «Aquí tenía ocho meses.» | tierno | 8 meses | `voces/recuerdos/pie_8_meses.wav` |
| recuerdos_pie_9_meses | Cometa | «Aquí tenía nueve meses.» | tierno | 9 meses | `voces/recuerdos/pie_9_meses.wav` |
| recuerdos_pie_10_meses | Cometa | «Aquí tenía diez meses.» | tierno | 10 meses | `voces/recuerdos/pie_10_meses.wav` |
| recuerdos_pie_1_ano | Cometa | «¡Aquí tenía un añito!» | alegre | 1 año | `voces/recuerdos/pie_1_ano.wav` |
| recuerdos_pie_1_ano_3_meses | Cometa | «Aquí tenía un año... y un poquito.» | juguetón, pausa antes de "y un poquito" | 1 año y 3 meses | `voces/recuerdos/pie_1_ano_3_meses.wav` |
| recuerdos_pie_1_ano_6_meses | Cometa | «Aquí tenía un año y medio.» | tierno | 1 año y 6 meses | `voces/recuerdos/pie_1_ano_6_meses.wav` |
| recuerdos_pie_1_ano_9_meses | Cometa | «¡Aquí tenía casi dos años!» | alegre | 1 año y 9 meses | `voces/recuerdos/pie_1_ano_9_meses.wav` |
| recuerdos_pie_2_anos | Cometa | «Aquí tenía dos años.» | alegre | 2 años | `voces/recuerdos/pie_2_anos.wav` |
| recuerdos_pie_2_anos_6_meses | Cometa | «Aquí tenía dos años y medio.» | alegre | 2 años y 6 meses | `voces/recuerdos/pie_2_anos_6_meses.wav` |
| recuerdos_pie_3_anos | Cometa | «Aquí tenía tres años.» | alegre | 3 años | `voces/recuerdos/pie_3_anos.wav` |
| recuerdos_pie_3_anos_6_meses | Cometa | «Aquí tenía tres años y medio.» | alegre | 3 años y 6 meses | `voces/recuerdos/pie_3_anos_6_meses.wav` |
| recuerdos_pie_4_anos | Cometa | «Aquí tenía cuatro años.» | alegre | 4 años | `voces/recuerdos/pie_4_anos.wav` |
| recuerdos_pie_4_anos_6_meses | Cometa | «Aquí tenía cuatro años y medio.» | alegre | 4 años y 6 meses | `voces/recuerdos/pie_4_anos_6_meses.wav` |
| recuerdos_pie_5_anos | Cometa | «Aquí tenía cinco años.» | alegre | 5 años | `voces/recuerdos/pie_5_anos.wav` |
| recuerdos_pie_6_anos | Cometa | «Aquí tenía seis años.» | alegre | 6 años | `voces/recuerdos/pie_6_anos.wav` |
| recuerdos_pie_6_anos_6_meses | Cometa | «Aquí tenía seis años y medio.» | alegre | 6 años y 6 meses | `voces/recuerdos/pie_6_anos_6_meses.wav` |
| recuerdos_pie_7_anos | Cometa | «Aquí tenía siete años.» | alegre | 7 años | `voces/recuerdos/pie_7_anos.wav` |
| recuerdos_pie_8_anos | Cometa | «Aquí tenía ocho años.» | alegre | 8 años | `voces/recuerdos/pie_8_anos.wav` |
| recuerdos_pie_hoy | Cometa | «¡Y esta foto es de ahora, ahora!» | con risa, el "ahora, ahora" rebotado | hoy | `voces/recuerdos/pie_hoy.wav` |

### 8.2 Pies del álbum familiar

Uno por tipo de foto de la lista sugerida del catálogo (`sugerencia` de `familia_01` a `familia_09`).
El PO elige la que calce con la foto real; si ninguna calza, el pie se omite (es opcional).

| id | Personaje | Línea | Intención | Foto sugerida | Ruta sugerida |
|---|---|---|---|---|---|
| recuerdos_pie_familia_billetera | Cometa | «¡La foto de la billetera de papá! Los cinco, juntitos.» | cálido, orgulloso | los cinco antes del secuestro (`familia_01`) | `voces/recuerdos/pie_familia_billetera.wav` |
| recuerdos_pie_familia_mama_papa_guagua | Cometa | «¡Mamá y papá con una guagua chiquitita! ¿Adivinan quién es?» | cómplice, pregunta de juego | mamá y papá con Sofía bebé | `voces/recuerdos/pie_familia_mama_papa_guagua.wav` |
| recuerdos_pie_familia_hermanos_primera_vez | Cometa | «¡Los tres hermanos juntos, por primera vez!» | emocionado | los tres hermanos juntos por primera vez | `voces/recuerdos/pie_familia_hermanos_primera_vez.wav` |
| recuerdos_pie_familia_paseo | Cometa | «¡De paseo en familia!» | alegre | un paseo en familia | `voces/recuerdos/pie_familia_paseo.wav` |
| recuerdos_pie_familia_cumpleanos | Cometa | «¡Un cumpleaños en familia! ¿Cuántas velitas había?» | fiesta, pregunta de juego | un cumpleaños en familia | `voces/recuerdos/pie_familia_cumpleanos.wav` |
| recuerdos_pie_familia_vacaciones_chile | Cometa | «¡De vacaciones por Chile!» | alegre | vacaciones en Chile | `voces/recuerdos/pie_familia_vacaciones_chile.wav` |
| recuerdos_pie_familia_navidad | Cometa | «¡Navidad en familia!» | cálido | Navidad | `voces/recuerdos/pie_familia_navidad.wav` |
| recuerdos_pie_familia_dieciocho | Cometa | «¡Celebrando el Dieciocho! ¡Viva Chile!» | fiesta patria | 18 de septiembre | `voces/recuerdos/pie_familia_dieciocho.wav` |
| recuerdos_pie_familia_hermanos_hoy | Cometa | «¡Los tres hermanos... así de grandes hoy!» | admirado, "grandes" estirado | los tres hermanos hoy | `voces/recuerdos/pie_familia_hermanos_hoy.wav` |
| recuerdos_pie_familia_todos_juntos | Cometa | «¡Todos juntos! Esta es la foto más nueva de todas.» | tierno, cierre | los cinco juntos, rescate final (`familia_09`) | `voces/recuerdos/pie_familia_todos_juntos.wav` |

> "Guagua" es la palabra de la casa (chileno). Con la voz de Cometa (latino neutro) se entiende
> igual. Si el TTS la pronuncia raro, la alternativa es "¡Mamá y papá con un bebé chiquitito!".

---

## Observaciones del guionista

1. **La "primera apertura" y el secuestro, en el orden equivocado (importante).** La ficha entrega
   la foto "antes del secuestro" la primera vez que se abre el juego. Pero en ese momento el niño
   todavía no vio la intro. Si Cometa explica que "a papá se le cayeron las fotos al ser llevado",
   cuenta el secuestro antes de mostrarlo y le quita el efecto a la escena. **Propuesta**: entregar
   `familia_01` al terminar la intro (tras la video-llamada de papá, Beat 7, antes de `intro_037`).
   El álbum igual nunca está vacío, porque la intro es lo primero que se juega. Si el PO quiere
   que exista desde el segundo uno, la foto puede estar sin la explicación y dejar
   `recuerdos_primera_01/02` para el final de la intro. Decisión para el PO y
   `director-cinematicas`.
2. **Coherencia del lugar**: el secuestro ocurre en el living (GDD §1, intro Beat 2). Unas fotos
   "caídas al ser llevado" caerían en la alfombra, no en la galaxia. El guion lo resuelve así: la
   primera cae en la alfombra y las demás se van flotando detrás de la nave del Coleccionauta (§0).
   Conviene que la intro (HE-30) muestre ese detalle en un plano: en el destello, unas fotitos
   salen volando con brillitos. Así la miga no aparece de la nada.
3. **"Se le cayeron" pide una causa amable**. Con solo "se le cayeron cuando se lo llevaron", un
   niño de 5 puede imaginar un forcejeo. Propongo la causa cómica: el rayo hace cosquillas, papá
   se ríe, *pffft*. Refuerza que papá está tranquilo y que el Coleccionauta es torpe, no
   peligroso. Si el PO la aprueba, conviene reflejarla en la ficha §1 y en el GDD §3.
4. **"Migas" y Hansel y Gretel**: el nombre de la épica es bonito para los adultos, pero en boca de
   un personaje "migas para encontrar el camino" evoca niños perdidos. Por eso ninguna línea de
   Cometa usa "migas" ni "camino hacia papá": dice "fotos" y "estrellas-recuerdo". El nombre
   "Las migas de papá" puede quedar como título interno.
5. **Choque de nombres: "recuerdo de zona" vs. "recuerdos"**. La ficha de zonas de Arcoíris (§2.2)
   ya llama "recuerdos de zona" a los objetos que regala Coco para el hangar (pincel rojo, gota
   dorada...). Además, en las zonas 2 y 4 ambas cosas llegan **en el mismo momento**. Hablado,
   "¡un recuerdo!" confunde a Nicole y a Maxi, y en código se mezclan `recuerdos` y `recuerdo_zona`.
   **Propuesta**: en voz, las fotos son "fotos" o "estrellas-recuerdo" y los objetos del hangar,
   "regalos de Coco" (o del anfitrión). Además hay que fijar el orden cuando coinciden: primero el
   regalo del anfitrión y después, con una pausa, el sobre-estrella. Así se evitan dos
   celebraciones encimadas. Lo decide `disenador-mecanicas`.
6. **La burbuja que "cruza la pantalla"**: si cruza una sola vez y se va, un niño de 2 años la
   pierde casi siempre. La ficha solo la repone en el viaje siguiente, y eso es mucho esperar para
   Maxi. **Propuesta**: que en el mismo viaje vuelva a pasar, más lenta, hasta que la atrapen. Para
   eso está `recuerdos_burbuja_vuelve_01` ("ya vuelve a pasar"), y esa promesa tiene que cumplirse
   en el momento. Lo deciden `disenador-mecanicas` y `experto-ux-parvulo`.
7. **Marco dorado y celos**: está bien que sea solo de Sofía (es su reto real), pero Nicole va a ver
   el álbum de Sofía. Cometa no debe comentar el marco al mirar el álbum, solo en el momento de
   ganarlo (`recuerdos_dorado_01`). Sugiero que en la vista del álbum el dorado no se note mucho
   más que el resto, un borde bonito y no un brillo pulsante. Lo decide `disenador-personajes`.
8. **Papá no debe extrañar sus fotos con pena**. Si las video-llamadas de los planetas (HE-39 y
   escenas por planeta) reaccionan a las fotos, papá debe hacerlo con chiste ("¿encontraron la
   de mi corte de pelo del 2019? Esa escóndanla"), nunca con "las extraño tanto". Lo mismo en el
   final (`final_rec_01`: "creía que se me habían volado", dicho feliz).
9. **Fotos sensibles (para el PO, con cariño)**: si alguna foto familiar incluye a alguien que ya no
   está (abuelos, mascotas), puede abrir preguntas difíciles en medio del juego. No es un
   problema, pero conviene elegirlas a propósito y que un adulto esté cerca la primera vez que
   aparezcan.
10. **Coherencia con el Coleccionauta**: la épica calza bien. Él guarda en cajas y Cometa colecciona
    amigos (GDD §2). Solo hay que cuidar que el Coleccionauta **nunca** trate de quedarse con las
    fotos durante la aventura (sería un rival que las roba y metería tensión). Las fotos se las
    lleva el viento, no él. Su único momento con ellas es el final, y ahí aprende.
11. **Pista del rescate final**: el hueco de la última foto está a la vista desde el comienzo. Su
    pista ("la guardamos para el final, cuando estemos todos juntos") **no** nombra a papá ni al
    rescate, para que no funcione como recordatorio de que "papá espera".
