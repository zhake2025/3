// Kelivo PWA Service Worker - 优化版本
// 版本号用于缓存管理
const CACHE_NAME = 'kelivo-pwa-v1.0.13';
const STATIC_CACHE = 'kelivo-static-v1.0.13';
const DYNAMIC_CACHE = 'kelivo-dynamic-v1.0.13';
const FLUTTER_CACHE = 'kelivo-flutter-v1.0.13';

// 核心静态资源 - 优先级最高
const CORE_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png'
];

// Flutter引擎资源
const FLUTTER_ASSETS = [
  '/flutter.js',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/flutter_service_worker.js'
];

// 图标资源
const ICON_ASSETS = [
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png'
];

// 需要缓存的Flutter资源模式 - 优化正则表达式
const FLUTTER_ASSETS_PATTERNS = [
  /\/assets\//,
  /\/canvaskit\//,
  /\/fonts\//,
  /\.dart\.js$/,
  /\.dart\.wasm$/,
  /\.dart\.mjs$/,
  /main\.dart\.js$/,
  /\/flutter_assets\//
];

// 网络优先的资源模式
const NETWORK_FIRST_PATTERNS = [
  /\/api\//,
  /\.json$/,
  /\/sw\.js$/
];

// 离线页面HTML
const OFFLINE_PAGE = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kelivo - 离线模式</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 20px;
      background: linear-gradient(135deg, #1565C0 0%, #42A5F5 100%);
      color: white;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
    }
    .container {
      max-width: 400px;
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 16px;
      backdrop-filter: blur(10px);
    }
    .icon {
      font-size: 64px;
      margin-bottom: 20px;
    }
    h1 {
      margin: 0 0 16px 0;
      font-size: 24px;
      font-weight: 600;
    }
    p {
      margin: 0 0 24px 0;
      opacity: 0.9;
      line-height: 1.5;
    }
    .retry-btn {
      background: white;
      color: #1565C0;
      border: none;
      padding: 12px 24px;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 500;
      cursor: pointer;
      transition: transform 0.2s;
    }
    .retry-btn:hover {
      transform: translateY(-2px);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">🔌</div>
    <h1>当前处于离线状态</h1>
    <p>请检查网络连接后重试，或使用已缓存的功能。</p>
    <button class="retry-btn" onclick="window.location.reload()">重新连接</button>
  </div>
</body>
</html>
`;

// Service Worker 安装事件 - 优化缓存策略
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...', CACHE_NAME);
  
  event.waitUntil(
    Promise.all([
      // 分层缓存核心资源，提高加载速度
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('Caching core assets');
        return cache.addAll(CORE_ASSETS);
      }),
      
      // Flutter资源单独缓存
      caches.open(FLUTTER_CACHE).then((cache) => {
        console.log('Caching Flutter assets');
        return cache.addAll(FLUTTER_ASSETS.concat(ICON_ASSETS));
      }),
      
      // 缓存离线页面
      caches.open(DYNAMIC_CACHE).then((cache) => {
        return cache.put('/offline.html', new Response(OFFLINE_PAGE, {
          headers: { 'Content-Type': 'text/html' }
        }));
      })
    ]).then(() => {
      console.log('Service Worker installed successfully');
      // 强制激活新的Service Worker
      return self.skipWaiting();
    })
  );
});

// Service Worker 激活事件 - 优化缓存清理
self.addEventListener('activate', (event) => {
  console.log('Service Worker activating...', CACHE_NAME);
  
  event.waitUntil(
    Promise.all([
      // 清理旧缓存
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE && 
                cacheName !== DYNAMIC_CACHE &&
                cacheName !== FLUTTER_CACHE &&
                cacheName !== CACHE_NAME) {
              console.log('Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      // 立即控制所有客户端
      self.clients.claim()
    ]).then(() => {
      console.log('Service Worker activated successfully');
    })
  );
});

// 网络请求拦截
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // 跳过非HTTP请求
  if (!request.url.startsWith('http')) {
    return;
  }
  
  // 跳过Chrome扩展请求
  if (url.protocol === 'chrome-extension:') {
    return;
  }
  
  event.respondWith(handleFetch(request));
});

// 处理网络请求的核心逻辑 - 优化版本
async function handleFetch(request) {
  const url = new URL(request.url);
  
  try {
    // 1. 对于导航请求（页面请求）
    if (request.mode === 'navigate') {
      return await handleNavigationRequest(request);
    }
    
    // 2. 对于Flutter资源 - 缓存优先
    if (isFlutterAsset(url.pathname)) {
      return await handleFlutterAsset(request);
    }
    
    // 3. 对于静态资源 - 缓存优先
    if (isStaticAsset(url.pathname)) {
      return await handleStaticAsset(request);
    }
    
    // 4. 对于网络优先资源
    if (isNetworkFirst(url.pathname)) {
      return await networkFirst(request);
    }
    
    // 5. 对于API请求
    if (isApiRequest(url)) {
      return await handleApiRequest(request);
    }
    
    // 6. 其他请求使用网络优先策略
    return await networkFirst(request);
    
  } catch (error) {
    console.error('Fetch handler error:', error);
    return await handleFallback(request);
  }
}

// 处理导航请求
async function handleNavigationRequest(request) {
  try {
    // 尝试网络请求
    const networkResponse = await fetch(request);
    
    // 如果成功，缓存响应并返回
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    }
    
    throw new Error('Network response not ok');
    
  } catch (error) {
    // 网络失败，尝试从缓存获取
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // 返回离线页面
    return caches.match('/offline.html');
  }
}

// 处理静态资源
async function handleStaticAsset(request) {
  // 缓存优先策略
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  // 缓存中没有，尝试网络请求
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    }
    throw new Error('Network response not ok');
  } catch (error) {
    console.error('Failed to fetch static asset:', request.url);
    throw error;
  }
}

// 处理Flutter资源 - 优化版本
async function handleFlutterAsset(request) {
  // Flutter资源使用缓存优先策略，因为它们通常不变
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(FLUTTER_CACHE);
      // 使用后台缓存以提高响应速度
      cache.put(request, networkResponse.clone()).catch(err => 
        console.log('Background cache failed:', err)
      );
      return networkResponse;
    }
    throw new Error('Network response not ok');
  } catch (error) {
    console.error('Failed to fetch Flutter asset:', request.url);
    throw error;
  }
}

// 处理API请求
async function handleApiRequest(request) {
  try {
    // API请求优先使用网络
    const networkResponse = await fetch(request);
    
    // 只缓存GET请求的成功响应
    if (request.method === 'GET' && networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch (error) {
    // 网络失败，对于GET请求尝试返回缓存
    if (request.method === 'GET') {
      const cachedResponse = await caches.match(request);
      if (cachedResponse) {
        // 添加离线标识头
        const response = cachedResponse.clone();
        response.headers.set('X-Served-From', 'cache');
        return response;
      }
    }
    
    throw error;
  }
}

// 网络优先策略
async function networkFirst(request) {
  try {
    const networkResponse = await fetch(request);
    
    // 缓存成功的响应
    if (networkResponse.ok && request.method === 'GET') {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch (error) {
    // 网络失败，尝试缓存
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    throw error;
  }
}

// 处理请求失败的回退方案
async function handleFallback(request) {
  // 对于导航请求，返回离线页面
  if (request.mode === 'navigate') {
    return caches.match('/offline.html');
  }
  
  // 对于图片请求，返回占位图
  if (request.destination === 'image') {
    return new Response(
      '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200"><rect width="200" height="200" fill="#f0f0f0"/><text x="100" y="100" text-anchor="middle" dy=".3em" fill="#999">图片加载失败</text></svg>',
      { headers: { 'Content-Type': 'image/svg+xml' } }
    );
  }
  
  // 其他请求返回网络错误
  return new Response('Network Error', {
    status: 408,
    headers: { 'Content-Type': 'text/plain' }
  });
}

// 工具函数：判断是否为网络优先资源
function isNetworkFirst(pathname) {
  return NETWORK_FIRST_PATTERNS.some(pattern => pattern.test(pathname));
}

// 工具函数：判断是否为静态资源 - 优化版本
function isStaticAsset(pathname) {
  const staticExtensions = ['.css', '.js', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.woff', '.woff2', '.ttf'];
  return staticExtensions.some(ext => pathname.endsWith(ext)) || 
         pathname === '/' || 
         pathname === '/index.html' ||
         pathname === '/manifest.json' ||
         pathname === '/favicon.png';
}

// 工具函数：判断是否为Flutter资源
function isFlutterAsset(pathname) {
  return FLUTTER_ASSETS_PATTERNS.some(pattern => pattern.test(pathname));
}

// 工具函数：判断是否为API请求
function isApiRequest(url) {
  return url.pathname.startsWith('/api/') || 
         url.hostname !== self.location.hostname ||
         url.pathname.includes('/v1/') ||
         url.pathname.includes('/graphql');
}

// 推送通知处理
self.addEventListener('push', (event) => {
  console.log('Push message received:', event);
  
  let notificationData = {
    title: 'Kelivo',
    body: '您有新消息',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-96.png',
    tag: 'kelivo-notification',
    requireInteraction: false,
    actions: [
      {
        action: 'open',
        title: '查看',
        icon: '/icons/action-open.png'
      },
      {
        action: 'dismiss',
        title: '忽略',
        icon: '/icons/action-dismiss.png'
      }
    ]
  };
  
  // 解析推送数据
  if (event.data) {
    try {
      const pushData = event.data.json();
      notificationData = { ...notificationData, ...pushData };
    } catch (error) {
      console.error('Error parsing push data:', error);
      notificationData.body = event.data.text() || notificationData.body;
    }
  }
  
  event.waitUntil(
    self.registration.showNotification(notificationData.title, notificationData)
  );
});

// 通知点击处理
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event);
  
  event.notification.close();
  
  const action = event.action;
  const notificationData = event.notification.data || {};
  
  if (action === 'dismiss') {
    return;
  }
  
  // 打开应用
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // 如果已有窗口打开，聚焦到该窗口
        for (const client of clientList) {
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            return client.focus();
          }
        }
        
        // 否则打开新窗口
        const urlToOpen = notificationData.url || '/';
        return clients.openWindow(urlToOpen);
      })
  );
});

// 后台同步
self.addEventListener('sync', (event) => {
  console.log('Background sync triggered:', event.tag);
  
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

// 执行后台同步
async function doBackgroundSync() {
  try {
    // 这里可以实现数据同步逻辑
    console.log('Performing background sync...');
    
    // 示例：同步离线时的操作
    const cache = await caches.open(DYNAMIC_CACHE);
    const requests = await cache.keys();
    
    // 处理离线时缓存的请求
    for (const request of requests) {
      if (request.url.includes('/api/') && request.method !== 'GET') {
        try {
          await fetch(request);
          await cache.delete(request);
        } catch (error) {
          console.error('Sync failed for request:', request.url);
        }
      }
    }
    
    console.log('Background sync completed');
  } catch (error) {
    console.error('Background sync error:', error);
  }
}

// 消息处理（与主线程通信）
self.addEventListener('message', (event) => {
  console.log('Service Worker received message:', event.data);
  
  const { type, payload } = event.data;
  
  switch (type) {
    case 'SKIP_WAITING':
      self.skipWaiting();
      break;
      
    case 'GET_VERSION':
      event.ports[0].postMessage({ version: CACHE_NAME });
      break;
      
    case 'CLEAR_CACHE':
      clearAllCaches().then(() => {
        event.ports[0].postMessage({ success: true });
      });
      break;
      
    case 'CACHE_URLS':
      cacheUrls(payload.urls).then(() => {
        event.ports[0].postMessage({ success: true });
      });
      break;
      
    default:
      console.log('Unknown message type:', type);
  }
});

// 清理所有缓存
async function clearAllCaches() {
  const cacheNames = await caches.keys();
  await Promise.all(cacheNames.map(name => caches.delete(name)));
  console.log('All caches cleared');
}

// 缓存指定URL
async function cacheUrls(urls) {
  const cache = await caches.open(DYNAMIC_CACHE);
  await cache.addAll(urls);
  console.log('URLs cached:', urls);
}

console.log('Kelivo Service Worker loaded successfully');