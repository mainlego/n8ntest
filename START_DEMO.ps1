# PowerShell скрипт для запуска демо

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Starting n8n Demo Interface" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location demo

# Проверяем наличие Python
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Starting demo with Python server..." -ForegroundColor Green
    Write-Host "Open in browser: http://localhost:8000" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    # Запускаем Python сервер
    python -m http.server 8000
} 
# Проверяем наличие Node.js
elseif (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "Starting demo with Node.js..." -ForegroundColor Green
    
    if (-not (Test-Path "node_modules")) {
        Write-Host "Installing http-server..." -ForegroundColor Yellow
        npm init -y
        npm install --save-dev http-server
    }
    
    Write-Host "Open in browser: http://localhost:8000" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    npx http-server -p 8000 -o --cors
}
else {
    Write-Host "Error: Neither Python nor Node.js found!" -ForegroundColor Red
    Write-Host "Please install one of them to run the demo." -ForegroundColor Yellow
    
    # Открываем файл напрямую в браузере
    Write-Host ""
    Write-Host "Opening index.html directly in browser..." -ForegroundColor Yellow
    Start-Process "index.html"
}

Set-Location ..