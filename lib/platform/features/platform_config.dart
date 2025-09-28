/// 平台配置管理
/// 统一管理不同平台的配置信息
class PlatformConfig {
  // 布局配置
  static const Map<String, double> layoutConfig = {
    'mobile_max_width': 600.0,
    'tablet_max_width': 900.0,
    'desktop_min_width': 1200.0,
    'sidebar_min_width': 900.0,
    'content_max_width': 1600.0,
  };

  // PWA配置
  static const Map<String, dynamic> pwaConfig = {
    'app_name': 'Kelivo PWA',
    'short_name': 'Kelivo',
    'description': 'AI Chat Client with PWA Support',
    'theme_color': '#6366f1',
    'background_color': '#ffffff',
    'start_url': '/',
    'display': 'standalone',
    'orientation': 'any',
  };

  // 缓存策略配置
  static const Map<String, dynamic> cacheConfig = {
    'cache_version': 'v1.0.12',
    'static_cache_name': 'kelivo-static-v1',
    'dynamic_cache_name': 'kelivo-dynamic-v1',
    'cache_timeout_hours': 24,
    'max_cache_size_mb': 50,
  };

  // 性能配置
  static const Map<String, dynamic> performanceConfig = {
    'lazy_loading_enabled': true,
    'image_optimization_enabled': true,
    'code_splitting_enabled': true,
    'preload_critical_resources': true,
    'debounce_ms': 300,
    'throttle_ms': 100,
  };

  // 通知配置
  static const Map<String, dynamic> notificationConfig = {
    'vapid_public_key': '', // TODO: 配置VAPID公钥
    'notification_icon': '/icons/icon-192x192.png',
    'notification_badge': '/icons/badge-72x72.png',
    'default_notification_title': 'Kelivo',
    'notification_timeout_ms': 5000,
  };

  // API配置
  static const Map<String, dynamic> apiConfig = {
    'timeout_seconds': 30,
    'retry_attempts': 3,
    'retry_delay_ms': 1000,
    'offline_cache_enabled': true,
  };

  /// 根据平台获取特定配置
  static Map<String, dynamic> getConfigForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'web':
        return {
          ...pwaConfig,
          ...cacheConfig,
          ...performanceConfig,
          ...notificationConfig,
        };
      case 'mobile':
        return {
          ...performanceConfig,
          'offline_mode_enabled': false,
          'push_notifications_enabled': true,
        };
      case 'desktop':
        return {
          ...performanceConfig,
          'window_controls_enabled': true,
          'menu_bar_enabled': true,
        };
      default:
        return {};
    }
  }

  /// 获取布局断点配置
  static double getBreakpoint(String breakpoint) {
    return layoutConfig[breakpoint] ?? 0.0;
  }

  /// 获取缓存配置
  static String getCacheName(String type) {
    return cacheConfig['${type}_cache_name']?.toString() ?? '';
  }

  /// 检查功能是否在当前平台启用
  static bool isFeatureEnabledForPlatform(String feature, String platform) {
    final platformConfig = getConfigForPlatform(platform);
    return platformConfig[feature] == true;
  }
}
