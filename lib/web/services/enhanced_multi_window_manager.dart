import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import '../../platform/detector/platform_detector.dart';
import '../../platform/features/feature_flags.dart';
import '../../core/models/conversation.dart';
import '../../core/models/chat_message.dart';

/// 增强版多窗口聊天管理器
/// 支持窗口间状态同步、消息传递和智能布局管理
class EnhancedMultiWindowManager {
  static EnhancedMultiWindowManager? _instance;
  static EnhancedMultiWindowManager get instance =>
      _instance ??= EnhancedMultiWindowManager._();

  EnhancedMultiWindowManager._();

  final Map<String, EnhancedChatWindow> _activeWindows = {};
  final List<MultiWindowEventListener> _listeners = [];
  final StreamController<WindowSyncEvent> _syncController = StreamController.broadcast();
  bool _isInitialized = false;
  Timer? _heartbeatTimer;
  String? _currentWindowId;

  /// 同步事件流
  Stream<WindowSyncEvent> get syncStream => _syncController.stream;

  /// 初始化增强版多窗口管理器
  Future<void> initialize() async {
    if (!PlatformDetector.isWeb || _isInitialized) return;

    try {
      // 获取当前窗口ID
      _currentWindowId = _getCurrentWindowId();
      
      // 监听窗口消息事件
      html.window.onMessage.listen(_handleWindowMessage);

      // 监听存储变化（用于跨窗口同步）
      html.window.onStorage.listen(_handleStorageChange);

      // 注册当前窗口
      await _registerCurrentWindow();

      // 启动心跳检测
      _startHeartbeat();

      // 恢复活跃窗口状态
      await _restoreActiveWindows();

      _isInitialized = true;
      print('Enhanced multi-window manager initialized');
    } catch (e) {
      print('Enhanced multi-window manager initialization failed: $e');
    }
  }

  /// 打开新的聊天窗口
  Future<EnhancedChatWindow?> openChatWindow({
    required String conversationId,
    String? title,
    EnhancedWindowOptions? options,
    Map<String, dynamic>? initialData,
  }) async {
    if (!PlatformDetector.isWeb || !FeatureFlags.isPWAEnabled) {
      return null;
    }

    try {
      final windowOptions = options ?? EnhancedWindowOptions.defaultOptions();
      final windowId = 'chat_${DateTime.now().millisecondsSinceEpoch}';

      // 检查窗口数量限制
      if (_activeWindows.length >= windowOptions.maxWindows) {
        throw Exception('已达到最大窗口数量限制: ${windowOptions.maxWindows}');
      }

      // 构建URL参数
      final url = _buildWindowUrl(
        conversationId: conversationId,
        windowId: windowId,
        title: title,
        initialData: initialData,
      );

      // 打开新窗口
      final window = html.window.open(
        url,
        windowId,
        _buildWindowFeatures(windowOptions),
      );

      if (window != null) {
        final chatWindow = EnhancedChatWindow(
          id: windowId,
          conversationId: conversationId,
          title: title ?? '聊天窗口',
          windowRef: window,
          options: windowOptions,
          createdAt: DateTime.now(),
          initialData: initialData,
        );

        _activeWindows[windowId] = chatWindow;
        await _saveWindowState();
        
        _notifyListeners(MultiWindowEvent.opened, chatWindow);
        _syncController.add(WindowSyncEvent.windowOpened(chatWindow));

        return chatWindow;
      }
    } catch (e) {
      print('Failed to open chat window: $e');
      rethrow;
    }

    return null;
  }

  /// 关闭聊天窗口
  Future<void> closeChatWindow(String windowId) async {
    final window = _activeWindows[windowId];
    if (window != null) {
      try {
        // 发送关闭前事件
        await sendMessageToWindow(windowId, {
          'type': 'window_closing',
          'timestamp': DateTime.now().toIso8601String(),
        });

        window.close();
        _activeWindows.remove(windowId);
        await _saveWindowState();
        
        _notifyListeners(MultiWindowEvent.closed, window);
        _syncController.add(WindowSyncEvent.windowClosed(window));
      } catch (e) {
        print('Failed to close chat window: $e');
      }
    }
  }

  /// 向指定窗口发送消息
  Future<void> sendMessageToWindow(
    String windowId,
    Map<String, dynamic> message,
  ) async {
    final window = _activeWindows[windowId];
    if (window != null && window.isOpen) {
      try {
        final enrichedMessage = {
          ...message,
          'source_window_id': _currentWindowId,
          'target_window_id': windowId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        window.postMessage(enrichedMessage);
        window.updateActivity();
      } catch (e) {
        print('Failed to send message to window: $e');
      }
    }
  }

  /// 广播消息到所有窗口
  Future<void> broadcastMessage(Map<String, dynamic> message) async {
    final enrichedMessage = {
      ...message,
      'source_window_id': _currentWindowId,
      'broadcast': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    for (final window in _activeWindows.values) {
      if (window.isOpen) {
        try {
          window.postMessage(enrichedMessage);
          window.updateActivity();
        } catch (e) {
          print('Failed to broadcast message to ${window.id}: $e');
        }
      }
    }

    // 同时通过localStorage广播（用于同源窗口）
    await _broadcastViaStorage(enrichedMessage);
  }

  /// 同步会话状态到所有窗口
  Future<void> syncConversationState(
    String conversationId,
    Map<String, dynamic> state,
  ) async {
    final syncMessage = {
      'type': 'conversation_sync',
      'conversation_id': conversationId,
      'state': state,
      'sync_id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    await broadcastMessage(syncMessage);
    _syncController.add(WindowSyncEvent.conversationSync(conversationId, state));
  }

  /// 同步新消息到相关窗口
  Future<void> syncNewMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    final syncMessage = {
      'type': 'message_sync',
      'conversation_id': conversationId,
      'message': message.toJson(),
    };

    // 只发送给相同会话的窗口
    final relevantWindows = _activeWindows.values
        .where((w) => w.conversationId == conversationId);

    for (final window in relevantWindows) {
      await sendMessageToWindow(window.id, syncMessage);
    }

    _syncController.add(WindowSyncEvent.messageSync(conversationId, message));
  }

  /// 获取活跃窗口列表
  List<EnhancedChatWindow> getActiveWindows() {
    // 清理已关闭的窗口
    _cleanupClosedWindows();
    return _activeWindows.values.toList();
  }

  /// 获取指定会话的窗口
  List<EnhancedChatWindow> getWindowsForConversation(String conversationId) {
    return _activeWindows.values
        .where((w) => w.conversationId == conversationId)
        .toList();
  }

  /// 检查窗口是否存在
  bool hasWindow(String windowId) {
    return _activeWindows.containsKey(windowId) && 
           _activeWindows[windowId]!.isOpen;
  }

  /// 聚焦指定窗口
  Future<void> focusWindow(String windowId) async {
    final window = _activeWindows[windowId];
    if (window != null && window.isOpen) {
      try {
        window.focus();
        await sendMessageToWindow(windowId, {'type': 'window_focus_request'});
        _notifyListeners(MultiWindowEvent.focused, window);
      } catch (e) {
        print('Failed to focus window: $e');
      }
    }
  }

  /// 添加事件监听器
  void addListener(MultiWindowEventListener listener) {
    _listeners.add(listener);
  }

  /// 移除事件监听器
  void removeListener(MultiWindowEventListener listener) {
    _listeners.remove(listener);
  }

  /// 获取窗口统计信息
  WindowStatistics getStatistics() {
    final windows = getActiveWindows();
    final conversationCounts = <String, int>{};
    
    for (final window in windows) {
      conversationCounts[window.conversationId] = 
          (conversationCounts[window.conversationId] ?? 0) + 1;
    }

    return WindowStatistics(
      totalWindows: windows.length,
      activeWindows: windows.where((w) => w.isActive).length,
      conversationCounts: conversationCounts,
      oldestWindow: windows.isEmpty ? null : 
          windows.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b),
      newestWindow: windows.isEmpty ? null :
          windows.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b),
    );
  }

  // 私有方法实现
  void _handleWindowMessage(html.MessageEvent event) {
    try {
      final data = event.data as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'window_ready':
          _handleWindowReady(data);
          break;
        case 'conversation_update':
          _handleConversationUpdate(data);
          break;
        case 'window_focus':
          _handleWindowFocus(data);
          break;
        case 'heartbeat':
          _handleHeartbeat(data);
          break;
        case 'sync_request':
          _handleSyncRequest(data);
          break;
      }

      // 转发给监听器
      _syncController.add(WindowSyncEvent.messageReceived(data));
    } catch (e) {
      print('Error handling window message: $e');
    }
  }

  void _handleStorageChange(html.StorageEvent event) {
    if (event.key == 'multi_window_broadcast') {
      try {
        final data = jsonDecode(event.newValue ?? '{}') as Map<String, dynamic>;
        _syncController.add(WindowSyncEvent.storageSync(data));
      } catch (e) {
        print('Error handling storage change: $e');
      }
    }
  }

  Future<void> _registerCurrentWindow() async {
    if (_currentWindowId != null) {
      // 将当前窗口信息保存到localStorage
      final windowInfo = {
        'id': _currentWindowId,
        'url': html.window.location.href,
        'title': html.document.title,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      html.window.localStorage['current_window_$_currentWindowId'] = 
          jsonEncode(windowInfo);
    }
  }

  String? _getCurrentWindowId() {
    // 从URL参数获取窗口ID
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters['window_id'];
  }

  String _buildWindowUrl({
    required String conversationId,
    required String windowId,
    String? title,
    Map<String, dynamic>? initialData,
  }) {
    final baseUrl = html.window.location.origin;
    final params = <String, String>{
      'conversation_id': conversationId,
      'window_id': windowId,
      'mode': 'enhanced_chat_window',
    };

    if (title != null) {
      params['title'] = title;
    }

    if (initialData != null) {
      params['initial_data'] = base64Encode(utf8.encode(jsonEncode(initialData)));
    }

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl/?$query';
  }

  String _buildWindowFeatures(EnhancedWindowOptions options) {
    final features = <String>[
      'width=${options.width}',
      'height=${options.height}',
      'left=${options.left}',
      'top=${options.top}',
      'resizable=${options.resizable ? 'yes' : 'no'}',
      'scrollbars=${options.scrollbars ? 'yes' : 'no'}',
      'status=${options.status ? 'yes' : 'no'}',
      'menubar=${options.menubar ? 'yes' : 'no'}',
      'toolbar=${options.toolbar ? 'yes' : 'no'}',
    ];

    return features.join(',');
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      broadcastMessage({
        'type': 'heartbeat',
        'window_id': _currentWindowId,
      });
      _cleanupClosedWindows();
    });
  }

  void _cleanupClosedWindows() {
    final closedWindows = <String>[];
    
    for (final entry in _activeWindows.entries) {
      if (!entry.value.isOpen) {
        closedWindows.add(entry.key);
      }
    }

    for (final windowId in closedWindows) {
      final window = _activeWindows.remove(windowId);
      if (window != null) {
        _notifyListeners(MultiWindowEvent.closed, window);
        _syncController.add(WindowSyncEvent.windowClosed(window));
      }
    }

    if (closedWindows.isNotEmpty) {
      _saveWindowState();
    }
  }

  Future<void> _saveWindowState() async {
    try {
      final windowStates = _activeWindows.values.map((w) => {
        'id': w.id,
        'conversationId': w.conversationId,
        'title': w.title,
        'createdAt': w.createdAt.toIso8601String(),
        'lastActivity': w.lastActivity.toIso8601String(),
      }).toList();

      html.window.localStorage['multi_window_state'] = jsonEncode(windowStates);
    } catch (e) {
      print('Failed to save window state: $e');
    }
  }

  Future<void> _restoreActiveWindows() async {
    try {
      final stateJson = html.window.localStorage['multi_window_state'];
      if (stateJson != null) {
        final states = jsonDecode(stateJson) as List<dynamic>;
        print('Found ${states.length} previous window states');
      }
    } catch (e) {
      print('Failed to restore window state: $e');
    }
  }

  Future<void> _broadcastViaStorage(Map<String, dynamic> message) async {
    try {
      html.window.localStorage['multi_window_broadcast'] = jsonEncode(message);
      // 立即清除，避免重复触发
      await Future.delayed(Duration(milliseconds: 100));
      html.window.localStorage.remove('multi_window_broadcast');
    } catch (e) {
      print('Failed to broadcast via storage: $e');
    }
  }

  void _handleWindowReady(Map<String, dynamic> data) {
    final windowId = data['window_id'] as String?;
    if (windowId != null && _activeWindows.containsKey(windowId)) {
      final window = _activeWindows[windowId]!;
      window.markAsReady();
      _notifyListeners(MultiWindowEvent.ready, window);
    }
  }

  void _handleConversationUpdate(Map<String, dynamic> data) {
    final conversationId = data['conversation_id'] as String?;
    final state = data['state'] as Map<String, dynamic>?;
    
    if (conversationId != null && state != null) {
      _syncController.add(WindowSyncEvent.conversationSync(conversationId, state));
    }
  }

  void _handleWindowFocus(Map<String, dynamic> data) {
    final windowId = data['window_id'] as String?;
    if (windowId != null && _activeWindows.containsKey(windowId)) {
      final window = _activeWindows[windowId]!;
      window.updateActivity();
      _notifyListeners(MultiWindowEvent.focused, window);
    }
  }

  void _handleHeartbeat(Map<String, dynamic> data) {
    final windowId = data['window_id'] as String?;
    if (windowId != null && _activeWindows.containsKey(windowId)) {
      _activeWindows[windowId]!.updateActivity();
    }
  }

  void _handleSyncRequest(Map<String, dynamic> data) {
    final requestType = data['request_type'] as String?;
    final sourceWindowId = data['source_window_id'] as String?;
    
    if (requestType == 'full_state' && sourceWindowId != null) {
      sendMessageToWindow(sourceWindowId, {
        'type': 'full_state_response',
        'windows': _activeWindows.values.map((w) => w.toJson()).toList(),
      });
    }
  }

  void _notifyListeners(MultiWindowEvent event, EnhancedChatWindow window) {
    for (final listener in _listeners) {
      try {
        listener.onMultiWindowEvent(event, window);
      } catch (e) {
        print('Error notifying listener: $e');
      }
    }
  }

  /// 清理资源
  void dispose() {
    _heartbeatTimer?.cancel();
    _syncController.close();
    _activeWindows.clear();
    _listeners.clear();
    _isInitialized = false;
  }
}

/// 增强版聊天窗口
class EnhancedChatWindow {
  final String id;
  final String conversationId;
  final String title;
  final html.WindowBase? windowRef;
  final EnhancedWindowOptions options;
  final DateTime createdAt;
  final Map<String, dynamic>? initialData;
  
  DateTime lastActivity;
  bool _isReady = false;
  final Map<String, dynamic> _metadata = {};

  EnhancedChatWindow({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.windowRef,
    required this.options,
    required this.createdAt,
    this.initialData,
  }) : lastActivity = DateTime.now();

  /// 检查窗口是否仍然打开
  bool get isOpen {
    try {
      if (windowRef == null) return false;
      final closed = windowRef!.closed;
      return closed != null ? !closed : true;
    } catch (e) {
      return false;
    }
  }

  /// 检查窗口是否准备就绪
  bool get isReady => _isReady && isOpen;

  /// 检查窗口是否活跃（最近5分钟内有活动）
  bool get isActive {
    return DateTime.now().difference(lastActivity).inMinutes < 5;
  }

  /// 聚焦窗口
  void focus() {
    try {
      if (windowRef != null && isOpen) {
        // 简化的聚焦实现
        postMessage({'type': 'focus_request'});
      }
      updateActivity();
    } catch (e) {
      print('Failed to focus window: $e');
    }
  }

  /// 关闭窗口
  void close() {
    try {
      windowRef?.close();
    } catch (e) {
      print('Failed to close window: $e');
    }
  }

  /// 发送消息到窗口
  void postMessage(Map<String, dynamic> message) {
    try {
      if (windowRef != null && isOpen) {
        windowRef!.postMessage(message, '*');
      }
    } catch (e) {
      print('Failed to post message to window: $e');
    }
  }

  /// 更新最后活动时间
  void updateActivity() {
    lastActivity = DateTime.now();
  }

  /// 标记窗口为准备就绪
  void markAsReady() {
    _isReady = true;
    updateActivity();
  }

  /// 设置元数据
  void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
  }

  /// 获取元数据
  T? getMetadata<T>(String key) {
    return _metadata[key] as T?;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'isReady': isReady,
      'isActive': isActive,
      'metadata': _metadata,
    };
  }
}

/// 增强版窗口选项
class EnhancedWindowOptions {
  final int width;
  final int height;
  final int left;
  final int top;
  final bool resizable;
  final bool scrollbars;
  final bool status;
  final bool menubar;
  final bool toolbar;
  final bool autoLayout;
  final int maxWindows;
  final bool enableSync;
  final bool enableHeartbeat;

  const EnhancedWindowOptions({
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    this.resizable = true,
    this.scrollbars = true,
    this.status = false,
    this.menubar = false,
    this.toolbar = false,
    this.autoLayout = true,
    this.maxWindows = 6,
    this.enableSync = true,
    this.enableHeartbeat = true,
  });

  factory EnhancedWindowOptions.defaultOptions() {
    final screenWidth = html.window.screen?.width ?? 1920;
    final screenHeight = html.window.screen?.height ?? 1080;

    return EnhancedWindowOptions(
      width: (screenWidth * 0.6).round(),
      height: (screenHeight * 0.8).round(),
      left: (screenWidth * 0.2).round(),
      top: (screenHeight * 0.1).round(),
    );
  }

  factory EnhancedWindowOptions.compact() {
    return const EnhancedWindowOptions(
      width: 450,
      height: 650,
      left: 100,
      top: 100,
      maxWindows: 4,
    );
  }

  factory EnhancedWindowOptions.performance() {
    return const EnhancedWindowOptions(
      width: 800,
      height: 600,
      left: 200,
      top: 150,
      enableSync: false,
      enableHeartbeat: false,
      maxWindows: 3,
    );
  }
}

/// 多窗口事件枚举
enum MultiWindowEvent {
  opened,
  closed,
  ready,
  focused,
  minimized,
  maximized,
  syncReceived,
}

/// 窗口同步事件
class WindowSyncEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WindowSyncEvent({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();

  factory WindowSyncEvent.windowOpened(EnhancedChatWindow window) {
    return WindowSyncEvent(
      type: 'window_opened',
      data: window.toJson(),
    );
  }

  factory WindowSyncEvent.windowClosed(EnhancedChatWindow window) {
    return WindowSyncEvent(
      type: 'window_closed',
      data: window.toJson(),
    );
  }

  factory WindowSyncEvent.conversationSync(
    String conversationId,
    Map<String, dynamic> state,
  ) {
    return WindowSyncEvent(
      type: 'conversation_sync',
      data: {
        'conversation_id': conversationId,
        'state': state,
      },
    );
  }

  factory WindowSyncEvent.messageSync(
    String conversationId,
    ChatMessage message,
  ) {
    return WindowSyncEvent(
      type: 'message_sync',
      data: {
        'conversation_id': conversationId,
        'message': message.toJson(),
      },
    );
  }

  factory WindowSyncEvent.messageReceived(Map<String, dynamic> message) {
    return WindowSyncEvent(
      type: 'message_received',
      data: message,
    );
  }

  factory WindowSyncEvent.storageSync(Map<String, dynamic> data) {
    return WindowSyncEvent(
      type: 'storage_sync',
      data: data,
    );
  }
}

/// 窗口统计信息
class WindowStatistics {
  final int totalWindows;
  final int activeWindows;
  final Map<String, int> conversationCounts;
  final EnhancedChatWindow? oldestWindow;
  final EnhancedChatWindow? newestWindow;

  const WindowStatistics({
    required this.totalWindows,
    required this.activeWindows,
    required this.conversationCounts,
    this.oldestWindow,
    this.newestWindow,
  });

  /// 获取平均窗口年龄（分钟）
  double get averageWindowAge {
    if (totalWindows == 0) return 0;
    
    final now = DateTime.now();
    final totalAge = [oldestWindow, newestWindow]
        .where((w) => w != null)
        .map((w) => now.difference(w!.createdAt).inMinutes)
        .fold(0, (sum, age) => sum + age);
    
    return totalAge / totalWindows;
  }

  /// 获取最活跃的会话ID
  String? get mostActiveConversation {
    if (conversationCounts.isEmpty) return null;
    
    return conversationCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// 多窗口事件监听器
abstract class MultiWindowEventListener {
  void onMultiWindowEvent(MultiWindowEvent event, EnhancedChatWindow window);
}