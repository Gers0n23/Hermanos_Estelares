---
name: planificar
description: Refina el backlog y selecciona el siguiente entregable del roadmap de desarrollo activo (docs/TABLERO.md), sea cual sea. Usar cuando el usuario diga "qué tomamos ahora", "planifiquemos lo que sigue", "refinemos el backlog", al completar una tarjeta y necesitar la siguiente, o al cambiar de fase.
---

# Planificar el siguiente entregable

Delega al agente `scrum-master` (vía Agent tool) con este encargo:

1. Leer `docs/TABLERO.md` y, si lo referencia, el documento de diseño/roadmap vinculado, y verificar el estado real del WIP.
2. Proponer la(s) siguiente(s) tarjeta(s) a tomar, justificando con: prioridad de la fase/épica activa, dependencias satisfechas (según la columna "Dependencias" del tablero), y criterio de salida de la fase/épica activa.
3. Si la tarjeta elegida es grande, descomponerla en subtareas concretas dentro del tablero, manteniendo el esquema de IDs que ya use ese tablero (no inventes uno nuevo).
4. Señalar bloqueos que impidan avanzar y quién debe resolverlos (Product Owner o Dev).

## Al recibir la respuesta del agente

- Presenta al usuario la recomendación con su justificación y pide confirmación para iniciar.
- Confirmada la tarjeta: si es de desarrollo, ejecútala con el agente de desarrollo del repo (revisa `.claude/agents/` para identificar cuál aplica al stack de este proyecto); si es de negocio/decisión (responsable Product Owner), entrégale al usuario las preguntas concretas que debe resolver.
