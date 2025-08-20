# GitHub Pages Setup Instructions

## Enabling GitHub Pages for Demo Frontend

Follow these steps to deploy your n8n notification system demo on GitHub Pages:

### 1. Go to Repository Settings
1. Navigate to https://github.com/mainlego/n8ntest
2. Click on "Settings" tab

### 2. Enable GitHub Pages
1. Scroll down to "Pages" section in the left sidebar
2. Under "Source", select "Deploy from a branch"
3. Choose "main" branch
4. Select "/ (root)" as the folder
5. Click "Save"

### 3. Wait for Deployment
- GitHub will take 1-2 minutes to build and deploy your site
- You'll see a green checkmark when it's ready

### 4. Access Your Demo
Your demo will be available at:
```
https://mainlego.github.io/n8ntest/
```

The site will automatically redirect to `/demo/index.html`

## What's Deployed

The demo includes:
- **Interactive Form**: Schedule notifications with user/event details
- **Live Dashboard**: View scheduled, sent, and cancelled notifications
- **Supabase Integration**: Real-time database operations
- **Statistics**: Track notification metrics
- **Activity Logs**: Monitor all system operations

## Features

✅ **Supabase Integration**: Uses your actual Supabase database
✅ **n8n Webhook Calls**: Connects to your n8n instance at https://n8ntest-uwxt.onrender.com
✅ **Real-time Updates**: Automatically refreshes every 5 seconds
✅ **Fallback Mode**: Works even if backend is unavailable (demo mode)

## Testing the System

1. **Schedule a Notification**:
   - Fill in the form with event details
   - Click "Запланировать уведомления"
   - Two notifications will be created (day before at 21:00 and 3 hours before)

2. **Cancel Notifications**:
   - Find the notification in the list
   - Click "Отменить" button
   - Status will update to "cancelled"

3. **Monitor Logs**:
   - All operations are logged at the bottom
   - Shows success/error messages with timestamps

## Troubleshooting

If the demo doesn't work:
1. Check that n8n workflows are imported and active
2. Verify Supabase credentials in n8n PostgreSQL node
3. Check browser console for errors (F12)
4. Ensure CORS is enabled on your n8n instance

## Next Steps

1. Import n8n workflows into your instance
2. Configure PostgreSQL credentials in n8n
3. Test the complete flow from frontend to database
4. Monitor notification scheduling and sending