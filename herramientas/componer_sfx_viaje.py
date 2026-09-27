"""Efectos de sonido chiptune del viaje estelar "arcade" (disparos, explosiones, vidas,
poderes y jefe), sintetizados en código con las mismas voces de consola que la música
(`componer_chiptune.py`): sin costo, sin APIs y 100% originales.

Pedido del PO 27-Sep-2026: "que se parezca un poco a los juegos antiguos de nave tipo
galaga... que sea divertido, no solo una transición".

Todos son cortos, suaves (sin chirridos agudos) y con volumen contenido: el disparo suena
muchas veces por segundo, así que es el más bajito y corto.

Genera en assets/audio/sfx/viaje/:
  disparo.ogg        "pew" corto descendente
  golpe.ogg          toquecito sobre una roca que aún no se rompe
  explosion.ogg      roca/basura que se rompe (ruido + caída)
  pierde_corazon.ogg la nave pierde un corazón (dos notas bajando, nada dramático)
  averia.ogg         se acabaron los corazones: la nave se desarma (glissando cómico)
  reparada.ogg       Cometa arregla la nave (arpegio subiendo)
  poder.ogg          recoger el poder de triple disparo
  corazon.ogg        recoger un corazón
  jefe.ogg           aparece el meteorito gigante
  jefe_explota.ogg   se rompe el meteorito gigante (explosión larga + fanfarria)
  escuadrilla.ogg    se rompe una escuadrilla completa (bonus)

Uso:  python herramientas/componer_sfx_viaje.py
"""
from pathlib import Path

import numpy as np

from componer_chiptune import FS, envolvente, escribir_ogg, frecuencia, pulso, ruido, triangulo

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "assets" / "audio" / "sfx" / "viaje"


def muestras(segundos: float) -> int:
    return int(segundos * FS)


def barrido(desde: float, hasta: float, segundos: float, ciclo=0.25) -> np.ndarray:
    """Pulso cuya nota MIDI va de `desde` a `hasta` (glissando)."""
    n = muestras(segundos)
    notas = np.linspace(desde, hasta, n)
    fase = np.cumsum(frecuencia(notas)) / FS
    return np.where(np.mod(fase, 1.0) < ciclo, 1.0, -1.0)


def caida(n: int, velocidad: float) -> np.ndarray:
    return np.exp(-np.arange(n) / FS * velocidad)


def secuencia(notas, paso: float, ciclo=0.25, voz="pulso") -> np.ndarray:
    """Notas MIDI seguidas, cada una de `paso` segundos."""
    n = muestras(paso)
    partes = []
    for nota in notas:
        onda = pulso(nota, n, ciclo) if voz == "pulso" else triangulo(nota, n)
        partes.append(onda * envolvente(n, caida=paso * 0.8, sostén=0.5, relajo=0.01))
    return np.concatenate(partes)


def normalizar(pista: np.ndarray, pico: float) -> np.ndarray:
    # paso bajo suave de un polo (igual que `pulir` de la música, sin loop circular)
    salida = np.empty_like(pista)
    previo = 0.0
    for i, x in enumerate(pista):
        previo = previo + 0.5 * (x - previo)
        salida[i] = previo
    cola = min(len(salida), muestras(0.01))
    salida[-cola:] *= np.linspace(1, 0, cola)
    return salida / np.max(np.abs(salida)) * pico


def mezclar(*pistas) -> np.ndarray:
    largo = max(len(p) for p in pistas)
    total = np.zeros(largo)
    for p in pistas:
        total[: len(p)] += p
    return total


def sfx_disparo():
    s = barrido(88, 70, 0.09, 0.125)
    return normalizar(s * caida(len(s), 30), 0.28)


def sfx_golpe():
    n = muestras(0.07)
    s = mezclar(ruido(n, 3, 0.6) * caida(n, 60), 0.6 * pulso(60, n, 0.5) * caida(n, 50))
    return normalizar(s, 0.35)


def sfx_explosion():
    n = muestras(0.38)
    s = mezclar(ruido(n, 7, 0.75) * caida(n, 9), 0.5 * barrido(55, 36, 0.38, 0.5) * caida(n, 10))
    return normalizar(s, 0.5)


def sfx_pierde_corazon():
    s = secuencia([67, 60], 0.12, 0.5, "pulso")
    return normalizar(s, 0.4)


def sfx_averia():
    s = barrido(79, 43, 0.9, 0.25)
    wobble = 0.5 + 0.5 * np.sin(np.arange(len(s)) / FS * 2 * np.pi * 9)
    n = muestras(0.3)
    boom = ruido(n, 11, 0.8) * caida(n, 12)
    return normalizar(mezclar(s * wobble * caida(len(s), 2.5), boom), 0.5)


def sfx_reparada():
    return normalizar(secuencia([72, 76, 79, 84, 88], 0.07), 0.45)


def sfx_poder():
    return normalizar(mezclar(secuencia([72, 79, 84, 91], 0.06, 0.125),
                              0.5 * secuencia([60, 67, 72, 79], 0.06, 0.5, "triangulo")), 0.45)


def sfx_corazon():
    return normalizar(secuencia([76, 84], 0.09, 0.25), 0.45)


def sfx_jefe():
    # tres notas graves "¡oh, oh!" más cómicas que amenazantes
    return normalizar(secuencia([48, 47, 48, 55], 0.14, 0.5, "triangulo"), 0.55)


def sfx_jefe_explota():
    n = muestras(0.8)
    boom = ruido(n, 13, 0.8) * caida(n, 4.5)
    fanfarria = np.concatenate([np.zeros(muestras(0.35)), secuencia([72, 76, 79, 84, 84], 0.09)])
    return normalizar(mezclar(boom, 0.7 * fanfarria), 0.55)


def sfx_escuadrilla():
    return normalizar(secuencia([79, 84, 88, 91], 0.055, 0.125), 0.4)


def main() -> None:
    SALIDA.mkdir(parents=True, exist_ok=True)
    efectos = {
        "disparo": sfx_disparo, "golpe": sfx_golpe, "explosion": sfx_explosion,
        "pierde_corazon": sfx_pierde_corazon, "averia": sfx_averia, "reparada": sfx_reparada,
        "poder": sfx_poder, "corazon": sfx_corazon, "jefe": sfx_jefe,
        "jefe_explota": sfx_jefe_explota, "escuadrilla": sfx_escuadrilla,
    }
    for nombre, crear in efectos.items():
        pista = crear()
        escribir_ogg(SALIDA / f"{nombre}.ogg", pista)
        print(f"{nombre}.ogg  {len(pista) / FS:.2f} s")


if __name__ == "__main__":
    main()
