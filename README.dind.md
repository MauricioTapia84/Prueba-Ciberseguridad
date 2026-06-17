DinD setup for Jenkins

This compose brings up a Docker-in-Docker daemon and a Jenkins service configured to talk to it.

Usage:

1. From the project folder run:

```bash
docker-compose -f docker-compose.dind.yml up -d --build
```

2. Open Jenkins at http://localhost:8080 and complete setup.

3. In your `Jenkinsfile`, before any `docker` invocations, set `DOCKER_HOST` to the DinD address, for example in a `withEnv` step:

```groovy
withEnv(["DOCKER_HOST=tcp://dind:2375"]) {
  sh 'docker version'
  sh 'docker build -t pruebaciberseguridad:latest .'
}
```

Notes:
- DinD is privileged; for local testing only. For CI in production prefer remote build agents or a proper Docker cluster.
- The `docker` client must be available inside the Jenkins image. `jenkins-with-docker` already includes it.
- If you run Jenkins outside the compose, you can point it to the DinD host by setting `DOCKER_HOST` to the machine IP or using the `docker` daemon TCP endpoint.

*** End of file
