# 📋 Импорт Workflows в n8n - Пошаговая инструкция

## 🎯 Проблема
```
The requested webhook "POST schedule-notification" is not registered.
The requested webhook "DELETE cancel-notifications" is not registered.
```

**Причина:** Webhooks не зарегистрированы, нужно импортировать workflows!

## ✅ Решение (5 минут)

### Шаг 1: Откройте n8n
1. Перейдите: https://n8ntest-uwxt.onrender.com
2. Авторизуйтесь (если настроена авторизация)

### Шаг 2: Импортируйте 3 готовых workflow

#### Способ A: Импорт по URL (быстрее)
1. Нажмите **"+"** → **"Import from URL"**
2. Вставьте первый URL:
   ```
   https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/1-schedule-webhook.json
   ```
3. Нажмите **"Import"**
4. Повторите для остальных:
   ```
   https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/2-test-webhook.json
   https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/3-cancel-webhook.json
   ```

#### Способ B: Скачать и импортировать файлы
1. Скачайте файлы:
   - [1-schedule-webhook.json](https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/1-schedule-webhook.json)
   - [2-test-webhook.json](https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/2-test-webhook.json)
   - [3-cancel-webhook.json](https://raw.githubusercontent.com/mainlego/n8ntest/main/workflows-simple/3-cancel-webhook.json)

2. В n8n: **"+"** → **"Import from File"** → выберите файл

### Шаг 3: АКТИВИРУЙТЕ каждый workflow! 🔴
**ВАЖНО:** Workflow должны быть активными!

1. Откройте каждый импортированный workflow
2. Переключатель справа вверху: **"Inactive"** → **"Active"**
3. Нажмите **"Save"** (Ctrl+S)

### Шаг 4: Проверьте работу
После активации у вас будут endpoints:

| Endpoint | Метод | Описание |
|----------|-------|----------|
| `/webhook/test` | GET | Тестовый endpoint |
| `/webhook/schedule-notification` | POST | Планирование уведомлений |
| `/webhook/cancel-notifications/:id` | DELETE | Отмена уведомлений |

## 🧪 Быстрая проверка

### Тест 1: Простой GET
Откройте в браузере:
```
https://n8ntest-uwxt.onrender.com/webhook/test
```
Должно вернуть:
```json
{
  "message": "n8n is working!",
  "timestamp": "2024-01-20T15:30:00.000Z",
  "version": "1.0.0"
}
```

### Тест 2: Из демо интерфейса
1. Откройте: https://mainlego.github.io/n8ntest/
2. Нажмите **"🧪 Тест CORS"**
3. Запланируйте уведомление через форму

## ⚠️ Важные моменты

1. **Все workflows должны быть ACTIVE** ⚡
2. **Сохраняйте после изменений** 💾
3. **Проверяйте статус в Executions** 📊

## 🔧 Если что-то не работает

### Проверьте активность workflows:
- **Workflows** → каждый должен быть **Active**

### Проверьте выполнения:
- **Executions** → посмотрите на ошибки

### Проверьте CORS:
- Добавьте переменные в Render Environment:
  ```
  WEBHOOK_CORS_ENABLED=true
  WEBHOOK_CORS_ORIGIN=https://mainlego.github.io
  ```

## 🎉 После успешного импорта

Демо интерфейс будет полностью функциональным:
- ✅ Планирование уведомлений
- ✅ Отмена уведомлений  
- ✅ Данные в Supabase
- ✅ Webhook работают

**Время настройки: 5 минут!** ⏱️