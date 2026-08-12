# certs/ is git-ignored — TLS certificates are generated at deploy time.
# See: scripts/generate-certs.sh (Linux/macOS) or scripts/generate-certs.ps1 (Windows)
#
# Required files (not committed):
#   server.crt  — public certificate
#   server.key  — private key (NEVER commit this file)
