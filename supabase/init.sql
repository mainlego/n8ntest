-- Создание таблицы для хранения запланированных уведомлений
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id SERIAL PRIMARY KEY,
    activity_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- 'day_before' | 'three_hours'
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    activity_date DATE NOT NULL,
    activity_time TIME NOT NULL,
    activity_url TEXT,
    activity_qr TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending' | 'sent' | 'cancelled' | 'failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    notification_data JSONB -- Для хранения полных данных уведомления
);

-- Индексы для оптимизации
CREATE INDEX IF NOT EXISTS idx_scheduled_time_status 
    ON scheduled_notifications(scheduled_time, status);
CREATE INDEX IF NOT EXISTS idx_activity_id 
    ON scheduled_notifications(activity_id);
CREATE INDEX IF NOT EXISTS idx_user_id 
    ON scheduled_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_status_scheduled 
    ON scheduled_notifications(status, scheduled_time) 
    WHERE status = 'pending';

-- Таблица для логирования всех операций
CREATE TABLE IF NOT EXISTS notification_logs (
    id SERIAL PRIMARY KEY,
    operation_type VARCHAR(50) NOT NULL, -- 'schedule' | 'send' | 'cancel' | 'error'
    activity_id VARCHAR(255),
    user_id VARCHAR(255),
    request_data JSONB,
    response_data JSONB,
    status_code INTEGER,
    execution_time_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address VARCHAR(45),
    error_message TEXT
);

-- Индекс для логов
CREATE INDEX IF NOT EXISTS idx_logs_created ON notification_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_activity ON notification_logs(activity_id);

-- Представление для статистики
CREATE OR REPLACE VIEW notification_statistics AS
SELECT 
    DATE(scheduled_time) as notification_date,
    notification_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (sent_at - scheduled_time))) as avg_delay_seconds
FROM scheduled_notifications
GROUP BY DATE(scheduled_time), notification_type, status
ORDER BY notification_date DESC;

-- Функция для очистки старых записей
CREATE OR REPLACE FUNCTION cleanup_old_notifications() 
RETURNS void AS $$
BEGIN
    DELETE FROM scheduled_notifications 
    WHERE status IN ('sent', 'cancelled') 
    AND created_at < NOW() - INTERVAL '30 days';
    
    DELETE FROM notification_logs
    WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Включаем Row Level Security для Supabase
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Политики доступа (для публичного API Supabase)
CREATE POLICY "Enable all for service role" ON scheduled_notifications
    FOR ALL USING (true);

CREATE POLICY "Enable all for service role logs" ON notification_logs
    FOR ALL USING (true);