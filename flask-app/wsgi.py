from app import app
from werkzeug.middleware.proxy_fix import ProxyFix

# Apply ProxyFix middleware to handle X-Forwarded-* headers from the load balancer
# This ensures Flask gets the correct client IP and protocol information
app.wsgi_app = ProxyFix(
    app.wsgi_app,
    x_for=1,        # Number of proxies setting X-Forwarded-For
    x_proto=1,      # Number of proxies setting X-Forwarded-Proto
    x_host=1,       # Number of proxies setting X-Forwarded-Host
    x_port=1,       # Number of proxies setting X-Forwarded-Port
    x_prefix=0      # Number of proxies setting X-Forwarded-Prefix
)

if __name__ == "__main__":
    app.run() 