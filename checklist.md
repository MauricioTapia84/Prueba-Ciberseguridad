# Checklist de despliegue: Jenkins + Docker agents

- [ ] `docker` CLI disponible en la imagen del agente (`docker --version`).
- [ ] `/var/run/docker.sock` montado si se usa socket: `-v /var/run/docker.sock:/var/run/docker.sock`.
- [ ] El usuario del build pertenece al grupo con permisos sobre el socket: `id jenkins` debe incluir `docker`.
- [ ] Si usas mount, lanza contenedor con `--group-add $(getent group docker | cut -d: -f3)`.
- [ ] Evita `chmod 666 /var/run/docker.sock` en producción.
- [ ] Verifica nombres de contenedores antes de `docker run` para evitar conflictos.
- [ ] Mantén versiones compatibles entre `docker` client y daemon.
