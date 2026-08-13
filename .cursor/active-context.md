> **BrainSync Context Pumper** 🧠
> Dynamically loaded for active file: `UM_Authority-Check-Analyzer.html` (Domain: **Generic Logic**)

### 📐 Generic Logic Conventions & Fixes
- **[what-changed] 🟢 Edited UM_Authority-Check-Analyzer.html (41 changes, 10min)**: Active editing session on UM_Authority-Check-Analyzer.html.
41 content changes over 10 minutes.
- **[convention] 🟢 Edited UM_Authority-Check-Analyzer.html (18 changes, 2min) — confirmed 3x**: Active editing session on UM_Authority-Check-Analyzer.html.
18 content changes over 2 minutes.
- **[what-changed] what-changed in UM_Authority-Check-Analyzer.html**: File updated (external): UM_Authority-Check-Analyzer.html

Content summary (1016 lines):
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>UM_Authority-Check-Analyzer | IBM SAP Security Intelligence</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans+Condensed:wght@400;600;700&display=swap" rel="stylesheet">
<style>
/* ══════════════
- **[what-changed] Replaced auth MODE**: -   # No account needed (Quick Tunnel). The public URL is printed in container logs:
+   #
-   #   docker compose logs cloudflared
+   # MODE A — Quick Tunnel (default, no account needed):
-   # Note: Quick Tunnel URLs are ephemeral (change on every restart).
+   #   Public URL changes on every restart. Run to see current URL:
-   # For a stable URL, create a free Cloudflare account and use a named tunnel.
+   #     docker compose logs cloudflared | grep trycloudflare
-   cloudflared:
+   #
-     image: cloudflare/cloudflared:latest
+   # MODE B — Named Tunnel (stable permanent URL, recommended):
-     container_name: cloudflared-tunnel
+   #   1. Sign up free at https://dash.cloudflare.com
-     restart: unless-stopped
+   #   2. Go to Zero Trust → Networks → Tunnels → Create tunnel → Cloudflared
-     depends_on:
+   #   3. Copy the tunnel token
-       authority-check-analyzer:
+   #   4. Create a .env file in this folder:  TUNNEL_TOKEN=<your-token>
-         condition: service_healthy
+   #   5. docker compose down && docker compose up -d
-     networks:
+   #   Your app will be live at the stable URL shown in the Cloudflare dashboard.
-       - default
+   cloudflared:
-     command: ["tunnel", "--url", "https://authority-check-analyzer:8443", "--no-tls-verify", "--protocol", "http2"]
+     image: cloudflare/cloudflared:latest
-     # Security hardening
+     container_name: cloudflared-tunnel
-     security_opt:
+     restart: unless-stopped
-       - no-new-privileges:true
+     depends_on:
-     cap_drop:
+       authority-check-analyzer:
-       - ALL
+         condition: service_healthy
-     read_only: true
+     networks:
-     tmpfs:
+       - default
-       - /tmp
+     # If TUNNEL_TOKEN is set → named tunnel (stable URL)
-     deploy:
+     # If TUNNEL_TOKEN is absent → quick tunnel (ephemeral URL)
-       resources:
+     entrypoint: >
-         limits:
+       /bin/sh -c "
-           cpus: "0.25"
+         if [ -n \"$$TUNNEL_TOKEN\" ]; then
-     
… [diff truncated]
- **[what-changed] what-changed in Dockerfile**: File updated (external): Dockerfile

Content summary (62 lines):
# ─────────────────────────────────────────────────────────────────────────────
#  UM_Authority-Check-Analyzer — Production Dockerfile
#
#  Base image : registry.redhat.io/ubi9/nginx-124 (Red Hat UBI, minimal, nginx)
#  User       : non-root (UID 1001 — nginx default in UBI image)
#  Ports      : 8080 (HTTP → redirects to HTTPS) · 8443 (HTTPS)
#
#  IBM Security Policy compliance:
#    ✓ Red Hat registry image
#    ✓ Non-root execution
#    ✓ No hardcoded secrets
#    ✓ server_tokens off (no vers
