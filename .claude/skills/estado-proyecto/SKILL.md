---
name: estado-proyecto
description: Entrega un resumen ejecutivo del estado del roadmap de desarrollo activo (docs/TABLERO.md), sea cual sea el proyecto en curso. Usar cuando el usuario pregunte "cómo vamos", "en qué estamos", "estado del proyecto", o quiera una vista rápida del tablero sin modificarlo. Solo lectura, no edita nada.
---

# Estado del proyecto (solo lectura)

1. Lee `docs/TABLERO.md` completo y, si el encabezado referencia un documento de diseño/roadmap, revísalo para contexto adicional.
2. Reporta en este orden, breve y en español:
   - **Fase/épica activa y % de avance** (tarjetas ✅ vs total del roadmap).
   - **En curso (WIP)** y si respeta el límite declarado en el tablero.
   - **Bloqueos** activos y qué los destraba.
   - **Próximas 2-3 tarjetas** según prioridad y dependencias.
   - **Criterio de salida** de la fase/épica activa (para saber cuándo pasa a la siguiente).
3. No muevas tarjetas ni edites archivos. Si detectas inconsistencias (ej: WIP excedido, tarjeta hecha sin registrar), señálalas y sugiere correr `/avance`.
