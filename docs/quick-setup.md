# 🚀 Быстрая настройка системы уведомлений

## Настройки PostgreSQL для n8n Credentials

Используйте эти точные значения при создании PostgreSQL credentials в n8n:

| Поле | Значение |
|------|----------|
| **Credential Name** | `PostgreSQL Notifications` |
| **Host** | `localhost` |
| **Database** | `notifications_db` |
| **User** | `postgres` |
| **Password** | `lego1994vM!` |
| **Port** | `5432` |
| **SSL** | `Disable` |
| **Maximum Number of Connections** | `100` |
| **Ignore SSL Issues** | ☐ (не отмечать) |
| **SSH Tunnel** | `Disable` |

## Пошаговая инструкция

### 1️⃣ Создание базы данных

Откройте pgAdmin или psql и выполните:

```sql
-- Создание базы данных
CREATE DATABASE notifications_db;
```

### 2️⃣ Инициализация таблиц

Подключитесь к созданной базе и выполните скрипт:

```sql
-- В pgAdmin: выберите notifications_db, затем откройте Query Tool
-- В psql: \c notifications_db

-- Скопируйте и выполните содержимое файла database/init.sql
```

Или через командную строку:
```bash
psql -U postgres -d notifications_db -f "C:\Users\mainv\WebstormProjects\n8ntest\database\init.sql"
```
При запросе пароля введите: `lego1994vM!`

### 3️⃣ Настройка n8n

1. Откройте n8n (http://localhost:5678)
2. Перейдите в **Credentials** → **Create New** → **PostgreSQL**
3. Заполните поля точно как указано в таблице выше
4. Нажмите **Test Connection** - должно показать "Connection successful"
5. Сохраните credentials

### 4️⃣ Импорт Workflow

1. В n8n перейдите в **Workflows**
2. Нажмите **Import from File** для каждого файла:
   - `workflows/1-schedule-notifications.json`
   - `workflows/2-send-notifications.json`
   - `workflows/3-cancel-notifications.json`
3. В каждом workflow найдите PostgreSQL ноды и выберите созданные credentials
4. Активируйте все три workflow (переключатель Active)

### 5️⃣ Тестирование

Запустите тест в PowerShell:

```powershell
cd C:\Users\mainv\WebstormProjects\n8ntest
.\tests\test-notifications.ps1
```

## ⚠️ Важные моменты

1. **Webhook URL**: Если n8n доступен не на localhost:5678, обновите в `.env`:
   ```
   N8N_WEBHOOK_URL=http://ваш-адрес:порт
   ```

2. **API для отправки**: Замените в `.env` на реальные значения:
   ```
   NOTIFICATION_API_URL=https://ваш-api.com/send-notification
   NOTIFICATION_API_TOKEN=ваш_реальный_токен
   ```

3. **Проверка работы БД**:
   ```sql
   -- Проверка что таблица создана
   SELECT * FROM scheduled_notifications;
   ```

## 🔒 API ключи для webhook

Уже настроены в `.env`:
- Schedule API Key: `schedule_key_a8f3d2e1b9c7f4a2d6e9b3c8f1a4d7e2`
- Cancel API Key: `cancel_key_b7e2d1a4f8c3b9e6d2a7f1c4e8b3d6a9`

Используйте их при отправке запросов к webhook.

## 📞 Тестовый запрос

После настройки протестируйте систему:

```powershell
$headers = @{
    "X-API-Key" = "schedule_key_a8f3d2e1b9c7f4a2d6e9b3c8f1a4d7e2"
    "Content-Type" = "application/json"
}

$body = @{
    activity_date = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
    activity_id = "test_001"
    activity_time = "15:00"
    activity_url = "https://example.com/manage/test_001"
    activity_qr = "https://example.com/qr/test_001.png"
    id = "user_001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5678/webhook/schedule-notification" -Method POST -Headers $headers -Body $body
```

Если всё настроено правильно, вы получите ответ с подтверждением создания уведомлений.