import os

port = int(os.environ.get("INTERNAL_API_PORT", "8001"))
bind = f"127.0.0.1:{port}"
workers = int(os.environ.get("WORKERS", "2"))
threads = int(os.environ.get("THREADS", "2"))
worker_class = "gthread"
keepalive = 30
timeout = int(os.environ.get("TIMEOUT", "300"))
graceful_timeout = 30
accesslog = "-"
errorlog = "-"
loglevel = os.environ.get("LOG_LEVEL", "info")
capture_output = True
