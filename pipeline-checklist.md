# Checklist de Pipeline DevSecOps

Este checklist cubre la configuración y ejecución del flujo completo en Docker, incluyendo Jenkins, Grafana, Prometheus, OWASP ZAP y la aplicación bajo prueba.

## 1. Infraestructura de Docker
- [ ] Tener Docker y Docker Compose instalados en la máquina host.
- [ ] Revisar que el archivo `docker-compose.yml` esté presente y válido.
- [ ] Confirmar que el archivo `Dockerfile.jenkins` sea un Dockerfile único y válido.
- [ ] Confirmar que el archivo `Dockerfile` de la app está presente y construye la aplicación correctamente.
- [ ] Comprobar que los volúmenes esperados están declarados: `jenkins_home`, `grafana_data`.
- [ ] Confirmar que Prometheus está incluido en el `docker-compose.yml` y expone el puerto `9090`.

## 2. Servicios ejecutados con Compose
- [ ] Ejecutar `docker compose build` sin errores.
- [ ] Ejecutar `docker compose up -d` y verificar los servicios:
  - Jenkins en `http://localhost:8080`
  - Grafana en `http://localhost:3000`
  - Prometheus en `http://localhost:9090`
  - ZAP en `http://localhost:8090`
  - App en `http://localhost:8081`
- [ ] Confirmar que Jenkins arranca con acceso a `/var/run/docker.sock`.
- [ ] Confirmar que Grafana y Prometheus están conectados a la misma red de Docker.
- [ ] Verificar que ZAP arranca en modo daemon y escucha en el puerto `8090`.

## 3. Aplicación bajo prueba
- [ ] Confirmar que la app se construye con `docker build -t pruebaciberseguridad:latest .` o mediante Compose.
- [ ] Probar la app en `http://localhost:8081`.
- [ ] Comprobar healthcheck si está disponible.
- [ ] Ejecutar manualmente un request simple para validar la app.

## 4. Jenkins y pipeline
- [ ] Confirmar que el `Jenkinsfile` usa `agent any` y rutas relativas del workspace.
- [ ] Verificar que el pipeline no silencie errores críticos con `|| true` en pasos importantes.
- [ ] Confirmar que los pasos usan `docker build`, `pytest`, `docker run` y `zap` de forma consistente con el stack Compose.
- [ ] Verificar que el `Jenkinsfile` genera artefactos en `reports/` y que se archivan.
- [ ] Confirmar que el pipeline puede usar el contenedor Jenkins con Docker montado.

## 5. OWASP ZAP / DAST
- [ ] Confirmar que el servicio ZAP está disponible en `http://localhost:8090`.
- [ ] Verificar que el pipeline ejecuta un scan básico o spider contra la app.
- [ ] Confirmar que el reporte ZAP se guarda en `reports/zap/`.
- [ ] Verificar la existencia de los archivos `zap-report-local.html` o `zap-report.xml`.

## 6. Prometheus y monitoreo
- [ ] Confirmar que Prometheus levanta con `docker compose up -d`.
- [ ] Verificar que `prometheus.yml` está montado correctamente.
- [ ] Verificar que la app expone métricas y que Prometheus las scrapea.
- [ ] Verificar que Grafana arranca y puede conectarse a Prometheus.
- [ ] Definir un panel simple en Grafana para la app (opcional).

## 7. Documentación y evidencias
- [ ] Actualizar `README.md` con los puertos y comandos de Compose actuales.
- [ ] Documentar las credenciales temporales si se usan Jenkins/Grafana.
- [ ] Mantener un `run-steps.sh` o `run-all.sh` que ejecute el stack completo con Docker.
- [ ] Guardar evidencias de ejecución en `reports/`.
- [ ] Comparar con `safe_pipeline`:
  - `docker-compose.yml` como orquestador principal
  - `app/Dockerfile` limpio y reproducible
  - `Jenkinsfile` con stages claros
  - uso de Prometheus + Grafana

## 8. Limpieza final
- [ ] Detener el stack con `docker compose down -v`.
- [ ] Limpiar imágenes/volúmenes temporales si es necesario.
- [ ] Revisar `git status` antes de commit.
- [ ] Confirmar que el repositorio no incluye credenciales en texto plano.

---

### Referencia de comparación con `safe_pipeline`
- Usar un solo `docker-compose.yml` para coordinar Jenkins, app, Grafana, Prometheus y ZAP.
- Asegurar que la app tiene su propia carpeta de `Dockerfile` y `requirements.txt` si es el caso.
- Mantener evidencias de pipeline en `reports/`.
- Usar `Jenkinsfile` declarativo y no ocultar errores.
