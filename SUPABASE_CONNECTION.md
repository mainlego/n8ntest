# 🔧 Настройка подключения к Supabase

## Правильные параметры подключения:

### Вариант 1: Прямое подключение (рекомендую)
```
Host: db.xklameqcsrbvepjecwtn.supabase.co
Port: 6543
Database: postgres  
User: postgres.xklameqcsrbvepjecwtn
Password: lego1994vM!
SSL: Require
```

### Вариант 2: Pooling подключение
```
Host: aws-0-eu-central-1.pooler.supabase.com
Port: 6543
Database: postgres
User: postgres.xklameqcsrbvepjecwtn
Password: lego1994vM!
SSL: Require
```

### Вариант 3: Connection String
```
postgresql://postgres.xklameqcsrbvepjecwtn:lego1994vM!@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
```

## Важно:
- Порт Supabase: **6543** (не 5432!)
- Пользователь с префиксом проекта: **postgres.xklameqcsrbvepjecwtn**
- SSL обязателен: **Require**

## Если все еще не работает:

1. Зайдите в Supabase Dashboard
2. Settings → Database
3. Скопируйте Connection String (URI)
4. Используйте в n8n как есть