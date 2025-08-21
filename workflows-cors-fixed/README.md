# 🔧 Workflows с исправленным CORS

## 📋 Файлы для импорта:

1. **1-schedule-notification-cors.json** - Планирование уведомлений (POST)
2. **2-cancel-notification-cors.json** - Отмена уведомлений (DELETE)
3. **3-options-handler-cors.json** - Обработчик OPTIONS запросов для CORS

## 🚀 Как импортировать:

### Способ 1: По прямым ссылкам (быстрее)

1. Откройте n8n: https://n8ntest-uwxt.onrender.com
2. Нажмите **"+"** → **"Import from URL"**
3. Вставьте поочередно:

```
https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-cors-fixed/1-schedule-notification-cors.json
https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-cors-fixed/2-cancel-notification-cors.json
https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-cors-fixed/3-options-handler-cors.json
```

### Способ 2: Копировать JSON

1. Откройте файл .json
2. Скопируйте весь текст
3. В n8n: **"+"** → **"Import from File"** → вставьте JSON

## ⚡ ВАЖНО: Активируйте workflows!

После импорта КАЖДОГО workflow:
1. Откройте workflow
2. Переключатель вверху справа → **"Active"** (зеленый)
3. Сохраните (Ctrl+S)

## ✅ Что исправлено:

Каждый webhook теперь содержит CORS заголовки:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS, PUT`
- `Access-Control-Allow-Headers: Content-Type, Authorization`

## 🧪 Проверка после импорта:

1. Откройте демо: https://mainlego.github.io/n8ntest/
2. Нажмите **"🧪 Тест CORS"**
3. Должно показать: **"✅ CORS настроен корректно!"**

## 📝 Endpoints после активации:

| Endpoint | Метод | Описание |
|----------|-------|----------|
| `/webhook/schedule-notification` | POST | Планирование уведомлений |
| `/webhook/cancel-notifications/:activity_id` | DELETE | Отмена уведомлений |
| `/webhook/*` | OPTIONS | CORS preflight |

## 🎯 После активации всех workflows:

- ✅ CORS будет работать
- ✅ Демо интерфейс сможет отправлять запросы
- ✅ Система будет полностью функциональна!