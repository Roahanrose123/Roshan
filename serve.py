#!/usr/bin/env python3
import http.server
import socketserver
import os
import webbrowser

PORT = 5000

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()

def main():
    os.chdir('build/web')
    
    with socketserver.TCPServer(('', PORT), MyHTTPRequestHandler) as httpd:
        print(f"✅ Todo App is running at: http://localhost:{PORT}")
        print("🌐 Open this URL in your web browser")
        print("📱 Works on both Windows and Linux!")
        print("Press Ctrl+C to stop the server")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped")

if __name__ == "__main__":
    main()