import http.server
import os

PORT = 8080
DIRECTORY = "public"

class SecureHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Configurar para servir desde el directorio público
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # 1. Mitigar: Content Security Policy (CSP) Header Not Set
        self.send_header("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none';")
        # 2. Mitigar: Missing Anti-clickjacking Header (X-Frame-Options)
        self.send_header("X-Frame-Options", "DENY")
        # 3. Mitigar: X-Content-Type-Options Header Missing
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()

    # 4. Mitigar: Server Leaks Version Information (Ocultar Server Header)
    def version_string(self):
        return "WebServer"

if __name__ == "__main__":
    # Asegurar que el directorio public exista
    os.makedirs(DIRECTORY, exist_ok=True)
    server_address = ("", PORT)
    httpd = http.server.HTTPServer(server_address, SecureHTTPRequestHandler)
    print(f"Serving secure web app on port {PORT}...")
    httpd.serve_forever()
