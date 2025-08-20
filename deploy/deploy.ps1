# PowerShell скрипт развертывания системы уведомлений n8n
# ========================================================

$ErrorActionPreference = "Stop"

# Цвета для вывода
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-Host "=====================================" -ForegroundColor Blue
Write-Host "  n8n Notification System Deployment" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue
Write-Host ""

# Проверка Docker
function Check-Command {
    param($CommandName)
    
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host "✓ $CommandName установлен" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $CommandName не установлен" -ForegroundColor Red
        return $false
    }
}

Write-Host "Проверка зависимостей..." -ForegroundColor Yellow
$dockerInstalled = Check-Command "docker"
$dockerComposeInstalled = Check-Command "docker-compose"

if (-not $dockerInstalled -or -not $dockerComposeInstalled) {
    Write-Host "Установите Docker Desktop для Windows: https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Выберите режим развертывания:" -ForegroundColor Yellow
Write-Host "1) Локальная разработка (HTTP, порт 5678)"
Write-Host "2) Production с Nginx (HTTPS, требует домен)"
Write-Host "3) Остановить все контейнеры"
Write-Host "4) Просмотр логов"
Write-Host "5) Резервное копирование БД"
Write-Host "6) Восстановление БД"
Write-Host "7) Обновление n8n"
Write-Host "8) Полная очистка (УДАЛИТ ВСЕ ДАННЫЕ!)"
$choice = Read-Host "Выбор (1-8)"

Set-Location $PSScriptRoot

switch ($choice) {
    "1" {
        Write-Host "Запуск в режиме разработки..." -ForegroundColor Green
        docker-compose up -d postgres n8n
        
        Write-Host ""
        Write-Host "✓ Система запущена!" -ForegroundColor Green
        Write-Host "n8n доступен по адресу: http://localhost:5678" -ForegroundColor Blue
        Write-Host "Логин: admin | Пароль: admin123" -ForegroundColor Blue
        Write-Host ""
        Write-Host "Ожидание запуска n8n..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        Write-Host "Проверка статуса:" -ForegroundColor Green
        docker-compose ps
    }
    
    "2" {
        Write-Host "Production развертывание" -ForegroundColor Yellow
        $domain = Read-Host "Введите ваш домен (например, n8n.example.com)"
        
        # Обновление домена в nginx.conf
        $nginxConfig = Get-Content nginx.conf -Raw
        $nginxConfig = $nginxConfig -replace "your-domain.com", $domain
        Set-Content nginx.conf -Value $nginxConfig
        
        Write-Host "Настройка SSL сертификатов..." -ForegroundColor Yellow
        Write-Host "1) У меня есть SSL сертификаты"
        Write-Host "2) Создать самоподписанные (для тестирования)"
        $sslChoice = Read-Host "Выбор (1-2)"
        
        switch ($sslChoice) {
            "1" {
                Write-Host "Поместите файлы в папку ./ssl/:" -ForegroundColor Yellow
                Write-Host "  - fullchain.pem"
                Write-Host "  - privkey.pem"
                Read-Host "Нажмите Enter когда файлы будут готовы"
            }
            
            "2" {
                Write-Host "Создание самоподписанных сертификатов..." -ForegroundColor Yellow
                
                if (-not (Test-Path "ssl")) {
                    New-Item -ItemType Directory -Path "ssl"
                }
                
                # Создание самоподписанного сертификата
                $cert = New-SelfSignedCertificate `
                    -DnsName $domain `
                    -CertStoreLocation "cert:\CurrentUser\My" `
                    -NotAfter (Get-Date).AddYears(1)
                
                # Экспорт сертификата
                $certPath = "cert:\CurrentUser\My\$($cert.Thumbprint)"
                Export-Certificate -Cert $certPath -FilePath "ssl\fullchain.pem"
                Export-PfxCertificate -Cert $certPath -FilePath "ssl\cert.pfx" -Password (ConvertTo-SecureString -String "password" -Force -AsPlainText)
                
                Write-Host "✓ Самоподписанные сертификаты созданы" -ForegroundColor Green
            }
        }
        
        # Обновление webhook URL
        $composeContent = Get-Content docker-compose.yml -Raw
        $composeContent = $composeContent -replace "WEBHOOK_URL: http://localhost:5678", "WEBHOOK_URL: https://$domain"
        $composeContent = $composeContent -replace "N8N_WEBHOOK_URL: http://localhost:5678", "N8N_WEBHOOK_URL: https://$domain"
        Set-Content docker-compose.yml -Value $composeContent
        
        Write-Host "Запуск production окружения..." -ForegroundColor Green
        docker-compose --profile production up -d
        
        Write-Host ""
        Write-Host "✓ Production система запущена!" -ForegroundColor Green
        Write-Host "n8n доступен по адресу: https://$domain" -ForegroundColor Blue
        Write-Host "Логин: admin | Пароль: admin123" -ForegroundColor Blue
        Write-Host "⚠️  ВАЖНО: Смените пароль администратора!" -ForegroundColor Red
    }
    
    "3" {
        Write-Host "Остановка контейнеров..." -ForegroundColor Yellow
        docker-compose down
        Write-Host "✓ Все контейнеры остановлены" -ForegroundColor Green
    }
    
    "4" {
        Write-Host "Просмотр логов. Выберите сервис:" -ForegroundColor Yellow
        Write-Host "1) n8n"
        Write-Host "2) PostgreSQL"
        Write-Host "3) Nginx"
        Write-Host "4) Все сервисы"
        $logChoice = Read-Host "Выбор (1-4)"
        
        switch ($logChoice) {
            "1" { docker-compose logs -f n8n }
            "2" { docker-compose logs -f postgres }
            "3" { docker-compose logs -f nginx }
            "4" { docker-compose logs -f }
        }
    }
    
    "5" {
        Write-Host "Создание резервной копии БД..." -ForegroundColor Yellow
        
        if (-not (Test-Path "backups")) {
            New-Item -ItemType Directory -Path "backups"
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "backups\backup_$timestamp.sql"
        
        docker-compose exec -T postgres pg_dump -U postgres notifications_db > $backupFile
        
        Write-Host "✓ Резервная копия создана: $backupFile" -ForegroundColor Green
    }
    
    "6" {
        Write-Host "Восстановление из резервной копии" -ForegroundColor Yellow
        
        if (Test-Path "backups") {
            Write-Host "Доступные резервные копии:"
            Get-ChildItem "backups\*.sql" | ForEach-Object { Write-Host $_.Name }
        } else {
            Write-Host "Нет резервных копий" -ForegroundColor Red
            exit 1
        }
        
        $backupFile = Read-Host "Введите имя файла резервной копии"
        $fullPath = "backups\$backupFile"
        
        if (Test-Path $fullPath) {
            Get-Content $fullPath | docker-compose exec -T postgres psql -U postgres notifications_db
            Write-Host "✓ База данных восстановлена" -ForegroundColor Green
        } else {
            Write-Host "❌ Файл не найден" -ForegroundColor Red
        }
    }
    
    "7" {
        Write-Host "Обновление n8n до последней версии..." -ForegroundColor Yellow
        docker-compose pull n8n
        docker-compose up -d n8n
        Write-Host "✓ n8n обновлен" -ForegroundColor Green
    }
    
    "8" {
        Write-Host "⚠️  ВНИМАНИЕ: Это удалит ВСЕ данные!" -ForegroundColor Red
        $confirm = Read-Host "Вы уверены? Введите 'YES' для подтверждения"
        
        if ($confirm -eq "YES") {
            docker-compose down -v
            if (Test-Path "ssl") {
                Remove-Item -Recurse -Force "ssl\*"
            }
            Write-Host "✓ Все данные удалены" -ForegroundColor Green
        } else {
            Write-Host "Отменено" -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "Неверный выбор" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Blue
Write-Host "         Операция завершена          " -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue