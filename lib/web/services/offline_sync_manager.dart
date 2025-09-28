import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import '../../core/models/conversation.dart';
import '../../core/models/chat_message.dart';
import '../../platform/detector/platform_detector.dart';

/// 智能离线模式和数据同步管理器
/// 支持离线数据存储、智能同步策略和冲突解决
class OfflineSyncManager extends ChangeNotifier {
  static OfflineSyncManager? _instance;
  static OfflineSyncManager get instance => _instance ??= OfflineSyncManager._();

  OfflineSyncManager._();

  // 数据库相关
  dynamic _database;
  static const String _dbName = 'kelivo_offline_db';
  static const int _dbVersion = 1;

  // 同步状态
  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final StreamController<SyncEvent> _syncController = StreamController.broadcast();

  // 离线队列
  final List<OfflineOperation> _pendingOperations = [];
  final Map<String, ConversationCache> _conversationCache = {};
  final Map<String, MessageCache> _messageCache = {};

  // 配置
  late OfflineSyncConfig _config;
  Timer? _syncTimer;
  Timer? _cleanupTimer;

  /// 同步事件流
  Stream<SyncEvent> get syncStream => _syncController.stream;

  /// 是否在线
  bool get isOnline => _isOnline;

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 最后同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 待同步操作数量
  int get pendingOperationsCount => _pendingOperations.length;

  /// 初始化离线同步管理器
  Future<void> initialize({OfflineSyncConfig? config}) async {
    if (!PlatformDetector.isWeb) return;

    _config = config ?? OfflineSyncConfig.defaultConfig();

    try {
      // 初始化IndexedDB
      await _initializeDatabase();

      // 监听网络状态变化
      _setupNetworkListeners();

      // 恢复离线数据
      await _restoreOfflineData();

      // 启动定时同步
      _startPeriodicSync();

      // 启动清理任务
      _startPeriodicCleanup();

      print('Offline sync manager initialized');
      _syncController.add(SyncEvent.initialized());
    } catch (e) {
      print('Failed to initialize offline sync manager: $e');
      rethrow;
    }
  }

  /// 缓存会话数据
  Future<void> cacheConversation(Conversation conversation) async {
    try {
      final cache = ConversationCache(
        conversation: conversation,
        cachedAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      _conversationCache[conversation.id] = cache;
      await _saveConversationToDb(cache);

      _syncController.add(SyncEvent.conversationCached(conversation.id));
    } catch (e) {
      print('Failed to cache conversation: $e');
    }
  }

  /// 缓存消息数据
  Future<void> cacheMessage(ChatMessage message) async {
    try {
      final cache = MessageCache(
        message: message,
        cachedAt: DateTime.now(),
        syncStatus: _isOnline ? SyncStatus.synced : SyncStatus.pending,
      );

      _messageCache[message.id] = cache;
      await _saveMessageToDb(cache);

      if (!_isOnline) {
        _addPendingOperation(OfflineOperation.createMessage(message));
      }

      _syncController.add(SyncEvent.messageCached(message.id));
    } catch (e) {
      print('Failed to cache message: $e');
    }
  }

  /// 获取缓存的会话
  Future<Conversation?> getCachedConversation(String conversationId) async {
    try {
      // 先从内存缓存获取
      final memoryCache = _conversationCache[conversationId];
      if (memoryCache != null) {
        memoryCache.lastAccessed = DateTime.now();
        return memoryCache.conversation;
      }

      // 从数据库获取
      final dbCache = await _getConversationFromDb(conversationId);
      if (dbCache != null) {
        _conversationCache[conversationId] = dbCache;
        dbCache.lastAccessed = DateTime.now();
        return dbCache.conversation;
      }

      return null;
    } catch (e) {
      print('Failed to get cached conversation: $e');
      return null;
    }
  }

  /// 获取缓存的消息列表
  Future<List<ChatMessage>> getCachedMessages(String conversationId) async {
    try {
      final messages = <ChatMessage>[];

      // 从内存缓存获取
      for (final cache in _messageCache.values) {
        if (cache.message.conversationId == conversationId) {
          messages.add(cache.message);
        }
      }

      // 如果内存中没有，从数据库获取
      if (messages.isEmpty) {
        final dbMessages = await _getMessagesFromDb(conversationId);
        messages.addAll(dbMessages);

        // 更新内存缓存
        for (final message in dbMessages) {
          _messageCache[message.id] = MessageCache(
            message: message,
            cachedAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
          );
        }
      }

      // 按时间排序
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      print('Failed to get cached messages: $e');
      return [];
    }
  }

  /// 添加离线操作
  Future<void> addOfflineOperation(OfflineOperation operation) async {
    _pendingOperations.add(operation);
    await _savePendingOperations();
    _syncController.add(SyncEvent.operationQueued(operation));

    // 如果在线，立即尝试同步
    if (_isOnline && !_isSyncing) {
      _performSync();
    }
  }

  /// 执行同步
  Future<void> performSync({bool force = false}) async {
    if (_isSyncing && !force) return;

    _isSyncing = true;
    _syncController.add(SyncEvent.syncStarted());

    try {
      // 同步待处理的操作
      await _syncPendingOperations();

      // 同步服务器数据
      await _syncFromServer();

      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();

      _syncController.add(SyncEvent.syncCompleted(_lastSyncTime!));
    } catch (e) {
      print('Sync failed: $e');
      _syncController.add(SyncEvent.syncFailed(e.toString()));
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 清理过期缓存
  Future<void> cleanupExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiredConversations = <String>[];
      final expiredMessages = <String>[];

      // 清理过期会话缓存
      for (final entry in _conversationCache.entries) {
        final cache = entry.value;
        final age = now.difference(cache.lastAccessed);
        
        if (age.inDays > _config.conversationCacheExpireDays) {
          expiredConversations.add(entry.key);
        }
      }

      // 清理过期消息缓存
      for (final entry in _messageCache.entries) {
        final cache = entry.value;
        final age = now.difference(cache.cachedAt);
        
        if (age.inDays > _config.messageCacheExpireDays) {
          expiredMessages.add(entry.key);
        }
      }

      // 从内存和数据库中删除
      for (final id in expiredConversations) {
        _conversationCache.remove(id);
        await _deleteConversationFromDb(id);
      }

      for (final id in expiredMessages) {
        _messageCache.remove(id);
        await _deleteMessageFromDb(id);
      }

      if (expiredConversations.isNotEmpty || expiredMessages.isNotEmpty) {
        _syncController.add(SyncEvent.cacheCleanup(
          expiredConversations.length + expiredMessages.length,
        ));
      }
    } catch (e) {
      print('Failed to cleanup expired cache: $e');
    }
  }

  /// 获取缓存统计信息
  CacheStatistics getCacheStatistics() {
    final now = DateTime.now();
    int totalSize = 0;
    int recentlyAccessed = 0;

    for (final cache in _conversationCache.values) {
      totalSize += _estimateConversationSize(cache.conversation);
      if (now.difference(cache.lastAccessed).inHours < 24) {
        recentlyAccessed++;
      }
    }

    for (final cache in _messageCache.values) {
      totalSize += _estimateMessageSize(cache.message);
    }

    return CacheStatistics(
      totalConversations: _conversationCache.length,
      totalMessages: _messageCache.length,
      estimatedSizeBytes: totalSize,
      recentlyAccessedConversations: recentlyAccessed,
      pendingOperations: _pendingOperations.length,
      lastSyncTime: _lastSyncTime,
    );
  }

  // 私有方法实现
  Future<void> _initializeDatabase() async {
    try {
      _database = await html.window.indexedDB!.open(
        _dbName,
        version: _dbVersion,
        onUpgradeNeeded: (event) {
          final db = event.target!.result;
          
          // 创建会话存储
          if (!db.objectStoreNames!.contains('conversations')) {
            db.createObjectStore('conversations', keyPath: 'id');
          }

          // 创建消息存储
          if (!db.objectStoreNames!.contains('messages')) {
            final messageStore = db.createObjectStore('messages', keyPath: 'id');
            messageStore.createIndex('conversationId', 'conversationId', unique: false);
            messageStore.createIndex('timestamp', 'timestamp', unique: false);
          }

          // 创建操作队列存储
          if (!db.objectStoreNames!.contains('pending_operations')) {
            db.createObjectStore('pending_operations', keyPath: 'id');
          }

          // 创建元数据存储
          if (!db.objectStoreNames!.contains('metadata')) {
            db.createObjectStore('metadata', keyPath: 'key');
          }
        },
      );
    } catch (e) {
      print('Failed to initialize database: $e');
      rethrow;
    }
  }

  void _setupNetworkListeners() {
    // 监听在线/离线状态
    html.window.onOnline.listen((_) {
      _isOnline = true;
      _syncController.add(SyncEvent.networkStatusChanged(true));
      notifyListeners();
      
      // 网络恢复时立即同步
      _performSync();
    });

    html.window.onOffline.listen((_) {
      _isOnline = false;
      _syncController.add(SyncEvent.networkStatusChanged(false));
      notifyListeners();
    });

    // 初始网络状态
    _isOnline = html.window.navigator.onLine ?? true;
  }

  Future<void> _restoreOfflineData() async {
    try {
      // 恢复待处理操作
      await _loadPendingOperations();

      // 恢复最后同步时间
      await _loadLastSyncTime();

      // 预加载最近的会话和消息到内存
      await _preloadRecentData();
    } catch (e) {
      print('Failed to restore offline data: $e');
    }
  }

  void _startPeriodicSync() {
    if (_config.autoSyncEnabled) {
      _syncTimer = Timer.periodic(
        Duration(minutes: _config.syncIntervalMinutes),
        (_) {
          if (_isOnline && !_isSyncing) {
            _performSync();
          }
        },
      );
    }
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(
      Duration(hours: _config.cleanupIntervalHours),
      (_) => cleanupExpiredCache(),
    );
  }

  Future<void> _performSync() async {
    await performSync();
  }

  Future<void> _syncPendingOperations() async {
    final operations = List<OfflineOperation>.from(_pendingOperations);
    final completedOperations = <OfflineOperation>[];

    for (final operation in operations) {
      try {
        final success = await _executePendingOperation(operation);
        if (success) {
          completedOperations.add(operation);
        }
      } catch (e) {
        print('Failed to execute pending operation: $e');
        // 标记操作失败，但继续处理其他操作
        operation.retryCount++;
        if (operation.retryCount >= _config.maxRetryCount) {
          completedOperations.add(operation); // 放弃重试
        }
      }
    }

    // 移除已完成的操作
    for (final operation in completedOperations) {
      _pendingOperations.remove(operation);
    }

    if (completedOperations.isNotEmpty) {
      await _savePendingOperations();
    }
  }

  Future<bool> _executePendingOperation(OfflineOperation operation) async {
    // 这里应该调用实际的API来执行操作
    // 为了演示，我们模拟成功
    await Future.delayed(Duration(milliseconds: 100));
    
    switch (operation.type) {
      case OperationType.createMessage:
        // 发送消息到服务器
        return true;
      case OperationType.updateMessage:
        // 更新服务器上的消息
        return true;
      case OperationType.deleteMessage:
        // 从服务器删除消息
        return true;
      case OperationType.createConversation:
        // 在服务器创建会话
        return true;
      case OperationType.updateConversation:
        // 更新服务器上的会话
        return true;
    }
  }

  Future<void> _syncFromServer() async {
    // 这里应该从服务器获取最新数据
    // 为了演示，我们跳过实际的网络请求
    await Future.delayed(Duration(milliseconds: 200));
  }

  void _addPendingOperation(OfflineOperation operation) {
    _pendingOperations.add(operation);
    _savePendingOperations();
  }

  // 数据库操作方法
  Future<void> _saveConversationToDb(ConversationCache cache) async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('conversations', 'readwrite');
      final store = transaction.objectStore('conversations');
      
      await store.put({
        'id': cache.conversation.id,
        'data': cache.conversation.toJson(),
        'cachedAt': cache.cachedAt.toIso8601String(),
        'lastAccessed': cache.lastAccessed.toIso8601String(),
      });
    } catch (e) {
      print('Failed to save conversation to database: $e');
    }
  }

  Future<void> _saveMessageToDb(MessageCache cache) async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('messages', 'readwrite');
      final store = transaction.objectStore('messages');
      
      await store.put({
        'id': cache.message.id,
        'conversationId': cache.message.conversationId,
        'data': cache.message.toJson(),
        'cachedAt': cache.cachedAt.toIso8601String(),
        'syncStatus': cache.syncStatus.toString(),
        'timestamp': cache.message.timestamp.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Failed to save message to database: $e');
    }
  }

  Future<ConversationCache?> _getConversationFromDb(String conversationId) async {
    if (_database == null) return null;

    try {
      final transaction = _database!.transaction('conversations', 'readonly');
      final store = transaction.objectStore('conversations');
      final result = await store.getObject(conversationId);
      
      if (result != null) {
        final data = result as Map<String, dynamic>;
        return ConversationCache(
          conversation: Conversation.fromJson(data['data']),
          cachedAt: DateTime.parse(data['cachedAt']),
          lastAccessed: DateTime.parse(data['lastAccessed']),
        );
      }
    } catch (e) {
      print('Failed to get conversation from database: $e');
    }

    return null;
  }

  Future<List<ChatMessage>> _getMessagesFromDb(String conversationId) async {
    if (_database == null) return [];

    try {
      final transaction = _database!.transaction('messages', 'readonly');
      final store = transaction.objectStore('messages');
      final index = store.index('conversationId');
      final results = await index.getAll(conversationId);
      
      final messages = <ChatMessage>[];
      for (final result in results) {
        final data = result as Map<String, dynamic>;
        messages.add(ChatMessage.fromJson(data['data']));
      }
      
      return messages;
    } catch (e) {
      print('Failed to get messages from database: $e');
      return [];
    }
  }

  Future<void> _deleteConversationFromDb(String conversationId) async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('conversations', 'readwrite');
      final store = transaction.objectStore('conversations');
      await store.delete(conversationId);
    } catch (e) {
      print('Failed to delete conversation from database: $e');
    }
  }

  Future<void> _deleteMessageFromDb(String messageId) async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('messages', 'readwrite');
      final store = transaction.objectStore('messages');
      await store.delete(messageId);
    } catch (e) {
      print('Failed to delete message from database: $e');
    }
  }

  Future<void> _savePendingOperations() async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('pending_operations', 'readwrite');
      final store = transaction.objectStore('pending_operations');
      
      // 清空现有操作
      await store.clear();
      
      // 保存当前操作
      for (int i = 0; i < _pendingOperations.length; i++) {
        await store.put({
          'id': i,
          'data': _pendingOperations[i].toJson(),
        });
      }
    } catch (e) {
      print('Failed to save pending operations: $e');
    }
  }

  Future<void> _loadPendingOperations() async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('pending_operations', 'readonly');
      final store = transaction.objectStore('pending_operations');
      final results = await store.getAll();
      
      _pendingOperations.clear();
      for (final result in results) {
        final data = result as Map<String, dynamic>;
        _pendingOperations.add(OfflineOperation.fromJson(data['data']));
      }
    } catch (e) {
      print('Failed to load pending operations: $e');
    }
  }

  Future<void> _saveLastSyncTime() async {
    if (_database == null || _lastSyncTime == null) return;

    try {
      final transaction = _database!.transaction('metadata', 'readwrite');
      final store = transaction.objectStore('metadata');
      
      await store.put({
        'key': 'last_sync_time',
        'value': _lastSyncTime!.toIso8601String(),
      });
    } catch (e) {
      print('Failed to save last sync time: $e');
    }
  }

  Future<void> _loadLastSyncTime() async {
    if (_database == null) return;

    try {
      final transaction = _database!.transaction('metadata', 'readonly');
      final store = transaction.objectStore('metadata');
      final result = await store.getObject('last_sync_time');
      
      if (result != null) {
        final data = result as Map<String, dynamic>;
        _lastSyncTime = DateTime.parse(data['value']);
      }
    } catch (e) {
      print('Failed to load last sync time: $e');
    }
  }

  Future<void> _preloadRecentData() async {
    // 预加载最近访问的数据到内存缓存
    // 这里可以根据需要实现具体的预加载逻辑
  }

  int _estimateConversationSize(Conversation conversation) {
    // 估算会话数据大小（字节）
    return jsonEncode(conversation.toJson()).length;
  }

  int _estimateMessageSize(ChatMessage message) {
    // 估算消息数据大小（字节）
    return jsonEncode(message.toJson()).length;
  }

  /// 清理资源
  void dispose() {
    _syncTimer?.cancel();
    _cleanupTimer?.cancel();
    _syncController.close();
    _database?.close();
    super.dispose();
  }
}

/// 离线同步配置
class OfflineSyncConfig {
  final bool autoSyncEnabled;
  final int syncIntervalMinutes;
  final int cleanupIntervalHours;
  final int conversationCacheExpireDays;
  final int messageCacheExpireDays;
  final int maxRetryCount;
  final int maxCacheSize;

  const OfflineSyncConfig({
    this.autoSyncEnabled = true,
    this.syncIntervalMinutes = 5,
    this.cleanupIntervalHours = 24,
    this.conversationCacheExpireDays = 30,
    this.messageCacheExpireDays = 7,
    this.maxRetryCount = 3,
    this.maxCacheSize = 100 * 1024 * 1024, // 100MB
  });

  factory OfflineSyncConfig.defaultConfig() => const OfflineSyncConfig();

  factory OfflineSyncConfig.aggressive() => const OfflineSyncConfig(
    syncIntervalMinutes: 1,
    cleanupIntervalHours: 6,
    conversationCacheExpireDays: 7,
    messageCacheExpireDays: 3,
  );

  factory OfflineSyncConfig.conservative() => const OfflineSyncConfig(
    syncIntervalMinutes: 30,
    cleanupIntervalHours: 72,
    conversationCacheExpireDays: 90,
    messageCacheExpireDays: 30,
  );
}

/// 会话缓存
class ConversationCache {
  final Conversation conversation;
  final DateTime cachedAt;
  DateTime lastAccessed;

  ConversationCache({
    required this.conversation,
    required this.cachedAt,
    required this.lastAccessed,
  });
}

/// 消息缓存
class MessageCache {
  final ChatMessage message;
  final DateTime cachedAt;
  final SyncStatus syncStatus;

  MessageCache({
    required this.message,
    required this.cachedAt,
    required this.syncStatus,
  });
}

/// 离线操作
class OfflineOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory OfflineOperation.createMessage(ChatMessage message) {
    return OfflineOperation(
      id: 'create_message_${message.id}',
      type: OperationType.createMessage,
      data: message.toJson(),
      createdAt: DateTime.now(),
    );
  }

  factory OfflineOperation.updateMessage(ChatMessage message) {
    return OfflineOperation(
      id: 'update_message_${message.id}',
      type: OperationType.updateMessage,
      data: message.toJson(),
      createdAt: DateTime.now(),
    );
  }

  factory OfflineOperation.deleteMessage(String messageId) {
    return OfflineOperation(
      id: 'delete_message_$messageId',
      type: OperationType.deleteMessage,
      data: {'messageId': messageId},
      createdAt: DateTime.now(),
    );
  }

  factory OfflineOperation.createConversation(Conversation conversation) {
    return OfflineOperation(
      id: 'create_conversation_${conversation.id}',
      type: OperationType.createConversation,
      data: conversation.toJson(),
      createdAt: DateTime.now(),
    );
  }

  factory OfflineOperation.updateConversation(Conversation conversation) {
    return OfflineOperation(
      id: 'update_conversation_${conversation.id}',
      type: OperationType.updateConversation,
      data: conversation.toJson(),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: OperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// 操作类型
enum OperationType {
  createMessage,
  updateMessage,
  deleteMessage,
  createConversation,
  updateConversation,
}

/// 同步状态
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

/// 同步事件
class SyncEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();

  factory SyncEvent.initialized() {
    return SyncEvent(type: 'initialized', data: {});
  }

  factory SyncEvent.networkStatusChanged(bool isOnline) {
    return SyncEvent(
      type: 'network_status_changed',
      data: {'isOnline': isOnline},
    );
  }

  factory SyncEvent.conversationCached(String conversationId) {
    return SyncEvent(
      type: 'conversation_cached',
      data: {'conversationId': conversationId},
    );
  }

  factory SyncEvent.messageCached(String messageId) {
    return SyncEvent(
      type: 'message_cached',
      data: {'messageId': messageId},
    );
  }

  factory SyncEvent.operationQueued(OfflineOperation operation) {
    return SyncEvent(
      type: 'operation_queued',
      data: {'operationId': operation.id, 'operationType': operation.type.toString()},
    );
  }

  factory SyncEvent.syncStarted() {
    return SyncEvent(type: 'sync_started', data: {});
  }

  factory SyncEvent.syncCompleted(DateTime syncTime) {
    return SyncEvent(
      type: 'sync_completed',
      data: {'syncTime': syncTime.toIso8601String()},
    );
  }

  factory SyncEvent.syncFailed(String error) {
    return SyncEvent(
      type: 'sync_failed',
      data: {'error': error},
    );
  }

  factory SyncEvent.cacheCleanup(int itemsRemoved) {
    return SyncEvent(
      type: 'cache_cleanup',
      data: {'itemsRemoved': itemsRemoved},
    );
  }
}

/// 缓存统计信息
class CacheStatistics {
  final int totalConversations;
  final int totalMessages;
  final int estimatedSizeBytes;
  final int recentlyAccessedConversations;
  final int pendingOperations;
  final DateTime? lastSyncTime;

  const CacheStatistics({
    required this.totalConversations,
    required this.totalMessages,
    required this.estimatedSizeBytes,
    required this.recentlyAccessedConversations,
    required this.pendingOperations,
    this.lastSyncTime,
  });

  /// 获取格式化的缓存大小
  String get formattedSize {
    if (estimatedSizeBytes < 1024) {
      return '${estimatedSizeBytes}B';
    } else if (estimatedSizeBytes < 1024 * 1024) {
      return '${(estimatedSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(estimatedSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取最后同步时间的描述
  String get lastSyncDescription {
    if (lastSyncTime == null) return '从未同步';
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return '刚刚同步';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前同步';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前同步';
    } else {
      return '${difference.inDays}天前同步';
    }
  }
}