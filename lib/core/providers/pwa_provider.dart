import 'package:flutter/foundation.dart';
import '../services/pwa_service.dart';

/// PWA状态管理Provider
class PWAProvider extends ChangeNotifier {
  final PWAService _pwaService = PWAService.instance;
  
  bool _isOnline = true;
  bool _isInstalled = false;
  bool _updateAvailable = false;
  bool _showInstallPrompt = false;
  bool _showOfflineMessage = false;
  bool _notificationPermissionGranted = false;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isInstalled => _isInstalled;
  bool get updateAvailable => _updateAvailable;
  bool get showInstallPrompt => _showInstallPrompt;
  bool get showOfflineMessage => _showOfflineMessage;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  
  /// 初始化PWA Provider
  Future<void> initialize() async {
    if (!kIsWeb) return;
    
    try {
      // 初始化PWA服务
      await _pwaService.initialize();
      
      // 监听网络状态变化
      _pwaService.networkStatusStream.listen((isOnline) {
        _isOnline = isOnline;
        _showOfflineMessage = !isOnline;
        notifyListeners();
        
        if (!isOnline) {
          _showOfflineNotification();
        }
      });
      
      // 监听安装状态变化
      _pwaService.installStatusStream.listen((isInstalled) {
        _isInstalled = isInstalled;
        _showInstallPrompt = !isInstalled && _shouldShowInstallPrompt();
        notifyListeners();
      });
      
      // 监听更新状态变化
      _pwaService.updateAvailableStream.listen((updateAvailable) {
        _updateAvailable = updateAvailable;
        notifyListeners();
        
        if (updateAvailable) {
          _showUpdateNotification();
        }
      });
      
      // 初始化状态
      _isOnline = _pwaService.isOnline;
      _isInstalled = _pwaService.isInstalled;
      _updateAvailable = _pwaService.updateAvailable;
      _showInstallPrompt = !_isInstalled && _shouldShowInstallPrompt();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('PWA Provider initialization error: $e');
    }
  }
  
  /// 判断是否应该显示安装提示
  bool _shouldShowInstallPrompt() {
    // 这里可以添加更复杂的逻辑，比如：
    // - 用户访问次数
    // - 用户使用时长
    // - 用户是否之前拒绝过安装
    return true;
  }
  
  /// 显示离线通知
  void _showOfflineNotification() {
    _pwaService.showNotification(
      title: 'Kelivo',
      body: '当前处于离线状态，部分功能可能受限',
      icon: '/icons/Icon-192.png',
      tag: 'offline-notification',
    );
  }
  
  /// 显示更新通知
  void _showUpdateNotification() {
    _pwaService.showNotification(
      title: 'Kelivo 更新',
      body: '发现新版本，点击刷新应用',
      icon: '/icons/Icon-192.png',
      tag: 'update-notification',
      data: {'action': 'update'},
    );
  }
  
  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      final granted = await _pwaService.requestNotificationPermission();
      _notificationPermissionGranted = granted;
      notifyListeners();
      return granted;
    } catch (e) {
      debugPrint('Request notification permission error: $e');
      return false;
    }
  }
  
  /// 显示自定义通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    await _pwaService.showNotification(
      title: title,
      body: body,
      icon: icon,
      tag: tag,
      data: data,
    );
  }
  
  /// 缓存数据
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await _pwaService.cacheData(key, data);
  }
  
  /// 获取缓存数据
  Future<Map<String, dynamic>?> getCachedData(String key, {Duration? maxAge}) async {
    return await _pwaService.getCachedData(key, maxAge: maxAge);
  }
  
  /// 清除缓存
  Future<void> clearCache(String key) async {
    await _pwaService.clearCache(key);
  }
  
  /// 清除所有缓存
  Future<void> clearAllCache() async {
    await _pwaService.clearAllCache();
  }
  
  /// 保存离线操作
  Future<void> saveOfflineAction({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _pwaService.saveOfflineAction(type: type, data: data);
  }
  
  /// 刷新应用
  Future<void> refreshApp() async {
    await _pwaService.forceRefresh();
  }
  
  /// 隐藏安装提示
  void hideInstallPrompt() {
    _showInstallPrompt = false;
    notifyListeners();
  }
  
  /// 隐藏离线消息
  void hideOfflineMessage() {
    _showOfflineMessage = false;
    notifyListeners();
  }
  
  /// 手动触发安装提示显示
  void triggerInstallPrompt() {
    if (!_isInstalled) {
      _showInstallPrompt = true;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _pwaService.dispose();
    super.dispose();
  }
}