# 📚 Техническая документация системы уведомлений n8n

## 1. Алгоритм работы системы

### 1.1 Архитектура решения

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│     n8n     │────▶│  Supabase   │
│   (API)     │     │  Workflows  │     │  PostgreSQL │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Notification│
                    │     API     │
                    └─────────────┘
```

### 1.2 Используемые n8n ноды и их порядок

#### Workflow #1: Schedule Notifications
1. **Webhook Node** - Принимает POST запросы на `/webhook/schedule-notification`
2. **Code Node (Validate and Log)** - Валидация данных и логирование
3. **Code Node (Calculate Schedule)** - Расчет времени отправки уведомлений
4. **PostgreSQL Node** - Сохранение в базу данных Supabase
5. **Code Node (Prepare Response)** - Формирование ответа

#### Workflow #2: Send Notifications (Автоматическая отправка)
1. **Schedule Trigger Node** - Запуск каждые 30 секунд
2. **PostgreSQL Node** - Выборка pending уведомлений
3. **IF Node** - Проверка наличия уведомлений
4. **Code Node (Prepare API Data)** - Формирование данных по ТЗ
5. **HTTP Request Node** - Отправка на API уведомлений
6. **PostgreSQL Node** - Обновление статуса
7. **Code Node (Log Results)** - Логирование результатов

#### Workflow #3: Cancel Notifications
1. **Webhook Node** - Принимает DELETE запросы на `/webhook/cancel-notifications/:activity_id`
2. **Code Node (Extract ID)** - Извлечение activity_id
3. **PostgreSQL Node** - Обновление статуса на 'cancelled'
4. **Code Node (Response)** - Формирование ответа

### 1.3 Формат API запросов согласно ТЗ

#### Входящий запрос планирования:
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

#### Исходящий запрос уведомления (накануне):
```json
{
  "client_id": "user_67890",
  "message": "notification_evt_12345",
  "text": "Напоминаем: завтра в 14:30 у вас запланировано событие",
  "button_url": "https://example.com/manage/evt_12345"
}
```

#### Исходящий запрос уведомления (за 3 часа):
```json
{
  "client_id": "user_67890",
  "message": "notification_evt_12345",
  "text": "Событие начнется через 3 часа в 14:30",
  "qr": "https://example.com/qr/evt_12345.png"
}
```

## 2. Дополнительное ПО

### 2.1 На сервере n8n (Render.com):
- **n8n** (latest) - платформа автоматизации
- **PostgreSQL client** - для работы с БД
- **curl** - для health checks

### 2.2 Внешние сервисы:
- **Supabase PostgreSQL** - хранение данных
- **Render.com** - хостинг n8n
- **API уведомлений** - внешний сервис отправки

## 3. Обеспечение выполнения требований

### 3.1 Время ответа < 6 секунд
- ✅ Асинхронная обработка в n8n
- ✅ Индексы в БД по scheduled_time и status
- ✅ Timeout настроен на 6 секунд в workflow settings
- ✅ Минимальная логика в webhook, основная работа в фоне

### 3.2 Время отправки < 2 секунд
- ✅ Batch обработка до 10 уведомлений за раз
- ✅ HTTP timeout 2000ms для API запросов
- ✅ Параллельная обработка в n8n
- ✅ Кеширование соединений с БД

### 3.3 Масштабируемость
- ✅ Горизонтальное масштабирование на Render
- ✅ Индексированные запросы к БД
- ✅ Партиционирование таблиц по дате (опционально)
- ✅ Очистка старых записей функцией cleanup_old_notifications()

### 3.4 Обработка ошибок
- ✅ HTTP коды: 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found), 500 (Server Error)
- ✅ Retry механизм (3 попытки)
- ✅ Логирование всех ошибок в БД
- ✅ Graceful degradation при недоступности API

## 4. Меры безопасности

### 4.1 Аутентификация и авторизация
```javascript
// Webhook защита через API ключи (опционально)
if (headers['X-API-Key'] !== process.env.WEBHOOK_API_KEY) {
  return { statusCode: 401, error: 'Unauthorized' };
}
```

### 4.2 Валидация данных
- ✅ Проверка всех обязательных полей
- ✅ Валидация форматов даты/времени
- ✅ Проверка что событие в будущем
- ✅ Санитизация через параметризованные запросы

### 4.3 Rate Limiting
- ✅ Render автоматический rate limiting
- ✅ Максимум 10 уведомлений за batch
- ✅ Throttling через n8n execution limits

### 4.4 Защита данных
- ✅ HTTPS для всех соединений
- ✅ Row Level Security в Supabase
- ✅ Шифрование паролей БД
- ✅ Логирование без sensitive данных

## 5. Логирование

### 5.1 Структура логов
```javascript
{
  timestamp: "2025-08-20T10:30:00Z",
  operation_type: "schedule|send|cancel|error",
  activity_id: "evt_12345",
  user_id: "user_67890",
  execution_time_ms: 145,
  status_code: 201,
  ip_address: "192.168.1.1",
  request_data: {...},
  response_data: {...},
  error_message: null
}
```

### 5.2 Уровни логирования
- **INFO**: Успешные операции
- **WARN**: Повторные попытки
- **ERROR**: Неудачные операции
- **DEBUG**: Детальная информация (dev mode)

## 6. Мониторинг и метрики

### 6.1 Ключевые метрики
- Количество запланированных уведомлений
- Количество отправленных уведомлений
- Средне время выполнения
- Процент ошибок
- Задержка отправки

### 6.2 SQL запросы для мониторинга
```sql
-- Статистика по статусам
SELECT status, COUNT(*) FROM scheduled_notifications 
GROUP BY status;

-- Среднее время выполнения
SELECT AVG(execution_time_ms) FROM notification_logs 
WHERE created_at > NOW() - INTERVAL '1 hour';

-- Уведомления с задержкой
SELECT * FROM scheduled_notifications 
WHERE status = 'pending' 
AND scheduled_time < NOW() - INTERVAL '5 minutes';
```

## 7. Тестирование

### 7.1 Unit тесты
- Валидация входных данных
- Расчет времени уведомлений
- Формирование API запросов

### 7.2 Integration тесты
- Webhook endpoints
- База данных операции
- API вызовы

### 7.3 Load тесты
- 1000 одновременных запросов
- Проверка времени ответа < 6 сек
- Проверка времени отправки < 2 сек

## 8. Deployment

### 8.1 Environment Variables
```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
DB_SSL_MODE=require

# n8n
N8N_WEBHOOK_URL=https://n8ntest-uwxt.onrender.com
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password

# API
NOTIFICATION_API_URL=https://api.example.com/send
NOTIFICATION_API_TOKEN=bearer_token

# Security
WEBHOOK_API_KEY_SCHEDULE=random_key_1
WEBHOOK_API_KEY_CANCEL=random_key_2
```

### 8.2 CI/CD Pipeline
1. Git push to main branch
2. Render auto-deploy
3. Database migrations
4. Health check
5. Smoke tests

## 9. Результаты и соответствие ТЗ

| Требование | Статус | Реализация |
|------------|--------|------------|
| Планирование уведомлений | ✅ | Webhook endpoint с валидацией |
| Отмена уведомлений | ✅ | DELETE endpoint по activity_id |
| Обработка ошибок | ✅ | Try-catch, retry, правильные HTTP коды |
| Логирование | ✅ | Полное логирование в БД |
| Масштабируемость | ✅ | Horizontal scaling на Render |
| Время ответа < 6 сек | ✅ | Асинхронная обработка |
| Время отправки < 2 сек | ✅ | Оптимизированные запросы |
| Формат API | ✅ | Точное соответствие ТЗ |

## 10. Демонстрация

Для демонстрации работы системы:

1. Откройте `demo/index.html` в браузере
2. Заполните форму планирования события
3. Наблюдайте за автоматической отправкой уведомлений
4. Проверьте логи и статистику
5. Протестируйте отмену уведомлений

Система полностью соответствует всем требованиям технического задания.