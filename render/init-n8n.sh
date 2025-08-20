#!/bin/sh

# Скрипт инициализации n8n на Render
# =====================================

echo "Starting n8n initialization..."

# Ожидание запуска PostgreSQL
echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h $DB_POSTGRESDB_HOST -p 5432 -U postgres
do
  echo "Waiting for database..."
  sleep 2
done

echo "PostgreSQL is ready!"

# Создание базы данных для n8n если не существует
PGPASSWORD=$DB_POSTGRESDB_PASSWORD psql -h $DB_POSTGRESDB_HOST -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'n8n'" | grep -q 1 || \
PGPASSWORD=$DB_POSTGRESDB_PASSWORD psql -h $DB_POSTGRESDB_HOST -U postgres -c "CREATE DATABASE n8n"

# Создание базы данных для уведомлений если не существует
PGPASSWORD=$DB_POSTGRESDB_PASSWORD psql -h $DB_POSTGRESDB_HOST -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'notifications_db'" | grep -q 1 || \
PGPASSWORD=$DB_POSTGRESDB_PASSWORD psql -h $DB_POSTGRESDB_HOST -U postgres -c "CREATE DATABASE notifications_db"

# Выполнение SQL скрипта для создания таблиц уведомлений
echo "Initializing notifications database..."
PGPASSWORD=$DB_POSTGRESDB_PASSWORD psql -h $DB_POSTGRESDB_HOST -U postgres -d notifications_db <<EOF
-- Создание таблицы если не существует
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id SERIAL PRIMARY KEY,
    activity_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    activity_date DATE NOT NULL,
    activity_time TIME NOT NULL,
    activity_url TEXT,
    activity_qr TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    sent_at TIMESTAMP,
    retry_count INTEGER DEFAULT 0,
    error_message TEXT
);

-- Создание индексов если не существуют
CREATE INDEX IF NOT EXISTS idx_scheduled_time_status 
    ON scheduled_notifications(scheduled_time, status);

CREATE INDEX IF NOT EXISTS idx_activity_id 
    ON scheduled_notifications(activity_id);

CREATE INDEX IF NOT EXISTS idx_user_id 
    ON scheduled_notifications(user_id);

CREATE INDEX IF NOT EXISTS idx_status_scheduled_time 
    ON scheduled_notifications(status, scheduled_time) 
    WHERE status = 'pending';

-- Создание представления для статистики
CREATE OR REPLACE VIEW notification_statistics AS
SELECT 
    DATE(scheduled_time) as notification_date,
    notification_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (sent_at - scheduled_time))) as avg_delay_seconds
FROM scheduled_notifications
GROUP BY DATE(scheduled_time), notification_type, status
ORDER BY notification_date DESC, notification_type, status;

-- Функция для очистки старых записей
CREATE OR REPLACE FUNCTION cleanup_old_notifications() 
RETURNS void AS \$\$
BEGIN
    DELETE FROM scheduled_notifications 
    WHERE status IN ('sent', 'cancelled') 
    AND created_at < NOW() - INTERVAL '30 days';
END;
\$\$ LANGUAGE plpgsql;

GRANT ALL PRIVILEGES ON DATABASE notifications_db TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
EOF

echo "Database initialization completed!"

# Создание файла с информацией о подключении для n8n
cat > /home/node/.n8n/render-config.json <<EOF
{
  "database": {
    "type": "postgresdb",
    "host": "$DB_POSTGRESDB_HOST",
    "port": 5432,
    "database": "n8n",
    "user": "postgres",
    "password": "$DB_POSTGRESDB_PASSWORD"
  },
  "notifications_database": {
    "host": "$DB_POSTGRESDB_HOST",
    "port": 5432,
    "database": "notifications_db",
    "user": "postgres",
    "password": "$DB_POSTGRESDB_PASSWORD"
  }
}
EOF

echo "n8n initialization completed successfully!"