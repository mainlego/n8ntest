// Конфигурация
const CONFIG = {
    n8nWebhookUrl: 'https://n8ntest-uwxt.onrender.com',
    // Различные прокси опции (выберите одну)
    corsProxyOptions: {
        // 1. Публичный прокси (работает сейчас)
        public: 'https://proxy.cors.sh/https://n8ntest-uwxt.onrender.com',
        // 2. Ваш собственный прокси на Render (после деплоя замените URL)
        custom: 'https://n8n-cors-proxy-xxxx.onrender.com', // Замените xxxx на ваш ID
        // 3. Альтернативный публичный прокси
        alternative: 'https://cors-anywhere.herokuapp.com/https://n8ntest-uwxt.onrender.com'
    },
    currentProxy: 'public', // Какой прокси использовать: 'public', 'custom', 'alternative' или 'none'
    supabaseUrl: 'https://xklameqcsrbvepjecwtn.supabase.co',
    supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrbGFtZXFjc3JidmVwamVjd3RuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3MjE5MTIsImV4cCI6MjA3MTI5NzkxMn0.M82x241D4KgJ3GCKURlRfdr1qWsjLmjrWvzUMIMn9Oc',
    refreshInterval: 5000, // Обновление каждые 5 секунд
    useCorsProxy: true // CORS прокси включен для обхода блокировки
};

// Инициализация Supabase
let supabase = null;
let supabaseEnabled = true; // Включаем по умолчанию

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

// Функция переключения CORS прокси
function toggleCorsProxy() {
    CONFIG.useCorsProxy = !CONFIG.useCorsProxy;
    
    const status = CONFIG.useCorsProxy ? 'Включен' : 'Отключен';
    const btnText = CONFIG.useCorsProxy ? '🌐 CORS Прокси: Включен' : '🌐 CORS Прокси: Отключен';
    const btnColor = CONFIG.useCorsProxy ? '#f39c12' : '#95a5a6';
    
    document.getElementById('corsProxyStatus').textContent = status;
    document.getElementById('toggleCorsBtn').textContent = btnText;
    document.getElementById('toggleCorsBtn').style.background = btnColor;
    
    addLog('info', `CORS прокси ${status.toLowerCase()}`);
    
    if (CONFIG.useCorsProxy) {
        showAlert('info', `🌐 CORS прокси включен (${CONFIG.currentProxy}). Webhook запросы будут проходить через прокси.`);
    } else {
        showAlert('warning', '⚠️ CORS прокси отключен. Нужно настроить CORS в n8n.');
    }
}

// Функция переключения типа прокси
function switchProxyType(type) {
    if (!['public', 'custom', 'alternative', 'none'].includes(type)) {
        showAlert('error', '❌ Неверный тип прокси');
        return;
    }
    
    CONFIG.currentProxy = type;
    
    if (type === 'none') {
        CONFIG.useCorsProxy = false;
        addLog('warning', 'CORS прокси отключен');
        showAlert('warning', '⚠️ CORS прокси отключен. Требуется настройка CORS в n8n.');
    } else {
        CONFIG.useCorsProxy = true;
        const proxyUrl = CONFIG.corsProxyOptions[type];
        addLog('info', `Переключен на ${type} прокси: ${proxyUrl}`);
        showAlert('success', `✅ Используется ${type} прокси`);
    }
    
    // Обновляем UI
    toggleCorsProxy();
    toggleCorsProxy(); // Вызываем дважды чтобы вернуть в правильное состояние
}

// Тест CORS подключения
async function testCors() {
    addLog('info', 'Тестируем CORS подключение к n8n...');
    
    try {
        const response = await fetch(`${CONFIG.n8nWebhookUrl}/healthz`, {
            method: 'GET',
            mode: 'cors'
        });
        
        if (response.ok) {
            addLog('success', '✅ CORS настроен корректно! n8n доступен.');
            showAlert('success', '✅ CORS работает! Можно планировать уведомления.');
        } else {
            addLog('warning', `⚠️ n8n отвечает, но статус: ${response.status}`);
        }
    } catch (error) {
        if (error.message.includes('CORS')) {
            addLog('error', '❌ CORS заблокирован. Настройте переменные в Render.');
            showAlert('error', '❌ CORS не настроен. См. инструкции выше.');
        } else {
            addLog('error', `❌ Ошибка подключения: ${error.message}`);
        }
    }
}

// Глобальные функции
window.enableSupabase = enableSupabase;
window.toggleCorsProxy = toggleCorsProxy;
window.testCors = testCors;

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
async function initializeApp() {
    document.getElementById('webhookUrl').textContent = CONFIG.n8nWebhookUrl;
    
    // Инициализируем Supabase
    if (supabaseEnabled && typeof window !== 'undefined' && window.supabase) {
        supabase = window.supabase.createClient(CONFIG.supabaseUrl, CONFIG.supabaseKey);
        document.getElementById('supabaseStatus').textContent = 'Подключен';
        document.getElementById('enableSupabaseBtn').textContent = '✅ Supabase подключен';
        document.getElementById('enableSupabaseBtn').disabled = true;
    }
    
    // Обновляем статус CORS прокси
    const corsStatus = CONFIG.useCorsProxy ? 'Включен' : 'Отключен';
    const corsBtn = CONFIG.useCorsProxy ? '🌐 CORS Прокси: Включен' : '🌐 CORS Прокси: Отключен';
    const corsColor = CONFIG.useCorsProxy ? '#f39c12' : '#95a5a6';
    
    document.getElementById('corsProxyStatus').textContent = corsStatus;
    document.getElementById('toggleCorsBtn').textContent = corsBtn;
    document.getElementById('toggleCorsBtn').style.background = corsColor;
    
    loadNotifications();
    addLog('info', 'Система инициализирована. Готова к работе с реальными данными.');
    
    if (!CONFIG.useCorsProxy) {
        addLog('warning', 'CORS прокси отключен. Настройте CORS в n8n для работы webhooks.');
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
        // Определяем URL в зависимости от настроек прокси
        let webhookUrl;
        if (CONFIG.useCorsProxy && CONFIG.currentProxy !== 'none') {
            const proxyUrl = CONFIG.corsProxyOptions[CONFIG.currentProxy];
            webhookUrl = `${proxyUrl}/webhook/schedule-notification`;
        } else {
            webhookUrl = `${CONFIG.n8nWebhookUrl}/webhook/schedule-notification`;
        }
            
        const response = await fetch(webhookUrl, {
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
                    addLog('error', 'Таблицы Supabase не созданы! Создайте таблицы для работы системы.');
                    showAlert('error', '❌ Таблицы Supabase не найдены. См. документацию по настройке.');
                } else {
                    addLog('error', `Ошибка Supabase: ${error.message}`);
                }
                notifications = [];
                updateNotificationsList();
            } else if (data && data.length > 0) {
                notifications = data;
                updateNotificationsList();
                // Не логируем каждый раз одно и то же количество
                const currentCount = notifications.length;
                if (!window.lastNotificationCount || window.lastNotificationCount !== currentCount) {
                    addLog('success', `Загружено ${data.length} уведомлений из Supabase`);
                    window.lastNotificationCount = currentCount;
                }
            } else {
                // Если нет данных в базе
                notifications = [];
                updateNotificationsList();
                if (!window.emptyDataLogged) {
                    addLog('info', 'База данных пуста. Запланируйте первое уведомление!');
                    window.emptyDataLogged = true;
                }
            }
        } else {
            // Если Supabase не доступен
            notifications = [];
            updateNotificationsList();
            if (!window.supabaseOfflineLogged) {
                addLog('warning', 'Supabase отключен. Включите Supabase для работы с данными.');
                window.supabaseOfflineLogged = true;
            }
        }
        updateStats();
    } catch (error) {
        console.error('Error loading notifications:', error);
        notifications = [];
        updateNotificationsList();
        updateStats();
        addLog('error', `Ошибка загрузки данных: ${error.message}`);
    }
}

// Обновление списка уведомлений
function updateNotificationsList() {
    const container = document.getElementById('notifications');
    
    let html = '';
    
    if (notifications.length === 0) {
        html = '<div class="notification-item">Нет запланированных уведомлений. Запланируйте первое уведомление!</div>';
    } else {
        notifications.forEach(notification => {
            const typeLabel = notification.notification_type === 'day_before' 
                ? '📅 Накануне в 21:00' 
                : '⏰ За 3 часа';
            
            const scheduledDate = new Date(notification.scheduled_time);
            const formattedTime = scheduledDate.toLocaleString('ru-RU');
            
            // Статус на русском
            const statusLabels = {
                'pending': 'Ожидает',
                'sent': 'Отправлено', 
                'cancelled': 'Отменено'
            };
            
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
                            ${notification.sent_at ? `
                                <div style="color: #28a745; font-size: 0.8em; margin-top: 2px;">
                                    Отправлено: ${new Date(notification.sent_at).toLocaleString('ru-RU')}
                                </div>
                            ` : ''}
                        </div>
                        <div>
                            <span class="status-badge status-${notification.status}">
                                ${statusLabels[notification.status] || notification.status}
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
        // Определяем URL в зависимости от настроек прокси
        let webhookUrl;
        if (CONFIG.useCorsProxy && CONFIG.currentProxy !== 'none') {
            const proxyUrl = CONFIG.corsProxyOptions[CONFIG.currentProxy];
            webhookUrl = `${proxyUrl}/webhook/cancel-notifications/${activityId}`;
        } else {
            webhookUrl = `${CONFIG.n8nWebhookUrl}/webhook/cancel-notifications/${activityId}`;
        }
            
        const response = await fetch(webhookUrl, {
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

// Автоматическая отправка управляется n8n workflow, а не фронтендом

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