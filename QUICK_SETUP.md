# 🚀 Быстрая настройка демо

## Проблемы, которые вы видите:
1. ❌ **Таблицы Supabase не созданы** - ошибка 404
2. ❌ **CORS блокирует n8n** - демо не может отправлять webhook'и

## ⚡ Быстрое решение (5 минут):

### 1. Создайте таблицы в Supabase:
1. Откройте: https://supabase.com/dashboard/project/xklameqcsrbvepjecwtn/sql
2. Нажмите **New Query**
3. Скопируйте весь текст из файла `database/create-tables-simple.sql`
4. Нажмите **Run**

### 2. Включите Supabase в демо:
Нажмите кнопку **"🔌 Включить Supabase"** в демо интерфейсе

### 3. Исправьте CORS в n8n:
1. Откройте: https://dashboard.render.com
2. Выберите свой n8n сервис
3. Вкладка **Environment**
4. Добавьте:
   ```
   WEBHOOK_CORS_ENABLED=true
   WEBHOOK_CORS_ORIGIN=https://mainlego.github.io
   ```

## ✅ После этого:
- Демо будет работать полностью
- Вы сможете планировать и отменять уведомления
- Данные будут сохраняться в Supabase
- n8n webhooks будут работать

## 🎯 Текущий статус:
- ✅ Демо-интерфейс работает
- ✅ GitHub Pages развернут
- ⏳ Нужно создать таблицы Supabase
- ⏳ Нужно настроить CORS в n8n

**Демо:** https://mainlego.github.io/n8ntest/