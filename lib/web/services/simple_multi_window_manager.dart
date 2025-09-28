import 'package:flutter/material.dart';

/// 简化版多窗口聊天管理器
/// PWA专用功能，支持在多个浏览器窗口中同时进行不同的聊天会话
class SimpleMultiWindowManager {
  static SimpleMultiWindowManager? _instance;
  static SimpleMultiWindowManager get instance => _instance ??= SimpleMultiWindowManager._();
  
  SimpleMultiWindowManager._();

  final Map<String, ChatWindowInfo> _activeWindows = {};
  final List<ChatWindowListener> _listeners = [];
  bool _isInitialized = false;

  /// 初始化多窗口管理器
  Future<void> initialize() async {
    // 简化版本，不直接操作浏览器窗口
    _isInitialized = true;
  }

  /// 创建新的聊天窗口信息
  ChatWindowInfo createChatWindow({
    required String conversationId,
    String? title,
  }) {
    final windowId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    
    final windowInfo = ChatWindowInfo(
      id: windowId,
      conversationId: conversationId,
      title: title ?? '聊天窗口',
      createdAt: DateTime.now(),
    );
    
    _activeWindows[windowId] = windowInfo;
    _notifyListeners(ChatWindowEvent.opened, windowInfo);
    
    return windowInfo;
  }

  /// 关闭聊天窗口
  Future<void> closeChatWindow(String windowId) async {
    final window = _activeWindows[windowId];
    if (window != null) {
      _activeWindows.remove(windowId);
      _notifyListeners(ChatWindowEvent.closed, window);
    }
  }

  /// 获取活跃窗口列表
  List<ChatWindowInfo> getActiveWindows() {
    return _activeWindows.values.toList();
  }

  /// 检查窗口是否存在
  bool hasWindow(String windowId) {
    return _activeWindows.containsKey(windowId);
  }

  /// 添加窗口事件监听器
  void addListener(ChatWindowListener listener) {
    _listeners.add(listener);
  }

  /// 移除窗口事件监听器
  void removeListener(ChatWindowListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(ChatWindowEvent event, ChatWindowInfo window) {
    for (final listener in _listeners) {
      try {
        listener.onChatWindowEvent(event, window);
      } catch (e) {
        print('Error notifying listener: $e');
      }
    }
  }

  /// 清理资源
  void dispose() {
    _activeWindows.clear();
    _listeners.clear();
    _isInitialized = false;
  }
}

/// 聊天窗口信息
class ChatWindowInfo {
  final String id;
  final String conversationId;
  final String title;
  final DateTime createdAt;
  DateTime lastActivity;

  ChatWindowInfo({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.createdAt,
  }) : lastActivity = DateTime.now();

  /// 更新最后活动时间
  void updateActivity() {
    lastActivity = DateTime.now();
  }
}

/// 窗口事件枚举
enum ChatWindowEvent {
  opened,
  closed,
  focused,
}

/// 窗口事件监听器
abstract class ChatWindowListener {
  void onChatWindowEvent(ChatWindowEvent event, ChatWindowInfo window);
}

/// 多窗口聊天配置
class MultiWindowConfig {
  final bool enabled;
  final int maxWindows;
  final bool allowCrossWindowMessaging;
  final bool autoLayout;

  const MultiWindowConfig({
    this.enabled = true,
    this.maxWindows = 4,
    this.allowCrossWindowMessaging = true,
    this.autoLayout = true,
  });

  factory MultiWindowConfig.defaultConfig() {
    return const MultiWindowConfig();
  }

  factory MultiWindowConfig.conservative() {
    return const MultiWindowConfig(
      maxWindows: 2,
      allowCrossWindowMessaging: false,
    );
  }

  factory MultiWindowConfig.advanced() {
    return const MultiWindowConfig(
      maxWindows: 8,
      autoLayout: true,
    );
  }
}