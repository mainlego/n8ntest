# Инструкция по деплою CORS прокси на Render

## Быстрый способ деплоя

### 1. Создайте новый Web Service на Render

1. Откройте https://dashboard.render.com/
2. Нажмите "New +" → "Web Service"
3. Выберите "Build and deploy from a Git repository"
4. Подключите ваш GitHub репозиторий `n8ntest`

### 2. Настройте сервис

**Basic Settings:**
- **Name:** `n8n-cors-proxy`
- **Runtime:** Node
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Environment Variables:**
Добавьте следующие переменные:
- `N8N_URL` = `https://n8ntest-uwxt.onrender.com`
- `PORT` = `10000` (или оставьте пустым, будет использован порт по умолчанию)

### 3. Deploy

Нажмите "Create Web Service" и дождитесь деплоя.

После успешного деплоя вы получите URL вида:
```
https://n8n-cors-proxy-xxxx.onrender.com
```

### 4. Обновите demo/app.js

Замените URL прокси в файле `demo/app.js`:

```javascript
const CONFIG = {
    n8nWebhookUrl: 'https://n8ntest-uwxt.onrender.com',
    corsProxyUrl: 'https://n8n-cors-proxy-xxxx.onrender.com', // Ваш новый URL прокси
    // ...
};
```

## Альтернативный способ через render.yaml

Если вы используете Infrastructure as Code подход:

1. В корне репозитория уже есть обновлённый `render.yaml` с конфигурацией CORS прокси
2. В Render Dashboard создайте новый Blueprint:
   - New → Blueprint
   - Подключите репозиторий
   - Выберите branch `main`
   - Render автоматически обнаружит `render.yaml`

## Проверка работы

После деплоя проверьте работу прокси:

```bash
# Проверка health
curl https://n8n-cors-proxy-xxxx.onrender.com/webhook/test

# Проверка CORS заголовков
curl -I -X OPTIONS https://n8n-cors-proxy-xxxx.onrender.com/webhook/schedule-notification
```

Должны вернуться CORS заголовки:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
```

## Преимущества собственного прокси

1. **Надёжность** - не зависите от сторонних сервисов
2. **Контроль** - можете настроить под свои нужды
3. **Безопасность** - можете ограничить доступ только для вашего домена
4. **Бесплатно** - на Render free tier

## Устранение проблем

Если прокси не работает:

1. Проверьте логи в Render Dashboard
2. Убедитесь, что `N8N_URL` указан правильно
3. Проверьте, что n8n сервис доступен
4. Убедитесь, что в `demo/app.js` используется правильный URL прокси