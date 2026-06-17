# Runbook: errores comunes y soluciones rápidas

1) Error: `docker: not found`
- Causa: el cliente Docker no está instalado en la imagen del agente.
- Solución: instalar `docker-cli` en la imagen o montar el binario del host. Ejemplo en `Dockerfile`:
  - instalar `docker-ce-cli` desde repositorio oficial o `apt-get install docker.io` y crear symlink `/usr/bin/docker`.

2) Error: `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`
- Causa: el usuario que ejecuta el proceso (ej. `jenkins`) no pertenece al grupo que tiene permisos sobre el socket del host.
- Diagnóstico rápido:
  - En host: `stat -c "%U:%G %a" /var/run/docker.sock` y `getent group docker`.
  - En contenedor: `id jenkins`, `ls -l /var/run/docker.sock`.
- Soluciones:
  - Opción A (recomendada para tests): ejecutar contenedor con `--group-add $(getent group docker | cut -d: -f3)` y montar el socket.
  - Opción B: mapear GID del host al contenedor y crear el grupo con ese GID: `groupadd -g $DOCKER_GID docker && usermod -aG docker jenkins`.
  - Opción C: ajustar permisos del socket en host (temporal): `sudo chmod 666 /var/run/docker.sock` (no recomendado en producción).

3) Error: versiones incompatibles o librerías faltantes
- Causa: cliente `docker` en contenedor necesita libs del host o la imagen es mínima.
- Solución: instalar `docker-cli` desde repo oficial en la imagen o montar el binario del host junto con librerías necesarias.

4) Contenedores huérfanos / nombres en uso
- `Conflict. The container name "/jenkins-lts" is already in use` → `docker rm -f jenkins-lts` antes de recrear.

5) Buenas prácticas rápidas
- Prefiere agentes dedicados para builds con Docker (no el master).
- Usa `docker` CLI instalado en la imagen del agente o agentes con Docker preconfigurado.
- Prefiere `--group-add` con GID del grupo `docker` del host en vez de chmod 666 en socket.
