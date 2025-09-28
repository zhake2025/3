import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// 简化版PWA推送通知服务
/// 专注于基本的通知功能，避免复杂的Web API兼容性问题
class SimplePushNotificationService {
  static SimplePushNotificationService? _instance;
  static SimplePushNotificationService get instance => 
      _instance ??= SimplePushNotificationService._();
  
  SimplePushNotificationService._();

  final StreamController<NotificationEvent> _notificationController = 
      StreamController<NotificationEvent>.broadcast();
  
  Stream<NotificationEvent> get notificationStream => 
      _notificationController.stream;
  
  bool _isInitialized = false;
  bool _hasPermission = false;
  
  /// 初始化推送通知服务
  Future<void> initialize() async {
    if (!kIsWeb) {
      debugPrint('Push notifications only supported on web platform');
      return;
    }

    try {
      // 检查浏览器支持
      if (!_isBrowserSupported()) {
        throw UnsupportedError('Push notifications not supported in this browser');
      }
      
      // 检查通知权限
      await _checkNotificationPermission();
      
      _isInitialized = true;
      
      _notificationController.add(NotificationEvent.initialized());
      debugPrint('Simple Push Notification Service initialized');
      
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
  
  /// 显示本地通知
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (!_hasPermission) {
      throw StateError('Notification permission not granted');
    }
    
    try {
      final options = <String, dynamic>{
        'body': body,
        'icon': icon ?? '/icons/icon-192.png',
        'tag': tag,
        'data': data,
        'requireInteraction': false,
        'silent': false,
      };
      
      // 使用浏览器原生通知
      final notification = html.Notification(title);
      
      // 设置点击事件监听
      notification.onClick.listen((_) {
        _handleNotificationClick(title, data);
        notification.close();
      });
      
      // 自动关闭通知
      Timer(const Duration(seconds: 5), () {
        notification.close();
      });
      
      _notificationController.add(NotificationEvent.notificationShown(title));
      
    } catch (e) {
      debugPrint('Failed to show notification: $e');
      _notificationController.add(NotificationEvent.error(e.toString()));
    }
  }
  
  /// 显示系统通知
  Future<void> showSystemNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    String icon;
    switch (type) {
      case NotificationType.success:
        icon = '/icons/success.png';
        break;
      case NotificationType.warning:
        icon = '/icons/warning.png';
        break;
      case NotificationType.error:
        icon = '/icons/error.png';
        break;
      case NotificationType.info:
      default:
        icon = '/icons/info.png';
        break;
    }
    
    await showLocalNotification(
      title: title,
      body: message,
      icon: icon,
      tag: 'system_${type.name}',
      data: {'type': type.name},
    );
  }
  
  /// 显示聊天消息通知
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    String? conversationId,
    String? avatarUrl,
  }) async {
    await showLocalNotification(
      title: senderName,
      body: message,
      icon: avatarUrl ?? '/icons/chat.png',
      tag: 'chat_${conversationId ?? 'default'}',
      data: {
        'type': 'chat',
        'conversationId': conversationId,
        'senderName': senderName,
      },
    );
  }
  
  /// 检查是否有权限
  bool get hasPermission => _hasPermission;
  
  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 获取权限状态
  String get permissionStatus {
    return html.Notification.permission ?? 'default';
  }
  
  // 私有方法
  
  bool _isBrowserSupported() {
    try {
      return html.Notification.supported;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _checkNotificationPermission() async {
    final permission = html.Notification.permission;
    _hasPermission = permission == 'granted';
    
    if (permission == 'default') {
      debugPrint('Notification permission not set, can request');
    } else if (permission == 'denied') {
      debugPrint('Notification permission denied');
      _notificationController.add(NotificationEvent.permissionDenied());
    }
  }
  
  void _handleNotificationClick(String title, Map<String, dynamic>? data) {
    final event = NotificationEvent.notificationClicked({
      'title': title,
      'data': data,
    });
    _notificationController.add(event);
    
    // 尝试聚焦到窗口
    try {
      (html.window as dynamic).focus();
    } catch (e) {
      debugPrint('Cannot focus window: $e');
    }
  }
  
  /// 清理资源
  void dispose() {
    _notificationController.close();
  }
}

/// 通知类型
enum NotificationType {
  info,
  success,
  warning,
  error,
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
  
  factory NotificationEvent.error(String error) {
    return NotificationEvent(
      type: 'error',
      data: {'error': error},
    );
  }
}