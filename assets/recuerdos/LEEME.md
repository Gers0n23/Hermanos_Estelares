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
- Cada etapa (zona) completa desbloquea **una** foto por hermano y una para la familia. Hay 6 planetas
  con 5 zonas: 30 etapas. Hoy tienen mapa Arcoíris y Animalia (10 etapas); las demás aparecen como
  huecos cuando su mapa exista.
- Un recuerdo familiar lo encuentra el primer hermano que llega y queda para los tres.
- Sofía con estrellitas máximas en una zona gana un **marco dorado** en esa foto.
- La edad aparece en el pie de la polaroid. Para Maxi y Nicole es la **edad real** de la foto, con su
  fecha de nacimiento (Maxi 26-nov-2022, Nicole 12-oct-2020). El pie de voz solo suena si esa edad
  calza con uno ya grabado (±1 mes); si no, la foto va sin pie. Sofía sigue con su escala original.

## Lista de recuerdos (orden de edad)

| id | edad | foto | se encuentra al... |
|---|---|---|---|
| `maxi_01` | 1 año y 3 meses | foto del 10-feb-2024 | primer viaje estelar |
| `maxi_02` | 1 año y 6 meses | hueco (sin foto aún) | completar zona 1 de Arcoíris |
| `maxi_03` | 1 año y 9 meses | foto del 15-sep-2024 | completar zona 2 de Arcoíris |
| `maxi_04` | 1 año y 10 meses | hueco (sin foto aún) | completar zona 3 de Arcoíris |
| `maxi_05` | 2 años | foto del 02-nov-2024 | completar zona 4 de Arcoíris |
| `maxi_06` | 2 años | hueco (sin foto aún) | completar zona 5 de Arcoíris |
| `maxi_07` | 2 años y 1 mes | hueco (sin foto aún) | completar zona 1 de Animalia |
| `maxi_08` | 2 años y 2 meses | foto del 26-ene-2025 | completar zona 2 de Animalia |
| `maxi_09` | 2 años y 2 meses | hueco (sin foto aún) | completar zona 3 de Animalia |
| `maxi_10` | 2 años y 2 meses | foto del 04-feb-2025 | completar zona 4 de Animalia |
| `maxi_11` | 2 años y 4 meses | hueco (sin foto aún) | completar zona 5 de Animalia |
| `maxi_12` | 2 años y 6 meses | foto del 24-may-2025 | completar zona 1 de Melodía |
| `maxi_13` | 2 años y 6 meses | hueco (sin foto aún) | completar zona 2 de Melodía |
| `maxi_14` | 2 años y 7 meses | foto del 21-jun-2025 | completar zona 3 de Melodía |
| `maxi_15` | 2 años y 7 meses | hueco (sin foto aún) | completar zona 4 de Melodía |
| `maxi_16` | 2 años y 8 meses | hueco (sin foto aún) | completar zona 5 de Melodía |
| `maxi_17` | 2 años y 8 meses | foto del 10-ago-2025 | completar zona 1 de Cuenta-Cuentas |
| `maxi_18` | 2 años y 9 meses | hueco (sin foto aún) | completar zona 2 de Cuenta-Cuentas |
| `maxi_19` | 2 años y 10 meses | foto del 21-sep-2025 | completar zona 3 de Cuenta-Cuentas |
| `maxi_20` | 2 años y 10 meses | hueco (sin foto aún) | completar zona 4 de Cuenta-Cuentas |
| `maxi_21` | 2 años y 10 meses | foto del 25-sep-2025 | completar zona 5 de Cuenta-Cuentas |
| `maxi_22` | 2 años y 10 meses | hueco (sin foto aún) | completar zona 1 de Letralandia |
| `maxi_23` | 2 años y 11 meses | foto del 12-oct-2025 | completar zona 2 de Letralandia |
| `maxi_24` | 3 años | hueco (sin foto aún) | completar zona 3 de Letralandia |
| `maxi_25` | 3 años y 1 mes | foto del 03-ene-2026 | completar zona 4 de Letralandia |
| `maxi_26` | 3 años y 2 meses | hueco (sin foto aún) | completar zona 5 de Letralandia |
| `maxi_27` | 3 años y 3 meses | hueco (sin foto aún) | completar zona 1 de Corazón |
| `maxi_28` | 3 años y 3 meses | foto del 03-mar-2026 | completar zona 2 de Corazón |
| `maxi_29` | 3 años y 4 meses | hueco (sin foto aún) | completar zona 3 de Corazón |
| `maxi_30` | 3 años y 6 meses | foto del 01-may-2026 | completar zona 4 de Corazón |
| `maxi_31` | 3 años y 7 meses | hueco (sin foto aún) | completar zona 5 de Corazón |
| `maxi_32` | 3 años y 9 meses | foto del 29-ago-2026 | viaje al planeta final |
| `nicole_01` | 1 año | foto del 25-sep-2021 | primer viaje estelar |
| `nicole_02` | 1 año | hueco (sin foto aún) | completar zona 1 de Arcoíris |
| `nicole_03` | 1 año | hueco (sin foto aún) | completar zona 2 de Arcoíris |
| `nicole_04` | 1 año y 1 mes | foto del 05-nov-2021 | completar zona 3 de Arcoíris |
| `nicole_05` | 1 año y 1 mes | hueco (sin foto aún) | completar zona 4 de Arcoíris |
| `nicole_06` | 1 año y 2 meses | foto del 09-dic-2021 | completar zona 5 de Arcoíris |
| `nicole_07` | 1 año y 4 meses | hueco (sin foto aún) | completar zona 1 de Animalia |
| `nicole_08` | 1 año y 5 meses | hueco (sin foto aún) | completar zona 2 de Animalia |
| `nicole_09` | 1 año y 7 meses | foto del 15-may-2022 | completar zona 3 de Animalia |
| `nicole_10` | 2 años y 2 meses | hueco (sin foto aún) | completar zona 4 de Animalia |
| `nicole_11` | 2 años y 8 meses | foto del 28-jun-2023 | completar zona 5 de Animalia |
| `nicole_12` | 3 años y 2 meses | hueco (sin foto aún) | completar zona 1 de Melodía |
| `nicole_13` | 3 años y 7 meses | hueco (sin foto aún) | completar zona 2 de Melodía |
| `nicole_14` | 4 años | foto del 31-oct-2024 | completar zona 3 de Melodía |
| `nicole_15` | 4 años y 6 meses | hueco (sin foto aún) | completar zona 4 de Melodía |
| `nicole_16` | 4 años y 11 meses | hueco (sin foto aún) | completar zona 5 de Melodía |
| `nicole_17` | 5 años y 4 meses | foto del 05-feb-2026 | completar zona 1 de Cuenta-Cuentas |
| `nicole_18` | 5 años y 4 meses | hueco (sin foto aún) | completar zona 2 de Cuenta-Cuentas |
| `nicole_19` | 5 años y 4 meses | foto del 21-feb-2026 | completar zona 3 de Cuenta-Cuentas |
| `nicole_20` | 5 años y 5 meses | hueco (sin foto aún) | completar zona 4 de Cuenta-Cuentas |
| `nicole_21` | 5 años y 6 meses | hueco (sin foto aún) | completar zona 5 de Cuenta-Cuentas |
| `nicole_22` | 5 años y 7 meses | foto del 01-may-2026 | completar zona 1 de Letralandia |
| `nicole_23` | 5 años y 8 meses | hueco (sin foto aún) | completar zona 2 de Letralandia |
| `nicole_24` | 5 años y 9 meses | foto del 04-jul-2026 | completar zona 3 de Letralandia |
| `nicole_25` | 5 años y 9 meses | hueco (sin foto aún) | completar zona 4 de Letralandia |
| `nicole_26` | 5 años y 10 meses | hueco (sin foto aún) | completar zona 5 de Letralandia |
| `nicole_27` | 5 años y 11 meses | foto del 29-ago-2026 | completar zona 1 de Corazón |
| `nicole_28` | 5 años y 11 meses | hueco (sin foto aún) | completar zona 2 de Corazón |
| `nicole_29` | 5 años y 11 meses | foto del 29-ago-2026 | completar zona 3 de Corazón |
| `nicole_30` | 5 años y 11 meses | hueco (sin foto aún) | completar zona 4 de Corazón |
| `nicole_31` | 5 años y 11 meses | hueco (sin foto aún) | completar zona 5 de Corazón |
| `nicole_32` | 6 años | foto del 16-sep-2026 | viaje al planeta final |
| `sofia_01` | recién nacido | foto del 27-jun-2018 | primer viaje estelar |
| `sofia_02` | 1 mes | hueco (sin foto aún) | completar zona 1 de Arcoíris |
| `sofia_03` | 1 mes | foto del 16-ago-2018 | completar zona 2 de Arcoíris |
| `sofia_04` | 4 meses | hueco (sin foto aún) | completar zona 3 de Arcoíris |
| `sofia_05` | 6 meses | foto del 25-dic-2018 | completar zona 4 de Arcoíris |
| `sofia_06` | 6 meses | hueco (sin foto aún) | completar zona 5 de Arcoíris |
| `sofia_07` | 6 meses | hueco (sin foto aún) | completar zona 1 de Animalia |
| `sofia_08` | 7 meses | foto del 16-ene-2019 | completar zona 2 de Animalia |
| `sofia_09` | 7 meses | hueco (sin foto aún) | completar zona 3 de Animalia |
| `sofia_10` | 7 meses | foto del 20-ene-2019 | completar zona 4 de Animalia |
| `sofia_11` | 7 meses | hueco (sin foto aún) | completar zona 5 de Animalia |
| `sofia_12` | 7 meses | foto del 26-ene-2019 | completar zona 1 de Melodía |
| `sofia_13` | 7 meses | hueco (sin foto aún) | completar zona 2 de Melodía |
| `sofia_14` | 8 meses | foto del 03-feb-2019 | completar zona 3 de Melodía |
| `sofia_15` | 9 meses | hueco (sin foto aún) | completar zona 4 de Melodía |
| `sofia_16` | 10 meses | hueco (sin foto aún) | completar zona 5 de Melodía |
| `sofia_17` | 1 año | foto del 07-jun-2019 | completar zona 1 de Cuenta-Cuentas |
| `sofia_18` | 1 año y 8 meses | hueco (sin foto aún) | completar zona 2 de Cuenta-Cuentas |
| `sofia_19` | 2 años y 4 meses | foto del 18-oct-2020 | completar zona 3 de Cuenta-Cuentas |
| `sofia_20` | 3 años y 5 meses | hueco (sin foto aún) | completar zona 4 de Cuenta-Cuentas |
| `sofia_21` | 4 años y 7 meses | foto del 28-ene-2023 | completar zona 5 de Cuenta-Cuentas |
| `sofia_22` | 5 años y 11 meses | hueco (sin foto aún) | completar zona 1 de Letralandia |
| `sofia_23` | 7 años y 2 meses | foto del 05-sep-2025 | completar zona 2 de Letralandia |
| `sofia_24` | 7 años y 5 meses | hueco (sin foto aún) | completar zona 3 de Letralandia |
| `sofia_25` | 7 años y 7 meses | foto del 24-ene-2026 | completar zona 4 de Letralandia |
| `sofia_26` | 7 años y 8 meses | hueco (sin foto aún) | completar zona 5 de Letralandia |
| `sofia_27` | 7 años y 9 meses | hueco (sin foto aún) | completar zona 1 de Corazón |
| `sofia_28` | 7 años y 10 meses | foto del 01-may-2026 | completar zona 2 de Corazón |
| `sofia_29` | 7 años y 11 meses | hueco (sin foto aún) | completar zona 3 de Corazón |
| `sofia_30` | 8 años | foto del 27-jun-2026 | completar zona 4 de Corazón |
| `sofia_31` | 8 años | hueco (sin foto aún) | completar zona 5 de Corazón |
| `sofia_32` | 8 años | foto del 04-jul-2026 | viaje al planeta final |
| `familia_01` | — | foto del 29-ago-2026 · holográfica | primera vez que se abre el juego |
| `familia_02` | — | hueco (sin foto aún) | pieza de la nave de Arcoíris |
| `familia_03` | — | foto del 30-abr-2023 | pieza de la nave de Animalia |
| `familia_04` | — | foto del 04-jul-2026 · holográfica | pieza de la nave de Melodía |
| `familia_05` | — | foto del 26-jul-2026 | pieza de la nave de Cuenta-Cuentas |
| `familia_06` | — | foto del 02-may-2026 | pieza de la nave de Letralandia |
| `familia_07` | — | hueco (sin foto aún) | pieza de la nave de Corazón |
| `familia_08` | — | foto del 02-jul-2026 | viaje al planeta final |
| `familia_09` | — | foto del 31-oct-2026 | rescate final |
| `familia_10` | — | foto del 04-feb-2025 · holográfica | completar zona 1 de Arcoíris |
| `familia_11` | — | foto del 02-may-2026 · holográfica | completar zona 2 de Arcoíris |
| `familia_12` | — | foto del 12-jun-2026 · holográfica | completar zona 3 de Arcoíris |
| `familia_13` | — | foto del 02-jul-2026 · holográfica | completar zona 4 de Arcoíris |
| `familia_14` | — | foto del 02-jul-2026 · holográfica | completar zona 5 de Arcoíris |
| `familia_15` | — | foto del 02-jul-2026 · holográfica | completar zona 1 de Animalia |
| `familia_16` | — | foto del 31-oct-2021 | completar zona 2 de Animalia |
| `familia_17` | — | foto del 07-nov-2021 | completar zona 3 de Animalia |
| `familia_18` | — | foto del 24-abr-2022 | completar zona 4 de Animalia |
| `familia_19` | — | foto del 27-dic-2022 | completar zona 5 de Animalia |
| `familia_20` | — | foto del 07-ene-2023 | completar zona 1 de Melodía |
| `familia_21` | — | foto del 11-feb-2023 | completar zona 2 de Melodía |
| `familia_22` | — | foto del 11-feb-2023 | completar zona 3 de Melodía |
| `familia_23` | — | foto del 16-abr-2023 | completar zona 4 de Melodía |
| `familia_24` | — | foto del 30-abr-2023 | completar zona 5 de Melodía |
| `familia_25` | — | foto del 16-jul-2023 | completar zona 1 de Cuenta-Cuentas |
| `familia_26` | — | foto del 10-feb-2024 | completar zona 2 de Cuenta-Cuentas |
| `familia_27` | — | foto del 31-oct-2024 | completar zona 3 de Cuenta-Cuentas |
| `familia_28` | — | foto del 07-dic-2024 | completar zona 4 de Cuenta-Cuentas |
| `familia_29` | — | foto del 11-dic-2024 | completar zona 5 de Cuenta-Cuentas |
| `familia_30` | — | foto del 04-feb-2025 | completar zona 1 de Letralandia |
| `familia_31` | — | foto del 03-may-2025 | completar zona 2 de Letralandia |
| `familia_32` | — | foto del 24-may-2025 | completar zona 3 de Letralandia |
| `familia_33` | — | foto del 24-may-2025 | completar zona 4 de Letralandia |
| `familia_34` | — | foto del 21-sep-2025 | completar zona 5 de Letralandia |
| `familia_35` | — | foto del 31-oct-2025 | completar zona 1 de Corazón |
| `familia_36` | — | foto del 24-ene-2026 | completar zona 2 de Corazón |
| `familia_37` | — | foto del 03-abr-2026 | completar zona 3 de Corazón |
| `familia_38` | — | foto del 03-abr-2026 | completar zona 4 de Corazón |
| `familia_39` | — | foto del 05-abr-2026 | completar zona 5 de Corazón |
