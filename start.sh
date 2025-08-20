#!/bin/sh
# Скрипт запуска n8n для Render

# Экспорт переменных окружения
export N8N_HOST=0.0.0.0
export N8N_PORT=${PORT:-5678}
export N8N_PROTOCOL=https
export WEBHOOK_URL=https://n8ntest-uwxt.onrender.com

# Запуск n8n
if [ -f /usr/local/bin/n8n ]; then
    echo "Starting n8n from /usr/local/bin/n8n"
    /usr/local/bin/n8n
elif command -v n8n >/dev/null 2>&1; then
    echo "Starting n8n from PATH"
    n8n
elif [ -f ./node_modules/.bin/n8n ]; then
    echo "Starting n8n from node_modules"
    ./node_modules/.bin/n8n
else
    echo "Starting n8n with npx"
    npx n8n
fi