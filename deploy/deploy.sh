#!/bin/bash

# Скрипт развертывания системы уведомлений n8n
# =============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  n8n Notification System Deployment ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Функция для проверки команд
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 не установлен. Пожалуйста, установите $1${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $1 установлен${NC}"
    fi
}

# Проверка зависимостей
echo -e "${YELLOW}Проверка зависимостей...${NC}"
check_command docker
check_command docker-compose
echo ""

# Меню развертывания
echo -e "${YELLOW}Выберите режим развертывания:${NC}"
echo "1) Локальная разработка (HTTP, порт 5678)"
echo "2) Production с Nginx (HTTPS, требует домен)"
echo "3) Остановить все контейнеры"
echo "4) Просмотр логов"
echo "5) Резервное копирование БД"
echo "6) Восстановление БД"
echo "7) Обновление n8n"
echo "8) Полная очистка (УДАЛИТ ВСЕ ДАННЫЕ!)"
read -p "Выбор (1-8): " choice

case $choice in
    1)
        echo -e "${GREEN}Запуск в режиме разработки...${NC}"
        docker-compose up -d postgres n8n
        echo ""
        echo -e "${GREEN}✓ Система запущена!${NC}"
        echo -e "${BLUE}n8n доступен по адресу: http://localhost:5678${NC}"
        echo -e "${BLUE}Логин: admin | Пароль: admin123${NC}"
        echo ""
        echo -e "${YELLOW}Ожидание запуска n8n...${NC}"
        sleep 10
        echo -e "${GREEN}Проверка статуса:${NC}"
        docker-compose ps
        ;;
        
    2)
        echo -e "${YELLOW}Production развертывание${NC}"
        read -p "Введите ваш домен (например, n8n.example.com): " domain
        
        # Обновление домена в nginx.conf
        sed -i "s/your-domain.com/$domain/g" nginx.conf
        
        echo -e "${YELLOW}Настройка SSL сертификатов...${NC}"
        echo "1) У меня есть SSL сертификаты"
        echo "2) Получить через Let's Encrypt"
        echo "3) Использовать самоподписанные (для тестирования)"
        read -p "Выбор (1-3): " ssl_choice
        
        case $ssl_choice in
            1)
                echo "Поместите файлы в папку ./ssl/:"
                echo "  - fullchain.pem"
                echo "  - privkey.pem"
                read -p "Нажмите Enter когда файлы будут готовы..."
                ;;
            2)
                echo -e "${GREEN}Получение сертификатов Let's Encrypt...${NC}"
                docker run -it --rm \
                    -v $(pwd)/ssl:/etc/letsencrypt \
                    -p 80:80 \
                    certbot/certbot certonly \
                    --standalone \
                    -d $domain \
                    --agree-tos \
                    --email your-email@example.com \
                    --non-interactive
                
                # Копирование сертификатов
                cp ssl/live/$domain/fullchain.pem ssl/fullchain.pem
                cp ssl/live/$domain/privkey.pem ssl/privkey.pem
                ;;
            3)
                echo -e "${YELLOW}Создание самоподписанных сертификатов...${NC}"
                mkdir -p ssl
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout ssl/privkey.pem \
                    -out ssl/fullchain.pem \
                    -subj "/C=RU/ST=Moscow/L=Moscow/O=Company/CN=$domain"
                ;;
        esac
        
        # Обновление webhook URL в docker-compose
        sed -i "s|WEBHOOK_URL: http://localhost:5678|WEBHOOK_URL: https://$domain|g" docker-compose.yml
        sed -i "s|N8N_WEBHOOK_URL: http://localhost:5678|N8N_WEBHOOK_URL: https://$domain|g" docker-compose.yml
        
        echo -e "${GREEN}Запуск production окружения...${NC}"
        docker-compose --profile production up -d
        
        echo ""
        echo -e "${GREEN}✓ Production система запущена!${NC}"
        echo -e "${BLUE}n8n доступен по адресу: https://$domain${NC}"
        echo -e "${BLUE}Логин: admin | Пароль: admin123${NC}"
        echo -e "${RED}⚠️  ВАЖНО: Смените пароль администратора!${NC}"
        ;;
        
    3)
        echo -e "${YELLOW}Остановка контейнеров...${NC}"
        docker-compose down
        echo -e "${GREEN}✓ Все контейнеры остановлены${NC}"
        ;;
        
    4)
        echo -e "${YELLOW}Просмотр логов. Выберите сервис:${NC}"
        echo "1) n8n"
        echo "2) PostgreSQL"
        echo "3) Nginx"
        echo "4) Все сервисы"
        read -p "Выбор (1-4): " log_choice
        
        case $log_choice in
            1) docker-compose logs -f n8n ;;
            2) docker-compose logs -f postgres ;;
            3) docker-compose logs -f nginx ;;
            4) docker-compose logs -f ;;
        esac
        ;;
        
    5)
        echo -e "${YELLOW}Создание резервной копии БД...${NC}"
        timestamp=$(date +%Y%m%d_%H%M%S)
        backup_file="backup_${timestamp}.sql"
        
        docker-compose exec -T postgres pg_dump -U postgres notifications_db > backups/$backup_file
        
        echo -e "${GREEN}✓ Резервная копия создана: backups/$backup_file${NC}"
        ;;
        
    6)
        echo -e "${YELLOW}Восстановление из резервной копии${NC}"
        echo "Доступные резервные копии:"
        ls -la backups/*.sql 2>/dev/null || echo "Нет резервных копий"
        
        read -p "Введите имя файла резервной копии: " backup_file
        
        if [ -f "backups/$backup_file" ]; then
            docker-compose exec -T postgres psql -U postgres notifications_db < backups/$backup_file
            echo -e "${GREEN}✓ База данных восстановлена${NC}"
        else
            echo -e "${RED}❌ Файл не найден${NC}"
        fi
        ;;
        
    7)
        echo -e "${YELLOW}Обновление n8n до последней версии...${NC}"
        docker-compose pull n8n
        docker-compose up -d n8n
        echo -e "${GREEN}✓ n8n обновлен${NC}"
        ;;
        
    8)
        echo -e "${RED}⚠️  ВНИМАНИЕ: Это удалит ВСЕ данные!${NC}"
        read -p "Вы уверены? Введите 'YES' для подтверждения: " confirm
        
        if [ "$confirm" = "YES" ]; then
            docker-compose down -v
            rm -rf ssl/*
            echo -e "${GREEN}✓ Все данные удалены${NC}"
        else
            echo -e "${YELLOW}Отменено${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}         Операция завершена          ${NC}"
echo -e "${BLUE}=====================================${NC}"