# Recuerdos de la familia — cómo agregar las fotos y voces reales

Guía para el PO (papá). El álbum "Las migas de papá" (`docs/fichas/album-recuerdos.md`) ya funciona
completo con **placeholders**: mientras una foto real no exista, el juego muestra un marco de
polaroid con el personaje del álbum y el número del recuerdo. En cuanto copies el archivo con el
nombre correcto, el juego usa la foto (o la voz) real **sin tocar código**.

## Privacidad

- `assets/recuerdos/fotos/` y `assets/recuerdos/voces/` están en `.gitignore`: **nunca se suben a
  GitHub**. Solo viajan dentro del APK que instalas en la tablet.
- Sí se versionan: este LEEME, el catálogo (`datos/recuerdos/catalogo.json`) y los placeholders
  (`assets/recuerdos/placeholders/`).

## Paso a paso

1. Junta las fotos en una carpeta cualquiera (fuera del repo si quieres) y **renómbralas con el id**
   de la tabla de abajo: `maxi_01.jpg`, `familia_01.png`... (sirve jpg, jpeg, png, webp; heic si
   instalas `pillow-heif`).
2. Prepáralas (1280 px en el lado largo, JPG calidad 85, giradas según la cámara):

   ```bash
   python herramientas/preparar_recuerdos.py fotos --origen "C:/ruta/a/mis fotos"
   ```

3. Graba los audios (3-10 s cada uno, la voz de quien corresponda: los niños, mamá o papá),
   nómbralos también con el id y conviértelos a OGG (acepta WAV/FLAC directo; m4a/mp3/aac/opus del
   celular usando el ffmpeg de `imageio-ffmpeg`, que ya está instalado):

   ```bash
   python herramientas/preparar_recuerdos.py voces --origen "C:/ruta/a/mis audios"
   ```

4. Revisa qué falta: `python herramientas/preparar_recuerdos.py estado`.
5. **Antes de exportar el APK, abre el proyecto en el editor de Godot una vez** (o ejecuta
   `godot --headless --path . --import`) para que importe las fotos y voces nuevas: el APK solo
   lleva archivos importados. En PC el juego las lee igual aunque no estén importadas.

También puedes copiar los archivos a mano directamente en `assets/recuerdos/fotos/<id>.jpg` y
`assets/recuerdos/voces/<id>.ogg` (o `.wav`). Formatos: foto jpg/jpeg/png/webp, máximo 1280 px en
el lado largo; voz ogg/wav/mp3, mono, 3-10 s.

## Qué pasa en el juego

- Cada recuerdo tiene un momento fijo y **siempre se entrega** (sin azar, nada se pierde).
- Hoy existen los momentos del capítulo 1: primera apertura (`familia_01`), primer viaje estelar
  (`<hermano>_01`) y zonas 2 y 4 de Arcoíris (`<hermano>_02` y `_03`). Los demás aparecen como
  huecos en el álbum recién cuando su pantalla exista (planetas nuevos, piezas de la nave, final).
- Un recuerdo familiar lo encuentra el primer hermano que llega y queda para los tres.
- Sofía con estrellitas máximas en una zona gana un **marco dorado** en esa foto.
- La edad y la sugerencia son solo una guía para elegir fotos; la edad aparece en el pie de la
  polaroid (se puede cambiar en el catálogo).

## Lista de recuerdos (orden de edad)

| id | edad sugerida | foto sugerida | se encuentra al... |
|---|---|---|---|
| `maxi_01` | recién nacido | recién nacido/a | primer viaje estelar |
| `maxi_02` | 1 mes | primer baño | completar zona 2 (Charcos) de Arcoíris |
| `maxi_03` | 3 meses | primera sonrisa | completar zona 4 (Islotes) de Arcoíris |
| `maxi_04` | 5 meses | gateando | completar zona 2 de Animalia |
| `maxi_05` | 6 meses | primer cumpleaños | completar zona 4 de Animalia |
| `maxi_06` | 8 meses | primeros pasos | completar zona 2 de Melodía |
| `maxi_07` | 10 meses | con sus hermanos | completar zona 4 de Melodía |
| `maxi_08` | 1 año | jugando | completar zona 2 de Cuenta-Cuentas |
| `maxi_09` | 1 año y 3 meses | en el jardín | completar zona 4 de Cuenta-Cuentas |
| `maxi_10` | 1 año y 6 meses | disfrazado/a | completar zona 2 de Letralandia |
| `maxi_11` | 1 año y 9 meses | vacaciones | completar zona 4 de Letralandia |
| `maxi_12` | 2 años | en el colegio o jardín | completar zona 2 de Corazón |
| `maxi_13` | 2 años | cumpleaños reciente | completar zona 4 de Corazón |
| `maxi_14` | hoy | hoy | viaje al planeta final |
| `nicole_01` | recién nacida | recién nacido/a | primer viaje estelar |
| `nicole_02` | 3 meses | primer baño | completar zona 2 (Charcos) de Arcoíris |
| `nicole_03` | 6 meses | primera sonrisa | completar zona 4 (Islotes) de Arcoíris |
| `nicole_04` | 9 meses | gateando | completar zona 2 de Animalia |
| `nicole_05` | 1 año | primer cumpleaños | completar zona 4 de Animalia |
| `nicole_06` | 1 año y 6 meses | primeros pasos | completar zona 2 de Melodía |
| `nicole_07` | 2 años | con sus hermanos | completar zona 4 de Melodía |
| `nicole_08` | 2 años y 6 meses | jugando | completar zona 2 de Cuenta-Cuentas |
| `nicole_09` | 3 años | en el jardín | completar zona 4 de Cuenta-Cuentas |
| `nicole_10` | 3 años y 6 meses | disfrazado/a | completar zona 2 de Letralandia |
| `nicole_11` | 4 años | vacaciones | completar zona 4 de Letralandia |
| `nicole_12` | 4 años y 6 meses | en el colegio o jardín | completar zona 2 de Corazón |
| `nicole_13` | 5 años | cumpleaños reciente | completar zona 4 de Corazón |
| `nicole_14` | hoy | hoy | viaje al planeta final |
| `sofia_01` | recién nacida | recién nacido/a | primer viaje estelar |
| `sofia_02` | 3 meses | primer baño | completar zona 2 (Charcos) de Arcoíris |
| `sofia_03` | 6 meses | primera sonrisa | completar zona 4 (Islotes) de Arcoíris |
| `sofia_04` | 1 año | gateando | completar zona 2 de Animalia |
| `sofia_05` | 1 año y 6 meses | primer cumpleaños | completar zona 4 de Animalia |
| `sofia_06` | 2 años | primeros pasos | completar zona 2 de Melodía |
| `sofia_07` | 3 años | con sus hermanos | completar zona 4 de Melodía |
| `sofia_08` | 4 años | jugando | completar zona 2 de Cuenta-Cuentas |
| `sofia_09` | 5 años | en el jardín | completar zona 4 de Cuenta-Cuentas |
| `sofia_10` | 6 años | disfrazado/a | completar zona 2 de Letralandia |
| `sofia_11` | 6 años y 6 meses | vacaciones | completar zona 4 de Letralandia |
| `sofia_12` | 7 años | en el colegio o jardín | completar zona 2 de Corazón |
| `sofia_13` | 8 años | cumpleaños reciente | completar zona 4 de Corazón |
| `sofia_14` | hoy | hoy | viaje al planeta final |
| `familia_01` | — | los cinco antes del secuestro (la foto de la billetera) | primera vez que se abre el juego |
| `familia_02` | — | mamá y papá con Sofía bebé | pieza de la nave de Arcoíris |
| `familia_03` | — | los tres hermanos juntos por primera vez | pieza de la nave de Animalia |
| `familia_04` | — | un paseo en familia | pieza de la nave de Melodía |
| `familia_05` | — | un cumpleaños en familia | pieza de la nave de Cuenta-Cuentas |
| `familia_06` | — | vacaciones en Chile | pieza de la nave de Letralandia |
| `familia_07` | — | una Navidad o 18 de septiembre | pieza de la nave de Corazón |
| `familia_08` | — | los tres hermanos hoy | viaje al planeta final |
| `familia_09` | — | los cinco juntos (o los tres jugando este juego) | rescate final |
