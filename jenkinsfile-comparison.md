# Comparación de Jenkinsfile con `safe_pipeline`

Este documento explica qué se mejoró en el `Jenkinsfile` de este repositorio y cómo se compara con el flujo de referencia `safe_pipeline`.

## Cambios clave del `Jenkinsfile`

- `agent any` mantiene compatibilidad con agentes Jenkins que ejecutan Docker.
- El pipeline ya no usa `|| true` en pasos críticos de build/test para que los errores reales rompan la ejecución.
- Se creó un entorno virtual Python local y se instala `requirements.txt` antes de ejecutar `pytest`.
- Se construye la imagen Docker de la aplicación con `docker build -t ${DOCKER_IMAGE} .` desde el workspace.
- El análisis DAST se ejecuta con `ghcr.io/zaproxy/zaproxy:stable` en lugar de una imagen `owasp/zap2docker-stable` problemática.
- El escaneo ZAP y la app se levantan en la red Docker compartida `devsecops_net`.
- El reporte OWASP ZAP se guarda en `reports/zap/` en formato HTML, JSON y XML.

## Comparación con `safe_pipeline`

| Área | Este repositorio | `safe_pipeline` referencia |
|---|---|---|
| Orquestación | `docker-compose.yml` único con Jenkins, Grafana, Prometheus, ZAP y app | `docker-compose.yml` centralizado para todo el stack |
| Uso de Docker en Jenkins | Jenkins con socket montado y image build local | Jenkins con Docker-in-Docker o host Docker socket según referencia |
| Manejo de errores | Sin `|| true` en pasos esenciales; `set -eux` en scripts | Buena práctica: fallar temprano en build/test/scans |
| DAST | Imagen `ghcr.io/zaproxy/zaproxy:stable` y scan `zap-full-scan.py` | Scan ZAP en contenedor separado conectado a la misma red |
| Reportes | `reports/test-results.xml` + `reports/zap/` | Reportes guardados y archivados en un directorio dedicado |
| Monitoreo | Prometheus + Grafana declarados en Compose | Similar: monitoreo host + servicios dentro de red común |

## Recomendaciones de alineación

- Mantener `docker-compose.yml` como orquestador principal y no dividir el stack en múltiples Compose files innecesarios.
- Controlar versiones de imágenes base en `docker-compose.yml` para evitar cambios sorpresa.
- Añadir `agent { docker { image 'docker:latest' } }` solo si el pipeline se ejecuta en un agente sin acceso al socket Docker del host.
- Registrar credenciales y accesos temporales en documentación separada, no en código fuente.

## Conclusión

El nuevo `Jenkinsfile` está alineado con `safe_pipeline` al:
- evitar falsos positivos de pipeline,
- usar la misma red Docker para app y ZAP,
- crear artefactos visibles en `reports/`,
- conectar Jenkins con el host Docker correctamente para builds y scans.
