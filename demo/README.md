# n8n Notification System - Demo Interface

## 🚀 Live Demo
Access the demo at: https://mainlego.github.io/n8ntest/

## 📋 Overview
This is a demonstration interface for the n8n notification scheduling system. It showcases the complete workflow of scheduling, managing, and tracking event notifications.

## 🔧 Configuration

The demo is configured to work with:
- **n8n Instance**: https://n8ntest-uwxt.onrender.com
- **Database**: Supabase PostgreSQL
- **Auto-refresh**: Every 5 seconds

## 💡 Features

### Schedule Notifications
- Enter user and event details
- Automatically creates two notifications:
  - Day before at 21:00
  - 3 hours before event

### Real-time Dashboard
- View all scheduled notifications
- Track notification status (pending/sent/cancelled)
- Live statistics

### Database Integration
- Connects to Supabase for data persistence
- Falls back to demo mode if database is unavailable

## 🛠 Local Development

To run locally:
```bash
cd demo
node server.js
```
Then open http://localhost:3000

## 📝 API Endpoints

### Schedule Notification
```
POST /webhook/schedule-notification
Body: {
  "id": "user_id",
  "activity_id": "event_id",
  "activity_date": "YYYY-MM-DD",
  "activity_time": "HH:MM",
  "activity_url": "https://...",
  "activity_qr": "https://..."
}
```

### Cancel Notifications
```
DELETE /webhook/cancel-notifications/{activity_id}
```

## 🔐 Security Note
This demo uses a public Supabase anon key which is safe for frontend use. The key only allows operations permitted by your Supabase RLS policies.