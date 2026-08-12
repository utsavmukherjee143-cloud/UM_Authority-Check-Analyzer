# UM_Authority-Check-Analyzer — Production Deployment Guide

Governed SAP Authorization Diagnostic Intelligence tool.
Runs as a fully static HTTPS web application inside a hardened Docker container.

---

## Architecture

```
Browser  ──HTTPS──►  nginx (port 8443, TLS 1.2+)
                       │
                       └── serves  /index.html  (static, no backend)
HTTP (8080) auto-redirects → HTTPS (8443)
```

All analysis logic runs entirely in the browser. No data ever leaves the user's machine.

---

## Prerequisites

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| Docker | 24.x | Build and run the container |
| Docker Compose | v2 (included with Docker Desktop) | Orchestration |
| openssl | any recent | TLS certificate generation |

---

## Quick Start (3 commands)

### Linux / macOS

```bash
# 1. Generate TLS certificates
chmod +x scripts/generate-certs.sh
./scripts/generate-certs.sh

# 2. Build and start
docker compose up -d --build

# 3. Open the tool
open https://localhost:8443
```

### Windows (PowerShell)

```powershell
# 1. Generate TLS certificates
.\scripts\generate-certs.ps1

# 2. Build and start
docker compose up -d --build

# 3. Open the tool
Start-Process "https://localhost:8443"
```

---

## Deployment on a Public Server

1. **Get a CA-signed TLS certificate** from your PKI / Let's Encrypt / internal CA.
2. Place the files at:
   - `certs/server.crt` — public certificate chain
   - `certs/server.key` — private key (**never commit this file**)
3. Set your server's hostname:
   ```bash
   ./scripts/generate-certs.sh your-server.example.com  # or skip if using real certs
   ```
4. **Update your firewall** to allow inbound TCP 8443.
5. Deploy:
   ```bash
   docker compose up -d --build
   ```
6. Share the link: `https://your-server.example.com:8443`

> For port 443 (standard HTTPS), place a reverse proxy (nginx, HAProxy, or your cloud load balancer) in front and proxy to `127.0.0.1:8443`.

---

## Security Highlights

| Control | Implementation |
|---------|---------------|
| TLS | 1.2 minimum, 1.3 preferred; strong cipher suites only |
| HSTS | `max-age=31536000; includeSubDomains` |
| CSP | `default-src 'self'`; inline scripts/styles explicitly allowed |
| Clickjacking | `X-Frame-Options: DENY` |
| MIME sniffing | `X-Content-Type-Options: nosniff` |
| Container user | UID 1001 (non-root) |
| Capabilities | All dropped (`cap_drop: ALL`) |
| Filesystem | Read-only root; tmpfs for writable paths |
| Service binding | `127.0.0.1` only (never `0.0.0.0`) |
| Secrets | TLS key mounted at runtime, never baked into image |

---

## Useful Commands

```bash
# View logs
docker compose logs -f

# Stop
docker compose down

# Rebuild after HTML changes
docker compose up -d --build

# Check health
docker inspect authority-check-analyzer --format='{{.State.Health.Status}}'

# Shell into container (debugging only)
docker exec -it authority-check-analyzer sh
```

---

## File Structure

```
.
├── UM_Authority-Check-Analyzer.html   # Application (single file)
├── Dockerfile                         # Container build
├── docker-compose.yml                 # Orchestration
├── nginx/
│   └── nginx.conf                     # HTTPS server configuration
├── scripts/
│   ├── generate-certs.sh              # Linux/macOS cert generator
│   └── generate-certs.ps1             # Windows cert generator
├── certs/                             # Runtime TLS certs (git-ignored)
│   ├── server.crt
│   └── server.key
└── .vscode/
    └── launch.json                    # VS Code debugger config
```

---

## Notes

- **No backend, no database.** All logic is client-side JavaScript.
- **No data persisted.** Analysis state lives only in the browser session.
- **Human approval mandatory.** All findings require SAP Security review before any correction is applied.
