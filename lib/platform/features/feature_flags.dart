import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 功能标志管理系统
/// 根据平台和环境动态控制功能开启
class FeatureFlags {
  // PWA相关功能标志
  static const bool isPWAEnabled = kIsWeb;
  static const bool isDesktopLayoutEnabled = true;
  static const bool isOfflineEnabled = kIsWeb;
  static const bool isPushNotificationEnabled = kIsWeb;
  static const bool isInstallPromptEnabled = kIsWeb;

  // 响应式布局标志
  static const bool isResponsiveLayoutEnabled = true;
  static const bool isAdaptiveNavigationEnabled = true;

  // 性能相关标志
  static const bool isPerformanceMonitoringEnabled = kDebugMode;
  static const bool isAnimationOptimizationEnabled = kIsWeb;

  // 开发调试标志
  static const bool isDebugModeEnabled = kDebugMode;
  static const bool isLoggingEnabled = kDebugMode;

  /// 动态功能检查

  /// 检查是否应该显示PWA安装提示
  static bool get shouldShowInstallPrompt {
    if (!isPWAEnabled || !isInstallPromptEnabled) return false;
    // 在Web环境下进一步检查是否已安装
    return kIsWeb && !_isAppInstalled();
  }

  /// 检查是否应该使用响应式布局
  static bool shouldUseResponsiveLayout(double screenWidth) {
    return isResponsiveLayoutEnabled && screenWidth > 768;
  }

  /// 检查是否应该启用桌面布局
  static bool shouldUseDesktopLayout(double screenWidth) {
    return isDesktopLayoutEnabled && isPWAEnabled && screenWidth >= 1200;
  }

  /// 检查是否应该启用侧边栏导航
  static bool shouldUseSidebarNavigation(double screenWidth) {
    return isAdaptiveNavigationEnabled && screenWidth >= 900;
  }

  /// 检查是否应该启用离线功能
  static bool get shouldEnableOfflineFeatures {
    return isOfflineEnabled && isPWAEnabled;
  }

  /// 检查是否应该启用推送通知
  static bool get shouldEnablePushNotifications {
    return isPushNotificationEnabled &&
        isPWAEnabled &&
        _isNotificationSupported();
  }

  // 私有辅助方法
  static bool _isAppInstalled() {
    // TODO: 实现PWA安装状态检测
    // 可以通过检查display-mode或使用Web API
    return false;
  }

  static bool _isNotificationSupported() {
    // TODO: 检查浏览器是否支持推送通知
    return kIsWeb;
  }

  /// 获取平台特定的功能配置
  static Map<String, bool> getPlatformFeatures() {
    return {
      'pwa_enabled': isPWAEnabled,
      'desktop_layout': isDesktopLayoutEnabled,
      'offline_enabled': isOfflineEnabled,
      'push_notifications': isPushNotificationEnabled,
      'install_prompt': isInstallPromptEnabled,
      'responsive_layout': isResponsiveLayoutEnabled,
      'adaptive_navigation': isAdaptiveNavigationEnabled,
      'performance_monitoring': isPerformanceMonitoringEnabled,
      'animation_optimization': isAnimationOptimizationEnabled,
      'debug_mode': isDebugModeEnabled,
      'logging': isLoggingEnabled,
    };
  }

  /// 打印当前功能配置（调试用）
  static void printFeatureStatus() {
    if (!kDebugMode) return;

    print('=== Feature Flags Status ===');
    getPlatformFeatures().forEach((feature, enabled) {
      print('$feature: ${enabled ? "✓" : "✗"}');
    });
    print('===========================');
  }
}
