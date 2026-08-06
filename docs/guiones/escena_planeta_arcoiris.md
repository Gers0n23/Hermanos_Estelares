# Escena de historia — Planeta 1 (Arcoíris): «El ala pintada de Coco»

> Guion narrativo (HE-D5) — versión completa y definitiva del planeta 1 (los otros 5 planetas usan
> `plantilla_escena_planeta.md` hasta que se aborde su tarjeta de contenido).
> Fuente de verdad: `docs/diseno-juego.md` §1, §4; `docs/guia-estilo-generacion.md` §3 (fichas de
> Camaleona Coco y Nave-estrella).

- **Disparador**: al recuperar todos los destellos de los 3 minijuegos del Planeta Arcoíris
  (Lluvia de colores, Formas traviesas, Pinta con Coco), sin importar en qué orden se jugaron.
- **Duración estimada**: 20-30 s de cinemática sin interacción (GDD §4, "Escena de historia por
  planeta"), pensada para reproducirse con los tres hermanos presentes (modo misión familiar).
- **Personajes**: Maxi, Nicole, Sofía, Cometa, Camaleona Coco, Papá (voz, video-llamada).
- **Escenario**: Planeta Arcoíris — claro central en forma de trébol (ficha en
  `docs/guia-estilo-generacion.md` §3, "Planeta Arcoíris").
- **Prefijo de id de línea / carpeta de audio**: `arcoiris_XXX` →
  `assets/audio/voces/historia/arcoiris/`

## Salvaguardas de tono (recordatorio explícito)

Cometa sigue sin regañar ni apurar; Coco celebra en grande y nunca compara a los hermanos entre
sí (cuidado especial: Sofía siente celos de Nicole, GDD §2 — cada logro se celebra por igual);
papá vuelve a aparecer relajado y bromista, sin gancho de urgencia.

---

## Beat 1 — Coco agradece y celebra

**Acotación**: Coco espera en el claro central (plataforma en forma de trébol); su cresta de
nuditos a lo largo del lomo se enciende arcoíris de la emoción, tal como describe su ficha de
personaje ("se ilumina y brilla más fuerte con la emoción"). Tic verbal de Coco: anuncia en voz
alta el color que "es" en cada momento, como parte del juego de imitar colores.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| arcoiris_001 | Coco | «¡Uy, uy, uy, miren nada más! Terminaron todo mi arcoíris del claro. ¡Ahora soy... color FELIZ!» | asombrada, encantada (tic: anuncia su color) |
| arcoiris_002 | Cometa | «Coco, ¡lo lograron los tres, cada uno jugando a su manera!» | celebra sin comparar a nadie |
| arcoiris_003 | Nicole | «¡Pinté un charco entero de rosado, Coco! Como tú.» | orgullosa, conectando con Coco |
| arcoiris_004 | Coco | «¡El rosado me queda regio! Miren... ahora soy... ¡rosado chicle!» | cambia de color en vivo (tic), tierna |
| arcoiris_005 | Sofía | «Y yo até el azul con el amarillo. Salió verde. Química de planeta, nada mal.» | orgullosa, chistosa, presume su lógica |
| arcoiris_006 | Maxi | «¡Yo toqué TODO!» | gritando feliz, sin culpa — así es su nivel |
| arcoiris_007 | Coco | (riendo) «Tocaste todo... ¡y todo brilló! Así se juega en mi planeta, chiquitín.» | celebra a Maxi igual de grande que a sus hermanos |

## Beat 2 — Entrega de la pieza

**Acotación**: Coco se acerca a uno de los árboles piruleta y saca de entre sus ramas —envuelta
como regalo con una cinta arcoíris— el **ala izquierda** de la nave-estrella (panel curvo a
franjas multicolor pastel, ver ficha de Nave-estrella §3).

| id | Personaje | Línea | Intención |
|---|---|---|---|
| arcoiris_008 | Coco | «Esto es para su nave. El ala del Arcoíris... la pinté yo misma, con todos los colores que me enseñaron hoy.» | orgullosa, tierna, un poco solemne-juguetona |
| arcoiris_009 | Cometa | «¡La primera pieza! Miren cómo le queda a la nave.» | entusiasta — la nave brilla, el hueco fantasma se llena |

## Beat 3 — Celebración con los gestos canon

**Acotación**: los tres celebran con su gesto real de la vida (GDD §2, "Gesto de celebración
canon" — no varía nunca, es la animación de victoria fija del juego). Cometa aplaude con sus
bracitos cortos, dando saltitos.

| id | Personaje | Línea | Intención |
|---|---|---|---|
| celeb_maxi_01 | Maxi | «¡¡Siiii!!» *(salto + puño derecho arriba, x3)* | grito de alegría total |
| celeb_nicole_01 | Nicole | «¡Lo logramos!» *(corazón coreano con los dedos, expresión tierna)* | dulce, orgullosa |
| celeb_sofia_01 | Sofía | «Nada mal para el primer planeta.» *(mano en cintura, signo de la paz, guiño, cabeza ladeada)* | segura, con humor |

> Nota: `celeb_maxi_01`, `celeb_nicole_01` y `celeb_sofia_01` son líneas **genéricas de
> celebración**, reutilizables en cualquier escena de historia de cualquier planeta (no exclusivas
> del Planeta Arcoíris) — ver tabla compartida en `guion_voces.md`.

## Beat 4 — Video-llamada de papá

**Acotación**: la pantalla de la nave (o algo brillante del planeta) se enciende y aparece papá,
feliz, con algo gracioso de fondo de la colección del Coleccionauta (por ejemplo, usando un objeto
raro como sombrero improvisado).

| id | Personaje | Línea | Intención |
|---|---|---|---|
| arcoiris_010 | Cometa | «¡Sorpresa! Alguien quiere saludarlos.» | pícaro, contento |
| arcoiris_011 | Papá | «¡Hermanos Estelares! Me contaron que ya tienen su primera pieza. ¡Una ala! Con esa y la otra, casi puedo volar yo también... si el Coleccionauta me presta sus lentes de lupa.» | bromista, orgulloso |
| arcoiris_012 | Papá | «¿Vieron colores nuevos? Cuéntenme todos cuando nos veamos. Mientras tanto, sigan jugando tranquilos, que acá estoy la mar de bien.» | calma explícita, sin presión |
| arcoiris_013 | Nicole | «¡Papi, mezclamos azul con amarillo y salió verde!» | contándole encantada |
| arcoiris_014 | Maxi | «¡Toqué TODO, papi!» | orgulloso, repite su logro |
| arcoiris_015 | Sofía | «Vamos por la segunda pieza. No te aburras mucho allá.» | cariñosa, chistosa |
| arcoiris_016 | Papá | «¿Yo, aburrido? Imposible, aquí el Coleccionauta me está enseñando a doblar servilletas en forma de pato. Los quiero, ¡nos vemos pronto!» | dad joke, cálido |

## Beat 5 — Cierre y gancho al siguiente planeta

**Acotación**: la llamada se corta con destellos dorados; Coco se despide agitando la cola en
espiral; se ve a lo lejos, en el Mapa Estelar, el Planeta Animalia brillando "todavía muy lejos"
(sin candado ni "próximamente" — GDD §3).

| id | Personaje | Línea | Intención |
|---|---|---|---|
| arcoiris_017 | Coco | «Vuelvan cuando quieran, ¡mi arcoíris siempre los espera!» | cálida despedida |
| arcoiris_018 | Cometa | «Vamos, Hermanos Estelares... el siguiente planeta nos espera, brillando allá lejos.» | invita, sin apuro, ilusiona |

---

## Notas para `director-cinematicas` y `dev-godot`

- Beat 3 (celebración con gestos canon) es un momento fijo y reutilizable: la misma animación y
  las mismas 3 líneas se repiten en las 6 escenas de historia de planeta y en la prueba final —
  conviene implementarlo como un solo "clip de celebración" parametrizable, no rehacerlo por
  planeta.
- El chiste temático de papá (arcoiris_016) usa un objeto doméstico ("servilletas") a propósito:
  mantiene el registro de "papá normal haciendo bromas normales", no un chiste espacial forzado —
  este criterio se repite en la plantilla de planetas 2-6.
