@echo off
echo ========================================
echo   Starting n8n Demo Interface
echo ========================================
echo.

cd demo

if exist node_modules (
    echo Starting server...
) else (
    echo Installing dependencies...
    npm init -y
    npm install --save-dev http-server
)

echo.
echo Demo will open at: http://localhost:3000
echo Press Ctrl+C to stop
echo.

npx http-server -p 3000 -o --cors

pause