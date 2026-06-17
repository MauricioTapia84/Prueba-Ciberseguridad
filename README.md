# Jenkins + Docker: Guía práctica para agentes

Este repositorio contiene un flujo DevSecOps local basado en Docker Compose, con Jenkins, OWASP ZAP, Prometheus, Grafana y una aplicación bajo prueba.

## Qué incluye

- `docker-compose.yml` — orquesta Jenkins, app, ZAP, Prometheus y Grafana.
- `Dockerfile.jenkins` — Jenkins preparado para usar Docker en el agente.
- `Jenkinsfile` — pipeline final para build, test, DAST y verificación.
- `run-all.sh` — inicia el stack completo y valida salud básica.
- `run-dast.sh` — ejecuta un scan ZAP y genera reportes en `reports/zap/`.
- `validate-monitoring.sh` — comprueba Prometheus, Grafana y scrapeo.
- `clean.sh` — detiene y elimina el stack de Docker Compose.

## Flujo recomendado

1. Levanta el stack completo:
   ```bash
   ./run-all.sh
   ```
   - Construye y arranca Jenkins, app, Prometheus, Grafana y ZAP.
   - Usa healthchecks para validar la disponibilidad de los servicios.

2. Corre el análisis DAST:
   ```bash
   ./run-dast.sh
   ```
   - Genera `reports/zap/zap-full-report.html`, `reports/zap/zap-full-report.json` y `reports/zap/zap-full-report.xml`.

3. Verifica monitoreo y scrapeo:
   ```bash
   ./validate-monitoring.sh
   ```
   - Confirma que la app responde en `http://localhost:8081`.
   - Confirma que Prometheus responde en `http://localhost:9090`.
   - Confirma que Grafana responde en `http://localhost:3000`.
   - Valida que Prometheus scrapea la app.

4. Limpia el entorno:
   ```bash
   ./clean.sh
   ```

## Puertos expuestos

- Jenkins: `http://localhost:8080`
- App bajo prueba: `http://localhost:8081`
- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- OWASP ZAP API: `http://localhost:8090`

## Docker Compose

`docker-compose.yml` ahora incluye:

- `depends_on` para asegurar el orden de arranque entre `app-under-test`, `prometheus`, `grafana` y `zap`.
- `healthcheck` configurados para `app-under-test`, `prometheus`, `grafana`, `zap` y `jenkins`.
- red compartida `devsecops_net` para que los contenedores se descubran internamente.

## Jenkins Pipeline final

El `Jenkinsfile` ejecuta:

1. checkout del código.
2. creación de entorno y build de la imagen Docker de la app.
3. ejecución de tests con `pytest` y publicación de resultados JUnit.
4. arranque de la app de prueba en un contenedor Docker.
5. escaneo DAST con ZAP en la misma red.
6. limpieza del contenedor de la app después del scan.

Los artefactos generados se archivan desde `reports/**`.

## Si algo falla

- Usa `docker compose ps` y `docker compose logs <servicio>`.
- Revisa los reports en `reports/zap/`.
- Si Jenkins no arranca, confirma `/var/run/docker.sock` montado y permisos.

## Notas de seguridad

- No commits credenciales ni datos sensibles.
- El cluster está pensado para pruebas locales; en producción usa secretos y credenciales seguras.


