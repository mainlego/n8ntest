-- Create scheduled_notifications table
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id SERIAL PRIMARY KEY,
    activity_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    activity_time VARCHAR(10),
    activity_url TEXT,
    activity_qr TEXT,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create notification_logs table
CREATE TABLE IF NOT EXISTS notification_logs (
    id SERIAL PRIMARY KEY,
    notification_id INTEGER REFERENCES scheduled_notifications(id),
    activity_id VARCHAR(255),
    user_id VARCHAR(255),
    status VARCHAR(50),
    response_data JSONB,
    execution_time INTEGER,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_activity_id ON scheduled_notifications(activity_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_user_id ON scheduled_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_status ON scheduled_notifications(status);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_scheduled_time ON scheduled_notifications(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_notification_logs_activity_id ON notification_logs(activity_id);

-- Enable Row Level Security (optional but recommended)
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for anonymous access (for demo purposes)
-- In production, you'd want more restrictive policies
CREATE POLICY "Enable read access for all users" ON scheduled_notifications
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for all users" ON scheduled_notifications
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for all users" ON scheduled_notifications
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for all users" ON scheduled_notifications
    FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON notification_logs
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for all users" ON notification_logs
    FOR INSERT WITH CHECK (true);