# Тестовые скрипты для системы уведомлений (PowerShell версия для Windows)
# =========================================================================

# Конфигурация
$N8N_URL = if ($env:N8N_WEBHOOK_URL) { $env:N8N_WEBHOOK_URL } else { "http://localhost:5678" }
$API_KEY_SCHEDULE = if ($env:WEBHOOK_API_KEY_SCHEDULE) { $env:WEBHOOK_API_KEY_SCHEDULE } else { "test_schedule_key" }
$API_KEY_CANCEL = if ($env:WEBHOOK_API_KEY_CANCEL) { $env:WEBHOOK_API_KEY_CANCEL } else { "test_cancel_key" }

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Тестирование системы уведомлений n8n" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "URL: $N8N_URL"
Write-Host ""

# Получение даты и времени
$Tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
$FutureTime = (Get-Date).AddHours(4).ToString("HH:mm")
$TestId = "test_" + [DateTimeOffset]::Now.ToUnixTimeSeconds()

# Тест 1: Планирование уведомления
Write-Host "Тест 1: Планирование уведомления" -ForegroundColor Green
Write-Host "Отправка запроса на планирование..."
Write-Host "Дата события: $Tomorrow"
Write-Host "Время события: $FutureTime"
Write-Host ""

$Body = @{
    activity_date = $Tomorrow
    activity_id = $TestId
    activity_time = $FutureTime
    activity_url = "https://example.com/manage/$TestId"
    activity_qr = "https://example.com/qr/$TestId.png"
    id = "user_test_123"
} | ConvertTo-Json

$Headers = @{
    "X-API-Key" = $API_KEY_SCHEDULE
    "Content-Type" = "application/json"
}

try {
    $Response = Invoke-RestMethod -Uri "$N8N_URL/webhook/schedule-notification" `
        -Method POST `
        -Headers $Headers `
        -Body $Body
    
    Write-Host "Ответ: $($Response | ConvertTo-Json -Compress)"
    Write-Host ""
    
    if ($Response.success -eq $true) {
        Write-Host "✓ Тест 1 пройден успешно" -ForegroundColor Green
    } else {
        Write-Host "✗ Тест 1 провален" -ForegroundColor Red
    }
} catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
    Write-Host "✗ Тест 1 провален" -ForegroundColor Red
}
Write-Host ""

Start-Sleep -Seconds 2

# Тест 2: Проверка валидации (прошедшая дата)
Write-Host "Тест 2: Проверка валидации (прошедшая дата)" -ForegroundColor Green
Write-Host "Отправка запроса с прошедшей датой..."
Write-Host ""

$Body = @{
    activity_date = "2020-01-01"
    activity_id = "test_past"
    activity_time = "14:30"
    activity_url = "https://example.com/manage/test_past"
    activity_qr = "https://example.com/qr/test_past.png"
    id = "user_test_456"
} | ConvertTo-Json

try {
    $Response = Invoke-RestMethod -Uri "$N8N_URL/webhook/schedule-notification" `
        -Method POST `
        -Headers $Headers `
        -Body $Body `
        -ErrorAction Stop
    
    Write-Host "Ответ: $($Response | ConvertTo-Json -Compress)"
    Write-Host "✗ Тест 2 провален (должна была быть ошибка)" -ForegroundColor Red
} catch {
    $ErrorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "Ответ: $($ErrorResponse | ConvertTo-Json -Compress)"
    
    if ($ErrorResponse.error -like "*future*") {
        Write-Host "✓ Тест 2 пройден успешно (валидация работает)" -ForegroundColor Green
    } else {
        Write-Host "✗ Тест 2 провален" -ForegroundColor Red
    }
}
Write-Host ""

Start-Sleep -Seconds 2

# Тест 3: Отмена уведомлений
Write-Host "Тест 3: Отмена уведомлений" -ForegroundColor Green
Write-Host "Отправка запроса на отмену для activity_id: $TestId"
Write-Host ""

$CancelHeaders = @{
    "X-API-Key" = $API_KEY_CANCEL
}

try {
    $Response = Invoke-RestMethod -Uri "$N8N_URL/webhook/cancel-notifications/$TestId" `
        -Method DELETE `
        -Headers $CancelHeaders
    
    Write-Host "Ответ: $($Response | ConvertTo-Json -Compress)"
    Write-Host ""
    
    if ($Response.success -eq $true) {
        Write-Host "✓ Тест 3 пройден успешно" -ForegroundColor Green
    } else {
        Write-Host "✗ Тест 3 провален" -ForegroundColor Red
    }
} catch {
    Write-Host "Ошибка: $_" -ForegroundColor Red
    Write-Host "✗ Тест 3 провален" -ForegroundColor Red
}
Write-Host ""

# Тест 4: Проверка безопасности (неправильный API ключ)
Write-Host "Тест 4: Проверка безопасности (неправильный API ключ)" -ForegroundColor Green
Write-Host "Отправка запроса с неправильным API ключом..."
Write-Host ""

$WrongHeaders = @{
    "X-API-Key" = "wrong_key"
    "Content-Type" = "application/json"
}

$Body = @{
    activity_date = $Tomorrow
    activity_id = "test_auth"
    activity_time = "14:30"
    activity_url = "https://example.com/manage/test_auth"
    activity_qr = "https://example.com/qr/test_auth.png"
    id = "user_test_789"
} | ConvertTo-Json

try {
    $Response = Invoke-WebRequest -Uri "$N8N_URL/webhook/schedule-notification" `
        -Method POST `
        -Headers $WrongHeaders `
        -Body $Body `
        -UseBasicParsing
    
    Write-Host "HTTP код ответа: $($Response.StatusCode)"
    Write-Host "✗ Тест 4 провален (должна была быть ошибка аутентификации)" -ForegroundColor Red
} catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "HTTP код ответа: $StatusCode"
    
    if ($StatusCode -eq 401 -or $StatusCode -eq 403) {
        Write-Host "✓ Тест 4 пройден успешно (аутентификация работает)" -ForegroundColor Green
    } else {
        Write-Host "✗ Тест 4 провален (получен код $StatusCode вместо 401/403)" -ForegroundColor Red
    }
}
Write-Host ""

# Тест 5: Проверка обязательных полей
Write-Host "Тест 5: Проверка обязательных полей" -ForegroundColor Green
Write-Host "Отправка запроса без activity_id..."
Write-Host ""

$Body = @{
    activity_date = $Tomorrow
    activity_time = "14:30"
    activity_url = "https://example.com/manage/test_missing"
    activity_qr = "https://example.com/qr/test_missing.png"
    id = "user_test_999"
} | ConvertTo-Json

try {
    $Response = Invoke-RestMethod -Uri "$N8N_URL/webhook/schedule-notification" `
        -Method POST `
        -Headers $Headers `
        -Body $Body `
        -ErrorAction Stop
    
    Write-Host "Ответ: $($Response | ConvertTo-Json -Compress)"
    Write-Host "✗ Тест 5 провален (должна была быть ошибка)" -ForegroundColor Red
} catch {
    $ErrorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "Ответ: $($ErrorResponse | ConvertTo-Json -Compress)"
    
    if ($ErrorResponse.error -like "*Missing required field*") {
        Write-Host "✓ Тест 5 пройден успешно (валидация полей работает)" -ForegroundColor Green
    } else {
        Write-Host "✗ Тест 5 провален" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Тестирование завершено" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow