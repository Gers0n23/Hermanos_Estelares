# Guía de corte de piezas para personajes articulados

Cómo convertir **una imagen de referencia aprobada** en las **10 piezas PNG** que `dev-godot`
necesita para armar el rig de cutout.

Esta guía se sigue a mano, con Krita abierto. Está escrita sobre Sofía, pero el método es
idéntico para Nicole y Maxi: cambian las coordenadas, no los pasos.

> **Por qué a mano y no generando las piezas con IA**: un modelo de imagen dibuja cada pieza
> por separado y no garantiza que el brazo calce con el hueco del hombro. Al ensamblar quedan
> costuras. Cortando **una sola imagen coherente** las piezas encajan por construcción, porque
> salen de los mismos píxeles. Ver `docs/stack-tecnico.md` §4.

---

## 1. Antes de empezar

**Herramienta**: Krita 5.3.3 (gratis, GPL). Ya está puesta —  es la versión **portable**, así que
no requiere instalador ni permisos de admin:

- Acceso directo en el Escritorio: **Krita**
- Ruta real: `C:\Users\gcordero\Apps\krita-x64-5.3.3\bin\krita.exe`

Para desinstalarla, borra esa carpeta. No toca el registro ni deja nada más en el sistema.

> **Plan B sin instalar nada**: [photopea.com](https://www.photopea.com) en el navegador.
> Gratis, sin cuenta, mismos conceptos (capas, lazo, cuentagotas). Los nombres de menú cambian,
> el método no.

**Archivos** (en `assets/generadas/sofia_piezas/`):

| Archivo | Qué es |
|---|---|
| `00_base_sofia.png` | Sofía recortada de su hoja de referencia, fondo ya transparente. **332 × 768 px.** Este es el que abres. |
| `00_mapa_cortes.png` | El mapa con las líneas de corte. **Ábrelo aparte y tenlo al lado mientras trabajas.** |

No cambies el tamaño del lienzo en ningún momento. Todo el método depende de que las 10 piezas
salgan de 332 × 768.

> La imagen es chica (332 px de ancho) y está bien así: en un juego de 1280 × 720 Sofía va a
> medir unos 400 px de alto. Ampliarla no agrega detalle, solo la vuelve borrosa.

---

## 2. Las cuatro reglas

Si entiendes estas cuatro, el resto es mecánica.

**1. Corta por donde el traje ya tiene una costura.**
El diseño de Sofía te regaló las líneas: hombrera, codera, cinturón, ruedo de la túnica,
rodillera, caña de la bota. Si cortas ahí, el corte se vuelve invisible aunque la pieza gire.
El mapa está calibrado sobre esas costuras.

**2. Redondea toda articulación.**
Un codo cortado en línea recta muestra la esquina al girar. Un codo redondo, nunca. En el mapa,
los círculos azules punteados marcan dónde la pieza tiene que terminar en curva. Regla oficial
de Spine: *"deja una zona lo más parecida a un círculo posible donde las articulaciones se
solapan"*.

**3. Dos piezas vecinas NO se cortan en la misma línea.**
Esta es la que casi todos se saltan y es la que causa los huecos. La pieza que va **encima**
se corta en la costura visible. La pieza que va **debajo** se extiende ~20 px más hacia adentro,
metiéndose bajo la otra. Ese solape es lo único que impide que aparezca un hueco al rotar.

Ejemplo con la cadera: el torso termina en el ruedo de la túnica (línea **D**), pero el muslo
**empieza más arriba**, en la línea **E**, escondido bajo la túnica.

**4. Solo hay que pintar el margen escondido, no la anatomía completa.**
Aquí es donde se ahorra el 80 % del trabajo. No necesitas reconstruir el brazo entero que estaba
bajo el pelo. Solo necesitas tanto material oculto como se vaya a mover la pieza que estaba
encima. **Para este juego, 20 px alcanzan.** Las animaciones son sutiles: respirar, saludar,
saltar de alegría. Nada gira 90°.

---

## 3. Preparar el archivo (una sola vez)

1. Abre Krita → `Archivo > Abrir` → `assets/generadas/sofia_piezas/00_base_sofia.png`.
2. En el panel **Capas** (abajo a la derecha), la única capa se llama algo como `Capa 1`.
   Renómbrala a `base` (doble clic sobre el nombre).
3. **Duplica esa capa 10 veces**: clic derecho sobre `base` → `Duplicar capa`, diez veces.
4. Renombra las 10 copias con los nombres exactos de la tabla de la sección 7
   (`cabeza_casco`, `torso`, `brazo_sup_izq`, …). El orden en el panel no importa todavía.
5. Deja `base` abajo del todo y **ocúltala** (clic en el ojo). Te sirve de referencia para
   comparar y para volver a empezar una pieza si la arruinas.
6. `Archivo > Guardar como` → `sofia_piezas.kra` en la misma carpeta. Guarda seguido.

> **izq / der** en esta guía = **izquierda y derecha de la pantalla, tal como miras la imagen**.
> No la izquierda de Sofía. Es la convención menos confusa al cortar y es la que usan los
> nombres de archivo.

---

## 4. El bucle: cortar una pieza

Repite esto 10 veces, una por capa. Con la primera vas a tardar; para la quinta te va a salir
en dos minutos.

1. **Selecciona solo la capa que vas a trabajar** en el panel Capas, y oculta todas las demás
   (así ves solo lo que estás cortando).
2. Toma la herramienta **Selección a mano alzada** (el lazo) o **Selección poligonal**.
3. **Dibuja el contorno de la pieza** siguiendo el mapa. Por fuera del cuerpo puedes ir holgado
   —ahí no hay nada, es transparente—; lo que importa es la línea de corte contra las piezas
   vecinas.
4. `Selección > Invertir selección` (`Ctrl+Shift+I`).
5. Pulsa `Supr`. Ahora esa capa tiene solo su pieza.
6. `Selección > Deseleccionar` (`Ctrl+Shift+A`).

Detalles por pieza que te van a ahorrar rehacer trabajo:

- **`cabeza_casco`** — incluye el casco, la cara **y todo el pelo**, incluidos los rizos que
  caen sobre los hombros hasta la altura del cinturón. El único corte recto es el cuello
  (línea **A**). Todo lo demás lo hace el contorno del pelo, que ya es el borde de la silueta.
  Es la pieza más grande y la más fácil.
- **`torso`** — del cuello (**A**) al ruedo de la túnica (**D**), entre las dos costuras de los
  brazos (**B** y **C**). Incluye el cuello del traje, la estrella, el cinturón y la túnica.
- **`brazo_sup_*`** — del hombro al codo. Arriba termina **redondo** dentro del hombro;
  abajo termina **redondo** pasando la codera.
- **`antebrazo_mano_*`** — del codo a la mano completa, dedos incluidos (no se separan dedos).
  Arriba corta **más alto que donde terminó el brazo superior**, para que se solapen.
- **`pierna_sup_*`** — sube hasta la línea **E**/**F**, bien metida bajo la túnica. Abajo
  termina redonda pasando la rodillera.
- **`pierna_inf_pie_*`** — de la rodilla a la planta del pie, bota incluida. Arriba corta
  **más alto que donde terminó el muslo**.

---

## 5. Reparar los márgenes escondidos

Este paso es el que decide si el rig se ve bien o se ve roto. Es rápido pero no se puede saltar.

Herramientas: un **pincel duro y redondo** (los `Basic` de Krita sirven), y el **cuentagotas**
— en Krita se activa manteniendo `Ctrl` mientras pintas, sin cambiar de herramienta.

Para cada pieza, mira su borde de corte y pregúntate: *¿qué había aquí, tapado por la pieza de
al lado?* Toma el color de al lado con `Ctrl` y **extiéndelo ~20 px hacia adentro, rematando en
curva**.

Lo concreto en Sofía:

| Pieza | Qué pintar |
|---|---|
| `torso` | Los dos hombros: donde estaban los brazos hay un mordisco. Extiende el rosado del traje hacia afuera y **remátalo en semicírculo**. También la zona bajo el pelo, en los hombros. |
| `torso` | Bajo el cuello: sube un poco el rosado del cuello del traje, para que al inclinar la cabeza no aparezca un hueco. |
| `brazo_sup_*` | El tope del hombro, que estaba bajo el pelo y bajo el torso: complétalo en círculo. |
| `antebrazo_mano_*` | El tope del codo: complétalo en círculo, con el color de la codera. |
| `pierna_sup_*` | La parte de arriba del muslo, que estaba bajo la túnica: extiéndela hacia arriba y ciérrala. Nadie la va a ver, puede ser un óvalo plano del color del traje. |
| `pierna_inf_pie_*` | El tope de la pantorrilla, bajo la rodillera: círculo del color del traje. |

Dos avisos:

- **No pintes con blanco ni dejes bordes semitransparentes sucios.** Si dudas del color, tómalo
  con `Ctrl` de un píxel vecino.
- **El contorno oscuro del dibujo**: donde extiendas material, continúa también la línea de
  contorno por arriba y por abajo de la zona que cruza. Si no, al girar la pieza el contorno
  se corta a la mitad y se nota.

---

## 6. Exportar las 10 piezas

El truco que hace que todo encaje solo: **las 10 salen del tamaño completo del lienzo**
(332 × 768), no recortadas a su contenido. Así, en Godot van todas en la posición (0, 0) y el
personaje se rearma pixel-perfect, sin acomodar nada a mano.

Para cada pieza:

1. En el panel Capas, deja **visible solo esa capa** (ojo encendido en ella, apagado en todas
   las demás, incluida `base`).
2. `Archivo > Exportar…`
3. Guarda en `assets/generadas/sofia_piezas/` con el nombre exacto de la pieza
   (`torso.png`, `brazo_sup_izq.png`, …).
4. En el diálogo de PNG: **marca "Guardar canal alfa (transparencia)"**. No marques nada que
   rellene el fondo. Acepta.

Krita exporta la imagen visible aplanada al tamaño del documento — por eso funciona.

> **Atajo opcional**: si las 10 exportaciones a mano te cansan, existe el
> [Krita Batch Exporter de GDQuest](https://www.gdquest.com/library/plugin_krita_batch_exporter/),
> que exporta todas las capas de una. Hay que agregar `e=png t=no` al nombre de cada capa
> (el `t=no` es el que conserva el tamaño de lienzo). No es necesario para 10 piezas.

---

## 7. Tabla de piezas

Coordenadas en píxeles del lienzo de 332 × 768. El **pivote** es el punto exacto sobre el que
gira la pieza; lo usa `dev-godot` al armar el rig.

> **Corregida 05-Ago-2026** tras el primer armado real del rig de Sofía: el orden de dibujo de
> abajo (`z_index`, de más al fondo a más al frente) no era el que muestra esta tabla en su
> versión original. El PO señaló el error comparando contra el orden real de capas de
> `assets/generadas/sofia_piezas/00_base_sofia.krz` y `dev-godot` lo verificó armando y
> animando el rig (sin costuras en ningún caso). Cambios: `cabeza_casco` pasa de ir delante de
> todo a ir **al fondo de todo** (el pelo queda detrás del cuerpo); `torso` pasa de ir delante
> de las piernas a ir **detrás** de ellas; se agrega `cinturon` como pieza propia del rig, al
> **frente de todo**; y `brazo_sup_*` pasa a ir delante de `antebrazo_mano_*` (antes era al
> revés) — esto último en realidad coincide con la regla 3 de la sección 2: el antebrazo es la
> pieza que se cortó con el margen extendido, es decir la que va "debajo".

| # | Pieza | Pivote (x, y) | z_index | Va delante de |
|---|---|---|---|---|
| — | `cinturon` | sin pivote propio — ancla al pivote de cadera del torso (166, 470), hijo de `torso` | 11 | todo |
| 9 | `pierna_inf_pie_izq` | 118, 550 (rodilla) | 10 | muslo izq |
| 7 | `pierna_sup_izq` | 118, 462 (cadera) | 9 | — |
| 10 | `pierna_inf_pie_der` | 202, 550 (rodilla) | 8 | muslo der |
| 8 | `pierna_sup_der` | 202, 462 (cadera) | 7 | — |
| 2 | `torso` | 166, 470 (cadera) | 6 | — (detrás de las 4 piezas de pierna) |
| 4 | `brazo_sup_der` | 226, 298 (hombro) | 5 | antebrazo der |
| 3 | `brazo_sup_izq` | 102, 298 (hombro) | 4 | antebrazo izq |
| 6 | `antebrazo_mano_der` | 254, 392 (codo) | 3 | — |
| 5 | `antebrazo_mano_izq` | 68, 392 (codo) | 2 | — |
| 1 | `cabeza_casco` | 166, 262 (cuello) | 1 | — (al fondo de todo; el pelo queda detrás del cuerpo) |

Jerarquía de nodos en Godot (ver `docs/stack-tecnico.md`, sección Animaciones):

```text
cadera (raiz, invisible)
├── torso
│   ├── cabeza_casco
│   ├── cinturon (sin pivote propio, rota solidario con el torso)
│   ├── brazo_sup_izq → antebrazo_mano_izq
│   └── brazo_sup_der → antebrazo_mano_der
├── pierna_sup_izq → pierna_inf_pie_izq
└── pierna_sup_der → pierna_inf_pie_der
```

---

## 8. Verificar antes de entregar

Dos chequeos rápidos en Krita, antes de dar la pieza por buena:

1. **Ensamble**: enciende las 10 capas a la vez y apaga `base`. Tiene que verse **exactamente**
   igual que la imagen original, sin líneas ni huecos entre piezas. Si ves una raya, a esa
   pieza le falta solape (regla 3).
2. **Prueba de giro**: toma una capa de brazo, `Ctrl+T` (transformar), rótala unos 20°, mira si
   aparece un hueco en el hombro, y **deshaz con `Ctrl+Z`**. Si apareció hueco, falta pintar
   margen (regla 4) o falta redondear (regla 2). Haz lo mismo con un muslo y con la cabeza.

Cuando las dos pruebas pasen, las 10 piezas están listas para `dev-godot`.

---

## 9. Qué sigue

Las piezas quedan en `assets/generadas/sofia_piezas/` (carpeta de staging, con `.gdignore`).
Se promueven a `assets/sprites/personajes/` recién después de la auditoría de
`experto-ux-parvulo` y la aprobación del PO, igual que el resto del arte generado.

`dev-godot` toma desde ahí: 10 `Sprite2D` con `centered = false`, todos en posición (0, 0)
— el personaje se arma solo —, y después a cada uno se le pone `offset = -pivote` y
`position = pivote` para que gire por la articulación correcta.

---

## Notas para otros personajes

Al hacer Nicole y Maxi, lo único que cambia son las coordenadas. Regenera su mapa con:

```bash
python herramientas/mapa_cortes.py <png_sin_fondo> <salida_mapa.png>
```

Las coordenadas viven en los diccionarios `LINEAS`, `ARTICULACIONES` y `PIEZAS` al principio
de `herramientas/mapa_cortes.py`. Ajústalas y vuelve a ejecutar hasta que los círculos azules
caigan sobre las hombreras, coderas y rodilleras del personaje.

Maxi tiene 2 años y su diseño es más compacto: probablemente convenga fusionar antebrazo y
brazo en una sola pieza por lado (8 piezas en vez de 10). Menos piezas, menos reparación, y a
esa edad la animación es más de rebote que de articulación.
