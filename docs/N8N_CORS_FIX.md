# n8n CORS Configuration Guide

## 🚨 Problem
Your n8n webhooks are blocking requests from GitHub Pages due to CORS policy.

## ✅ Solution

### Option 1: Configure n8n Environment Variables (Recommended)

Add these environment variables to your n8n instance on Render:

1. Go to https://dashboard.render.com
2. Select your n8n service
3. Go to **Environment** tab
4. Add these variables:

```
WEBHOOK_CORS_ENABLED=true
WEBHOOK_CORS_ORIGIN=*
```

Or to be more secure, only allow your GitHub Pages domain:
```
WEBHOOK_CORS_ENABLED=true
WEBHOOK_CORS_ORIGIN=https://mainlego.github.io
```

5. Click **Save Changes**
6. The service will automatically redeploy

### Option 2: Configure in Each Webhook Node

In n8n workflow editor:

1. Open each Webhook node
2. Click on **Add Option**
3. Select **Response Headers**
4. Add header:
   - Name: `Access-Control-Allow-Origin`
   - Value: `*` (or `https://mainlego.github.io`)
5. Add another header:
   - Name: `Access-Control-Allow-Methods`
   - Value: `GET, POST, DELETE, OPTIONS`
6. Add another header:
   - Name: `Access-Control-Allow-Headers`
   - Value: `Content-Type`

### Option 3: Use a Proxy (Temporary Workaround)

If you can't modify n8n settings immediately, use a CORS proxy:

1. Update `demo/app.js`:
```javascript
const CONFIG = {
    n8nWebhookUrl: 'https://cors-anywhere.herokuapp.com/https://n8ntest-uwxt.onrender.com',
    // ... rest of config
};
```

Note: This is only for testing. The public CORS proxy has rate limits.

## 🔧 Testing CORS

After applying the fix:

1. Open browser console (F12)
2. Try scheduling a notification
3. Check for CORS errors
4. If successful, you'll see the webhook response

## 📝 Expected Webhook Response

When CORS is properly configured, webhooks should return:
```json
{
  "success": true,
  "message": "Notifications scheduled successfully",
  "scheduled": [
    {
      "type": "day_before",
      "scheduled_time": "2024-01-19T21:00:00Z"
    },
    {
      "type": "three_hours",
      "scheduled_time": "2024-01-20T12:00:00Z"
    }
  ]
}
```

## 🎯 Quick Test

Run this in browser console to test CORS:
```javascript
fetch('https://n8ntest-uwxt.onrender.com/webhook/schedule-notification', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
        id: 'test_user',
        activity_id: 'test_event',
        activity_date: '2024-01-20',
        activity_time: '15:00',
        activity_url: 'https://example.com',
        activity_qr: 'https://example.com/qr.png'
    })
}).then(r => r.json()).then(console.log).catch(console.error);
```

If you get a CORS error, the configuration isn't applied yet.