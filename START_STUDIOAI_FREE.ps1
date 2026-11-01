$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "backend")
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js 18 or newer was not found. Install it from https://nodejs.org/" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Ollama was not found. Install it from https://ollama.com/download/windows" -ForegroundColor Red
    Read-Host "Install Ollama, then run this launcher again."
    exit 1
}
$env:STUDIOAI_PROVIDER = "ollama"
$env:STUDIOAI_MODEL = "qwen2.5-coder:3b"
Write-Host "Checking/downloading the free local AI model. First download may take a while..." -ForegroundColor Cyan
ollama pull $env:STUDIOAI_MODEL
if ($LASTEXITCODE -ne 0) {
    Write-Host "Model download failed. Check your internet connection and try again." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host "Starting free local StudioAI..." -ForegroundColor Green
node server.js
Read-Host "Press Enter to close"
