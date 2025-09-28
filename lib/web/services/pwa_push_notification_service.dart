import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// PWA推送通知服务
/// 集成Web Push API，支持后台推送通知
class PWAPushNotificationService {
  static PWAPushNotificationService? _instance;
  static PWAPushNotificationService get instance => 
      _instance ??= PWAPushNotificationService._();
  
  PWAPushNotificationService._();

  html.ServiceWorkerRegistration? _swRegistration;
  html.PushSubscription? _pushSubscription;
  
  final StreamController<NotificationEvent> _notificationController = 
      StreamController<NotificationEvent>.broadcast();
  
  Stream<NotificationEvent> get notificationStream => 
      _notificationController.stream;
  
  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _vapidPublicKey;
  
  /// 初始化推送通知服务
  Future<void> initialize({
    required String vapidPublicKey,
    String? serverEndpoint,
  }) async {
    if (!kIsWeb) {
      debugPrint('Push notifications only supported on web platform');
      return;
    }

    try {
      _vapidPublicKey = vapidPublicKey;
      
      // 检查浏览器支持
      if (!_isBrowserSupported()) {
        throw UnsupportedError('Push notifications not supported in this browser');
      }
      
      // 获取Service Worker注册
      await _getServiceWorkerRegistration();
      
      // 检查通知权限
      await _checkNotificationPermission();
      
      // 设置消息监听器
      _setupMessageListeners();
      
      _isInitialized = true;
      
      _notificationController.add(NotificationEvent.initialized());
      debugPrint('PWA Push Notification Service initialized');
      
    } catch (e) {
      debugPrint('Failed to initialize push notification service: $e');
      _notificationController.add(NotificationEvent.error(e.toString()));
      rethrow;
    }
  }
  
  /// 请求通知权限
  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }
    
    try {
      final permission = await html.Notification.requestPermission();
      _hasPermission = permission == 'granted';
      
      final event = _hasPermission 
          ? NotificationEvent.permissionGranted()
          : NotificationEvent.permissionDenied();
      
      _notificationController.add(event);
      
      return _hasPermission;
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
      _notificationController.add(NotificationEvent.error(e.toString()));
      return false;
    }
  }
  
  /// 订阅推送通知
  Future<PushSubscriptionInfo?> subscribeToPush() async {
    if (!_isInitialized || !_hasPermission) {
      throw StateError('Service not initialized or permission not granted');
    }
    
    if (_swRegistration == null) {
      throw StateError('Service Worker not registered');
    }
    
    try {
      // 检查现有订阅
      _pushSubscription = await _swRegistration!.pushManager?.getSubscription();
      
      if (_pushSubscription == null) {
        // 创建新订阅
        final subscribeOptions = {
          'userVisibleOnly': true,
          'applicationServerKey': _urlBase64ToUint8Array(_vapidPublicKey!),
        };
        
        _pushSubscription = await _swRegistration!.pushManager?.subscribe(subscribeOptions);
      }
      
      if (_pushSubscription != null) {
        final subscriptionInfo = _extractSubscriptionInfo(_pushSubscription!);
        
        _notificationController.add(NotificationEvent.subscribed(subscriptionInfo));
        
        return subscriptionInfo;
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to subscribe to push notifications: $e');
      _notificationController.add(NotificationEvent.error(e.toString()));
      return null;
    }
  }
  
  /// 取消推送订阅
  Future<bool> unsubscribeFromPush() async {
    if (_pushSubscription == null) return true;
    
    try {
      final success = await _pushSubscription!.unsubscribe();
      
      if (success) {
        _pushSubscription = null;
        _notificationController.add(NotificationEvent.unsubscribed());
      }
      
      return success;
    } catch (e) {
      debugPrint('Failed to unsubscribe from push notifications: $e');
      _notificationController.add(NotificationEvent.error(e.toString()));
      return false;
    }
  }
  
  /// 显示本地通知
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
    String? badge,
    String? tag,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
  }) async {
    if (!_hasPermission) {
      throw StateError('Notification permission not granted');
    }
    
    try {
      final options = <String, dynamic>{
        'body': body,
        'icon': icon ?? '/icons/icon-192.png',
        'badge': badge ?? '/icons/icon-72.png',
        'tag': tag,
        'data': data,
        'requireInteraction': false,
        'silent': false,
      };
      
      if (actions != null && actions.isNotEmpty) {
        options['actions'] = actions.map((action) => action.toJson()).toList();
      }
      
      // 如果Service Worker可用，通过SW显示通知
      if (_swRegistration != null) {
        await _swRegistration!.showNotification(title, options);
      } else {
        // 否则使用浏览器原生通知
        html.Notification(title);
      }
      
      _notificationController.add(NotificationEvent.notificationShown(title));
      
    } catch (e) {
      debugPrint('Failed to show notification: $e');
      _notificationController.add(NotificationEvent.error(e.toString()));
    }
  }
  
  /// 获取活跃的通知
  Future<List<html.Notification>> getActiveNotifications() async {
    if (_swRegistration == null) return <html.Notification>[];
    
    try {
      final notifications = await _swRegistration!.getNotifications();
      return notifications.cast<html.Notification>();
    } catch (e) {
      debugPrint('Failed to get active notifications: $e');
      return <html.Notification>[];
    }
  }
  
  /// 清除所有通知
  Future<void> clearAllNotifications() async {
    try {
      final notifications = await getActiveNotifications();
      for (final notification in notifications) {
        notification.close();
      }
      
      _notificationController.add(NotificationEvent.notificationsCleared());
    } catch (e) {
      debugPrint('Failed to clear notifications: $e');
    }
  }
  
  /// 获取当前订阅信息
  PushSubscriptionInfo? getCurrentSubscription() {
    if (_pushSubscription == null) return null;
    return _extractSubscriptionInfo(_pushSubscription!);
  }
  
  /// 检查是否已订阅
  bool get isSubscribed => _pushSubscription != null;
  
  /// 检查是否有权限
  bool get hasPermission => _hasPermission;
  
  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
  
  // 私有方法
  
  bool _isBrowserSupported() {
    try {
      return html.window.navigator.serviceWorker != null &&
             _isPushManagerSupported();
    } catch (e) {
      return false;
    }
  }
  
  bool _isPushManagerSupported() {
    try {
      return js.context.hasProperty('PushManager');
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _getServiceWorkerRegistration() async {
    try {
      _swRegistration = await html.window.navigator.serviceWorker?.ready;
      
      if (_swRegistration == null) {
        // 尝试注册Service Worker
        _swRegistration = await html.window.navigator.serviceWorker?.register('/sw.js');
      }
      
      if (_swRegistration == null) {
        throw StateError('Failed to get Service Worker registration');
      }
      
    } catch (e) {
      debugPrint('Failed to get Service Worker registration: $e');
      rethrow;
    }
  }
  
  Future<void> _checkNotificationPermission() async {
    final permission = html.Notification.permission;
    _hasPermission = permission == 'granted';
    
    if (permission == 'default') {
      // 权限未设置，可以请求
      debugPrint('Notification permission not set, can request');
    } else if (permission == 'denied') {
      // 权限被拒绝
      debugPrint('Notification permission denied');
      _notificationController.add(NotificationEvent.permissionDenied());
    }
  }
  
  void _setupMessageListeners() {
    // 监听来自Service Worker的消息
    html.window.navigator.serviceWorker?.onMessage.listen((html.MessageEvent event) {
      try {
        final data = event.data;
        if (data is Map && data['type'] == 'push_notification') {
          _handlePushMessage(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        debugPrint('Failed to handle service worker message: $e');
      }
    });
    
    // 监听通知点击事件（如果在主线程中）
    html.window.onMessage.listen((html.MessageEvent event) {
      try {
        final data = event.data;
        if (data is Map && data['type'] == 'notification_click') {
          _handleNotificationClick(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        debugPrint('Failed to handle notification click: $e');
      }
    });
  }
  
  void _handlePushMessage(Map<String, dynamic> data) {
    final event = NotificationEvent.messageReceived(Map<String, dynamic>.from(data));
    _notificationController.add(event);
  }
  
  void _handleNotificationClick(Map<String, dynamic> data) {
    final event = NotificationEvent.notificationClicked(Map<String, dynamic>.from(data));
    _notificationController.add(event);
  }
  
  PushSubscriptionInfo _extractSubscriptionInfo(html.PushSubscription subscription) {
    final endpoint = subscription.endpoint ?? '';
    final keys = subscription.getKey('p256dh');
    final auth = subscription.getKey('auth');
    
    return PushSubscriptionInfo(
      endpoint: endpoint,
      p256dhKey: keys != null ? _arrayBufferToBase64(keys) : null,
      authKey: auth != null ? _arrayBufferToBase64(auth) : null,
    );
  }
  
  List<int> _urlBase64ToUint8Array(String base64String) {
    const padding = '=';
    final normalizedBase64 = (base64String + padding * (4 - base64String.length % 4))
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    
    return base64Decode(normalizedBase64);
  }
  
  String _arrayBufferToBase64(dynamic buffer) {
    // 将ArrayBuffer转换为base64字符串
    // 这里需要根据实际的buffer类型进行处理
    if (buffer is List<int>) {
      return base64Encode(buffer);
    }
    // 其他类型的处理...
    return '';
  }
  
  /// 清理资源
  void dispose() {
    _notificationController.close();
  }
}

/// 推送订阅信息
class PushSubscriptionInfo {
  final String endpoint;
  final String? p256dhKey;
  final String? authKey;
  
  const PushSubscriptionInfo({
    required this.endpoint,
    this.p256dhKey,
    this.authKey,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'keys': {
        'p256dh': p256dhKey,
        'auth': authKey,
      },
    };
  }
  
  factory PushSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final keys = json['keys'] as Map<String, dynamic>?;
    return PushSubscriptionInfo(
      endpoint: json['endpoint'],
      p256dhKey: keys?['p256dh'],
      authKey: keys?['auth'],
    );
  }
}

/// 通知动作
class NotificationAction {
  final String action;
  final String title;
  final String? icon;
  
  const NotificationAction({
    required this.action,
    required this.title,
    this.icon,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'title': title,
      'icon': icon,
    };
  }
}

/// 通知事件
class NotificationEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  NotificationEvent({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();
  
  factory NotificationEvent.initialized() {
    return NotificationEvent(type: 'initialized', data: {});
  }
  
  factory NotificationEvent.permissionGranted() {
    return NotificationEvent(type: 'permission_granted', data: {});
  }
  
  factory NotificationEvent.permissionDenied() {
    return NotificationEvent(type: 'permission_denied', data: {});
  }
  
  factory NotificationEvent.subscribed(PushSubscriptionInfo subscription) {
    return NotificationEvent(
      type: 'subscribed',
      data: {'subscription': subscription.toJson()},
    );
  }
  
  factory NotificationEvent.unsubscribed() {
    return NotificationEvent(type: 'unsubscribed', data: {});
  }
  
  factory NotificationEvent.notificationShown(String title) {
    return NotificationEvent(
      type: 'notification_shown',
      data: {'title': title},
    );
  }
  
  factory NotificationEvent.notificationClicked(Map<String, dynamic> data) {
    return NotificationEvent(
      type: 'notification_clicked',
      data: data,
    );
  }
  
  factory NotificationEvent.messageReceived(Map<String, dynamic> data) {
    return NotificationEvent(
      type: 'message_received',
      data: data,
    );
  }
  
  factory NotificationEvent.notificationsCleared() {
    return NotificationEvent(type: 'notifications_cleared', data: {});
  }
  
  factory NotificationEvent.error(String error) {
    return NotificationEvent(
      type: 'error',
      data: {'error': error},
    );
  }
}