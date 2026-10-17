# Guion provisorio — «Conocen a Coco» (prueba de concepto)

> **No es canon todavía.** Lo escribió Claude para la prueba de concepto de cinemáticas por código
> (`cinematica_conocen_coco.tscn`). Antes de usarlo en el juego debe pasar por `guionista`
> (texto y tono), `director-cinematicas` (storyboard) y `experto-ux-parvulo` (duración y ritmo).
> Las voces de `voces/` son relleno: TTS de Windows (Sabina) con el tono cambiado por personaje.

- **Cuándo**: al llegar por primera vez al Planeta Arcoíris, antes de la zona 1. Hoy ese momento lo
  cubre la voz `arcoiris_mapa_bienvenida` («Se le perdieron los colores...»); esta escena la explica.
- **Engancha con**: `arcoiris_mapa_zona_1_llegada` («...¡aquí se escondió el rojo!») y con la entrega
  del ala en la zona 3 (`docs/guiones/escena_planeta_arcoiris.md`, `arcoiris_008`: «la pinté yo
  misma, con los colores que ustedes me devolvieron»).
- **Duración**: ≈ 96 s (77 s de voz de relleno). La voz oficial será más rápida.

## Líneas

| id | Personaje | Línea | Qué pasa en pantalla |
|---|---|---|---|
| 01 | Cometa | «¡Llegamos al Planeta Arcoíris! ...Uy. ¿Y los colores?» | La nave aterriza en el Claro gris; salen los tres y Cometa. Miran alrededor |
| 02 | Coco | «¡Aquí estoy!» | Coco estaba camuflada: aparece de los pies a la cabeza. Todos dan un saltito de sorpresa |
| 03 | Coco | «¡Hola, hola! Soy Coco, la camaleona de este planeta. Ahora soy... ¡color sorpresa!» | Su piel recorre todo el arcoíris (su tic) |
| 04 | Cometa | «Coco, te presento a los Hermanos Estelares: ¡Maxi, Nicole y Sofía!» | Cada uno salta y saluda al oír su nombre |
| 05 | Coco | «¡Qué lindos trajes! Perdonen que todo esté tan grisecito... Les cuento lo que pasó.» | Burbujas de pensamiento salen de su cabeza |
| 06 | Coco (en off) | «Mi planeta tenía todos los colores del arcoíris... hasta que llegó un visitante con antenas y una mochila gigante.» | Recuerdo en color, dentro de una burbuja. Llega volando el Coleccionauta |
| 07 | Coleccionauta | «¡Ooh! ¡Un chupetín gigante! ¡Para mi colección!» | El chupetín vuela a la mochila |
| 08 | Coleccionauta | «¡Y ese arcoíris también! Sluuurp...» | Chorritos de color viajan del arcoíris a la mochila |
| 09 | Coco (en off) | «¡Pero a los colores les dio cosquillas... y se escaparon a esconderse por todo el planeta!» | La mochila tiembla y estalla: seis gotitas con carita salen riéndose a esconderse; el planeta queda gris |
| 10 | Coleccionauta | «¿Eh? ¿Dónde se fueron? ...¡Bueno, me llevo el chupetín!» | Busca a un lado y al otro, y se va volando con una vuelta en el aire |
| 11 | Cometa | «¡El Coleccionauta! Es el mismo que se llevó a su papá.» | Los tres, sorprendidos |
| 12 | Coco | «¿A su papá? ¡Ese coleccionista! Entonces los ayudo. ¡Somos un equipo!» | Coco se pone rosada; todos celebran |
| 13 | Cometa | «Coco, necesitamos piezas para arreglar la nave y llegar hasta él.» | |
| 14 | Coco | «¡Yo tengo justo una! Miren: un ala para su nave. Pero está gris...» | Aparece el ala, gris, y se "desinfla" |
| 15 | Coco | «Si me ayudan a encontrar los colores escondidos, ¡la pinto con todos ellos para ustedes!» | Adelanto: las franjas se pintan una a una, todos celebran, y el ala vuelve a gris (es una promesa) |
| 16 | Coco | «¡Shhh! ¿Vieron eso? ¡El rojo se escondió por allá! ¡Vamos a buscarlo!» | La gotita roja se asoma detrás del chupetín, se ríe y se escapa. Iris |

## Decisiones de historia que necesitan al PO

1. **Qué hizo el Coleccionauta en Arcoíris.** Hoy ningún documento dice por qué el planeta perdió sus
   colores. Esta propuesta: pasó antes que los hermanos, quiso guardar el arcoíris en la mochila y los
   colores, con cosquillas, **se escaparon a esconderse** (no fueron robados). Encaja con «aquí se
   escondió el rojo» (zona 1), con los colores contentos de la batalla y con su teaser posterior
   («¿Un planeta que recupera colores? ¡Para mi colección!»), que lo trae de vuelta.
2. **Papá no aparece en el recuerdo.** Solo Cometa lo nombra, sin urgencia.
3. **El ala existe desde el principio, gris.** Coco promete pintarla: así la pieza de la zona 3 deja de
   ser una sorpresa y pasa a ser la meta del planeta.
