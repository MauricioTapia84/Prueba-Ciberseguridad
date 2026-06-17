FROM python:3.12-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt || true
COPY . .
EXPOSE 8080
# Simple default server so ZAP can access an HTTP endpoint during testing.
CMD ["python3", "-m", "http.server", "8080"]
