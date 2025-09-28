import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// 简化版离线同步管理器
/// 使用localStorage进行数据存储，避免IndexedDB的复杂性
class SimpleOfflineSyncManager extends ChangeNotifier {
  static SimpleOfflineSyncManager? _instance;
  static SimpleOfflineSyncManager get instance => _instance ??= SimpleOfflineSyncManager._();
  
  SimpleOfflineSyncManager._();

  final StreamController<SyncEvent> _syncController = 
      StreamController<SyncEvent>.broadcast();
  
  Stream<SyncEvent> get syncStream => _syncController.stream;
  
  Timer? _syncTimer;
  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  final Map<String, PendingOperation> _pendingOperations = {};
  final Map<String, dynamic> _offlineData = {};
  
  /// 初始化离线同步管理器
  Future<void> initialize() async {
    try {
      // 监听网络状态变化
      html.window.onOnline.listen((_) => _handleOnlineStatusChange(true));
      html.window.onOffline.listen((_) => _handleOnlineStatusChange(false));
      
      // 初始化网络状态
      _isOnline = html.window.navigator.onLine ?? true;
      
      // 加载离线数据
      await _loadOfflineData();
      
      // 加载待处理操作
      await _loadPendingOperations();
      
      // 如果在线，启动同步
      if (_isOnline) {
        _startPeriodicSync();
      }
      
      debugPrint('Simple Offline Sync Manager initialized. Online: $_isOnline');
    } catch (e) {
      debugPrint('Failed to initialize offline sync manager: $e');
    }
  }
  
  /// 处理网络状态变化
  void _handleOnlineStatusChange(bool isOnline) {
    if (_isOnline == isOnline) return;
    
    _isOnline = isOnline;
    
    final event = SyncEvent(
      type: isOnline ? SyncEventType.online : SyncEventType.offline,
      timestamp: DateTime.now(),
    );
    
    _syncController.add(event);
    
    if (isOnline) {
      _startPeriodicSync();
      _syncPendingOperations();
    } else {
      _stopPeriodicSync();
    }
    
    notifyListeners();
    debugPrint('Network status changed: ${isOnline ? 'Online' : 'Offline'}');
  }
  
  /// 启动定期同步
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && !_isSyncing) {
        _syncPendingOperations();
      }
    });
  }
  
  /// 停止定期同步
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  /// 加载离线数据
  Future<void> _loadOfflineData() async {
    try {
      final dataJson = html.window.localStorage['kelivo_offline_data'];
      if (dataJson != null) {
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        _offlineData.addAll(data);
      }
    } catch (e) {
      debugPrint('Failed to load offline data: $e');
    }
  }
  
  /// 保存离线数据
  Future<void> _saveOfflineData() async {
    try {
      html.window.localStorage['kelivo_offline_data'] = jsonEncode(_offlineData);
    } catch (e) {
      debugPrint('Failed to save offline data: $e');
    }
  }
  
  /// 加载待处理操作
  Future<void> _loadPendingOperations() async {
    try {
      final operationsJson = html.window.localStorage['kelivo_pending_operations'];
      if (operationsJson != null) {
        final operations = jsonDecode(operationsJson) as Map<String, dynamic>;
        operations.forEach((key, value) {
          _pendingOperations[key] = PendingOperation.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Failed to load pending operations: $e');
    }
  }
  
  /// 保存待处理操作
  Future<void> _savePendingOperations() async {
    try {
      final operations = <String, dynamic>{};
      _pendingOperations.forEach((key, operation) {
        operations[key] = operation.toJson();
      });
      html.window.localStorage['kelivo_pending_operations'] = jsonEncode(operations);
    } catch (e) {
      debugPrint('Failed to save pending operations: $e');
    }
  }
  
  /// 存储离线数据
  Future<void> storeOfflineData(String key, dynamic data) async {
    _offlineData[key] = data;
    await _saveOfflineData();
    
    final event = SyncEvent(
      type: SyncEventType.dataStored,
      data: {'key': key, 'data': data},
      timestamp: DateTime.now(),
    );
    
    _syncController.add(event);
  }
  
  /// 获取离线数据
  T? getOfflineData<T>(String key) {
    return _offlineData[key] as T?;
  }
  
  /// 删除离线数据
  Future<void> removeOfflineData(String key) async {
    _offlineData.remove(key);
    await _saveOfflineData();
  }
  
  /// 添加待处理操作
  Future<void> addPendingOperation({
    required String id,
    required String type,
    required Map<String, dynamic> data,
    int priority = 0,
    int maxRetries = 3,
  }) async {
    final operation = PendingOperation(
      id: id,
      type: type,
      data: data,
      priority: priority,
      maxRetries: maxRetries,
      createdAt: DateTime.now(),
    );
    
    _pendingOperations[id] = operation;
    await _savePendingOperations();
    
    final event = SyncEvent(
      type: SyncEventType.operationQueued,
      data: {'operation': operation.toJson()},
      timestamp: DateTime.now(),
    );
    
    _syncController.add(event);
    
    // 如果在线，立即尝试同步
    if (_isOnline && !_isSyncing) {
      _syncPendingOperations();
    }
  }
  
  /// 同步待处理操作
  Future<void> _syncPendingOperations() async {
    if (_isSyncing || !_isOnline || _pendingOperations.isEmpty) return;
    
    _isSyncing = true;
    
    final event = SyncEvent(
      type: SyncEventType.syncStarted,
      timestamp: DateTime.now(),
    );
    _syncController.add(event);
    
    try {
      // 按优先级排序操作
      final sortedOperations = _pendingOperations.values.toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      
      final completedOperations = <String>[];
      final failedOperations = <String>[];
      
      for (final operation in sortedOperations) {
        try {
          final success = await _executeOperation(operation);
          if (success) {
            completedOperations.add(operation.id);
          } else {
            operation.retryCount++;
            if (operation.retryCount >= operation.maxRetries) {
              failedOperations.add(operation.id);
            }
          }
        } catch (e) {
          debugPrint('Failed to execute operation ${operation.id}: $e');
          operation.retryCount++;
          if (operation.retryCount >= operation.maxRetries) {
            failedOperations.add(operation.id);
          }
        }
      }
      
      // 移除已完成的操作
      for (final id in completedOperations) {
        _pendingOperations.remove(id);
      }
      
      // 移除失败次数过多的操作
      for (final id in failedOperations) {
        _pendingOperations.remove(id);
      }
      
      await _savePendingOperations();
      
      _lastSyncTime = DateTime.now();
      html.window.localStorage['kelivo_last_sync_time'] = _lastSyncTime!.millisecondsSinceEpoch.toString();
      
      final syncCompleteEvent = SyncEvent(
        type: SyncEventType.syncCompleted,
        data: {
          'completed': completedOperations.length,
          'failed': failedOperations.length,
          'remaining': _pendingOperations.length,
        },
        timestamp: DateTime.now(),
      );
      
      _syncController.add(syncCompleteEvent);
      
    } catch (e) {
      debugPrint('Sync failed: $e');
      
      final syncFailedEvent = SyncEvent(
        type: SyncEventType.syncFailed,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
      
      _syncController.add(syncFailedEvent);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// 执行单个操作
  Future<bool> _executeOperation(PendingOperation operation) async {
    // 这里应该根据操作类型执行相应的网络请求
    // 目前返回模拟结果
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 模拟 80% 的成功率
    return DateTime.now().millisecond % 10 < 8;
  }
  
  /// 手动触发同步
  Future<void> forceSync() async {
    if (_isOnline) {
      await _syncPendingOperations();
    }
  }
  
  /// 清除所有离线数据
  Future<void> clearOfflineData() async {
    _offlineData.clear();
    _pendingOperations.clear();
    
    html.window.localStorage.remove('kelivo_offline_data');
    html.window.localStorage.remove('kelivo_pending_operations');
    
    final event = SyncEvent(
      type: SyncEventType.dataCleared,
      timestamp: DateTime.now(),
    );
    
    _syncController.add(event);
  }
  
  /// 获取同步状态
  SyncStatus get syncStatus {
    return SyncStatus(
      isOnline: _isOnline,
      isSyncing: _isSyncing,
      pendingOperationsCount: _pendingOperations.length,
      lastSyncTime: _getLastSyncTime(),
    );
  }
  
  DateTime? _getLastSyncTime() {
    final timestamp = html.window.localStorage['kelivo_last_sync_time'];
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    }
    return null;
  }
  
  /// 销毁管理器
  void dispose() {
    _syncTimer?.cancel();
    _syncController.close();
    super.dispose();
    debugPrint('Simple Offline Sync Manager disposed');
  }
}

/// 同步事件
class SyncEvent {
  final SyncEventType type;
  final Map<String, dynamic>? data;
  final String? error;
  final DateTime timestamp;
  
  SyncEvent({
    required this.type,
    this.data,
    this.error,
    required this.timestamp,
  });
}

/// 同步事件类型
enum SyncEventType {
  online,
  offline,
  dataStored,
  operationQueued,
  syncStarted,
  syncCompleted,
  syncFailed,
  dataCleared,
}

/// 待处理操作
class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final int priority;
  final int maxRetries;
  final DateTime createdAt;
  int retryCount;
  
  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    this.priority = 0,
    this.maxRetries = 3,
    required this.createdAt,
    this.retryCount = 0,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'priority': priority,
      'maxRetries': maxRetries,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }
  
  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      priority: json['priority'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// 同步状态
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingOperationsCount;
  final DateTime? lastSyncTime;
  
  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingOperationsCount,
    this.lastSyncTime,
  });
}