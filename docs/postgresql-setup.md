# Настройка PostgreSQL в n8n

## 🔧 Настройка PostgreSQL Credentials в n8n

### Шаг 1: Создание базы данных

Сначала создайте базу данных для уведомлений:

```sql
-- Подключитесь к PostgreSQL как суперпользователь
psql -U postgres

-- Создайте базу данных
CREATE DATABASE notifications_db;

-- Подключитесь к новой базе данных
\c notifications_db

-- Выполните скрипт инициализации
\i C:\Users\mainv\WebstormProjects\n8ntest\database\init.sql
```

### Шаг 2: Заполнение полей в n8n PostgreSQL Credentials

В n8n откройте раздел **Credentials** → **Create New** → **PostgreSQL** и заполните поля:

| Поле | Значение | Описание |
|------|----------|----------|
| **Credential Name** | `PostgreSQL Notifications` | Любое удобное имя |
| **Host** | `localhost` | Если PostgreSQL на том же сервере что и n8n |
| **Database** | `notifications_db` | Имя созданной базы данных |
| **User** | `postgres` | Пользователь PostgreSQL |
| **Password** | `postgres` | Пароль пользователя (измените на свой) |
| **Port** | `5432` | Стандартный порт PostgreSQL |
| **SSL** | `Disable` | Для локальной разработки |
| **Maximum Number of Connections** | `100` | Оставьте по умолчанию |
| **Ignore SSL Issues** | ☐ (не отмечено) | Для локальной разработки |
| **SSH Tunnel** | `Disable` | Не требуется для локального подключения |

### Шаг 3: Проверка подключения

1. Нажмите кнопку **Test Connection** в n8n
2. Должно появиться сообщение "Connection successful"

### Шаг 4: Важные замечания для разных сценариев

#### 🏠 Локальная разработка (PostgreSQL на том же компьютере):
```
Host: localhost
Port: 5432
SSL: Disable
SSH Tunnel: Disable
```

#### 🌐 PostgreSQL на удаленном сервере:
```
Host: your-server-ip или domain.com
Port: 5432
SSL: Require (рекомендуется)
SSH Tunnel: Enable (если требуется)
```

#### 🐳 Docker окружение:
```
Host: postgres (имя контейнера) или host.docker.internal
Port: 5432
SSL: Disable
SSH Tunnel: Disable
```

#### ☁️ Облачные базы данных:

**AWS RDS:**
```
Host: your-instance.region.rds.amazonaws.com
Port: 5432
SSL: Require
```

**Google Cloud SQL:**
```
Host: IP адрес инстанса
Port: 5432
SSL: Require
```

**Heroku Postgres:**
```
Host: ec2-xx-xxx-xxx-xx.compute-1.amazonaws.com
Port: 5432
SSL: Require
```

### Шаг 5: Проверка работы базы данных

После настройки выполните SQL запрос для проверки:

```sql
-- Проверка что таблица создана
SELECT COUNT(*) FROM scheduled_notifications;

-- Должно вернуть 0, если таблица пустая
```

### Шаг 6: Устранение проблем

#### ❌ Ошибка "Connection refused"
- Проверьте что PostgreSQL запущен: `pg_ctl status` или `systemctl status postgresql`
- Проверьте что PostgreSQL слушает на правильном порту: `netstat -an | grep 5432`

#### ❌ Ошибка "FATAL: password authentication failed"
- Проверьте правильность пароля
- Убедитесь что пользователь существует: `\du` в psql
- Проверьте файл pg_hba.conf для настроек аутентификации

#### ❌ Ошибка "database does not exist"
- Создайте базу данных: `CREATE DATABASE notifications_db;`
- Проверьте список баз: `\l` в psql

#### ❌ Ошибка "relation does not exist"
- Выполните скрипт инициализации: `\i database/init.sql`
- Проверьте что таблицы созданы: `\dt` в psql

### Шаг 7: Рекомендации по безопасности

1. **Не используйте пользователя postgres в продакшене**
   ```sql
   CREATE USER n8n_user WITH PASSWORD 'strong_password';
   GRANT ALL PRIVILEGES ON DATABASE notifications_db TO n8n_user;
   GRANT ALL ON ALL TABLES IN SCHEMA public TO n8n_user;
   GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO n8n_user;
   ```

2. **Используйте SSL для удаленных подключений**
   - Установите SSL: Require в n8n credentials

3. **Ограничьте доступ по IP**
   - Настройте pg_hba.conf для разрешения подключений только с определенных IP

4. **Регулярно обновляйте пароли**
   - Меняйте пароли каждые 90 дней

### Дополнительные настройки для production

```sql
-- Создание отдельного пользователя для n8n
CREATE USER n8n_notifications WITH PASSWORD 'SecurePassword123!';

-- Создание схемы
CREATE SCHEMA IF NOT EXISTS notifications;

-- Выдача прав
GRANT USAGE ON SCHEMA notifications TO n8n_notifications;
GRANT CREATE ON SCHEMA notifications TO n8n_notifications;
ALTER DEFAULT PRIVILEGES IN SCHEMA notifications GRANT ALL ON TABLES TO n8n_notifications;
ALTER DEFAULT PRIVILEGES IN SCHEMA notifications GRANT ALL ON SEQUENCES TO n8n_notifications;

-- Установка search_path
ALTER USER n8n_notifications SET search_path TO notifications, public;
```

После настройки credentials сохраните их и используйте во всех трех workflow для подключения к базе данных.