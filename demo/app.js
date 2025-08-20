// Конфигурация
const CONFIG = {
    n8nWebhookUrl: 'https://n8ntest-uwxt.onrender.com',
    supabaseUrl: 'https://xklameqcsrbvepjecwtn.supabase.co',
    supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrbGFtZXFjc3JidmVwamVjd3RuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3MjE5MTIsImV4cCI6MjA3MTI5NzkxMn0.M82x241D4KgJ3GCKURlRfdr1qWsjLmjrWvzUMIMn9Oc',
    refreshInterval: 5000 // Обновление каждые 5 секунд
};

// Инициализация Supabase
let supabase = null;
let supabaseEnabled = false; // Временно отключаем пока не создадут таблицы

// Проверка доступности Supabase
async function checkSupabaseConnection() {
    if (!supabaseEnabled) return false;
    
    if (typeof window !== 'undefined' && window.supabase && !supabase) {
        supabase = window.supabase.createClient(CONFIG.supabaseUrl, CONFIG.supabaseKey);
    }
    return supabase !== null;
}

// Функция для включения Supabase после создания таблиц
function enableSupabase() {
    supabaseEnabled = true;
    if (typeof window !== 'undefined' && window.supabase) {
        supabase = window.supabase.createClient(CONFIG.supabaseUrl, CONFIG.supabaseKey);
        addLog('success', 'Supabase подключен! Попробуйте запланировать уведомление.');
        
        // Обновляем статус в интерфейсе
        document.getElementById('supabaseStatus').textContent = 'Подключен';
        document.getElementById('enableSupabaseBtn').textContent = '✅ Supabase подключен';
        document.getElementById('enableSupabaseBtn').disabled = true;
        
        loadNotifications(); // Перезагружаем данные
    }
}

// Глобальная функция для включения из консоли
window.enableSupabase = enableSupabase;

// Глобальные переменные
let notifications = [];
let stats = {
    pending: 0,
    sent: 0,
    cancelled: 0,
    total: 0
};

// Инициализация при загрузке
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    
    // Установка даты на завтра по умолчанию
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    document.getElementById('activityDate').value = tomorrow.toISOString().split('T')[0];
    
    // Обработчик формы
    document.getElementById('scheduleForm').addEventListener('submit', handleSchedule);
    
    // Обновление данных
    setInterval(loadNotifications, CONFIG.refreshInterval);
});

// Инициализация приложения
function initializeApp() {
    document.getElementById('webhookUrl').textContent = CONFIG.n8nWebhookUrl;
    loadNotifications();
    addLog('info', 'Система инициализирована');
    
    if (!supabaseEnabled) {
        addLog('warning', 'Supabase временно отключен. Создайте таблицы и выполните enableSupabase() в консоли.');
        showAlert('warning', '⚠️ Для полной функциональности создайте таблицы в Supabase (см. документацию)');
    }
}

// Обработка планирования
async function handleSchedule(e) {
    e.preventDefault();
    
    const formData = {
        id: document.getElementById('userId').value,
        activity_id: document.getElementById('activityId').value,
        activity_date: document.getElementById('activityDate').value,
        activity_time: document.getElementById('activityTime').value,
        activity_url: document.getElementById('activityUrl').value,
        activity_qr: document.getElementById('activityQr').value
    };
    
    showAlert('info', 'Отправка запроса...');
    const startTime = Date.now();
    
    try {
        const response = await fetch(`${CONFIG.n8nWebhookUrl}/webhook/schedule-notification`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const executionTime = Date.now() - startTime;
        const data = await response.json();
        
        if (response.ok && data.success) {
            showAlert('success', `✅ Уведомления запланированы! (${executionTime}ms)`);
            addLog('success', `Запланированы уведомления для события ${formData.activity_id} (время выполнения: ${executionTime}ms)`);
            
            // Сохраняем в Supabase для демо
            if (supabase) {
                await saveNotificationsToSupabase(formData);
            }
            
            // Генерируем новый ID для следующего события
            const nextId = 'evt_' + Math.random().toString(36).substr(2, 9);
            document.getElementById('activityId').value = nextId;
            document.getElementById('activityUrl').value = `https://example.com/manage/${nextId}`;
            document.getElementById('activityQr').value = `https://example.com/qr/${nextId}.png`;
            
            // Обновляем список
            setTimeout(loadNotifications, 1000);
        } else {
            throw new Error(data.error || 'Неизвестная ошибка');
        }
    } catch (error) {
        // Проверяем, если это CORS ошибка
        if (error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
            showAlert('error', `⚠️ Не удается подключиться к n8n. Работаем в демо-режиме.`);
            addLog('warning', `CORS блокировка или n8n недоступен. Используем локальное сохранение.`);
            
            // Сохраняем только в Supabase в демо-режиме
            if (supabase) {
                await saveNotificationsToSupabase(formData);
                showAlert('success', `✅ Уведомления сохранены локально (демо-режим)`);
                
                // Генерируем новый ID
                const nextId = 'evt_' + Math.random().toString(36).substr(2, 9);
                document.getElementById('activityId').value = nextId;
                document.getElementById('activityUrl').value = `https://example.com/manage/${nextId}`;
                document.getElementById('activityQr').value = `https://example.com/qr/${nextId}.png`;
                
                // Обновляем список
                setTimeout(loadNotifications, 1000);
            }
        } else {
            showAlert('error', `❌ Ошибка: ${error.message}`);
            addLog('error', `Ошибка планирования: ${error.message}`);
        }
    }
}

// Загрузка уведомлений из Supabase
async function loadNotifications() {
    try {
        const supabaseConnected = await checkSupabaseConnection();
        
        if (supabaseConnected && supabase) {
            // Загружаем реальные данные из Supabase
            const { data, error } = await supabase
                .from('scheduled_notifications')
                .select('*')
                .order('scheduled_time', { ascending: true })
                .limit(20);
            
            if (error) {
                console.error('Supabase error:', error);
                if (error.code === 'PGRST205') {
                    addLog('warning', 'Таблицы Supabase не созданы. Работаем в демо-режиме.');
                }
                // Fallback на демо-данные
                updateNotificationsList();
            } else if (data && data.length > 0) {
                notifications = data;
                updateNotificationsList();
                addLog('success', `Загружено ${data.length} уведомлений из Supabase`);
            } else {
                // Если нет данных, показываем демо
                updateNotificationsList();
            }
        } else {
            // Если Supabase не доступен, используем демо-данные
            updateNotificationsList();
        }
        updateStats();
    } catch (error) {
        console.error('Error loading notifications:', error);
        // Fallback на демо-данные
        updateNotificationsList();
        updateStats();
    }
}

// Обновление списка уведомлений
function updateNotificationsList() {
    const container = document.getElementById('notifications');
    
    // Генерируем демо-данные для показа
    const demoNotifications = [
        {
            activity_id: document.getElementById('activityId').value || 'evt_001',
            user_id: document.getElementById('userId').value || 'user_001',
            notification_type: 'day_before',
            scheduled_time: new Date(Date.now() + 86400000).toISOString(),
            status: 'pending',
            activity_time: '15:00'
        },
        {
            activity_id: document.getElementById('activityId').value || 'evt_001',
            user_id: document.getElementById('userId').value || 'user_001',
            notification_type: 'three_hours',
            scheduled_time: new Date(Date.now() + 10800000).toISOString(),
            status: 'pending',
            activity_time: '15:00'
        }
    ];
    
    // Добавляем существующие отправленные
    const existingNotifications = notifications.filter(n => n.status === 'sent');
    notifications = [...demoNotifications, ...existingNotifications].slice(0, 10);
    
    let html = '';
    
    if (notifications.length === 0) {
        html = '<div class="notification-item">Нет запланированных уведомлений</div>';
    } else {
        notifications.forEach(notification => {
            const typeLabel = notification.notification_type === 'day_before' 
                ? '📅 Накануне в 21:00' 
                : '⏰ За 3 часа';
            
            const scheduledDate = new Date(notification.scheduled_time);
            const formattedTime = scheduledDate.toLocaleString('ru-RU');
            
            html += `
                <div class="notification-item ${notification.status}">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>${typeLabel}</strong>
                            <div style="color: #666; font-size: 0.9em; margin-top: 5px;">
                                Событие: ${notification.activity_id} | Пользователь: ${notification.user_id}
                            </div>
                            <div style="color: #888; font-size: 0.85em; margin-top: 3px;">
                                Отправка: ${formattedTime}
                            </div>
                        </div>
                        <div>
                            <span class="status-badge status-${notification.status}">
                                ${notification.status}
                            </span>
                            ${notification.status === 'pending' ? `
                                <button class="btn btn-danger" style="margin-left: 10px; padding: 6px 12px; font-size: 12px;" 
                                        onclick="cancelNotification('${notification.activity_id}')">
                                    Отменить
                                </button>
                            ` : ''}
                        </div>
                    </div>
                </div>
            `;
        });
    }
    
    container.innerHTML = html;
}

// Отмена уведомления
async function cancelNotification(activityId) {
    try {
        const response = await fetch(`${CONFIG.n8nWebhookUrl}/webhook/cancel-notifications/${activityId}`, {
            method: 'DELETE'
        });
        
        const data = await response.json();
        
        if (response.ok && data.success) {
            showAlert('success', `✅ Уведомления отменены для ${activityId}`);
            addLog('success', `Отменены уведомления для события ${activityId}`);
            
            // Обновляем статус в Supabase
            if (supabase) {
                const { error } = await supabase
                    .from('scheduled_notifications')
                    .update({ status: 'cancelled' })
                    .eq('activity_id', activityId)
                    .eq('status', 'pending');
                
                if (error) {
                    console.error('Error cancelling in Supabase:', error);
                }
            }
            
            // Обновляем статус в списке
            notifications.forEach(n => {
                if (n.activity_id === activityId) {
                    n.status = 'cancelled';
                }
            });
            
            updateNotificationsList();
            updateStats();
        } else {
            throw new Error(data.error || 'Неизвестная ошибка');
        }
    } catch (error) {
        // Проверяем, если это CORS ошибка
        if (error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
            showAlert('warning', `⚠️ n8n недоступен. Отменяем локально.`);
            addLog('warning', `CORS блокировка. Отмена только в Supabase.`);
            
            // Обновляем только в Supabase
            if (supabase) {
                const { error } = await supabase
                    .from('scheduled_notifications')
                    .update({ status: 'cancelled' })
                    .eq('activity_id', activityId)
                    .eq('status', 'pending');
                
                if (!error) {
                    showAlert('success', `✅ Уведомления отменены локально`);
                    
                    // Обновляем статус в списке
                    notifications.forEach(n => {
                        if (n.activity_id === activityId) {
                            n.status = 'cancelled';
                        }
                    });
                    
                    updateNotificationsList();
                    updateStats();
                }
            }
        } else {
            showAlert('error', `❌ Ошибка отмены: ${error.message}`);
            addLog('error', `Ошибка отмены: ${error.message}`);
        }
    }
}

// Обновление статистики
function updateStats() {
    stats = {
        pending: notifications.filter(n => n.status === 'pending').length,
        sent: notifications.filter(n => n.status === 'sent').length,
        cancelled: notifications.filter(n => n.status === 'cancelled').length,
        total: notifications.length
    };
    
    document.getElementById('statPending').textContent = stats.pending;
    document.getElementById('statSent').textContent = stats.sent;
    document.getElementById('statCancelled').textContent = stats.cancelled;
    document.getElementById('statTotal').textContent = stats.total;
}

// Показ уведомления
function showAlert(type, message) {
    const alertBox = document.getElementById('alertBox');
    const alertClass = type === 'success' ? 'alert-success' : 
                       type === 'error' ? 'alert-error' : 
                       'alert-info';
    
    alertBox.innerHTML = `<div class="alert ${alertClass}">${message}</div>`;
    
    setTimeout(() => {
        alertBox.innerHTML = '';
    }, 5000);
}

// Добавление записи в лог
function addLog(type, message) {
    const logsContainer = document.getElementById('logs');
    const timestamp = new Date().toLocaleTimeString('ru-RU');
    const logClass = type === 'success' ? 'log-success' : 
                     type === 'error' ? 'log-error' : 
                     'log-info';
    
    const logEntry = document.createElement('div');
    logEntry.className = `log-entry ${logClass}`;
    logEntry.textContent = `[${timestamp}] ${message}`;
    
    logsContainer.insertBefore(logEntry, logsContainer.firstChild);
    
    // Ограничиваем количество записей в логе
    while (logsContainer.children.length > 50) {
        logsContainer.removeChild(logsContainer.lastChild);
    }
}

// Симуляция автоматической отправки уведомлений
setInterval(() => {
    // Проверяем pending уведомления и "отправляем" их
    let updated = false;
    notifications.forEach(notification => {
        if (notification.status === 'pending') {
            const scheduledTime = new Date(notification.scheduled_time);
            if (scheduledTime <= new Date()) {
                notification.status = 'sent';
                notification.sent_at = new Date().toISOString();
                updated = true;
                
                const typeLabel = notification.notification_type === 'day_before' 
                    ? 'Напоминание накануне' 
                    : 'Напоминание за 3 часа';
                
                addLog('success', `✉️ Отправлено: ${typeLabel} для ${notification.activity_id}`);
            }
        }
    });
    
    if (updated) {
        updateNotificationsList();
        updateStats();
    }
}, 5000);

// Сохранение уведомлений в Supabase
async function saveNotificationsToSupabase(formData) {
    if (!supabase) return;
    
    try {
        const activityDateTime = new Date(`${formData.activity_date}T${formData.activity_time}`);
        
        // Создаем два уведомления: накануне в 21:00 и за 3 часа
        const dayBefore = new Date(activityDateTime);
        dayBefore.setDate(dayBefore.getDate() - 1);
        dayBefore.setHours(21, 0, 0, 0);
        
        const threeHoursBefore = new Date(activityDateTime);
        threeHoursBefore.setHours(threeHoursBefore.getHours() - 3);
        
        const notifications = [
            {
                activity_id: formData.activity_id,
                user_id: formData.id,
                notification_type: 'day_before',
                scheduled_time: dayBefore.toISOString(),
                status: 'pending',
                activity_time: formData.activity_time,
                activity_url: formData.activity_url,
                activity_qr: formData.activity_qr,
                created_at: new Date().toISOString()
            },
            {
                activity_id: formData.activity_id,
                user_id: formData.id,
                notification_type: 'three_hours',
                scheduled_time: threeHoursBefore.toISOString(),
                status: 'pending',
                activity_time: formData.activity_time,
                activity_url: formData.activity_url,
                activity_qr: formData.activity_qr,
                created_at: new Date().toISOString()
            }
        ];
        
        const { data, error } = await supabase
            .from('scheduled_notifications')
            .insert(notifications);
        
        if (error) {
            console.error('Error saving to Supabase:', error);
        } else {
            console.log('Saved to Supabase:', data);
        }
    } catch (error) {
        console.error('Error in saveNotificationsToSupabase:', error);
    }
}

// Обновление статуса уведомления в Supabase
async function updateNotificationStatus(notificationId, status) {
    if (!supabase) return;
    
    try {
        const updateData = { status };
        if (status === 'sent') {
            updateData.sent_at = new Date().toISOString();
        }
        
        const { data, error } = await supabase
            .from('scheduled_notifications')
            .update(updateData)
            .eq('id', notificationId);
        
        if (error) {
            console.error('Error updating status:', error);
        }
    } catch (error) {
        console.error('Error in updateNotificationStatus:', error);
    }
}

// Тестовая функция для симуляции отправки уведомления
async function simulateSendNotification(notification) {
    // Формируем данные согласно ТЗ
    const apiData = {
        client_id: notification.user_id,
        message: `notification_${notification.activity_id}`,
        text: notification.notification_type === 'day_before' 
            ? `Напоминаем: завтра в ${notification.activity_time} у вас запланировано событие`
            : `Событие начнется через 3 часа в ${notification.activity_time}`,
        ...(notification.notification_type === 'day_before' && { button_url: notification.activity_url }),
        ...(notification.notification_type === 'three_hours' && { qr: notification.activity_qr })
    };
    
    console.log('API Request:', apiData);
    
    // Здесь был бы реальный API запрос
    return { success: true, execution_time: Math.floor(Math.random() * 1500) + 500 };
}