# Guion de voces — Los Hermanos Estelares

> **Esqueleto (HE-04)**: esta es solo la estructura y las convenciones. El **contenido
> narrativo real** (líneas definitivas, personajes que hablan, tono, chistes) lo escribe
> `guionista` en HE-D5, una vez cerrado el guion narrativo completo (GDD §1-§4). Hasta
> entonces, cada motor/pantalla puede referenciar rutas de voz que aún no existen —
> `Audio.reproducir_voz()` no rompe el juego si el archivo falta, solo deja un aviso en
> consola (`push_warning`) señalando la línea pendiente de grabar.

## Cómo se usa este documento

1. Cada línea de voz que el juego necesita tiene una **fila** en la tabla de su
   escena/motor: id de línea, quién la dice, contexto/cuándo suena, texto guía para
   grabar, ruta del archivo `.ogg` y estado.
2. La **ruta del archivo** es siempre relativa a `res://assets/audio/voces/`, organizada
   por escena o motor (ver convención de carpetas más abajo), y es la misma ruta que
   usan los archivos de nivel en `datos/` dentro de su bloque `lineas_voz` (ver
   `docs/fichas/motor-emparejar.md` §4 como ejemplo del contrato).
3. **Estado** de cada línea: `pendiente de guion` (aún no la escribió `guionista`) →
   `pendiente de grabar` (texto listo, falta grabación) → `grabada` (archivo `.ogg` ya
   en `assets/audio/voces/`).
4. Voz de Cometa y de la familia: ver decisión pendiente **P2** del GDD §9 (grabada
   por la familia vs. TTS de relleno durante desarrollo) — se resuelve en HE-D5.

## Convención de carpetas y nombres

```
assets/audio/voces/
├── guion_voces.md          # este documento
├── nucleo/                 # titulo, seleccion_personaje, mapa_estelar, zona_padres
├── cometa/                  # líneas genéricas de Cometa (ayudante flotante, HE-11)
├── emparejar/               # líneas del motor "emparejar" (contrato en su ficha)
├── <otro_motor>/            # una carpeta por motor de mecánica compartido (GDD §5)
└── historia/                 # cinemáticas y escenas de historia por planeta (HE-30, HE-39)
```

Nombres de archivo en minúsculas, sin acentos, snake_case y numerados si hay variantes
(p. ej. `acierto_par_01.ogg`, `acierto_par_02.ogg`) para que el motor elija una al azar
y evite monotonía (ver `docs/fichas/motor-emparejar.md` §4/§7).

## Plantilla de tabla por escena/motor

Copiar esta tabla para cada escena o motor nuevo que necesite líneas de voz:

| id_línea | personaje | contexto (cuándo suena) | texto guía (a grabar) | archivo (`res://assets/audio/voces/...`) | estado |
|---|---|---|---|---|---|
| _ejemplo_intro | Cometa | Al entrar a la escena | _(pendiente de guion)_ | `nucleo/ejemplo_intro.ogg` | pendiente de guion |

## Claves estándar ya asumidas por el motor "emparejar" (piloto, 18-Jul-2026)

El contrato de nivel del motor "emparejar" (`docs/fichas/motor-emparejar.md` §4) ya
espera estas claves dentro de `lineas_voz` de cada archivo de nivel en `datos/`. Sirven
de referencia para que cualquier motor nuevo defina las suyas con el mismo patrón:

| clave | cuándo suena | admite variantes (array) |
|---|---|---|
| `intro` | Al entrar al nivel, antes de jugar | No |
| `pista` | Al tocar a Cometa, o tras varios intentos sin acierto (Brote/Estrella) | No |
| `acierto_par` | Al completar un par correctamente | Sí |
| `no_es_este` | Al tocar dos elementos que no forman par (feedback amistoso, nunca "error") | Sí |
| `victoria_final` | Al completar el nivel entero | No |
| `derrota_gag` | Al disparar la derrota-gag (solo Brote/Estrella con `limite_intentos`) | No |

## Pendiente

- [ ] Guion narrativo completo y primera versión de contenido real (HE-D5, `guionista`).
- [ ] Decisión P2 del GDD §9: voces grabadas por la familia vs. TTS provisional.
- [ ] Una tabla de líneas por cada escena/motor a medida que se implementan (HE-05, 06,
      08, 11, 14-16, 30, 39...).
