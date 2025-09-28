import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PWA服务类，处理Progressive Web App相关功能
class PWAService {
  static PWAService? _instance;
  static PWAService get instance => _instance ??= PWAService._();
  
  PWAService._();
  
  // 网络状态流控制器
  final StreamController<bool> _networkStatusController = StreamController<bool>.broadcast();
  Stream<bool> get networkStatusStream => _networkStatusController.stream;
  
  // 安装状态流控制器
  final StreamController<bool> _installStatusController = StreamController<bool>.broadcast();
  Stream<bool> get installStatusStream => _installStatusController.stream;
  
  // 更新状态流控制器
  final StreamController<bool> _updateAvailableController = StreamController<bool>.broadcast();
  Stream<bool> get updateAvailableStream => _updateAvailableController.stream;
  
  bool _isOnline = true;
  bool _isInstalled = false;
  bool _updateAvailable = false;
  
  /// 初始化PWA服务
  Future<void> initialize() async {
    if (!kIsWeb) return;
    
    try {
      // 检查网络状态
      _checkNetworkStatus();
      
      // 监听网络状态变化
      _setupNetworkListeners();
      
      // 检查安装状态
      _checkInstallStatus();
      
      // 设置Service Worker消息监听
      _setupServiceWorkerListeners();
      
      // 注册推送通知
      await _setupPushNotifications();
      
      print('PWA Service initialized successfully');
    } catch (e) {
      print('PWA Service initialization error: $e');
    }
  }
  
  /// 检查当前网络状态
  void _checkNetworkStatus() {
    _isOnline = html.window.navigator.onLine ?? true;
    _networkStatusController.add(_isOnline);
  }
  
  /// 设置网络状态监听器
  void _setupNetworkListeners() {
    html.window.addEventListener('online', (event) {
      _isOnline = true;
      _networkStatusController.add(true);
      _onNetworkStatusChanged(true);
    });
    
    html.window.addEventListener('offline', (event) {
      _isOnline = false;
      _networkStatusController.add(false);
      _onNetworkStatusChanged(false);
    });
  }
  
  /// 网络状态变化处理
  void _onNetworkStatusChanged(bool isOnline) {
    print('Network status changed: ${isOnline ? 'online' : 'offline'}');
    
    if (isOnline) {
      // 网络恢复时，触发数据同步
      _syncOfflineData();
    }
  }
  
  /// 检查应用安装状态
  void _checkInstallStatus() {
    // 检查是否在standalone模式下运行（已安装）
    final displayMode = html.window.matchMedia('(display-mode: standalone)').matches;
    final isInWebAppiOS = html.window.navigator.userAgent.contains('Mobile') && 
                         !html.window.navigator.userAgent.contains('Safari');
    
    _isInstalled = displayMode || isInWebAppiOS;
    _installStatusController.add(_isInstalled);
  }
  
  /// 设置Service Worker监听器
  void _setupServiceWorkerListeners() {
    if (html.window.navigator.serviceWorker != null) {
      // 监听Service Worker更新
      html.window.navigator.serviceWorker!.addEventListener('controllerchange', (event) {
        _updateAvailable = true;
        _updateAvailableController.add(true);
      });
      
      // 监听Service Worker消息
      html.window.navigator.serviceWorker!.addEventListener('message', (html.Event event) {
        // Service Worker消息处理
        _updateAvailable = true;
        _updateAvailableController.add(true);
      });
    }
  }
  
  /// 设置推送通知
  Future<void> _setupPushNotifications() async {
    if (!_isPushSupported()) return;
    
    try {
      // 检查通知权限
      final permission = html.Notification.permission;
      if (permission == 'default') {
        // 可以在适当时机请求权限
        print('Notification permission not requested yet');
      } else if (permission == 'granted') {
        await _subscribeToPush();
      }
    } catch (e) {
      print('Push notification setup error: $e');
    }
  }
  
  /// 检查推送通知支持
  bool _isPushSupported() {
    return html.window.navigator.serviceWorker != null &&
           js.context.hasProperty('PushManager') &&
           html.Notification.supported;
  }
  
  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    if (!_isPushSupported()) return false;
    
    try {
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        await _subscribeToPush();
        return true;
      }
    } catch (e) {
      print('Request notification permission error: $e');
    }
    
    return false;
  }
  
  /// 订阅推送通知
  Future<void> _subscribeToPush() async {
    try {
      final registration = await html.window.navigator.serviceWorker!.ready;
      
      // 这里需要配置VAPID密钥
      const vapidPublicKey = 'YOUR_VAPID_PUBLIC_KEY'; // 需要替换为实际的VAPID公钥
      
      final subscription = await registration.pushManager!.subscribe({
        'userVisibleOnly': true,
        'applicationServerKey': _urlBase64ToUint8Array(vapidPublicKey),
      });
      
      // 将订阅信息发送到服务器
      await _sendSubscriptionToServer(subscription);
      
      print('Push notification subscribed successfully');
    } catch (e) {
      print('Push subscription error: $e');
    }
  }
  
  /// 将订阅信息发送到服务器
  Future<void> _sendSubscriptionToServer(html.PushSubscription subscription) async {
    // 这里实现将订阅信息发送到后端服务器的逻辑
    final subscriptionData = {
      'endpoint': subscription.endpoint,
      'keys': {
        'p256dh': subscription.getKey('p256dh'),
        'auth': subscription.getKey('auth'),
      },
    };
    
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('push_subscription', jsonEncode(subscriptionData));
    
    print('Subscription data saved: $subscriptionData');
  }
  
  /// 转换VAPID密钥格式
  List<int> _urlBase64ToUint8Array(String base64String) {
    const padding = '=';
    final normalizedBase64 = (base64String + padding * (4 - base64String.length % 4))
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    
    return base64Decode(normalizedBase64);
  }
  
  /// 显示本地通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (!html.Notification.supported) return;
    
    try {
      final notification = html.Notification(title);
      
      // 设置点击事件
      notification.onClick.listen((event) {
        notification.close();
      });
      
      // 自动关闭
      Timer(const Duration(seconds: 5), () {
        notification.close();
      });
      
    } catch (e) {
      print('Show notification error: $e');
    }
  }
  
  /// 缓存数据到本地存储
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('cache_$key', jsonData);
      
      // 记录缓存时间
      await prefs.setInt('cache_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      print('Data cached successfully: $key');
    } catch (e) {
      print('Cache data error: $e');
    }
  }
  
  /// 从本地存储获取缓存数据
  Future<Map<String, dynamic>?> getCachedData(String key, {Duration? maxAge}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cache_$key');
      
      if (jsonData == null) return null;
      
      // 检查缓存时效
      if (maxAge != null) {
        final timestamp = prefs.getInt('cache_${key}_timestamp') ?? 0;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        
        if (now.difference(cacheTime) > maxAge) {
          // 缓存过期，删除数据
          await prefs.remove('cache_$key');
          await prefs.remove('cache_${key}_timestamp');
          return null;
        }
      }
      
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      print('Get cached data error: $e');
      return null;
    }
  }
  
  /// 清除指定缓存
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
      await prefs.remove('cache_${key}_timestamp');
      print('Cache cleared: $key');
    } catch (e) {
      print('Clear cache error: $e');
    }
  }
  
  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('All cache cleared');
    } catch (e) {
      print('Clear all cache error: $e');
    }
  }
  
  /// 同步离线数据
  Future<void> _syncOfflineData() async {
    if (!_isOnline) return;
    
    try {
      print('Starting offline data sync...');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('offline_')).toList();
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final offlineData = jsonDecode(data) as Map<String, dynamic>;
            
            // 这里实现具体的数据同步逻辑
            await _syncSingleOfflineData(offlineData);
            
            // 同步成功后删除离线数据
            await prefs.remove(key);
            
          } catch (e) {
            print('Sync single offline data error: $e');
          }
        }
      }
      
      print('Offline data sync completed');
    } catch (e) {
      print('Sync offline data error: $e');
    }
  }
  
  /// 同步单个离线数据
  Future<void> _syncSingleOfflineData(Map<String, dynamic> data) async {
    // 这里实现具体的数据同步逻辑
    // 例如：发送到服务器、更新本地数据库等
    print('Syncing offline data: ${data['type']}');
    
    // 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// 保存离线操作
  Future<void> saveOfflineAction({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = 'offline_${type}_$timestamp';
      
      final offlineData = {
        'type': type,
        'data': data,
        'timestamp': timestamp,
      };
      
      await prefs.setString(key, jsonEncode(offlineData));
      print('Offline action saved: $type');
      
      // 如果网络可用，立即尝试同步
      if (_isOnline) {
        await _syncSingleOfflineData(offlineData);
        await prefs.remove(key);
      }
      
    } catch (e) {
      print('Save offline action error: $e');
    }
  }
  
  /// 强制刷新应用（当有更新时）
  Future<void> forceRefresh() async {
    if (kIsWeb) {
      html.window.location.reload();
    }
  }
  
  /// 获取当前网络状态
  bool get isOnline => _isOnline;
  
  /// 获取安装状态
  bool get isInstalled => _isInstalled;
  
  /// 获取更新状态
  bool get updateAvailable => _updateAvailable;
  
  /// 释放资源
  void dispose() {
    _networkStatusController.close();
    _installStatusController.close();
    _updateAvailableController.close();
  }
}