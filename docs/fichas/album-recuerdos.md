# Ficha — Las migas de papá: álbum de recuerdos familiares

> **Decisión del PO (27-Sep-2026)**: la aventura suma una capa de **coleccionables con fotos
> reales de la familia** (los niños de bebés hasta hoy, con mamá y papá). Se encuentran jugando
> y quedan guardados en un **álbum** que se abre desde la pantalla principal cuando quieran.
> El PO eligió la historia "las migas de papá", **un álbum por hermano más uno familiar**,
> ~12-15 fotos por hermano y ~8-10 familiares, y cada foto con un **audio grabado por la
> familia** (los 3 niños, papá y mamá; el PO ya los está grabando).

- **Autor**: Dev a pedido del PO (propuesta de diseño) — **pendiente de validación** por
  `guionista` (líneas de Cometa y de papá), `disenador-mecanicas` (game feel de la entrega),
  `experto-ux-parvulo` (álbum y entrega para 2-8 años) y `disenador-personajes` (marco,
  sobre y placeholders).
- **Estado**: diseño propuesto, 27-Sep-2026.
- **Reglas**: GDD §6 (UX infantil) manda sobre todo lo de esta ficha.

---

## 1. Idea en una frase

Cuando el Coleccionauta se llevó a papá, a papá **se le cayeron las fotos de la billetera**, y
quedaron flotando por la galaxia como **estrellas-recuerdo**. Cada foto que los hermanos
encuentran es una miga del camino hacia papá. Al final, papá ve el álbum completo y el
Coleccionauta entiende que los recuerdos no se guardan en cajas: **se comparten**.

## 2. Por qué funciona

- **Calza con el guion**: Cometa colecciona amigos (álbum de abrazos) y el Coleccionauta
  colecciona cosas en cajas (GDD §2). Juntar recuerdos prepara la lección final sin explicarla.
- **Crecer como progresión**: los recuerdos se entregan **en orden de edad**. Avanzar en la
  aventura es verse crecer, de bebé a hoy.
- **Voz de casa**: cada foto suena con la voz real de la familia. Así se cierra en parte la
  pregunta abierta P2 del GDD.

## 3. Estructura: cuatro álbumes

| Álbum | Qué contiene | Quién lo llena | Cantidad |
|---|---|---|---|
| Álbum de Maxi | Fotos de Maxi, de recién nacido a hoy | Solo la ruta de Maxi | 12-15 |
| Álbum de Nicole | Fotos de Nicole, de recién nacida a hoy | Solo la ruta de Nicole | 12-15 |
| Álbum de Sofía | Fotos de Sofía, de recién nacida a hoy | Solo la ruta de Sofía | 12-15 |
| Álbum familiar | Mamá, papá y los tres (y fotos de a dos o tres hermanos) | **Cualquier** hermano; una vez encontrado, es de todos | 8-10 |

- Cada hermano ve **su álbum y el familiar** con el mismo protagonismo. También puede mirar los
  álbumes de sus hermanos (solo mirar): la idea es que los vean juntos.
- Un recuerdo familiar lo desbloquea **el primer hermano** que llega al momento, y queda para los
  tres. El mensaje: "¡Sofía encontró una foto de toda la familia!".

## 4. Momentos de entrega

Regla de oro: **cada recuerdo tiene un momento fijo y siempre se entrega**. No hay azar ni sobres
sorpresa, nada se pierde y nada exige un desempeño que un niño de 2 años no alcance.

| Momento | Qué entrega | Por qué ahí |
|---|---|---|
| **Viaje estelar entre planetas** (modo Galaga) | 1 recuerdo **personal**: una burbuja-recuerdo cruza la pantalla y se atrapa tocándola o chocándola con la nave | Es el momento más emocionante y es la "miga" literal en el camino |
| **Completar una zona del mapa del planeta** (sus 4 estaciones, con cualquier resultado) | 1 recuerdo **personal** (en zonas alternas, ver §5) | Premia constancia, no desempeño: vale igual para Maxi, Nicole y Sofía |
| **Pieza de la nave** (escena de historia de cada planeta) | 1 recuerdo **familiar** | Momento grande, con video-llamada de papá |
| **Primera vez que se abre el juego** | 1 recuerdo **familiar** (la foto "antes del secuestro") | El álbum empieza con algo desde el minuto uno: nunca está vacío |
| **Rescate final** | 1 recuerdo **familiar** (la última: los cinco juntos, o los tres jugando este juego) | Cierra el álbum y la historia |
| **Estrellitas máximas de Sofía** | **No da contenido extra**: le pone a la foto de esa zona un **marco dorado** | El reto real de Sofía brilla sin quitarles fotos a Maxi ni a Nicole |

- Los minijuegos sueltos **no dan fotos**, para que cada foto se sienta especial. Su premio
  coleccionable son las estampitas (§9, idea 7).
- **Si el momento no se completa** (por ejemplo, sale del viaje antes de atrapar la burbuja), la
  burbuja **vuelve a pasar** en el siguiente viaje. Nunca se pierde.
- Los mapas de zonas por capítulo (GDD §3) marcan el ritmo: el **capítulo 1** (Arcoíris) entrega
  las primeras fotos de bebé, y cada capítulo siguiente avanza en la línea de tiempo.

## 5. Reparto propuesto (placeholder, se ajusta al cerrar cada capítulo)

Por hermano, 14 recuerdos personales:

- **6 planetas × 2** = 12, al completar las zonas 2 y 4 de cada planeta (Arcoíris: charcos e islotes).
- **2 viajes estelares especiales**: el primer despegue (capítulo 1) y el viaje al planeta final.

Familiares, 9:

- 1 primera apertura + 6 piezas de la nave + 1 rescate final + 1 en el viaje al planeta final.

> Si un planeta todavía no tiene zonas (capítulos futuros), sus recuerdos quedan en el catálogo
> sin momento asignado y no aparecen como huecos hasta que el capítulo exista.

## 6. La entrega: game feel

1. Todo se detiene suavemente, sin cortar la celebración anterior. Cometa dice:
   *"¡Mira! ¡Otra foto de la billetera de papá!"*.
2. Un **sobre-estrella** baja girando y llega al centro de la pantalla, grande (más de 200 px).
3. **Un toque en cualquier parte** lo abre. Si pasan 3 s sin toque, se abre solo (Maxi).
4. La foto sale con un marco tipo **polaroid estelar**, crece hasta ocupar ~70% de la pantalla,
   suena el **audio de la familia** y cae confeti suave.
5. La foto vuela hacia un **ícono de álbum** que rebota: así el niño aprende dónde queda.
6. Sin botón de "continuar": al terminar el audio (o con un toque), se vuelve al flujo normal.

## 7. El álbum en la pantalla principal

- **Entrada**: un botón grande con forma de **libro-álbum con estrellas** en la pantalla de título
  o de selección de personaje. Tiene un brillo pulsante cuando hay una foto nueva sin ver.
- **Portada**: 4 tapas grandes (Maxi, Nicole, Sofía y Familia), cada una con la cara del
  personaje. Las toca cualquiera, sin selección de perfil previa.
- **Páginas**: una cuadrícula de 2×3 fotos por página, con miniaturas grandes (más de 180 px), en
  orden de edad. Se pasa de página deslizando o con flechas grandes.
- **Huecos**: silueta de marco con una estrella y un signo de interrogación. Al tocarlo, Cometa
  da una pista hablada: *"Esta foto está escondida en el Planeta Arcoíris"*.
- **Foto abierta**: pantalla completa, se repite el audio y hay un botón grande para cerrar.
  Opcional: un pie de foto con la edad ("Maxi, 3 meses"), dibujado y narrado, nunca obligatorio
  de leer.
- **Sin texto obligatorio**: todo se navega por íconos y voz (GDD §6).

## 8. Datos y archivos (para `dev-godot`)

### Catálogo

`datos/recuerdos/catalogo.json` es data-driven. El núcleo nunca conoce minijuegos concretos
(regla de oro 3): los momentos se identifican con eventos genéricos.

```json
{
  "recuerdos": [
    {
      "id": "maxi_01",
      "album": "maxi",
      "orden": 1,
      "edad": "recién nacido",
      "momento": {"tipo": "viaje", "id": "primer_despegue"},
      "foto": "res://assets/recuerdos/fotos/maxi_01.jpg",
      "voz": "res://assets/recuerdos/voces/maxi_01.ogg"
    },
    {
      "id": "familia_01",
      "album": "familia",
      "orden": 1,
      "momento": {"tipo": "primera_apertura"}
    }
  ]
}
```

- `momento.tipo` puede ser `primera_apertura`, `viaje`, `zona_completa` (con `planeta` y `zona`),
  `pieza_nave` (con `planeta`) o `rescate_final`.
- Si falta `foto` o `voz`, se usa la convención `<id>.jpg` / `<id>.ogg`.
- **Placeholders**: si el archivo no existe en disco, se muestra el placeholder versionado
  `assets/recuerdos/placeholders/<album>.svg` (marco de polaroid con la silueta del personaje y el
  número del recuerdo) y se usa una línea de Cometa genérica en vez del audio. Así el juego
  funciona completo sin las fotos reales, y el PO solo copia los archivos con el nombre del id.

### Progreso

`Progreso` suma `recuerdos_encontrados: {id: {fecha, visto, dorado}}` a **nivel global**, no por
perfil. El álbum familiar es compartido, y los personales se indexan por el campo `album`. Para
esto hace falta una migración de versión del guardado.

### Privacidad (decisión del PO)

- `assets/recuerdos/fotos/` y `assets/recuerdos/voces/` están en `.gitignore`: **las fotos y las
  voces de la familia nunca se suben a GitHub**. Solo viajan dentro del APK.
- Sí se versionan el catálogo, los placeholders y el código.
- Pipeline de fotos: redimensionar a un máximo de 1280 px en el lado largo y usar JPG de calidad
  ~85, para cuidar el tamaño del APK. Un script en `herramientas/` lo automatiza.

## 9. Otras ideas de personalización aprobadas (PO 27-Sep-2026, todas al backlog)

1. **Cumpleaños y fechas especiales**: el día del cumpleaños de cada hermano, Cometa lo saluda por
   su nombre, canta y hay confeti. También hay saludos para el 18 de septiembre (con la bandera de
   Chile, conectado al contenido educativo), Navidad y el Día del Padre y de la Madre.
2. **"Mis obras" en el álbum**: los dibujos que hacen en el lienzo libre se guardan solos en una
   sección del álbum personal (en `user://`, nunca se suben).
3. **Dibujos reales en el juego**: se escanea un dibujo de papel de cada hermano y se convierte en
   un planeta, una criatura o una estampita dentro de la aventura.
4. **Video-llamadas con papá real**: un clip o audio real de papá en cada entrega de pieza, en vez
   de la voz sintética. Mamá aparece en el final dándoles la bienvenida a casa.
5. **La casa real**: el living del inicio se inspira en su living de verdad, con cameos de
   mascotas, peluches o juguetes favoritos (cruzar con las fichas de la Fase 0).
6. **Cápsula del tiempo**: al terminar el juego, se desbloquea un mensaje de mamá y papá para cada
   hermano, pensado para cuando lo vuelvan a ver de más grandes.
7. **Estampitas cartoon**: una segunda capa de coleccionables del universo del juego (anfitriones,
   planetas, Coco) para premiar los minijuegos sueltos y decorar la nave.
8. **Frases de la familia**: las frases típicas de la casa, dichas por Cometa en las
   celebraciones.

## 10. Lo que el PO prepara

- Las fotos, con nombre `<id>.jpg`, según la lista de huecos del catálogo. Una guía sugerida por
  álbum va de recién nacido, primer baño, primera sonrisa, primeros pasos y primer cumpleaños,
  hasta el jardín o el colegio y hoy.
- Los audios, con nombre `<id>.ogg` (o WAV, que el pipeline convierte), de 3-10 s cada uno.
- Opcional: la edad o el momento de cada foto, para el pie de foto narrado.
