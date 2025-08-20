#!/bin/bash

# Тестовые скрипты для системы уведомлений
# ==========================================

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
N8N_URL="${N8N_WEBHOOK_URL:-http://localhost:5678}"
API_KEY_SCHEDULE="${WEBHOOK_API_KEY_SCHEDULE:-test_schedule_key}"
API_KEY_CANCEL="${WEBHOOK_API_KEY_CANCEL:-test_cancel_key}"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Тестирование системы уведомлений n8n${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "URL: $N8N_URL"
echo ""

# Функция для форматирования даты
get_tomorrow_date() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -v+1d "+%Y-%m-%d"
    else
        # Linux
        date -d "tomorrow" "+%Y-%m-%d"
    fi
}

# Функция для форматирования времени через 4 часа
get_future_time() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -v+4H "+%H:%M"
    else
        # Linux
        date -d "+4 hours" "+%H:%M"
    fi
}

TOMORROW=$(get_tomorrow_date)
FUTURE_TIME=$(get_future_time)
TEST_ID="test_$(date +%s)"

# Тест 1: Планирование уведомления
echo -e "${GREEN}Тест 1: Планирование уведомления${NC}"
echo "Отправка запроса на планирование..."
echo "Дата события: $TOMORROW"
echo "Время события: $FUTURE_TIME"
echo ""

RESPONSE=$(curl -s -X POST "$N8N_URL/webhook/schedule-notification" \
  -H "X-API-Key: $API_KEY_SCHEDULE" \
  -H "Content-Type: application/json" \
  -d "{
    \"activity_date\": \"$TOMORROW\",
    \"activity_id\": \"$TEST_ID\",
    \"activity_time\": \"$FUTURE_TIME\",
    \"activity_url\": \"https://example.com/manage/$TEST_ID\",
    \"activity_qr\": \"https://example.com/qr/$TEST_ID.png\",
    \"id\": \"user_test_123\"
  }")

echo "Ответ: $RESPONSE"
echo ""

# Проверка успешности
if echo "$RESPONSE" | grep -q "success.*true"; then
    echo -e "${GREEN}✓ Тест 1 пройден успешно${NC}"
else
    echo -e "${RED}✗ Тест 1 провален${NC}"
fi
echo ""

# Задержка перед следующим тестом
sleep 2

# Тест 2: Попытка создать уведомление с прошедшей датой
echo -e "${GREEN}Тест 2: Проверка валидации (прошедшая дата)${NC}"
echo "Отправка запроса с прошедшей датой..."
echo ""

RESPONSE=$(curl -s -X POST "$N8N_URL/webhook/schedule-notification" \
  -H "X-API-Key: $API_KEY_SCHEDULE" \
  -H "Content-Type: application/json" \
  -d '{
    "activity_date": "2020-01-01",
    "activity_id": "test_past",
    "activity_time": "14:30",
    "activity_url": "https://example.com/manage/test_past",
    "activity_qr": "https://example.com/qr/test_past.png",
    "id": "user_test_456"
  }')

echo "Ответ: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q "Event date must be in the future"; then
    echo -e "${GREEN}✓ Тест 2 пройден успешно (валидация работает)${NC}"
else
    echo -e "${RED}✗ Тест 2 провален${NC}"
fi
echo ""

# Задержка перед следующим тестом
sleep 2

# Тест 3: Отмена уведомлений
echo -e "${GREEN}Тест 3: Отмена уведомлений${NC}"
echo "Отправка запроса на отмену для activity_id: $TEST_ID"
echo ""

RESPONSE=$(curl -s -X DELETE "$N8N_URL/webhook/cancel-notifications/$TEST_ID" \
  -H "X-API-Key: $API_KEY_CANCEL")

echo "Ответ: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo -e "${GREEN}✓ Тест 3 пройден успешно${NC}"
else
    echo -e "${RED}✗ Тест 3 провален${NC}"
fi
echo ""

# Тест 4: Проверка неправильного API ключа
echo -e "${GREEN}Тест 4: Проверка безопасности (неправильный API ключ)${NC}"
echo "Отправка запроса с неправильным API ключом..."
echo ""

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$N8N_URL/webhook/schedule-notification" \
  -H "X-API-Key: wrong_key" \
  -H "Content-Type: application/json" \
  -d "{
    \"activity_date\": \"$TOMORROW\",
    \"activity_id\": \"test_auth\",
    \"activity_time\": \"14:30\",
    \"activity_url\": \"https://example.com/manage/test_auth\",
    \"activity_qr\": \"https://example.com/qr/test_auth.png\",
    \"id\": \"user_test_789\"
  }")

echo "HTTP код ответа: $RESPONSE"
echo ""

if [ "$RESPONSE" == "401" ] || [ "$RESPONSE" == "403" ]; then
    echo -e "${GREEN}✓ Тест 4 пройден успешно (аутентификация работает)${NC}"
else
    echo -e "${RED}✗ Тест 4 провален (получен код $RESPONSE вместо 401/403)${NC}"
fi
echo ""

# Тест 5: Проверка обязательных полей
echo -e "${GREEN}Тест 5: Проверка обязательных полей${NC}"
echo "Отправка запроса без activity_id..."
echo ""

RESPONSE=$(curl -s -X POST "$N8N_URL/webhook/schedule-notification" \
  -H "X-API-Key: $API_KEY_SCHEDULE" \
  -H "Content-Type: application/json" \
  -d "{
    \"activity_date\": \"$TOMORROW\",
    \"activity_time\": \"14:30\",
    \"activity_url\": \"https://example.com/manage/test_missing\",
    \"activity_qr\": \"https://example.com/qr/test_missing.png\",
    \"id\": \"user_test_999\"
  }")

echo "Ответ: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q "Missing required field"; then
    echo -e "${GREEN}✓ Тест 5 пройден успешно (валидация полей работает)${NC}"
else
    echo -e "${RED}✗ Тест 5 провален${NC}"
fi

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Тестирование завершено${NC}"
echo -e "${YELLOW}========================================${NC}"