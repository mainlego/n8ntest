# Supabase Database Setup Guide

## 📋 Quick Setup Instructions

### Step 1: Run the SQL Script

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/xklameqcsrbvepjecwtn
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy and paste the entire contents of `database/supabase-setup.sql`
5. Click **Run** button

### Step 2: Verify Tables Created

1. Go to **Table Editor** in the left sidebar
2. You should see two new tables:
   - `scheduled_notifications`
   - `notification_logs`

### Step 3: Check RLS Policies

1. Click on each table
2. Go to **RLS Policies** tab
3. Verify that policies are enabled and configured

## 🔧 Troubleshooting

### If tables already exist:
The script uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run multiple times.

### If you get permission errors:
Make sure you're logged in as the database owner or have admin privileges.

### To reset everything:
```sql
-- Drop existing tables (WARNING: This deletes all data!)
DROP TABLE IF EXISTS notification_logs CASCADE;
DROP TABLE IF EXISTS scheduled_notifications CASCADE;
```
Then run the setup script again.

## ✅ Success Indicators

After running the script, you should be able to:
1. See both tables in Table Editor
2. View the demo at https://mainlego.github.io/n8ntest/ without 404 errors
3. Schedule and view notifications in the demo interface

## 📝 Manual Table Creation (Alternative)

If the SQL script doesn't work, you can create tables manually in Supabase:

### Table: scheduled_notifications
| Column | Type | Default | Nullable |
|--------|------|---------|----------|
| id | int8 | auto-increment | No |
| activity_id | text | - | No |
| user_id | text | - | No |
| notification_type | text | - | No |
| scheduled_time | timestamptz | - | No |
| status | text | 'pending' | Yes |
| activity_time | text | - | Yes |
| activity_url | text | - | Yes |
| activity_qr | text | - | Yes |
| sent_at | timestamptz | - | Yes |
| created_at | timestamptz | now() | Yes |
| updated_at | timestamptz | now() | Yes |

### Table: notification_logs
| Column | Type | Default | Nullable |
|--------|------|---------|----------|
| id | int8 | auto-increment | No |
| notification_id | int8 | - | Yes |
| activity_id | text | - | Yes |
| user_id | text | - | Yes |
| status | text | - | Yes |
| response_data | jsonb | - | Yes |
| execution_time | int4 | - | Yes |
| error_message | text | - | Yes |
| created_at | timestamptz | now() | Yes |