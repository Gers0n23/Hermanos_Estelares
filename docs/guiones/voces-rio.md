# Guion de voz — Río de pintura en solitario (motor `rio` v2)

> Encargo de **HE-94** (05-Nov-2026): nombres para los niños de los **6 colores de 2 + 1** y del **café**, y sus
> voces. Fuentes: `docs/fichas/motor-rio.md` v2 (§5.3, §10.3-§10.7, §14.1, §16 y §18),
> `docs/roadmap-rio-de-pintura.md` §11 ("Voz") y el canon de colores de `zonas_arcoiris.md` (decisión de
> tono 5: "un solo nombre por color").
>
> **Decisión del PO (05-Nov-2026): se dice "naranja"**, no "naranjo". Cierra la pregunta abierta §18.2 de la
> ficha del Río.
>
> Este guion es **solo texto**. Las filas TTS ya están copiadas en
> `assets/audio/voces/arcoiris/rio/lineas_tts.tsv` (bajo `# personaje: coco`). El audio se genera después con
> el TTS local gratuito que elija el PO. Este guion no genera audio ni toca código.
>
> Las voces del Río **de la batalla** están en `voces-batalla-arcoiris.md` §4. No se duplican aquí.

- **Voz**: todas las líneas son de **Coco**, que es quien dispara en el Río (camaleona suave y cantarina,
  chilena suave de animadora infantil).
- **Rutas**: relativas a `assets/audio/`, en `.wav`, bajo `voces/arcoiris/rio/`.
- **Id estable**: `arcoiris_` + la ruta sin `voces/arcoiris/` ni extensión. Ejemplo:
  `voces/arcoiris/rio/colores/tomate.wav` → `arcoiris_rio_colores_tomate`.
- **Regla del Río (roadmap §11)**: **nunca hay voz entre disparos.** Cada línea de este guion suena **una sola
  vez por perfil** (se guarda en `Progreso`), antes de que el río empiece a moverse o encima de un momento que
  ya detiene el juego (el arco de las 2 gotas servidas o el eructo del café). La única excepción es tocar una
  receta, que pide el niño.
- **Estado**: las **14 líneas** de este guion son **nuevas** y están **pendientes de audio**. Además se
  **reutilizan 9** líneas ya escritas del Taller de Coco (§3), sin cambiar su texto ni su archivo.

---

## 1. Los nombres (HE-94)

### 1.1 Decisión: los mismos nombres del Taller de Coco

Los 6 colores de 2 + 1 del Río son **las mismas 6 recetas** que Sofía ya prepara en el Taller de pinturas de
Coco (`mezclar/lineas_tts.tsv`, `recetas/`), y ahí **ya tienen nombre y voz**. Se usan esos mismos nombres:

| id provisional (código) | Receta | Hex | **Nombre para los niños** | Cómo lo dice Coco | id final propuesto |
|---|---|---|---|---|---|
| `rojo_naranja` | rojo + rojo + amarillo | `#F2582B` | **rojo tomate** | «¡Rojo tomate!» | `tomate` |
| `amarillo_naranja` | amarillo + amarillo + rojo | `#FFAA2E` | **mango** | «¡Color mango!» | `mango` |
| `amarillo_verde` | amarillo + amarillo + azul | `#AFD13A` | **verde limón** | «¡Verde limón!» | `verde_limon` |
| `azul_verde` | azul + azul + amarillo | `#1FA39A` | **verde azulado** | «¡Verde azulado!» | `verde_azulado` |
| `azul_violeta` | azul + azul + rojo | `#5A5FD8` | **añil** | «¡Añil!» | `anil` |
| `rojo_violeta` | rojo + rojo + azul | `#C93E8E` | **fucsia** | «¡Fucsia!» | `fucsia` |
| `cafe` (ya es final) | rojo + amarillo + azul | `#8B5A3C` | **café** | «¡Café!» | `cafe` |

Los secundarios siguen igual: **verde**, **naranja** y **violeta** (nunca "naranjo" ni "morado").

**Por qué así**:

1. **Un solo nombre por color en todo el planeta** (`zonas_arcoiris.md`, decisión 5). Si en el Taller la
   gota de dos rojas y una amarilla se llama "rojo tomate" y en el Río se llamara de otra forma, Sofía
   aprendería dos nombres para lo mismo. Con el mismo nombre, lo que aprendió mezclando le sirve en el Río.
2. **Son palabras de la casa, no de catálogo**: tomate, mango y limón son cosas que los niños comen y
   reconocen. Ninguno está en inglés.
3. **Se dicen fácil**: ninguno pasa de cinco sílabas ni tiene grupos de consonantes difíciles. Nicole puede
   repetirlos aunque los 2 + 1 sean de Sofía.
4. **Se distinguen al oído**: cada nombre empieza con un sonido distinto (rrr-, mmm-, verde li-, verde a-,
   añ-, fu-). "Verde limón" y "verde azulado" comparten "verde" a propósito: los dos son verdes, y el
   apellido dice hacia dónde se inclinan (al amarillo o al azul).
5. **No chocan con el tic de Coco**: Coco dice "rojo **frutilla**", "amarillo **limón**", "azul
   **chupetín**" y "verde **menta**" cuando recupera un color. Ninguno de los 2 + 1 es igual a esos. "Verde
   limón" sí se parece a "amarillo limón", pero **los dos llevan limón por la misma razón** (el amarillo), y
   el color que va primero ("verde" o "amarillo") los separa.
6. **Café**: ya se llama así en Lluvia, en el Taller y en Pinta y Descubre. En Chile se dice café, no
   "marrón".

**Descartados**:

- **Nombres sistemáticos** ("rojo anaranjado", "amarillo anaranjado", "azul violáceo"...). Son exactos, pero
  largos (hasta 8 sílabas), suenan muy parecidos entre sí y "violáceo" no es una palabra de 5 años.
- **Nombres cortos nuevos** ("limón" a secas, "turquesa", "morado"). "Limón" a secas se confunde con el
  amarillo limón de Coco. "Turquesa" ya es otra receta del Taller (dos azules, una amarilla y una blanca).
  "Morado" es el nombre que se sacó del planeta para dejar solo "violeta".
- **"Rosa fuerte" o "frambuesa" en vez de fucsia**: "rosa" ya es una gota del Río (la de Maxi) y se
  confundiría con ella. "Fucsia" ya se usa en el Taller.

### 1.2 Para `dev-godot` (cuando le toque)

- Los ids provisionales (`rojo_naranja`, etc.) pueden quedarse en el código: **no se muestran ni se dicen**.
  Si se cambian a los "id final propuesto" (columna de la derecha), coinciden con los archivos de voz del
  Taller y del Río, y se puede armar la ruta de la voz con el id (`recetas/<id>.wav`, `colores/<id>.wav`). Es
  una propuesta; la decisión es de `dev-godot`.
- El comentario de `logica_rio.gd` que dice "pendiente de la decisión naranja/naranjo" ya se puede cerrar: la
  decisión es **"naranja"**, que es justo el id que ya usa `SECUNDARIOS`.
- Lo único que todavía dice "naranjo" son ids internos de datos de Parejas (`gatito_naranjo`,
  `cuadrado_naranjo`). No suenan ni se muestran, así que no hace falta cambiarlos. Su voz ya dice "naranja"
  (`emparejar/colores/naranja.wav`).

---

## 2. Líneas nuevas

### 2.1 El nombre del color, la primera vez que se sirve

Suena **la primera vez que la palanca sirve ese color** en ese perfil (una vez para siempre, se guarda en
`Progreso`), mientras las 2 gotas vuelan hacia Coco (0,38 s de arco, y durante ese tiempo no se puede
disparar, ficha §14.1). Después, ese color se sirve **sin voz**. Así el nombre llega pegado al color que el
niño acaba de fabricar, y no interrumpe nunca un disparo.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_rio_colores_verde | Coco | «¡Verde!» | sorpresa feliz, como quien muestra un regalo | 0,6 s | Primer verde servido (Nicole y Sofía) | `voces/arcoiris/rio/colores/verde.wav` | TTS |
| arcoiris_rio_colores_naranja | Coco | «¡Naranja!» | ídem | 0,7 s | Primer naranja servido (Sofía) | `voces/arcoiris/rio/colores/naranja.wav` | TTS |
| arcoiris_rio_colores_violeta | Coco | «¡Violeta!» | ídem | 0,7 s | Primer violeta servido (Sofía) | `voces/arcoiris/rio/colores/violeta.wav` | TTS |
| arcoiris_rio_colores_tomate | Coco | «¡Rojo tomate!» | golosa, saboreando la palabra "tomate" | 0,9 s | Primer rojo tomate servido (Sofía, desde la zona 3) | `voces/arcoiris/rio/colores/tomate.wav` | TTS |
| arcoiris_rio_colores_mango | Coco | «¡Color mango!» | ídem, alegre | 0,9 s | Primer mango servido | `voces/arcoiris/rio/colores/mango.wav` | TTS |
| arcoiris_rio_colores_verde_limon | Coco | «¡Verde limón!» | fresca, con chispa | 0,9 s | Primer verde limón servido | `voces/arcoiris/rio/colores/verde_limon.wav` | TTS |
| arcoiris_rio_colores_verde_azulado | Coco | «¡Verde azulado!» | tranquila, como agua de mar | 1 s | Primer verde azulado servido | `voces/arcoiris/rio/colores/verde_azulado.wav` | TTS |
| arcoiris_rio_colores_anil | Coco | «¡Añil!» | misteriosa y contenta, la "ñ" bien marcada | 0,6 s | Primer añil servido | `voces/arcoiris/rio/colores/anil.wav` | TTS |
| arcoiris_rio_colores_fucsia | Coco | «¡Fucsia!» | coqueta, con brillo | 0,7 s | Primer fucsia servido | `voces/arcoiris/rio/colores/fucsia.wav` | TTS |

Las nueve tienen la misma forma (solo el nombre, con exclamación), así ningún color "vale más" que otro.
El café no tiene línea de nombre: no se sirve, y se nombra en su gag (§2.3).

### 2.2 La batidora y los 2 + 1, la primera vez

Suenan **antes de que el río empiece a moverse** (en la pausa de entrada del río), **una vez por perfil**.
El río arranca cuando termina la voz o con el primer toque del niño (lo que pase antes), y la voz no se corta.
Cada línea dura 5 s o menos. Para Sofía no se repiten en cada río: más de una vez sería "dificultad de bebé" (ficha §10.8).

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_rio_batidora_presenta_brote | Coco | «¡Mira, Nicole, una batidora! Dispárale una amarilla y una azul... ¡y toca la palanca!» | maravillada, mostrando; pausa antes de "¡y toca la palanca!" | 4,5 s | Primer río con batidora de Nicole (perfil Brote). La flecha a la batidora ya está puesta (§10.8) | `voces/arcoiris/rio/batidora_presenta_brote.wav` | TTS |
| arcoiris_rio_batidora_presenta_estrella | Coco | «¡Una batidora en el puente! Dispárale dos colores, toca la palanca... ¡y te sirve la mezcla!» | entusiasta, de reto | 4,5 s | Primer río con batidora de Sofía (perfil Estrella) | `voces/arcoiris/rio/batidora_presenta_estrella.wav` | TTS |
| arcoiris_rio_dos_mas_uno_presenta | Coco | «¡Colores nuevos! Mira sus puntitos: dos de un color y uno de otro. ¡Tres gotas a la batidora!» | intrigada al principio, cómplice al final | 5 s | Primer río de Sofía con 2 + 1 (zona 3). Suena antes de que entren al río; si coincide con `batidora_presenta_estrella`, esa va primero y esta en el **río siguiente** | `voces/arcoiris/rio/dos_mas_uno_presenta.wav` | TTS |

- La de Nicole lleva **su receta** (amarilla + azul = verde), porque es lo único que ella mezcla (ficha §11)
  y así la regla queda dicha con colores, no con números. No dice "verde": el verde lo nombra la primera vez
  que sale (`colores/verde`), y ese es el premio.
- La de Sofía no da la receta: el reto es descubrirla con la caja de recetas.
- Ninguna dice "rápido", "cuidado" ni "difícil".

### 2.3 El café: un gag, no un error

El café es el **peligro** que eligió el PO para Sofía (ficha §10.5): no resta puntos ni corta el combo, y
tiene que dar risa. La batidora eructa 1,2 s y Coco se tapa la boca y se ríe. La voz suena **encima del
eructo**, cuando de todos modos no se puede disparar con provecho.

| id | personaje | texto | intención | duración | contexto | ruta | grabación |
|---|---|---|---|---|---|---|---|
| arcoiris_rio_cafe_primera | Coco | «¡Jajaja! ¡Rojo, amarillo y azul... café! ¡La batidora se tomó un cafecito!» | se ríe tapándose la boca; "cafecito" como chiste | 4 s | **El primer café** de Sofía (una vez por perfil) | `voces/arcoiris/rio/cafe_primera.wav` | TTS |
| arcoiris_rio_cafe_otra_vez | Coco | «¡Otro cafecito! Con dos iguales, sale un color nuevo.» | divertida y cómplice, como un secreto | 3 s | **Propuesta, a validar en el playtest** (riesgo R9): segundo café **seguido** en el mismo río, como máximo una vez por río. Si en el playtest molesta o no hace falta, se apaga en los datos | `voces/arcoiris/rio/cafe_otra_vez.wav` | TTS |

- "Se tomó un cafecito" es el juego de palabras suave para Sofía (café el color, cafecito la bebida), y el
  eructo es el chiste físico que ve Maxi si está mirando.
- `cafe_primera` dice la regla (los tres colores distintos dan café) sin decir que fue un error.
  `cafe_otra_vez` da un plan en positivo (cómo sí se hace un color), nunca un "no".

---

## 3. Líneas que se reutilizan (Taller de Coco)

**Propuesta para `disenador-mecanicas` y `dev-godot`**: si el niño **toca una fila de la caja de recetas**
(§10.7), Coco dice el nombre y la receta. Es la misma voz (Coco) y el mismo texto del Taller, así que no hace
falta grabar nada. Suena solo si no hay otra voz sonando y no frena el río. Si no se implementa el toque, la
caja sigue funcionando igual, sin voz.

| Fila de la caja | Archivo que se reutiliza | Texto |
|---|---|---|
| verde | `voces/arcoiris/mezclar/recetas/verde.wav` | «Verde: una gota amarilla y una gota azul.» |
| naranja | `voces/arcoiris/mezclar/recetas/naranja.wav` | «Naranja: una gota roja y una gota amarilla.» |
| violeta | `voces/arcoiris/mezclar/recetas/violeta.wav` | «Violeta: una gota roja y una gota azul.» |
| rojo tomate | `voces/arcoiris/mezclar/recetas/tomate.wav` | «Rojo tomate: dos gotas rojas y una amarilla.» |
| mango | `voces/arcoiris/mezclar/recetas/mango.wav` | «Color mango: dos gotas amarillas y una roja.» |
| verde limón | `voces/arcoiris/mezclar/recetas/verde_limon.wav` | «Verde limón: dos gotas amarillas y una azul.» |
| verde azulado | `voces/arcoiris/mezclar/recetas/verde_azulado.wav` | «Verde azulado: dos gotas azules y una amarilla.» |
| añil | `voces/arcoiris/mezclar/recetas/anil.wav` | «Añil: dos gotas azules y una roja.» |
| fucsia | `voces/arcoiris/mezclar/recetas/fucsia.wav` | «Fucsia: dos gotas rojas y una azul.» |

---

## 4. Guion de grabación (resumen)

Todo es TTS de Coco con el generador local gratuito (lista: `assets/audio/voces/arcoiris/rio/lineas_tts.tsv`).
No hay líneas caseras.

| id | texto | intención | dónde suena |
|---|---|---|---|
| arcoiris_rio_colores_verde | «¡Verde!» | sorpresa feliz | primer verde servido |
| arcoiris_rio_colores_naranja | «¡Naranja!» | sorpresa feliz | primer naranja servido |
| arcoiris_rio_colores_violeta | «¡Violeta!» | sorpresa feliz | primer violeta servido |
| arcoiris_rio_colores_tomate | «¡Rojo tomate!» | golosa | primer rojo tomate servido |
| arcoiris_rio_colores_mango | «¡Color mango!» | alegre | primer mango servido |
| arcoiris_rio_colores_verde_limon | «¡Verde limón!» | fresca | primer verde limón servido |
| arcoiris_rio_colores_verde_azulado | «¡Verde azulado!» | tranquila | primer verde azulado servido |
| arcoiris_rio_colores_anil | «¡Añil!» | misteriosa y contenta | primer añil servido |
| arcoiris_rio_colores_fucsia | «¡Fucsia!» | coqueta | primer fucsia servido |
| arcoiris_rio_batidora_presenta_brote | «¡Mira, Nicole, una batidora! Dispárale una amarilla y una azul... ¡y toca la palanca!» | maravillada | primer río con batidora (Nicole) |
| arcoiris_rio_batidora_presenta_estrella | «¡Una batidora en el puente! Dispárale dos colores, toca la palanca... ¡y te sirve la mezcla!» | entusiasta | primer río con batidora (Sofía) |
| arcoiris_rio_dos_mas_uno_presenta | «¡Colores nuevos! Mira sus puntitos: dos de un color y uno de otro. ¡Tres gotas a la batidora!» | intrigada y cómplice | primer río con 2 + 1 (Sofía, zona 3) |
| arcoiris_rio_cafe_primera | «¡Jajaja! ¡Rojo, amarillo y azul... café! ¡La batidora se tomó un cafecito!» | risa tapándose la boca | primer café (Sofía) |
| arcoiris_rio_cafe_otra_vez | «¡Otro cafecito! Con dos iguales, sale un color nuevo.» | cómplice | segundo café seguido en un río (propuesta) |

**Para el TTS**: "añil" se dice a-ÑIL (fuerza en la "i"). Conviene que suene igual que en
`mezclar/recetas/anil.wav`; si se regenera el Taller con la misma herramienta, quedan parejos.

---

## 5. Pendientes para otros roles

- **`dev-godot`**: claves de `lineas_voz` o una tabla en el motor para las voces de primera vez (§2.1-§2.3),
  con su marca "ya sonó" por perfil en `Progreso`; el toque de las filas de recetas (§3), si se aprueba.
  Los ids finales de la §1.2 son opcionales.
- **`disenador-mecanicas`**: aprobar o no el toque de las recetas (§3) y `cafe_otra_vez` (§2.3). Marcar
  §18.2 de la ficha como resuelta ("naranja", PO 05-Nov-2026) y poner los nombres de §1.1 en la tabla §5.3.
- **`experto-ux-parvulo`**: confirmar que las voces de primera vez no tapan un disparo (sobre todo
  `dos_mas_uno_presenta`, de 5 s) y escuchar si "verde limón" y "verde azulado" se distinguen bien con el TTS
  elegido.
