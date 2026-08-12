# ─────────────────────────────────────────────────────────────────────────────
#  UM_Authority-Check-Analyzer — Production Dockerfile
#
#  Base image : registry.access.redhat.com/ubi9/nginx-124 (Red Hat UBI, public mirror)
#  User       : non-root (UID 1001 — nginx default in UBI image)
#  Ports      : 8080 (HTTP → redirects to HTTPS) · 8443 (HTTPS)
#
#  IBM Security Policy compliance:
#    ✓ Red Hat registry image
#    ✓ Non-root execution
#    ✓ No hardcoded secrets
#    ✓ server_tokens off (no version disclosure)
#    ✓ TLS 1.2+ enforced in nginx.conf
# ─────────────────────────────────────────────────────────────────────────────

FROM registry.access.redhat.com/ubi9/nginx-124:latest

# ── Labels ───────────────────────────────────────────────────────────────────
LABEL maintainer="IBM SAP Authorization Intelligence Team" \
      description="UM_Authority-Check-Analyzer — SAP Authorization static analysis tool" \
      version="1.0"

# ── Switch to root only for setup, then drop back to non-root ────────────────
USER root

# ── Create directories with correct ownership for non-root nginx (UID 1001) ─
RUN mkdir -p /usr/share/nginx/html \
             /var/log/nginx \
             /var/cache/nginx \
             /tmp/nginx \
             /etc/nginx/certs \
    && chown -R 1001:0 /usr/share/nginx/html \
                       /var/log/nginx \
                       /var/cache/nginx \
                       /tmp/nginx \
                       /etc/nginx/certs \
    && chmod -R g=u   /usr/share/nginx/html \
                       /var/log/nginx \
                       /var/cache/nginx \
                       /tmp/nginx \
                       /etc/nginx/certs

# ── Copy application ──────────────────────────────────────────────────────────
# The HTML is served as index.html so the root URL opens the tool directly
COPY --chown=1001:0 UM_Authority-Check-Analyzer.html /usr/share/nginx/html/index.html

# ── Copy nginx configuration ─────────────────────────────────────────────────
COPY --chown=1001:0 nginx/nginx.conf /etc/nginx/nginx.conf

# ── Drop to non-root ──────────────────────────────────────────────────────────
USER 1001

# ── Expose ports ─────────────────────────────────────────────────────────────
EXPOSE 8080 8443

# ── Health check ─────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fsk https://localhost:8443/ || exit 1

# ── Start nginx in foreground ─────────────────────────────────────────────────
CMD ["nginx", "-g", "daemon off;"]
