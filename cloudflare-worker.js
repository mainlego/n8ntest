// Cloudflare Worker для CORS прокси
// Деплой: https://workers.cloudflare.com

const N8N_URL = 'https://n8ntest-uwxt.onrender.com';

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);
  
  // Строим новый URL для n8n
  const n8nUrl = N8N_URL + url.pathname + url.search;
  
  // CORS заголовки
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Max-Age': '86400',
  };
  
  // Обработка preflight запросов
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }
  
  // Прокси запрос к n8n
  const response = await fetch(n8nUrl, {
    method: request.method,
    headers: request.headers,
    body: request.method !== 'GET' && request.method !== 'HEAD' 
      ? request.body 
      : undefined
  });
  
  // Создаем новый ответ с CORS заголовками
  const newResponse = new Response(response.body, response);
  Object.keys(corsHeaders).forEach(key => {
    newResponse.headers.set(key, corsHeaders[key]);
  });
  
  return newResponse;
}