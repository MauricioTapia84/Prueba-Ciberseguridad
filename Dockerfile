FROM python:3.14-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt || true
COPY . .
RUN mkdir -p public && echo '<html><head><title>App Under Test</title></head><body><h1>App Under Test</h1><p>Welcome to the test application.</p></body></html>' > public/index.html
EXPOSE 8080
# Run the custom secure HTTP server to inject security headers
CMD ["python3", "server.py"]
