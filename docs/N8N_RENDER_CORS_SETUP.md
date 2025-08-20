# Настройка CORS для n8n на Render

## 🎯 Текущая проблема
```
Access to fetch at 'https://n8ntest-uwxt.onrender.com/webhook/schedule-notification' 
from origin 'https://mainlego.github.io' has been blocked by CORS policy
```

## ✅ Решение - добавить переменные окружения в Render:

### Шаг 1: Откройте настройки Render
1. Перейдите: https://dashboard.render.com
2. Найдите ваш сервис **n8ntest-uwxt**
3. Нажмите на него

### Шаг 2: Добавьте переменные окружения
1. Перейдите на вкладку **Environment**
2. Нажмите **Add Environment Variable**
3. Добавьте первую переменную:
   - **Key:** `WEBHOOK_CORS_ENABLED`
   - **Value:** `true`
4. Нажмите **Add Environment Variable** еще раз
5. Добавьте вторую переменную:
   - **Key:** `WEBHOOK_CORS_ORIGIN`
   - **Value:** `https://mainlego.github.io`

### Шаг 3: Сохранить и передеплоить
1. Нажмите **Save Changes**
2. Render автоматически начнет передеплой (займет 2-3 минуты)
3. Дождитесь зеленого статуса

## 🧪 Проверка результата
После передеплоя выполните в консоли браузера:
```javascript
fetch('https://n8ntest-uwxt.onrender.com/webhook/schedule-notification', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
        id: 'test_user',
        activity_id: 'test_event',
        activity_date: '2024-01-21',
        activity_time: '15:00',
        activity_url: 'https://example.com',
        activity_qr: 'https://example.com/qr.png'
    })
}).then(r => console.log('Success!', r.status)).catch(e => console.log('Error:', e.message));
```

Если CORS исправлен, увидите `Success! 200` или `Success! 404` (если webhook не настроен).
Если все еще проблема - увидите CORS ошибку.

## 📱 Альтернативный способ (если первый не работает)

Добавьте эти переменные тоже:
```
N8N_CORS_ORIGIN=https://mainlego.github.io
GENERIC_TIMEZONE=Europe/Moscow
N8N_DEFAULT_LOCALE=ru
```

## ✅ После исправления CORS:
- Демо будет полностью функциональным
- Webhook запросы будут проходить
- n8n сможет получать запросы от GitHub Pages
- Система будет работать в полном объеме