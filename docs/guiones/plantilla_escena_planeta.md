# Plantilla — Escena de historia por planeta (reutilizable, planetas 2-6)

> Esta plantilla **no contiene diálogo final**. Cuando se aborde la tarjeta de contenido de cada
> planeta (2-6), `guionista` copia esta estructura a un archivo nuevo (p. ej.
> `escena_planeta_animalia.md`) y completa los campos entre `[corchetes]` con el guion definitivo,
> siguiendo el mismo nivel de detalle que `escena_planeta_arcoiris.md` (referencia obligatoria).
> No inventar aquí tics verbales ni chistes definitivos de anfitriones sin ficha de personaje
> aprobada por el PO — eso es trabajo de `disenador-personajes` + PO antes de escribir el guion
> final de cada planeta.

## Estructura fija (igual en los 6 planetas — GDD §4, "Escena de historia por planeta")

- **Duración**: 15-30 s de cinemática sin interacción.
- **Disparador**: al recuperar todos los destellos de los minijuegos del planeta.
- **5 beats fijos, en este orden**:
  1. El anfitrión agradece y celebra lo logrado (sin comparar a los hermanos entre sí).
  2. Entrega la **pieza de la nave** de su mundo (ver ficha de Nave-estrella, tabla de 6 piezas).
  3. Celebración con los **gestos canon** de los tres hermanos — líneas fijas y reutilizables
     (`celeb_maxi_01`, `celeb_nicole_01`, `celeb_sofia_01`, ver `guion_voces.md`), nunca varían.
  4. Video-llamada cómica de papá, con **un chiste temático** ligado al tema del planeta pero de
     registro doméstico/cotidiano (mismo criterio que Arcoíris: "papá normal haciendo bromas
     normales", nunca un chiste forzado a la estética espacial).
  5. Cierre + gancho: el anfitrión se despide, Cometa invita a seguir sin apuro, se ve el próximo
     planeta brillando "todavía muy lejos" en el Mapa Estelar (sin candado ni "próximamente").

## Salvaguardas de tono (recordatorio obligatorio en cada escena final)

Anfitrión cómico y cálido, nunca amenazante; Cometa nunca regaña ni apura; papá siempre relajado y
bromista, sin gancho de urgencia; celebraciones siempre equivalentes en tamaño y ternura entre los
tres hermanos (cuidado especial con los celos de Sofía hacia Nicole, GDD §2).

## Campos a completar por planeta

| Campo | Qué va acá |
|---|---|
| `[ANFITRIÓN]` | Nombre y tic verbal — tomar de la ficha de personaje aprobada en `docs/guia-estilo-generacion.md` §3 (hoy solo Camaleona Coco tiene ficha completa con tic verbal; los demás anfitriones necesitan su ficha de `disenador-personajes` antes de escribir el guion final). |
| `[PIEZA]` | Nombre y aspecto de la pieza de nave que entrega (ver tabla de 6 piezas modulares, `guia-estilo-generacion.md` §3 "Nave-estrella"). |
| `[TEMA]` | Tema de aprendizaje del planeta (GDD §4). |
| `[CHISTE_PAPÁ]` | Gancho temático doméstico para el chiste de papá en la video-llamada. |
| `[PREFIJO_ID]` | Prefijo de línea de voz y carpeta: `assets/audio/voces/historia/[planeta]/`. |

## Referencia rápida — planetas 2-6 (datos ya confirmados en el GDD, solo para orientar al guionista futuro)

| # | Planeta | Anfitrión | Pieza que entrega | Tic verbal del anfitrión |
|---|---|---|---|---|
| 2 | Animalia | Perrito astronauta Toby | Ala derecha (verde selva + huellita) | Pendiente de ficha de personaje |
| 3 | Melodía | Pulpo DJ Octavio | Motor izquierdo (bocina morada/neón) | Pendiente de ficha de personaje |
| 4 | Cuenta-Cuentas | Búho contador Profesor Plumas | Motor derecho (azul noche, ventanitas numeradas) | Pendiente de ficha de personaje |
| 5 | Letralandia | Dragoncita lectora Lila | Antena-mástil con banderines naranjas | Pendiente de ficha de personaje |
| 6 | Corazón | Nube Mimi | Corazón del motor / núcleo central (última pieza) | Pendiente de ficha de personaje |

## Esqueleto de tabla de diálogo (copiar y completar)

```
### Beat 1 — [ANFITRIÓN] agradece y celebra
| id | Personaje | Línea | Intención |
|---|---|---|---|
| [prefijo]_001 | [ANFITRIÓN] | | |
| [prefijo]_002 | Cometa | | |
| [prefijo]_003 | Nicole/Sofía/Maxi | | |

### Beat 2 — Entrega de la pieza
| [prefijo]_00X | [ANFITRIÓN] | | |
| [prefijo]_00X | Cometa | | |

### Beat 3 — Celebración (líneas fijas, no reescribir)
celeb_maxi_01 / celeb_nicole_01 / celeb_sofia_01 (ver guion_voces.md)

### Beat 4 — Video-llamada de papá
| [prefijo]_00X | Cometa | | |
| [prefijo]_00X | Papá | [CHISTE_PAPÁ] | |
| [prefijo]_00X | (hermano) | | |
| [prefijo]_00X | Papá | | |

### Beat 5 — Cierre y gancho
| [prefijo]_00X | [ANFITRIÓN] | | |
| [prefijo]_00X | Cometa | | |
```

## Nota especial — Planeta 6 (Corazón)

Es la última pieza (núcleo central) antes de la prueba final: cuando se escriba su guion, la
escena de historia puede reforzar un poco más el tema emocional (GDD §4, "entrena justo el tema
del clímax") sin salirse de la estructura fija de 5 beats ni convertirse en un sermón — el mensaje
sigue mostrándose en acciones, nunca declamado (regla de oro del guionista).
