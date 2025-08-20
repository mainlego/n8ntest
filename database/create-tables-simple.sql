-- Простой SQL для создания таблиц в Supabase
-- Копируйте и выполните в SQL Editor на Supabase

-- Таблица для запланированных уведомлений
CREATE TABLE scheduled_notifications (
    id SERIAL PRIMARY KEY,
    activity_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    scheduled_time TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'pending',
    activity_time TEXT,
    activity_url TEXT,
    activity_qr TEXT,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Таблица для логов уведомлений
CREATE TABLE notification_logs (
    id SERIAL PRIMARY KEY,
    notification_id INTEGER REFERENCES scheduled_notifications(id),
    activity_id TEXT,
    user_id TEXT,
    status TEXT,
    response_data JSONB,
    execution_time INTEGER,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Индексы для производительности
CREATE INDEX idx_scheduled_notifications_activity_id ON scheduled_notifications(activity_id);
CREATE INDEX idx_scheduled_notifications_status ON scheduled_notifications(status);
CREATE INDEX idx_scheduled_notifications_scheduled_time ON scheduled_notifications(scheduled_time);