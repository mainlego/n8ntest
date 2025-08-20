-- Создание базы данных для системы уведомлений
-- Выполните этот скрипт в вашей PostgreSQL базе данных

-- Создание основной таблицы для хранения запланированных уведомлений
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id SERIAL PRIMARY KEY,
    activity_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- 'day_before' | 'three_hours'
    scheduled_time TIMESTAMP NOT NULL,
    activity_date DATE NOT NULL,
    activity_time TIME NOT NULL,
    activity_url TEXT,
    activity_qr TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending' | 'sent' | 'cancelled' | 'failed'
    created_at TIMESTAMP DEFAULT NOW(),
    sent_at TIMESTAMP,
    retry_count INTEGER DEFAULT 0,
    error_message TEXT
);

-- Создание индексов для оптимизации производительности
CREATE INDEX IF NOT EXISTS idx_scheduled_time_status 
    ON scheduled_notifications(scheduled_time, status);

CREATE INDEX IF NOT EXISTS idx_activity_id 
    ON scheduled_notifications(activity_id);

CREATE INDEX IF NOT EXISTS idx_user_id 
    ON scheduled_notifications(user_id);

-- Создание индекса для быстрого поиска pending уведомлений
CREATE INDEX IF NOT EXISTS idx_status_scheduled_time 
    ON scheduled_notifications(status, scheduled_time) 
    WHERE status = 'pending';

-- Комментарии к таблице и колонкам
COMMENT ON TABLE scheduled_notifications IS 'Таблица для хранения запланированных уведомлений о событиях';
COMMENT ON COLUMN scheduled_notifications.activity_id IS 'Идентификатор события';
COMMENT ON COLUMN scheduled_notifications.user_id IS 'Идентификатор пользователя';
COMMENT ON COLUMN scheduled_notifications.notification_type IS 'Тип уведомления: day_before (накануне) или three_hours (за 3 часа)';
COMMENT ON COLUMN scheduled_notifications.scheduled_time IS 'Время отправки уведомления';
COMMENT ON COLUMN scheduled_notifications.activity_date IS 'Дата события';
COMMENT ON COLUMN scheduled_notifications.activity_time IS 'Время события';
COMMENT ON COLUMN scheduled_notifications.activity_url IS 'URL для управления записью';
COMMENT ON COLUMN scheduled_notifications.activity_qr IS 'URL QR-кода для подтверждения';
COMMENT ON COLUMN scheduled_notifications.status IS 'Статус уведомления: pending, sent, cancelled, failed';
COMMENT ON COLUMN scheduled_notifications.retry_count IS 'Количество попыток отправки';
COMMENT ON COLUMN scheduled_notifications.error_message IS 'Сообщение об ошибке при неудачной отправке';

-- Функция для автоматической очистки старых записей (опционально)
CREATE OR REPLACE FUNCTION cleanup_old_notifications() 
RETURNS void AS $$
BEGIN
    DELETE FROM scheduled_notifications 
    WHERE status IN ('sent', 'cancelled') 
    AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Создание представления для мониторинга
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