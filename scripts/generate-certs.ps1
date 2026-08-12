# ─────────────────────────────────────────────────────────────────────────────
#  generate-certs.ps1
#  Windows PowerShell equivalent of generate-certs.sh
#
#  For PUBLIC PRODUCTION:
#    Replace certs/server.crt + certs/server.key with CA-signed certificates.
#
#  Usage (PowerShell):
#    .\scripts\generate-certs.ps1 [-Hostname my-server.example.com]
# ─────────────────────────────────────────────────────────────────────────────

param(
    [string]$Hostname = "localhost"
)

$ErrorActionPreference = "Stop"

$CertDir = Join-Path $PSScriptRoot "..\certs"
$Days    = 365

if (-not (Test-Path $CertDir)) {
    New-Item -ItemType Directory -Path $CertDir | Out-Null
}

$CertPath = Join-Path $CertDir "server.crt"
$KeyPath  = Join-Path $CertDir "server.key"

Write-Host "► Generating TLS certificate for: $Hostname" -ForegroundColor Cyan
Write-Host "  Output: $CertDir\server.crt + server.key"
Write-Host "  Validity: $Days days"
Write-Host ""

# Use openssl if available (Git Bash / WSL / installed separately)
$OpenSsl = Get-Command openssl -ErrorAction SilentlyContinue
if ($OpenSsl) {
    & openssl req -x509 `
        -newkey rsa:4096 `
        -keyout $KeyPath `
        -out    $CertPath `
        -sha256 `
        -days   $Days `
        -nodes `
        -subj   "/CN=$Hostname/O=IBM/OU=SAP-Authorization-Intelligence/C=US" `
        -addext "subjectAltName=DNS:$Hostname,DNS:localhost,IP:127.0.0.1"

    Write-Host ""
    Write-Host "✓ Certificate generated with openssl." -ForegroundColor Green
} else {
    # Fallback: use Windows built-in New-SelfSignedCertificate then export
    Write-Host "  openssl not found — using Windows New-SelfSignedCertificate" -ForegroundColor Yellow

    $Cert = New-SelfSignedCertificate `
        -DnsName $Hostname, "localhost" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -NotAfter (Get-Date).AddDays($Days) `
        -KeyLength 4096 `
        -KeyAlgorithm RSA `
        -HashAlgorithm SHA256 `
        -KeyUsage DigitalSignature, KeyEncipherment `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

    # Export .crt (public)
    $CertBytes = $Cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    [System.IO.File]::WriteAllBytes($CertPath, $CertBytes)

    # Export .pfx then extract key via openssl (if available after PATH refresh)
    $PfxPath = Join-Path $CertDir "server.pfx"
    $PfxPwd  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                        (ConvertTo-SecureString "changeme" -AsPlainText -Force)))
    $Cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
                 "changeme") | Set-Content $PfxPath -Encoding Byte

    Write-Host ""
    Write-Host "✓ Certificate exported to $CertDir" -ForegroundColor Green
    Write-Host "  NOTE: server.key extraction from .pfx requires openssl." -ForegroundColor Yellow
    Write-Host "  Install openssl (https://slproweb.com/products/Win32OpenSSL.html) then run:"
    Write-Host "  openssl pkcs12 -in certs\server.pfx -nocerts -nodes -out certs\server.key -passin pass:changeme"
    Write-Host "  Remove-Item certs\server.pfx"
}

Write-Host ""
Write-Host "  Next step: docker compose up -d" -ForegroundColor Cyan
Write-Host "  Then open: https://${Hostname}:8443" -ForegroundColor Cyan
Write-Host ""
Write-Host "  NOTE: For production, replace these files with CA-signed certificates." -ForegroundColor Yellow
