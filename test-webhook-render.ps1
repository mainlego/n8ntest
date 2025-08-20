# Тестирование webhook на Render
# ================================

$RenderURL = "https://n8ntest-uwxt.onrender.com"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Тестирование n8n на Render.com" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "URL: $RenderURL" -ForegroundColor Yellow
Write-Host ""

# Проверка доступности сервиса
Write-Host "Проверка доступности сервиса..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $RenderURL -UseBasicParsing -TimeoutSec 10
    Write-Host "✓ Сервис доступен (HTTP $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "⚠ Сервис может требовать авторизацию или еще запускается" -ForegroundColor Yellow
    Write-Host "Ошибка: $_" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Тестирование webhook для планирования уведомлений..." -ForegroundColor Yellow
Write-Host ""

# Данные для тестирования
$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
$futureTime = "15:00"
$testId = "test_render_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

$headers = @{
    "X-API-Key" = "wh_sched_7h3Kj9Xm2Np5Qw8Rt1Yv4Bc7Fg0Jk3Mn6Ps9Zx2Cd5Gh8Lq1Ws4"
    "Content-Type" = "application/json"
}

$body = @{
    activity_date = $tomorrow
    activity_id = $testId
    activity_time = $futureTime
    activity_url = "https://example.com/manage/$testId"
    activity_qr = "https://example.com/qr/$testId.png"
    id = "user_test_001"
} | ConvertTo-Json

Write-Host "Отправка запроса на планирование уведомления:" -ForegroundColor Cyan
Write-Host "Дата: $tomorrow" -ForegroundColor Gray
Write-Host "Время: $futureTime" -ForegroundColor Gray
Write-Host "ID события: $testId" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod `
        -Uri "$RenderURL/webhook/schedule-notification" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 30
    
    Write-Host "✓ Успешно!" -ForegroundColor Green
    Write-Host "Ответ:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 3 | Write-Host
    
    # Сохранение ID для теста отмены
    $activityId = $testId
    
} catch {
    Write-Host "✗ Ошибка при планировании" -ForegroundColor Red
    Write-Host "Детали: $_" -ForegroundColor Gray
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Ответ сервера: $responseBody" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Тест отмены уведомлений
if ($activityId) {
    Write-Host "Тестирование отмены уведомлений..." -ForegroundColor Yellow
    
    $cancelHeaders = @{
        "X-API-Key" = "wh_cancel_4Bv7Nx2Mz9Kl6Qw3Rt8Yp1Fg5Hj0Dc7Sn4Xa9Lm2Oi6Ue3Wb8"
    }
    
    try {
        Start-Sleep -Seconds 2
        
        $response = Invoke-RestMethod `
            -Uri "$RenderURL/webhook/cancel-notifications/$activityId" `
            -Method DELETE `
            -Headers $cancelHeaders `
            -TimeoutSec 30
        
        Write-Host "✓ Отмена успешна!" -ForegroundColor Green
        Write-Host "Ответ:" -ForegroundColor Yellow
        $response | ConvertTo-Json -Depth 3 | Write-Host
        
    } catch {
        Write-Host "✗ Ошибка при отмене" -ForegroundColor Red
        Write-Host "Детали: $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "         Тестирование завершено" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Информация для отладки:" -ForegroundColor Yellow
Write-Host "- n8n URL: $RenderURL" -ForegroundColor Gray
Write-Host "- Логин: admin" -ForegroundColor Gray
Write-Host "- Пароль: Secure#Pass2024!n8n (измените в Render Environment)" -ForegroundColor Gray
Write-Host "- Schedule API Key: wh_sched_7h3Kj9Xm2Np5Qw8Rt1Yv4Bc7Fg0Jk3Mn6Ps9Zx2Cd5Gh8Lq1Ws4" -ForegroundColor Gray
Write-Host "- Cancel API Key: wh_cancel_4Bv7Nx2Mz9Kl6Qw3Rt8Yp1Fg5Hj0Dc7Sn4Xa9Lm2Oi6Ue3Wb8" -ForegroundColor Gray