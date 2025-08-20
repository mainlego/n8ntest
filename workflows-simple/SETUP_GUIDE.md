# 📋 Пошаговая инструкция настройки n8n Workflow

## 🎯 Быстрый старт

### Шаг 1: Войдите в n8n
1. Откройте: https://n8ntest-uwxt.onrender.com
2. Логин: `admin`
3. Пароль: тот что вы установили в Render Environment (или отключите авторизацию)

### Шаг 2: Создайте первый тестовый workflow

#### Вариант A: Ручное создание (рекомендуется для понимания)

1. **Создайте новый workflow:**
   - Нажмите **"Add workflow"** или **"+"**

2. **Добавьте Webhook node:**
   - В левой панели найдите **"Webhook"**
   - Перетащите на canvas
   - Дважды кликните для настройки:
     - **HTTP Method:** `GET`
     - **Path:** `test`
     - **Response Mode:** `Using 'Respond to Webhook' Node`
   - Нажмите **"Save"**

3. **Добавьте Set node:**
   - Найдите **"Set"** в панели
   - Перетащите и соедините с Webhook
   - Настройте:
     - Добавьте поле:
       - **Name:** `message`
       - **Value:** `n8n is working!`
     - Добавьте еще поле:
       - **Name:** `timestamp`
       - **Value:** `{{ new Date().toISOString() }}`
   - Нажмите **"Save"**

4. **Добавьте Respond to Webhook node:**
   - Найдите **"Respond to Webhook"**
   - Перетащите и соедините с Set
   - Настройте:
     - **Response Code:** `200`
     - **Response Body:** `{{ $json }}`

5. **Активируйте workflow:**
   - Переключатель **"Inactive/Active"** вверху справа → **Active**
   - Сохраните workflow (Ctrl+S или кнопка Save)

6. **Протестируйте:**
   - Откройте: https://n8ntest-uwxt.onrender.com/webhook/test
   - Должны увидеть: `{"message":"n8n is working!","timestamp":"..."}`

#### Вариант B: Импорт готовых workflow

1. **Скачайте JSON файлы:**
   ```
   https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/1-schedule-webhook.json
   https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/2-test-webhook.json
   https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/3-cancel-webhook.json
   ```

2. **Импортируйте в n8n:**
   - **Workflows** → **Import from File** или **Import from URL**
   - Выберите скачанные файлы или вставьте URL

3. **Активируйте каждый workflow:**
   - Откройте workflow
   - Переключатель **Active**
   - Сохраните

### Шаг 3: Настройка основных webhook

#### 📅 Schedule Notification Webhook

1. **Создайте новый workflow**
2. **Добавьте Webhook node:**
   - **HTTP Method:** `POST`
   - **Path:** `schedule-notification`
   - **Response Mode:** `Using Last Node`

3. **Добавьте Code node:**
   - Соедините с Webhook
   - Вставьте код:
   ```javascript
   // Получаем данные
   const data = $input.first().json.body;
   
   // Валидация
   const required = ['activity_date', 'activity_id', 'activity_time', 'activity_url', 'activity_qr', 'id'];
   for (const field of required) {
     if (!data[field]) {
       return [{json: {success: false, error: `Missing ${field}`}}];
     }
   }
   
   // Логика планирования
   const eventDate = new Date(`${data.activity_date}T${data.activity_time}`);
   const dayBefore = new Date(eventDate);
   dayBefore.setDate(dayBefore.getDate() - 1);
   dayBefore.setHours(21, 0, 0, 0);
   
   const threeHoursBefore = new Date(eventDate);
   threeHoursBefore.setHours(threeHoursBefore.getHours() - 3);
   
   return [{
     json: {
       success: true,
       message: 'Notifications scheduled',
       activity_id: data.activity_id,
       notifications: [
         {type: 'day_before', time: dayBefore.toISOString()},
         {type: 'three_hours', time: threeHoursBefore.toISOString()}
       ]
     }
   }];
   ```

4. **Активируйте workflow**

#### ❌ Cancel Notification Webhook

1. **Создайте новый workflow**
2. **Добавьте Webhook node:**
   - **HTTP Method:** `DELETE`
   - **Path:** `cancel-notifications/:activity_id`
   - **Response Mode:** `Using Last Node`

3. **Добавьте Code node:**
   ```javascript
   const activityId = $input.first().json.params.activity_id;
   
   if (!activityId) {
     return [{json: {success: false, error: 'Missing activity_id'}}];
   }
   
   return [{
     json: {
       success: true,
       message: `Cancelled notifications for ${activityId}`,
       activity_id: activityId
     }
   }];
   ```

4. **Активируйте workflow**

## 🧪 Тестирование

### PowerShell тест:
```powershell
# Тест простого endpoint
Invoke-RestMethod -Uri "https://n8ntest-uwxt.onrender.com/webhook/test"

# Тест schedule
$body = @{
    activity_date = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
    activity_id = "test_001"
    activity_time = "15:00"
    activity_url = "https://example.com/test"
    activity_qr = "https://example.com/qr.png"
    id = "user_001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://n8ntest-uwxt.onrender.com/webhook/schedule-notification" `
    -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body $body

# Тест cancel
Invoke-RestMethod -Uri "https://n8ntest-uwxt.onrender.com/webhook/cancel-notifications/test_001" `
    -Method DELETE
```

### cURL тест:
```bash
# Тест простого endpoint
curl https://n8ntest-uwxt.onrender.com/webhook/test

# Тест schedule
curl -X POST https://n8ntest-uwxt.onrender.com/webhook/schedule-notification \
  -H "Content-Type: application/json" \
  -d '{
    "activity_date": "2025-08-22",
    "activity_id": "test_001",
    "activity_time": "15:00",
    "activity_url": "https://example.com/test",
    "activity_qr": "https://example.com/qr.png",
    "id": "user_001"
  }'

# Тест cancel
curl -X DELETE https://n8ntest-uwxt.onrender.com/webhook/cancel-notifications/test_001
```

## ⚠️ Важные моменты

1. **Workflow должны быть Active** - иначе webhook не работают
2. **Сохраняйте после изменений** - Ctrl+S или кнопка Save
3. **Проверяйте методы HTTP** - POST/GET/DELETE должны совпадать
4. **Путь webhook чувствителен к регистру** - `schedule-notification` ≠ `Schedule-Notification`

## 🔧 Отладка

### Если webhook не работает:
1. Проверьте что workflow **Active**
2. Откройте **Executions** в левом меню - там видны ошибки
3. Проверьте правильность HTTP метода
4. Проверьте путь webhook

### Просмотр логов выполнения:
- **Executions** → выберите выполнение → посмотрите данные на каждом node

## 🎯 Готовые endpoints после настройки:

| Endpoint | Method | Описание |
|----------|--------|----------|
| `/webhook/test` | GET | Тестовый endpoint |
| `/webhook/schedule-notification` | POST | Планирование уведомлений |
| `/webhook/cancel-notifications/:id` | DELETE | Отмена уведомлений |

## 📦 Минимальный рабочий workflow

Если нужен самый простой тест, создайте workflow с 2 нодами:
1. **Webhook** (GET, path: hello)
2. **Set** (message: "Hello World")

Активируйте и проверьте: https://n8ntest-uwxt.onrender.com/webhook/hello