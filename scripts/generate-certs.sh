#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  generate-certs.sh
#  Generates a self-signed TLS certificate for local / staging use.
#
#  For PUBLIC PRODUCTION:
#    Replace the output files (certs/server.crt + certs/server.key) with
#    certificates issued by a trusted CA (e.g. Let's Encrypt / internal PKI).
#
#  Usage:
#    chmod +x scripts/generate-certs.sh
#    ./scripts/generate-certs.sh [hostname]
#
#  Example:
#    ./scripts/generate-certs.sh my-server.example.com
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

HOSTNAME="${1:-localhost}"
CERT_DIR="$(dirname "$0")/../certs"
DAYS=365

mkdir -p "$CERT_DIR"

echo "► Generating TLS certificate for: ${HOSTNAME}"
echo "  Output: ${CERT_DIR}/server.crt + server.key"
echo "  Validity: ${DAYS} days"
echo ""

openssl req -x509 \
  -newkey rsa:4096 \
  -keyout "${CERT_DIR}/server.key" \
  -out    "${CERT_DIR}/server.crt" \
  -sha256 \
  -days   "${DAYS}" \
  -nodes  \
  -subj   "/CN=${HOSTNAME}/O=IBM/OU=SAP-Authorization-Intelligence/C=US" \
  -addext "subjectAltName=DNS:${HOSTNAME},DNS:localhost,IP:127.0.0.1"

chmod 600 "${CERT_DIR}/server.key"
chmod 644 "${CERT_DIR}/server.crt"

echo ""
echo "✓ Certificate generated successfully."
echo "  ${CERT_DIR}/server.crt  (public certificate)"
echo "  ${CERT_DIR}/server.key  (private key — keep secret, never commit)"
echo ""
echo "  Next step: docker compose up -d"
echo "  Then open: https://${HOSTNAME}:8443"
echo ""
echo "  NOTE: For production, replace these files with CA-signed certificates."
