# Validación del guionista — HE-40 (voces por zona del Planeta Arcoíris) y HE-44 (álbum "Las migas de papá")

- **Fecha**: 28-Sep-2026
- **Autor**: `guionista`, a pedido del PO (avanzar sin consultarle)
- **Alcance**: solo texto. No se generó audio ni se tocaron `.tsv`, código, `datos/` ni `docs/TABLERO.md`.

## Entregables

| Archivo | Qué contiene |
|---|---|
| `docs/guiones/zonas_arcoiris.md` (nuevo) | Voces del mapa por zona (llegada, abierta, completada con el tic de Coco, regalo de zona, zona dormida, estación repetida, cima secreta, planeta completo), 2 intros de estación que faltaban, pistas por zona del Taller de Sofía y revisión con veredicto de todas las voces TTS provisionales de `assets/audio/voces/arcoiris/` |
| `docs/guiones/escena_planeta_arcoiris.md` | Disparador nuevo (zona 3 completa), escenario movido al Bosque de Chupetines, `arcoiris_001`, `_008` y `_017` reescritas |
| `docs/guiones/recuerdos.md` | Entrega tras el regalo del anfitrión (§1.2b), pistas de zona reescritas (§4.2) y pies de foto narrados por edad y del álbum familiar (§8) |

## Conteo

| Tarjeta | Nuevas | Reescritas | Personajes |
|---|---|---|---|
| HE-40 | 20 | 32 | Coco 12 nuevas y 30 reescritas; Cometa 8 nuevas y 2 reescritas |
| HE-44 | 36 | 8 | Todas de Cometa |
| **Total** | **56** | **40** | — |

Además, ~23 líneas de Formas son **obsoletas**: ningún nivel las usa desde "Arma la figura". Recomiendo no
regenerarlas con la voz oficial, para ahorrar costo.

## Decisiones de tono

1. El tic de Coco (anuncia el color que "es") marca cada zona completada, con un apellido dulce sacado del
   mapa-isla: rojo frutilla, amarillo limón, azul chupetín, verde menta y "arcoíris de pies a cabeza".
2. Zona dormida, nunca bloqueada: se dice "juega todos los juegos de este lado y lo despertamos", que
   calza con la regla de zona completa del 27-Sep.
3. En voz, los objetos del hangar son "regalos de Coco" y las fotos son "fotos" o "estrellas-recuerdo".
4. Sin apuro ni avisos de dificultad para Sofía: se sacan "memoriza rápido" y "es mucho más difícil".
5. Un solo nombre por color: se propone violeta y naranja en todo el planeta. Hoy conviven morado y
   naranjo.
6. En el dato de la bandera de Chile, "la sangre de los héroes" pasa a ser "el corazón valiente de los héroes".
7. Los pies de foto no llevan nombre ("Aquí tenía tres mesecitos"): la tapa del álbum ya dice de quién es,
   y así la línea no se escucha cortada.

## Hallazgos para otros roles (no los corrige el guionista)

- **`dev-godot`**:
  - Claves nuevas para los audios:
    - en `mapa.json`: `voz_abierta` y `voz_regalo` por zona, más una voz de estación por perfil (`juego_taller` para Sofía);
    - en `mezcla_estrella.json`: una `pista` por zona;
    - en el catálogo de recuerdos: `entrega_zona`, y `pie` / `pie_en_audio` por recuerdo.
  - Cambiar la `intro` de `zona2_charcos/parejas_semilla.json` y `zona3_chupetines/parejas_brote.json`.
    Hoy cargan la intro de la demo.
  - Sincronizar `assets/audio/voces/guion_voces.md`. Sus filas `arcoiris_001`, `_008` y `_017` tienen el
    texto viejo, y conviene hacerlo **antes** de generar ese audio.
  - Confirmar si las líneas de `lluvia/estrella/*` siguen en uso: Sofía ahora juega el Taller.
- **`disenador-niveles`**: el pool de Nicole en Formas, zona 3, trae una mariposa, y su ficha prohíbe
  bichos. La figura `corona` está en el pool de Nicole, pero su voz le habla a Sofía; ya quedó reescrita.
- **`director-cinematicas`**: orden propuesto al completar una zona: completada → regalo → sobre-estrella
  → zona abierta. En la zona 3, la escena reemplaza a `zona_3_completada`.

## Pendiente de grabar o generar

Todo lo anterior, es decir 56 líneas nuevas y 40 reescritas. Todavía no existe audio de ninguna. Se generan
con la voz oficial de Coco o de Cometa cuando el PO apruebe el costo (`--estimar` primero). Las voces de la
familia para cada foto siguen la guía de `docs/guiones/recuerdos.md` §6.
