#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/webhook/build':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                # Parse webhook data
                webhook_data = json.loads(post_data.decode('utf-8'))
                logger.info(f"Received webhook: {webhook_data}")
                
                # Trigger Jenkins build
                result = subprocess.run([
                    'curl', '-X', 'POST',
                    'http://localhost:8080/job/docker-ci-pipeline/build',
                    '--user', 'admin:admin123'
                ], capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = {'status': 'success', 'message': 'Build triggered'}
                    self.wfile.write(json.dumps(response).encode())
                    logger.info("Build triggered successfully")
                else:
                    raise Exception(f"Failed to trigger build: {result.stderr}")
                    
            except Exception as e:
                logger.error(f"Error processing webhook: {e}")
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                response = {'status': 'error', 'message': str(e)}
                self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('localhost', 8081), WebhookHandler)
    logger.info("Webhook listener started on http://localhost:8081")
    logger.info("Send POST requests to http://localhost:8081/webhook/build")
    server.serve_forever()