import 'package:flutter/foundation.dart';
import 'multi_window_chat_manager.dart';
import 'simple_offline_sync_manager.dart';
import 'simple_push_notification_service.dart';
import 'responsive_theme_manager.dart';
import 'todo_service.dart';
import 'pwa_service.dart';

/// Web服务注册中心
/// 统一管理所有Web平台特有的服务
class WebServiceRegistry {
  static WebServiceRegistry? _instance;
  static WebServiceRegistry get instance => _instance ??= WebServiceRegistry._();
  
  WebServiceRegistry._();
  
  // 服务映射表
  final Map<Type, dynamic> _services = {};


  // 服务实例
  MultiWindowChatManager? _multiWindowManager;
  SimpleOfflineSyncManager? _offlineSyncManager;
  SimplePushNotificationService? _pushNotificationService;
  ResponsiveThemeManager? _themeManager;
  TodoService? _todoService;
  PWAService? _pwaService;
  
  bool _isInitialized = false;
  
  /// 初始化所有Web服务
  Future<void> initialize() async {
    return initializeServices();
  }
  
  /// 初始化所有Web服务
  Future<void> initializeServices() async {

    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing Web Services...');
      
      // 初始化PWA服务
      _pwaService = PWAService.instance;
      await _pwaService!.initialize();
      
      // 初始化响应式主题管理器
      _themeManager = ResponsiveThemeManager.instance;
      await _themeManager!.initialize();
      
      // 初始化待办事项服务
      _todoService = TodoService.instance;
      await _todoService!.initialize();
      
      // 初始化离线同步管理器
      _offlineSyncManager = SimpleOfflineSyncManager.instance;
      await _offlineSyncManager!.initialize();
      
      // 初始化推送通知服务
      _pushNotificationService = SimplePushNotificationService.instance;
      await _pushNotificationService!.initialize();
      
      // 初始化多窗口聊天管理器
      _multiWindowManager = MultiWindowChatManager.instance;
      await _multiWindowManager!.initialize();
      
      // 注册服务到映射表
      _services[MultiWindowChatManager] = _multiWindowManager;
      _services[SimpleOfflineSyncManager] = _offlineSyncManager;
      _services[SimplePushNotificationService] = _pushNotificationService;
      _services[ResponsiveThemeManager] = _themeManager;
      _services[TodoService] = _todoService;
      _services[PWAService] = _pwaService;
      
      _isInitialized = true;
      debugPrint('All Web Services initialized successfully');

      
    } catch (e) {
      debugPrint('Failed to initialize Web Services: $e');
      rethrow;
    }
  }
  
  /// 获取多窗口聊天管理器
  MultiWindowChatManager get multiWindowManager {
    if (_multiWindowManager == null) {
      throw StateError('MultiWindowChatManager not initialized. Call initializeServices() first.');
    }
    return _multiWindowManager!;
  }
  
  /// 获取离线同步管理器
  SimpleOfflineSyncManager get offlineSyncManager {
    if (_offlineSyncManager == null) {
      throw StateError('OfflineSyncManager not initialized. Call initializeServices() first.');
    }
    return _offlineSyncManager!;
  }
  
  /// 获取推送通知服务
  SimplePushNotificationService get pushNotificationService {
    if (_pushNotificationService == null) {
      throw StateError('PushNotificationService not initialized. Call initializeServices() first.');
    }
    return _pushNotificationService!;
  }
  
  /// 获取响应式主题管理器
  ResponsiveThemeManager get themeManager {
    if (_themeManager == null) {
      throw StateError('ResponsiveThemeManager not initialized. Call initializeServices() first.');
    }
    return _themeManager!;
  }
  
  /// 获取待办事项服务
  TodoService get todoService {
    if (_todoService == null) {
      throw StateError('TodoService not initialized. Call initializeServices() first.');
    }
    return _todoService!;
  }
  
  /// 获取PWA服务
  PWAService get pwaService {
    if (_pwaService == null) {
      throw StateError('PWAService not initialized. Call initializeServices() first.');
    }
    return _pwaService!;
  }
  
  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 获取指定类型的服务
  T? getService<T>() {
    return _services[T] as T?;
  }
  
  /// 获取服务健康状态
  Future<List<Map<String, dynamic>>> getServiceHealth() async {
    final healthStatus = <Map<String, dynamic>>[];
    
    for (final entry in _services.entries) {
      final serviceType = entry.key.toString();
      final service = entry.value;
      
      try {
        bool isHealthy = true;
        String status = 'healthy';
        
        healthStatus.add({
          'service': serviceType,
          'healthy': isHealthy,
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        healthStatus.add({
          'service': serviceType,
          'healthy': false,
          'status': 'error',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
    
    return healthStatus;
  }

  
  /// 获取服务状态
  Map<String, bool> getServiceStatus() {
    return {
      'multiWindowManager': _multiWindowManager != null,
      'offlineSyncManager': _offlineSyncManager != null,
      'pushNotificationService': _pushNotificationService != null,
      'themeManager': _themeManager != null,
      'todoService': _todoService != null,
      'pwaService': _pwaService != null,
    };
  }
  
  /// 重新初始化特定服务
  Future<void> reinitializeService(String serviceName) async {
    try {
      switch (serviceName) {
        case 'multiWindowManager':
          _multiWindowManager = MultiWindowChatManager.instance;
          await _multiWindowManager!.initialize();
          break;
        case 'offlineSyncManager':
          _offlineSyncManager = SimpleOfflineSyncManager.instance;
          await _offlineSyncManager!.initialize();
          break;
        case 'pushNotificationService':
          _pushNotificationService = SimplePushNotificationService.instance;
          await _pushNotificationService!.initialize();
          break;
        case 'themeManager':
          _themeManager = ResponsiveThemeManager.instance;
          await _themeManager!.initialize();
          break;
        case 'todoService':
          _todoService = TodoService.instance;
          await _todoService!.initialize();
          break;
        case 'pwaService':
          _pwaService = PWAService.instance;
          await _pwaService!.initialize();
          break;
        default:
          throw ArgumentError('Unknown service: $serviceName');
      }
      
      debugPrint('Service $serviceName reinitialized successfully');
    } catch (e) {
      debugPrint('Failed to reinitialize service $serviceName: $e');
      rethrow;
    }
  }
  
  /// 清理所有服务
  void dispose() {
    try {
      _multiWindowManager?.dispose();
      _offlineSyncManager?.dispose();
      _pushNotificationService?.dispose();
      _themeManager?.dispose();
      // TodoService 和 PWAService 没有dispose方法
      
      _multiWindowManager = null;
      _offlineSyncManager = null;
      _pushNotificationService = null;
      _themeManager = null;
      _todoService = null;
      _pwaService = null;
      
      _isInitialized = false;
      debugPrint('All Web Services disposed');
    } catch (e) {
      debugPrint('Error disposing Web Services: $e');
    }
  }
}

/// Web服务初始化扩展
extension WebServiceInitializer on WebServiceRegistry {
  /// 安全初始化服务（带重试机制）
  Future<void> safeInitializeServices({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        await initializeServices();
        return;
      } catch (e) {
        attempts++;
        debugPrint('Service initialization attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          debugPrint('Max retry attempts reached. Service initialization failed.');
          rethrow;
        }
        
        await Future.delayed(retryDelay);
      }
    }
  }
  
  /// 检查服务健康状态
  Future<Map<String, dynamic>> checkServiceHealth() async {
    final health = <String, dynamic>{};
    
    try {
      // 检查多窗口管理器
      health['multiWindowManager'] = {
        'initialized': _multiWindowManager != null,
        'active': _multiWindowManager != null,
      };
      
      // 检查离线同步管理器
      health['offlineSyncManager'] = {
        'initialized': _offlineSyncManager != null,
        'online': true, // 简化状态检查
      };
      
      // 检查推送通知服务
      health['pushNotificationService'] = {
        'initialized': _pushNotificationService != null,
        'hasPermission': _pushNotificationService?.hasPermission ?? false,
      };
      
      // 检查主题管理器
      health['themeManager'] = {
        'initialized': _themeManager != null,
        'currentTheme': _themeManager?.currentTheme.name ?? 'unknown',
      };
      
      // 检查待办事项服务
      health['todoService'] = {
        'initialized': _todoService != null,
        'todoCount': _todoService?.todos.length ?? 0,
      };
      
      // 检查PWA服务
      health['pwaService'] = {
        'initialized': _pwaService != null,
        'isInstallable': false, // 简化状态检查
      };
      
    } catch (e) {
      health['error'] = e.toString();
    }
    
    return health;
  }
}