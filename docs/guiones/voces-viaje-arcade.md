# Guion de voz — Viaje arcade: el Coleccionauta y Cometa (HE-134)

> Encargo de **HE-134** (21-Nov-2026). Fuentes: `docs/fichas/viaje-arcade.md` (§5.3 jefes, §7 derrota y ayudas,
> §8 Coleccionauta, §10.3 claves de voz, §14 riesgos, §15.2 preguntas), `docs/minijuegos/viaje_arcade_propuesta.md`
> §7.1 (decisiones del PO, que mandan), GDD §1 (tono y salvaguardas), §2 (Cometa), §6 regla 11 y el canon del
> Coleccionauta de `docs/guiones/voces-batalla-arcoiris.md` (gafas-lupa, antenas con bolitas, mochila-torre; "¡Para
> mi colección!"; habla en grande y se equivoca en chico).
>
> **Estado**: texto propuesto, **pendiente de revisión del PO** (ver §5). No genera audio, no toca código.
> **Segunda pasada (21-Nov-2026)**: ajustado a la ficha corregida (B1-B3, M1-M16). Cambios en §7.
> Todo es **audio**: ninguna línea aparece como texto en pantalla (GDD §6.2).

- **Ids**: `viaje_` + la clave de la ficha (§10.3 y §8.2). Ejemplo: `viaje_provoca_tierra_arcoiris`.
- **Rutas de audio** (relativas a `assets/audio/`, en `.wav`): `voces/viaje/coleccionauta/<clave>.wav` y
  `voces/viaje/cometa/<clave>.wav`.
- **Reglas de escritura del Coleccionauta** (GDD §1, §6.11 y ficha §8.2): el verbo es **querer** ("quiero para mi
  colección"), nunca robar. Nada de "te voy a atrapar", "perdiste", "gané" ni "¡rápido!". Él es el torpe: se
  enreda, cuenta mal, hace hipo. Los niños nunca quedan en ridículo.
- **Reglas de Cometa** (GDD §2 y ficha §4): anima y celebra. Nunca regaña, nunca apura, nunca dice "perdiste". En el
  gag de derrota es el que se marea, para que el niño se ría de Cometa y no de sí mismo.
- **Duraciones**: cada línea del Coleccionauta cabe en **≤ 4 s** (el encuentro completo son ~8 s, ficha §8.1).
  El gag de derrota (con Cometa) suma **≤ 1,5 s** (ficha §7.1).

---

## 1. Artefactos-jefe: un objeto de la colección por ruta

El jefe de cada ruta es un **artefacto** que el Coleccionauta maneja o captura (ficha §5.3). No se destruye: se
desarma en confeti. El Coleccionauta sale de él, dice qué quiere y huye al planeta de destino (ficha §8.1).

| Ruta (origen → destino) | Artefacto-jefe (lo que ve el niño) | Cómo lo presenta el Coleccionauta | Lo que quiere para su colección | Cómo huye | Qué sale de sus 3 bolsas (destellos, ficha §9.2) |
|---|---|---|---|---|---|
| Tierra → Arcoíris | **Meteorito Dormilón**: bosteza, lanza piedritas y después rueda | Asoma por la ventanita del meteorito con sus gafas-lupa; el meteorito bosteza primero | Una estrella fugaz | Sale volando con su mochila-torre y el cielo se abre hacia Arcoíris | Piedritas que brillan |
| Arcoíris → Animalia | **Aspiradora gigante**: su boca es un chorro de viento que empuja la nave | Asoma de la boca de la aspiradora, con sus antenas de bolitas; se hace cosquillas solo | Un pincel de colores | Se va rebotando con la mochila-torre hacia Animalia, dejando una estela de rayas | Cajitas de colores |
| Animalia → Melodía | **Tocadiscos-ovni**: dispara notas y gira el disco | Asoma desde el centro del disco que gira, con hipo | Un canto de pájaro | Se va bailando hacia Melodía, con el disco girando detrás | Notitas musicales |
| Melodía → Cuenta-Cuentas | **Grúa de cubos numerados**: lanza cubos que rebotan; el cubo central tiene el punto débil | Asoma de la cabina de la grúa y cuenta con los dedos (y se confunde) | Una fila de bolitas para contar | Se va rebotando como una bolita hacia Cuenta-Cuentas | Bolitas de colores |
| Cuenta-Cuentas → Letralandia | **Torre de bloques con letras**: se apila, se derrumba en dos mitades | Asoma entre los bloques que se acomodan solos | Un libro | Sale por encima de la torre, que se vuelve a armar, hacia Letralandia | Letritas de colores |
| Letralandia → Corazón | **Globo-caritas**: cuatro caritas que cambian de color; suelta globitos | Asoma por debajo del globo, tratando de agarrar un globito | Un abrazo para su álbum | Se va flotando entre globitos hacia Corazón | Globitos de colores |
| Corazón → Coleccionauta | **Su propia nave** (modelo de HE-131; provisional hasta entonces). Sin fase de batalla: el artefacto es su nave | Sale de su nave con las bolsas colgando, se ríe | Un amigo | Se va en su nave a su planeta; las bolsas se quedan flotando | Corazoncitos de colores |

> Nota: en la ruta final el Coleccionauta no es un artefacto que se desarma: su nave se va, y lo que se
> desarma son sus bolsas (ficha §5.3, última fila).

---

## 2. Líneas del Coleccionauta por ruta (provoca y huye)

Suenan en el encuentro final (ficha §8.1). **Provoca** suena cuando el artefacto se desarma y él asoma; **huye**, cuando
sus bolsas ya salieron. La línea de "provoca" lleva su intento de atrapar algo, con gag (antena enredada o mochila que
sopla), **sin castigar a la nave**.

| Ruta | id | Texto | Intención | Dura | Dónde suena |
|---|---|---|---|---|---|
| Tierra → Arcoíris | `viaje_provoca_tierra_arcoiris` | «¡Una estrella fugaz para mi colección! ¡Ay, se me enredó la antena!» | grandilocuente, y después torpe, rascándose la antena | 3,5 s | Asoma del meteorito, tras el bostezo |
| Tierra → Arcoíris | `viaje_huye_arcoiris` | «¡Me voy a Arcoíris, que allá hay colores! ¡Chao, chao!» | contento, de paseo | 3 s | Sale volando con la mochila-torre |
| Arcoíris → Animalia | `viaje_provoca_arcoiris_animalia` | «¡Un pincel para mi colección de rayas! ¡Jijiji, me hace cosquillas!» | goloso, riéndose de sí mismo | 3,5 s | Asoma de la aspiradora |
| Arcoíris → Animalia | `viaje_huye_animalia` | «¡Animalia me llama! ¡Quiero ver a los animalitos! ¡Adiós!» | ilusionado, como niño que va al zoológico | 3,5 s | Se va rebotando |
| Animalia → Melodía | `viaje_provoca_animalia_melodia` | «¡Un canto de pájaro para mi colección! ¡Hip!» | grandilocuente, y el hipo como gag | 3 s | Asoma del disco, con hipo |
| Animalia → Melodía | `viaje_huye_melodia` | «¡Me voy a Melodía a bailar! ¡Uy, qué bonito el disco!» | feliz, cantando | 3 s | Se va bailando |
| Melodía → Cuenta-Cuentas | `viaje_provoca_melodia_cuenta_cuentas` | «¡Bolitas para contar! Una, dos… ¿cuántas eran? ¡Ustedes cuenten!» | confundido, y después invitando a los niños a contar | 4 s | Asoma de la grúa, con los dedos |
| Melodía → Cuenta-Cuentas | `viaje_huye_cuenta_cuentas` | «¡Me voy a Cuenta-Cuentas a contar bien! ¡Uno, dos, tres!» | animado, como quien aprende | 3,5 s | Se va rebotando |
| Cuenta-Cuentas → Letralandia | `viaje_provoca_cuenta_cuentas_letralandia` | «¡Un libro! ¡Léemelo tú, que yo no sé!» | goloso, después pidiendo ayuda de buena gana | 3 s | Asoma entre los bloques |
| Cuenta-Cuentas → Letralandia | `viaje_huye_letralandia` | «¡Me voy a Letralandia, que allá hay cuentos!» | entusiasta | 2,5 s | Sale por encima de la torre |
| Letralandia → Corazón | `viaje_provoca_letralandia_corazon` | «¡Un abrazo para mi álbum! ¿No cabe? ¡Qué pena!» | grandilocuente, y se queda pensando | 3,5 s | Asoma debajo del globo |
| Letralandia → Corazón | `viaje_huye_corazon` | «¡Me voy a Corazón, que allá dan abrazos de regalo!» | contento, casi cantando | 3,5 s | Se va flotando entre globitos |
| Corazón → Coleccionauta | `viaje_provoca_corazon_coleccionauta` | «¡Un amigo para mi colección! ¿Cabe en mi mochila? …¡Mmm, no cabe!» | ilusionado, después desconcertado, rascándose la cabeza | 4 s | Sale de su nave |
| Corazón → Coleccionauta | `viaje_huye_coleccionauta` | «Un amigo no cabe en mi mochila… ¿me enseñan cómo se pide? ¡Adiós!» | pausado, como quien descubre algo; sin sermón, es una pregunta | 4 s | Se va en su nave (**ver §5, punto 3**) |

### 2.1 Claves comunes del encuentro (sin texto)

| Clave | Suena | Voz | Nota |
|---|---|---|---|
| `bolsa_revienta` | cada bolsa que se toca | **Sin voz**: sonido de bolsa con tilín | Un destello por bolsa (ficha §9.2) |
| `viaje_bolsa_vacia` | la última bolsa | «¡Ay, ay, ay! ¡Se me acabó la bolsa!» (casera, ver §5) | Cómico, nunca de castigo: el niño ya ganó la bolsa |
| `gag_pinza` | el enredo de la antena o la pinza | **Sin voz**, con risa de Cometa | Dura ≤ 1 s; la nave se esquiva |
| `cometa_celebra` | Cometa baila al verlo huir | **Sin voz**: baile y tilín | Cierra el encuentro |

---

## 3. Líneas de Cometa: gag de derrota y ayudas

Cometa es el **power-up y la voz de casa** (GDD §2). Cuando el niño pierde, Cometa se marea, no el niño. Nunca dice
"perdiste", "otra vez no" ni "apúrate".

| id | Texto | Intención | Dura | Dónde suena |
|---|---|---|---|---|
| `viaje_cometa_mareado` | «¡Uuuy… qué vueltas!» | mareado, riéndose de sí mismo | 1 s | Gag de derrota, mientras la nave se desarma y la música se "desinfla" (ficha §7.1; máx. 1,5 s en Nicole y Sofía, 1,2 s en Maxi, M1) |
| `viaje_otra_vez` | «¡Otra vez! Aquí empezamos.» | alegre, con el fogonazo de la nave | 1,5 s | Al reiniciar en el checkpoint (ficha §7.2). Dice **dónde** vuelve, para que Maxi no se quede esperando (R6) |
| `viaje_regalo` | «¡Un regalo de Cometa! ¡Escudo y disparo más fuerte!» | emocionado, como quien abre un paquete | 3 s | Al reiniciar con el regalo tras 2 derrotas (Maxi y Nicole) o 3 (Sofía) (ficha §7.4). Sustituye la línea corta de la ficha, que no decía qué era el regalo |
| `viaje_descanso` | «¿Descansamos un ratito?» | tranquilo, como pregunta de amigo, sin apuro | 1,5 s | Al aparecer el icono de descanso (Nicole tras 3 derrotas, Sofía tras 4), en el checkpoint y con pantalla vacía. El icono es de 96 px en el HUD (esquina superior derecha): no hay pantalla, ni botones, ni tiempo límite (ficha §7.4 y §10.3). La línea no dice "cuando quieran" para no sonar a plazo |
| `viaje_cometa_al_volante` | «¡Brrrum! ¡Cometa al volante! ¡Hoy vienen de a poquito!» | cantarín, como coche de juguete que arranca | ~4 s | **Solo Maxi**, al reiniciar tras 3 derrotas, con pantalla vacía (ficha §7.4). La ayuda baja la frecuencia de enemigos a la mitad, no la velocidad: por eso "de a poquito" y no "despacito". Sin tropiezo: en la ayuda los golpes suenan solo "boing" (M5). Maxi ama los autos (perfil), y "Brrrum" le da la idea de ayuda |
| `viaje_aviso_jefe` | «¡Cuidado, se prepara!» | alerta, sin asustar | ~1,5 s | En el checkpoint antes del jefe, con pantalla vacía (ficha §3 y §10.3). Durante la telegrafía del jefe solo suenan sonido y brillo (M8). Lo dice Cometa, un aviso de amigo y no una amenaza (GDD §1). Ver §5, punto 13 (la ficha pide ≤ 1 s) |

---

## 4. Guion de grabación (tabla lista para papá o mamá)

Todas las líneas son **nuevas** (ninguna está grabada). Cada una tiene su id estable y su archivo.

| id | Personaje | Texto | Intención | Dónde suena | Grabación propuesta |
|---|---|---|---|---|---|
| `viaje_provoca_tierra_arcoiris` | Coleccionauta | «¡Una estrella fugaz para mi colección! ¡Ay, se me enredó la antena!» | grandilocuente, después torpe | Meteorito, tras el bostezo | casera (papá) — §5.1 |
| `viaje_huye_arcoiris` | Coleccionauta | «¡Me voy a Arcoíris, que allá hay colores! ¡Chao, chao!» | contento | Sale volando | casera (papá) |
| `viaje_provoca_arcoiris_animalia` | Coleccionauta | «¡Un pincel para mi colección de rayas! ¡Jijiji, me hace cosquillas!» | goloso, riéndose | Aspiradora | casera (papá) |
| `viaje_huye_animalia` | Coleccionauta | «¡Animalia me llama! ¡Quiero ver a los animalitos! ¡Adiós!» | ilusionado | Se va rebotando | casera (papá) |
| `viaje_provoca_animalia_melodia` | Coleccionauta | «¡Un canto de pájaro para mi colección! ¡Hip!» | grandilocuente, con hipo | Tocadiscos | casera (papá) |
| `viaje_huye_melodia` | Coleccionauta | «¡Me voy a Melodía a bailar! ¡Uy, qué bonito el disco!» | feliz | Se va bailando | casera (papá) |
| `viaje_provoca_melodia_cuenta_cuentas` | Coleccionauta | «¡Bolitas para contar! Una, dos… ¿cuántas eran? ¡Ustedes cuenten!» | confundido, invitando | Grúa | casera (papá) |
| `viaje_huye_cuenta_cuentas` | Coleccionauta | «¡Me voy a Cuenta-Cuentas a contar bien! ¡Uno, dos, tres!» | animado | Se va rebotando | casera (papá) |
| `viaje_provoca_cuenta_cuentas_letralandia` | Coleccionauta | «¡Un libro! ¡Léemelo tú, que yo no sé!» | goloso, pide ayuda | Torre de bloques | casera (papá) |
| `viaje_huye_letralandia` | Coleccionauta | «¡Me voy a Letralandia, que allá hay cuentos!» | entusiasta | Sale por la torre | casera (papá) |
| `viaje_provoca_letralandia_corazon` | Coleccionauta | «¡Un abrazo para mi álbum! ¿No cabe? ¡Qué pena!» | grandilocuente, pensando | Globo-caritas | casera (papá) |
| `viaje_huye_corazon` | Coleccionauta | «¡Me voy a Corazón, que allá dan abrazos de regalo!» | contento | Globitos | casera (papá) |
| `viaje_provoca_corazon_coleccionauta` | Coleccionauta | «¡Un amigo para mi colección! ¿Cabe en mi mochila? …¡Mmm, no cabe!» | ilusionado, desconcertado | Su nave | casera (papá) |
| `viaje_huye_coleccionauta` | Coleccionauta | «Un amigo no cabe en mi mochila… ¿me enseñan cómo se pide? ¡Adiós!» | pausado, pregunta | Se va en su nave | casera (papá) — §5.3 |
| `viaje_bolsa_vacia` | Coleccionauta | «¡Ay, ay, ay! ¡Se me acabó la bolsa!» | cómico | Última bolsa | casera (papá) |
| `viaje_cometa_mareado` | Cometa | «¡Uuuy… qué vueltas!» | mareado, riéndose | Gag de derrota | TTS de Cometa, o casera si la familia la graba (§5.1) |
| `viaje_otra_vez` | Cometa | «¡Otra vez! Aquí empezamos.» | alegre | Reinicio | TTS de Cometa |
| `viaje_regalo` | Cometa | «¡Un regalo de Cometa! ¡Escudo y disparo más fuerte!» | emocionado | Reinicio con regalo | TTS de Cometa |
| `viaje_descanso` | Cometa | «¿Descansamos un ratito?» | tranquilo, sin apuro | Aparece el icono de descanso, en el checkpoint | TTS de Cometa |
| `viaje_cometa_al_volante` | Cometa | «¡Brrrum! ¡Cometa al volante! ¡Hoy vienen de a poquito!» | cantarín | Reinicio, solo Maxi | TTS de Cometa |
| `viaje_aviso_jefe` | Cometa | «¡Cuidado, se prepara!» | alerta, sin asustar | Checkpoint antes del jefe | TTS de Cometa |

**Total**: 21 líneas nuevas (15 del Coleccionauta, incluida `viaje_bolsa_vacia`, y 6 de Cometa).
Sin voz: `bolsa_revienta`, `gag_pinza`, `cometa_celebra` (ver §2.1).

### 4.1 Reglas de voz en acción (M8) y cortes

- **Intros** (`intro_maxi`, `intro_nicole`, `intro_sofia`, ficha §10.3): **se saltan con un toque** (M13). Graben
  **cada intro en su propio archivo**, sin silencio inicial de más de 0,2 s, para que el juego corte limpio.
  Todavía no tienen texto en este guion (ver §5, punto 11).
- Ninguna línea de esta tabla dura ≤ 0,5 s, así que **todas suenan en pantalla vacía** o en el gag de derrota.
  En el gag la nave ya se desarmó, así que no hay disparo que tapar.
- **Encuentro del Coleccionauta**: suena con pantalla sin enemigos ni balas (ficha §8.1). La nave aún puede
  disparar a las bolsas durante la línea: ver §5, punto 10.
- **Reinicios** (`viaje_otra_vez`, `viaje_regalo`, `viaje_descanso`, `viaje_cometa_al_volante`): la voz suena en el
  checkpoint con pantalla vacía, y la **primera oleada entra al terminar la voz**, como `sector_inicio` (ficha §10.3).
  Propuesta de este guion, ver §5, punto 12.
- **Orden de voces del encuentro**: `viaje_bolsa_vacia` y `viaje_huye_*` no se pisan. La huida empieza cuando
  termina la línea de la última bolsa, si ya sonó.
- **Tocar a Cometa** repite su última línea (M7). Si esa línea suena con la nave disparando, aplica el punto 10 de §5.

---

## 5. Pendientes para el PO y otros roles

1. **Voz del Coleccionauta (decisión del PO)**. El canon de la batalla (`voces-batalla-arcoiris.md`) dice que el
   Coleccionauta es **la grabación casera de papá**, con registro grandilocuente-tonto, y que las dos voces del
   mismo personaje deben ser una sola. La ficha §10.3 pide TTS provisional. **Propuesta**: papá graba las 15 líneas
   del Coleccionauta, así el mismo personaje suena igual en la batalla y en el viaje. Costo: ninguno si lo graba
   papá; si se usa TTS, requiere el OK del PO y `--estimar` antes de generar.
2. **Voz de Cometa**: TTS de fal.ai, con OK del PO sobre el costo y `--estimar` antes de generar (regla de costos).
   La grabación de la familia sigue siendo lo ideal (GDD §2 y voz de Cometa en la sección de audio), pero es decisión del PO.
3. **Lección final** (`viaje_huye_coleccionauta`): «…¿me enseñan cómo se pide?» hace la lección con una pregunta a los
   niños, sin sermón. Si el PO prefiere una frase más cerrada, la alternativa sería «¡Adiós, amigos!» solo. Lo decide el PO.
4. **Canon de captura**: la ficha §8.1-§8.2 habla de "pinza" y "red" para atrapar la nave. El canon de la batalla dice
   **sin red y sin nave-aspiradora** en el Coleccionauta. Propuesta de este guion: que capture con la **antena** y la
   **mochila-torre** (el "Sluurp" de la batalla). La pinza de la nave final queda como parte de su nave (ficha §5.3).
   Confirmar con `disenador-mecanicas` y el PO.
5. **"Un amigo para mi colección"** (`viaje_provoca_corazon_coleccionauta`): el Coleccionauta quiere un amigo y se
   equivoca al guardarlo. Es el gag de la lección, pero conviene que `experto-ux-parvulo` confirme que se lee como
   torpe y no como burla hacia los niños.
6. **Cambio respecto a la ficha**: en `viaje_huye_animalia` se cambió "tiene animalitos para mí" por "quiero ver a
   los animalitos", para que no suene a que colecciona animales. Confirmar.
7. **"Cometa al volante"** (R4 de la ficha): la línea dice "hoy vienen de a poquito", que describe la ayuda (la mitad
   de enemigos) sin decir que el juego juega por Maxi. Se quitó "despacito" porque la ayuda no baja la velocidad
   (ficha §7.4). Sin tropiezo (M5). `experto-ux-parvulo` debe confirmarlo con el perfil de Maxi.
8. **Número de rutas** (ficha §15.2, pregunta 2): este guion asume 7 rutas, incluida Corazón → Coleccionauta. Si el PO
   decide otra cosa, se quitan las filas correspondientes.
9. **Papá no aparece** en ninguna línea del viaje, igual que en la batalla (canon "nunca menciona a papá"). Papá
   sigue en las video-llamadas (GDD §1), que están fuera de este guion.
10. **Disparo bajo la voz** (M8): en el encuentro, la pantalla no tiene enemigos, pero la nave sigue disparando a las
    bolsas durante 3-4 s, y la repetición de Cometa (M7) puede caer en plena acción. Propuesta: bajar solo el pium
    (no la voz) unos 12 dB mientras suena la línea. Lo decide `disenador-mecanicas` con el PO (ficha §8.1 y §10.2).
11. **Líneas sin guion todavía**: la ficha §10.3 pide además `intro_maxi`, `intro_nicole`, `intro_sofia`,
    `sector_inicio` (1, 2, 3), `sector_listo`, `record` y `primer_record`, y la despedida de Cometa al tocar el icono
    de descanso (ficha §4, "Cometa dice adiós"). Este ajuste no las escribe (no estaban en el encargo). Quedan para
    la siguiente pasada de `guionista`.
12. **Duración de las voces de reinicio** (M1): `viaje_otra_vez` (1,5 s) y `viaje_cometa_al_volante` (~4 s) pasan del
    reinicio de ≤ 0,8 s de Maxi y ≤ 0,5 s de los demás (ficha §7.2). Propuesta: la voz no cuenta en ese tiempo y la
    primera oleada entra al terminar la voz, con un mínimo de 2 s. La ficha debe decirlo. Si no, `viaje_otra_vez`
    pasa a «¡Otra vez!» (~0,6 s).
13. **Aviso del jefe** (`viaje_aviso_jefe`, ~1,5 s): la ficha §10.3 pide ≤ 1 s, y «¡Cuidado, se prepara!» no entra en
    1 s. Opciones: (a) aceptar 1,5 s y que el jefe empiece a telegrafiar 1,5 s después; (b) acortar a «¡Se prepara!»
    (~0,8 s). Lo decide el PO con la ficha.

---

## 6. Sin texto en pantalla (control)

Ninguna línea de este guion se muestra escrita. Las instrucciones y avisos del viaje llegan por voz (ficha §13,
criterio 12). El texto de las tablas es solo para grabar.

---

## 7. Registro del ajuste HE-134 (segunda pasada, 21-Nov-2026)

| # | Cambio | Dónde |
|---|---|---|
| 1 | `viaje_descanso`: se quita "son dos botones". Es un icono de 96 px en el HUD (Nicole tras 3 derrotas, Sofía tras 4), sin pantalla y sin tiempo límite. Línea nueva: «¿Descansamos un ratito?» | §3, §4 |
| 2 | `viaje_cometa_al_volante` sin tropiezo (en la ayuda, solo "boing"). Línea con "de a poquito" (frecuencia, no velocidad) | §3, §4, §5 punto 7 |
| 3 | `viaje_aviso_jefe` pasa al checkpoint antes del jefe, con pantalla vacía. Es una línea nueva de Cometa | §3, §4, §5 punto 13 |
| 4 | Intros saltables con un toque: nota de corte para grabar | §4, §4.1 |
| 5 | Reglas M8 por línea: todas en pantalla vacía o en el gag; reinicios con la primera oleada después de la voz (propuesta) | §4.1, §5 puntos 10-13 |

Se mantienen las demás líneas. Se añade la nota del caso de Maxi en el gag (1,2 s, M1). Pendiente de la ficha y del PO: §5.
