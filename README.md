# Система автоматических напоминаний n8n

Система для автоматической отправки напоминаний пользователям о запланированных событиях с использованием n8n workflow automation.

## 🚀 Быстрый старт

### Требования
- n8n (версия 1.0+)
- PostgreSQL (версия 12+)
- API endpoint для отправки уведомлений

### Установка

1. **Настройка базы данных**
   ```bash
   psql -U postgres -d your_database < database/init.sql
   ```

2. **Настройка переменных окружения**
   ```bash
   cp .env.example .env
   # Отредактируйте .env и заполните все необходимые значения
   ```

3. **Импорт workflow в n8n**
   - Откройте n8n UI
   - Импортируйте файлы из папки `workflows/`:
     - `1-schedule-notifications.json`
     - `2-send-notifications.json`
     - `3-cancel-notifications.json`

4. **Настройка credentials в n8n**
   - Создайте PostgreSQL credentials с данными из `.env`
   - Убедитесь что переменные окружения доступны в n8n

5. **Активация workflow**
   - Активируйте все три workflow в n8n UI

## 📋 Функциональность

### Workflow #1: Schedule Notifications
Принимает webhook запросы и планирует два уведомления:
- За день до события в 21:00
- За 3 часа до начала события

**Endpoint:** `POST /webhook/schedule-notification`

**Пример запроса:**
```json
{
  "activity_date": "2025-08-25",
  "activity_id": "evt_12345", 
  "activity_time": "14:30",
  "activity_url": "https://example.com/manage/evt_12345",
  "activity_qr": "https://example.com/qr/evt_12345.png",
  "id": "user_67890"
}
```

### Workflow #2: Send Notifications
Автоматически проверяет и отправляет запланированные уведомления каждые 30 секунд.

### Workflow #3: Cancel Notifications
Позволяет отменить все запланированные уведомления для конкретного события.

**Endpoint:** `DELETE /webhook/cancel-notifications/:activity_id`

## 🧪 Тестирование

### Linux/macOS
```bash
chmod +x tests/test-notifications.sh
./tests/test-notifications.sh
```

### Windows
```powershell
.\tests\test-notifications.ps1
```

## 🔒 Безопасность

- Все webhook защищены API ключами через header `X-API-Key`
- Валидация всех входящих данных
- Санитизация данных для предотвращения SQL injection
- Rate limiting (настраивается в n8n)

## 📊 Мониторинг

База данных включает представление для статистики:
```sql
SELECT * FROM notification_statistics;
```

Для очистки старых записей:
```sql
SELECT cleanup_old_notifications();
```

## 📁 Структура проекта

```
n8ntest/
├── database/
│   └── init.sql              # SQL скрипт для создания таблиц
├── workflows/
│   ├── 1-schedule-notifications.json
│   ├── 2-send-notifications.json
│   └── 3-cancel-notifications.json
├── tests/
│   ├── test-notifications.sh  # Тесты для Linux/macOS
│   └── test-notifications.ps1 # Тесты для Windows
├── .env.example               # Пример переменных окружения
└── README.md                  # Документация
```

## ⚙️ Настройки производительности

- **Schedule interval:** 30 секунд (можно изменить в Workflow #2)
- **Batch size:** 10 уведомлений за раз (можно изменить в SQL запросе)
- **Retry count:** 3 попытки при ошибке отправки
- **Timeout:** 2 секунды на запрос к API

## 🐛 Устранение неполадок

### Уведомления не отправляются
1. Проверьте логи n8n
2. Убедитесь что Workflow #2 активен
3. Проверьте подключение к БД
4. Проверьте доступность API для отправки

### Ошибки валидации
1. Проверьте формат даты (YYYY-MM-DD)
2. Проверьте формат времени (HH:MM)
3. Убедитесь что событие в будущем

### Проблемы с базой данных
1. Проверьте credentials в n8n
2. Убедитесь что таблицы созданы
3. Проверьте права доступа пользователя БД

## 📝 Лицензия

MIT