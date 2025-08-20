# 🚀 Развертывание системы уведомлений n8n

## Способы развертывания

### 1️⃣ Docker (Рекомендуется)

Самый простой способ - использовать Docker Compose:

```powershell
cd deploy
.\deploy.ps1
# Выберите опцию 1 для локального развертывания
```

Система будет доступна по адресу: http://localhost:5678

### 2️⃣ Локальная установка n8n

Если вы хотите запустить n8n локально без Docker:

#### Установка n8n глобально:
```bash
npm install -g n8n
```

#### Запуск с переменными окружения:
```powershell
# Загрузка переменных из .env
Get-Content ..\.env | ForEach-Object {
    if ($_ -match '^([^#].*)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

# Запуск n8n
n8n start
```

### 3️⃣ Production развертывание

Для production используйте Docker Compose с Nginx:

```powershell
.\deploy.ps1
# Выберите опцию 2
```

## 📋 Требования

### Для Docker развертывания:
- Docker Desktop для Windows
- 4GB RAM минимум
- 10GB свободного места

### Для локальной установки:
- Node.js 18+
- PostgreSQL 12+
- 2GB RAM минимум

## 🔧 Конфигурация

### Переменные окружения

Основные переменные в `.env`:
- `N8N_WEBHOOK_URL` - публичный URL для webhook
- `NOTIFICATION_API_URL` - URL вашего API для отправки
- `WEBHOOK_API_KEY_*` - ключи безопасности

### База данных

PostgreSQL настройки:
- Host: `localhost` (или `postgres` в Docker)
- Port: `5432`
- Database: `notifications_db`
- User: `postgres`
- Password: `lego1994vM!`

## 🛠 Управление

### Запуск системы
```powershell
# Docker
docker-compose up -d

# Локально
n8n start
```

### Остановка
```powershell
# Docker
docker-compose down

# Локально
Ctrl+C в терминале
```

### Просмотр логов
```powershell
# Docker
docker-compose logs -f n8n

# Локально
Логи выводятся в консоль
```

### Резервное копирование
```powershell
.\deploy.ps1
# Выберите опцию 5
```

## 📊 Мониторинг

### Проверка статуса контейнеров:
```powershell
docker-compose ps
```

### Проверка здоровья БД:
```powershell
docker-compose exec postgres pg_isready -U postgres
```

### Проверка логов ошибок:
```powershell
docker-compose logs --tail=50 n8n | Select-String "ERROR"
```

## 🔒 Безопасность

### Production чеклист:

- [ ] Сменить пароль администратора n8n
- [ ] Настроить SSL сертификаты
- [ ] Изменить API ключи в `.env`
- [ ] Настроить firewall правила
- [ ] Включить логирование
- [ ] Настроить резервное копирование
- [ ] Ограничить доступ по IP

### Получение SSL сертификатов:

#### Let's Encrypt (бесплатно):
```bash
docker run -it --rm \
    -v ./ssl:/etc/letsencrypt \
    -p 80:80 \
    certbot/certbot certonly \
    --standalone \
    -d your-domain.com
```

#### Самоподписанные (для тестирования):
```powershell
.\deploy.ps1
# Выберите опцию 2, затем опцию создания самоподписанных
```

## 🐛 Устранение неполадок

### n8n не запускается
1. Проверьте порт 5678: `netstat -an | findstr :5678`
2. Проверьте логи: `docker-compose logs n8n`
3. Проверьте память: `docker system df`

### Ошибка подключения к БД
1. Проверьте что PostgreSQL запущен
2. Проверьте credentials в n8n
3. Проверьте сеть Docker: `docker network ls`

### Webhook не работают
1. Проверьте `N8N_WEBHOOK_URL` в `.env`
2. Проверьте firewall настройки
3. Проверьте API ключи

## 📦 Структура развертывания

```
deploy/
├── docker-compose.yml    # Конфигурация Docker
├── nginx.conf            # Конфигурация Nginx для HTTPS
├── deploy.ps1            # PowerShell скрипт развертывания
├── deploy.sh             # Bash скрипт для Linux/Mac
├── ssl/                  # SSL сертификаты (создается автоматически)
└── backups/              # Резервные копии БД (создается автоматически)
```

## 🔄 Обновление

### Обновление n8n:
```powershell
.\deploy.ps1
# Выберите опцию 7
```

### Обновление PostgreSQL:
```powershell
# Создайте резервную копию
.\deploy.ps1  # Опция 5

# Обновите образ
docker-compose pull postgres

# Перезапустите
docker-compose up -d postgres
```

## 📞 Поддержка

При проблемах проверьте:
1. Логи: `docker-compose logs`
2. Статус: `docker-compose ps`
3. Ресурсы: `docker stats`

Для детальной диагностики включите debug режим:
```powershell
$env:N8N_LOG_LEVEL = "debug"
docker-compose up -d n8n
```