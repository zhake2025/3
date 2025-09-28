import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// 多窗口聊天管理器
/// 支持在多个浏览器窗口/标签页之间同步聊天状态
class MultiWindowChatManager {
  static MultiWindowChatManager? _instance;
  static MultiWindowChatManager get instance => _instance ??= MultiWindowChatManager._();
  
  MultiWindowChatManager._();

  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  late html.Storage _localStorage;
  late html.BroadcastChannel? _broadcastChannel;
  Timer? _heartbeatTimer;
  
  String? _currentWindowId;
  final Map<String, DateTime> _activeWindows = {};
  
  /// 初始化多窗口管理器
  Future<void> initialize() async {
    try {
      _localStorage = html.window.localStorage;
      _currentWindowId = _generateWindowId();
      
      // 尝试创建 BroadcastChannel（如果浏览器支持）
      try {
        _broadcastChannel = html.BroadcastChannel('kelivo_chat_sync');
        _broadcastChannel!.onMessage.listen(_handleBroadcastMessage);
      } catch (e) {
        debugPrint('BroadcastChannel not supported, falling back to localStorage');
        _broadcastChannel = null;
      }
      
      // 监听 localStorage 变化（作为 BroadcastChannel 的备选方案）
      html.window.onStorage.listen(_handleStorageChange);
      
      // 启动心跳检测
      _startHeartbeat();
      
      // 注册当前窗口
      _registerWindow();
      
      debugPrint('MultiWindowChatManager initialized with window ID: $_currentWindowId');
    } catch (e) {
      debugPrint('Failed to initialize MultiWindowChatManager: $e');
    }
  }
  
  /// 生成唯一的窗口ID
  String _generateWindowId() {
    try {
      final randomBytes = html.window.crypto?.getRandomValues(Uint8List(1));
      final randomValue = randomBytes != null && randomBytes.lengthInBytes > 0 
          ? (randomBytes as Uint8List)[0] 
          : 0;
      return 'window_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * randomValue / 255)).round()}';
    } catch (e) {
      return 'window_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    }
  }
  
  /// 注册当前窗口
  void _registerWindow() {
    if (_currentWindowId == null) return;
    
    _activeWindows[_currentWindowId!] = DateTime.now();
    _updateActiveWindowsList();
  }
  
  /// 启动心跳检测
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendHeartbeat();
      _cleanupInactiveWindows();
    });
  }
  
  /// 发送心跳信号
  void _sendHeartbeat() {
    if (_currentWindowId == null) return;
    
    final heartbeat = {
      'type': 'heartbeat',
      'windowId': _currentWindowId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _broadcastMessage(heartbeat);
  }
  
  /// 清理非活跃窗口
  void _cleanupInactiveWindows() {
    final now = DateTime.now();
    final inactiveThreshold = const Duration(seconds: 15);
    
    _activeWindows.removeWhere((windowId, lastSeen) {
      return now.difference(lastSeen) > inactiveThreshold;
    });
    
    _updateActiveWindowsList();
  }
  
  /// 更新活跃窗口列表到 localStorage
  void _updateActiveWindowsList() {
    try {
      final windowsList = _activeWindows.keys.toList();
      _localStorage['kelivo_active_windows'] = jsonEncode(windowsList);
    } catch (e) {
      debugPrint('Failed to update active windows list: $e');
    }
  }
  
  /// 广播消息到其他窗口
  void _broadcastMessage(Map<String, dynamic> message) {
    try {
      final messageJson = jsonEncode(message);
      
      // 优先使用 BroadcastChannel
      if (_broadcastChannel != null) {
        _broadcastChannel!.postMessage(messageJson);
      } else {
        // 备选方案：使用 localStorage 事件
        final key = 'kelivo_broadcast_${DateTime.now().millisecondsSinceEpoch}';
        _localStorage[key] = messageJson;
        // 立即删除，触发 storage 事件
        _localStorage.remove(key);
      }
    } catch (e) {
      debugPrint('Failed to broadcast message: $e');
    }
  }
  
  /// 处理 BroadcastChannel 消息
  void _handleBroadcastMessage(html.MessageEvent event) {
    try {
      final data = jsonDecode(event.data as String) as Map<String, dynamic>;
      _processMessage(data);
    } catch (e) {
      debugPrint('Failed to handle broadcast message: $e');
    }
  }
  
  /// 处理 localStorage 变化
  void _handleStorageChange(html.StorageEvent event) {
    if (event.key?.startsWith('kelivo_broadcast_') == true && event.newValue != null) {
      try {
        final data = jsonDecode(event.newValue!) as Map<String, dynamic>;
        _processMessage(data);
      } catch (e) {
        debugPrint('Failed to handle storage change: $e');
      }
    }
  }
  
  /// 处理接收到的消息
  void _processMessage(Map<String, dynamic> message) {
    final messageType = message['type'] as String?;
    final senderWindowId = message['windowId'] as String?;
    
    // 忽略自己发送的消息
    if (senderWindowId == _currentWindowId) return;
    
    switch (messageType) {
      case 'heartbeat':
        if (senderWindowId != null) {
          _activeWindows[senderWindowId] = DateTime.now();
        }
        break;
      case 'chat_message':
      case 'chat_state_update':
      case 'user_typing':
        _messageController.add(message);
        break;
      default:
        debugPrint('Unknown message type: $messageType');
    }
  }
  
  /// 同步聊天消息
  void syncChatMessage({
    required String messageId,
    required String content,
    required String sender,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) {
    final message = {
      'type': 'chat_message',
      'windowId': _currentWindowId,
      'data': {
        'messageId': messageId,
        'content': content,
        'sender': sender,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'metadata': metadata,
      },
    };
    
    _broadcastMessage(message);
  }
  
  /// 同步聊天状态更新
  void syncChatState({
    required String chatId,
    required Map<String, dynamic> state,
  }) {
    final message = {
      'type': 'chat_state_update',
      'windowId': _currentWindowId,
      'data': {
        'chatId': chatId,
        'state': state,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };
    
    _broadcastMessage(message);
  }
  
  /// 同步用户输入状态
  void syncUserTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) {
    final message = {
      'type': 'user_typing',
      'windowId': _currentWindowId,
      'data': {
        'chatId': chatId,
        'userId': userId,
        'isTyping': isTyping,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    };
    
    _broadcastMessage(message);
  }
  
  /// 获取活跃窗口数量
  int get activeWindowCount => _activeWindows.length;
  
  /// 获取当前窗口ID
  String? get currentWindowId => _currentWindowId;
  
  /// 检查是否为主窗口（最早创建的窗口）
  bool get isPrimaryWindow {
    if (_currentWindowId == null || _activeWindows.isEmpty) return true;
    
    final sortedWindows = _activeWindows.keys.toList()..sort();
    return sortedWindows.first == _currentWindowId;
  }
  
  /// 销毁管理器
  void dispose() {
    _heartbeatTimer?.cancel();
    _broadcastChannel?.close();
    _messageController.close();
    
    // 从活跃窗口列表中移除当前窗口
    if (_currentWindowId != null) {
      _activeWindows.remove(_currentWindowId);
      _updateActiveWindowsList();
    }
    
    debugPrint('MultiWindowChatManager disposed');
  }
}