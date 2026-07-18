---
name: avance
description: Registra avances del roadmap de desarrollo activo en el tablero Kanban (docs/TABLERO.md), sea cual sea el proyecto o fase en curso. Usar cuando el usuario reporte trabajo completado o en progreso ("terminé la historia X", "registra el avance", "actualiza el tablero", "marca X como hecho"), o al cerrar una sesión de trabajo donde se completaron historias.
---

# Registrar avance en el tablero

**Regla no negociable**: en cuanto una tarjeta quede completada y validada en la sesión (tests pasando y/o verificación manual hecha), invoca este skill de inmediato, en el mismo turno donde reportas el resultado. NUNCA termines el turno preguntando "¿registro el avance?", "¿le pido a scrum-master que cierre la tarjeta?" o equivalente — eso ya está autorizado de antemano por el usuario. Regístralo y luego informa lo que se hizo.

Delega la actualización al agente `scrum-master` (vía Agent tool), entregándole en el prompt:

1. **Qué se avanzó**: IDs de las tarjetas (usa el formato de ID que ya use el tablero) y descripción concreta de lo hecho en esta sesión.
2. **Evidencia para la Definición de Hecho**: resultado real de pruebas o validación (pasaron/fallaron), documentación creada, validación manual si aplica.
3. **Quién**: Product Owner o Dev.

El agente moverá las tarjetas, actualizará ESTADO ACTUAL y agregará la entrada al Registro de Avances.

## Al recibir la respuesta del agente

- Releva al usuario: tarjetas movidas, estado del WIP, próxima tarjeta recomendada y bloqueos.
- Si el agente indica que el avance responde una "pregunta abierta" del documento de diseño/roadmap referenciado por el tablero, actualiza tú esa sección del documento (el scrum-master no edita fuera del tablero).

## Regla

No registres avances sin evidencia: si el usuario dice "terminé X" pero no hay forma de verificarlo, regístralo igual pero indica en la nota que la verificación de DoD está pendiente.
