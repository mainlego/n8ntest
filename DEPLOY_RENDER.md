# 🚀 Развертывание на Render.com

## Почему Render?
- ✅ Бесплатный SSL сертификат
- ✅ Автоматический CI/CD из GitHub
- ✅ PostgreSQL включен
- ✅ Простое масштабирование
- ✅ Мониторинг и логи

## 📋 Пошаговая инструкция

### Шаг 1: Подготовка репозитория

1. Создайте новый репозиторий на GitHub
2. Загрузите проект:
```bash
git init
git add .
git commit -m "Initial commit: n8n notification system"
git remote add origin https://github.com/YOUR_USERNAME/n8n-notifications.git
git push -u origin main
```

### Шаг 2: Регистрация на Render

1. Перейдите на [render.com](https://render.com)
2. Зарегистрируйтесь через GitHub
3. Дайте Render доступ к вашему репозиторию

### Шаг 3: Автоматическое развертывание

#### Вариант A: Blueprint (Рекомендуется)

1. В корне репозитория уже есть файл `render.yaml`
2. На Render Dashboard нажмите **New** → **Blueprint**
3. Выберите ваш репозиторий
4. Render автоматически найдет `render.yaml` и создаст все сервисы

#### Вариант B: Ручное создание

##### 1. Создание PostgreSQL:
- **New** → **PostgreSQL**
- Name: `n8n-postgres`
- Database: `notifications_db`
- User: `postgres`
- Region: Frankfurt (для России)
- Plan: Starter ($7/month) или Free (ограничения)

##### 2. Создание n8n Web Service:
- **New** → **Web Service**
- Connect репозиторий
- Name: `n8n-app`
- Environment: Docker
- Dockerfile Path: `./render/Dockerfile.n8n`
- Plan: Starter ($7/month)

### Шаг 4: Настройка переменных окружения

В настройках Web Service добавьте Environment Variables:

```env
# Основные
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n-app.onrender.com
N8N_WEBHOOK_URL=https://n8n-app.onrender.com

# Безопасность
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=[Сгенерируйте безопасный пароль]

# База данных (автоматически из Render PostgreSQL)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=[Internal Database URL от Render]
DB_POSTGRESDB_DATABASE=notifications_db
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=[Пароль от Render PostgreSQL]

# API ключи
WEBHOOK_API_KEY_SCHEDULE=schedule_key_a8f3d2e1b9c7f4a2d6e9b3c8f1a4d7e2
WEBHOOK_API_KEY_CANCEL=cancel_key_b7e2d1a4f8c3b9e6d2a7f1c4e8b3d6a9

# Ваш API для отправки (ОБНОВИТЕ!)
NOTIFICATION_API_URL=https://your-api.com/send-notification
NOTIFICATION_API_TOKEN=your_real_token
```

### Шаг 5: Первый запуск

1. После создания сервисов подождите 5-10 минут для инициализации
2. Откройте URL вашего n8n: `https://n8n-app.onrender.com`
3. Войдите с credentials из переменных окружения

### Шаг 6: Импорт Workflow

1. В n8n UI создайте PostgreSQL credentials:
   - Host: Используйте Internal Database URL от Render
   - Database: `notifications_db`
   - User: `postgres`
   - Password: Из Render PostgreSQL

2. Импортируйте workflow:
   - Settings → Import from File
   - Загрузите 3 workflow из папки `workflows/`

3. В каждом workflow:
   - Обновите PostgreSQL node - выберите созданные credentials
   - Активируйте workflow

### Шаг 7: Настройка Webhook URL

Обновите webhook URL в вашем приложении:
```
Schedule: https://n8n-app.onrender.com/webhook/schedule-notification
Cancel: https://n8n-app.onrender.com/webhook/cancel-notifications/:activity_id
```

## 💰 Стоимость на Render

### Минимальный план:
- PostgreSQL Starter: $7/месяц
- Web Service Starter: $7/месяц
- **Итого: $14/месяц**

### Бесплатный план (с ограничениями):
- PostgreSQL Free: 90 дней, затем удаляется
- Web Service Free: Засыпает после 15 минут неактивности
- **Подходит только для тестирования**

## 🔧 Полезные команды

### Просмотр логов:
В Render Dashboard → Service → Logs

### Перезапуск сервиса:
Manual Deploy → Deploy latest commit

### Обновление переменных:
Environment → Add/Edit variables → Save Changes

## 🐛 Устранение неполадок

### n8n не запускается:
1. Проверьте логи в Render Dashboard
2. Убедитесь что PostgreSQL запущен
3. Проверьте переменные окружения

### База данных не подключается:
1. Используйте Internal Database URL (не External)
2. Проверьте что база создана
3. Попробуйте перезапустить оба сервиса

### Webhook возвращает 404:
1. Проверьте что workflow активны
2. Убедитесь что URL правильный
3. Проверьте API ключи

## 🔒 Безопасность

После развертывания обязательно:
1. ✅ Смените пароль администратора n8n
2. ✅ Обновите API ключи на случайные
3. ✅ Настройте NOTIFICATION_API_URL на реальный
4. ✅ Включите 2FA в Render аккаунте

## 📊 Мониторинг

Render предоставляет:
- Метрики CPU и памяти
- Логи в реальном времени
- Уведомления о сбоях
- Автоматический перезапуск при падении

## 🔄 CI/CD

После настройки каждый push в main ветку автоматически:
1. Собирает новые Docker образы
2. Запускает health checks
3. Развертывает обновления с zero-downtime

## 📞 Тестирование после развертывания

```bash
# PowerShell
$headers = @{
    "X-API-Key" = "schedule_key_a8f3d2e1b9c7f4a2d6e9b3c8f1a4d7e2"
    "Content-Type" = "application/json"
}

$body = @{
    activity_date = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
    activity_id = "render_test_001"
    activity_time = "15:00"
    activity_url = "https://example.com/manage/test"
    activity_qr = "https://example.com/qr/test.png"
    id = "user_001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://n8n-app.onrender.com/webhook/schedule-notification" -Method POST -Headers $headers -Body $body
```

## 🎉 Готово!

Ваша система уведомлений теперь работает в облаке с:
- Автоматическим SSL
- Резервным копированием БД
- Автоматическим масштабированием
- CI/CD из GitHub

**Render Dashboard**: https://dashboard.render.com