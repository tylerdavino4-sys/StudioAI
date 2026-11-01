$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "backend")
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js 18 or newer was not found. Install it from https://nodejs.org/" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
$secure = Read-Host "Paste your OpenAI API key (your typing is hidden)" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    $env:OPENAI_MODEL = "gpt-4.1-mini"
    node server.js
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
}
Read-Host "Press Enter to close"
