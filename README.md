# Jenkins + Docker: Guía práctica para agentes

Breve paquete de entrenamiento para configurar Jenkins con soporte Docker en agentes, evitar errores comunes y seguir buenas prácticas.

Contenido:
- `runbook.md` — diagnóstico y soluciones rápidas (errores comunes).
- `docker-compose.yml` — demo para levantar Jenkins + agente con socket montado.
- `Jenkinsfile.example` — pipeline que usa Docker de forma segura.
- `checklist.md` — verificación previa al despliegue.

Idioma: Español. Sigue los pasos del `runbook.md` si tu pipeline muestra `permission denied` con `/var/run/docker.sock`.

Credenciales temporales (local, solo para pruebas)
- **Jenkins**: usuario `admin_reset` / contraseña `Cambiar123!` (creado por init script). Elimina o cambia la cuenta tras recuperar acceso.
- **Grafana (si instalaste)**: usuario `admin` / contraseña `admin` (valor por defecto). Cambia la contraseña en la primera entrada.

Notas de seguridad:
- No documentes credenciales en repositorios públicos.
- Estas credenciales son solo para entornos locales y de prueba; revoca/actualiza en entornos reales.

