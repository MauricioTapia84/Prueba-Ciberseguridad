# Jenkins + Docker: Guía práctica para agentes

Breve paquete de entrenamiento para configurar Jenkins con soporte Docker en agentes, evitar errores comunes y seguir buenas prácticas.

Contenido:
- `runbook.md` — diagnóstico y soluciones rápidas (errores comunes).
- `docker-compose.yml` — demo para levantar Jenkins + agente con socket montado.
- `Jenkinsfile.example` — pipeline que usa Docker de forma segura.
- `checklist.md` — verificación previa al despliegue.

Idioma: Español. Sigue los pasos del `runbook.md` si tu pipeline muestra `permission denied` con `/var/run/docker.sock`.
