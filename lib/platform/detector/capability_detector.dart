import '../detector/platform_detector.dart';

/// 设备能力检测器
/// 检测设备的具体能力和特性
class CapabilityDetector {
  static Map<String, dynamic>? _cachedCapabilities;

  /// 获取所有设备能力信息
  static Map<String, dynamic> getAllCapabilities() {
    _cachedCapabilities ??= _detectAllCapabilities();
    return Map.from(_cachedCapabilities!);
  }

  /// 检查网络连接能力
  static Future<bool> hasNetworkConnection() async {
    // TODO: 实现网络连接检测
    // 可以使用connectivity_plus包或Web API
    return true;
  }

  /// 检查摄像头权限和可用性
  static Future<bool> isCameraAvailable() async {
    if (!PlatformDetector.hasCapability(PlatformCapability.cameraAccess)) {
      return false;
    }
    // TODO: 实现摄像头可用性检测
    return true;
  }

  /// 检查麦克风权限和可用性
  static Future<bool> isMicrophoneAvailable() async {
    // TODO: 实现麦克风可用性检测
    return PlatformDetector.isNativeMobile || PlatformDetector.isWeb;
  }

  /// 检查地理位置权限
  static Future<bool> isLocationAvailable() async {
    if (!PlatformDetector.hasCapability(PlatformCapability.geolocationAccess)) {
      return false;
    }
    // TODO: 实现地理位置权限检测
    return true;
  }

  /// 检查推送通知权限
  static Future<bool> isPushNotificationAvailable() async {
    if (!PlatformDetector.hasCapability(PlatformCapability.pushNotifications)) {
      return false;
    }
    // TODO: 实现推送通知权限检测
    return true;
  }

  /// 检查文件访问权限
  static Future<bool> isFileAccessAvailable() async {
    return PlatformDetector.hasCapability(PlatformCapability.fileSystemAccess);
  }

  /// 检查剪贴板访问权限
  static Future<bool> isClipboardAvailable() async {
    return PlatformDetector.hasCapability(PlatformCapability.clipboardAccess);
  }

  /// 检查设备是否支持触摸
  static bool hasTouchSupport() {
    return PlatformDetector.hasCapability(PlatformCapability.touchInput);
  }

  /// 检查设备是否有物理键盘
  static bool hasPhysicalKeyboard() {
    return PlatformDetector.isDesktop;
  }

  /// 检查设备是否支持鼠标输入
  static bool hasMouseSupport() {
    return PlatformDetector.hasCapability(PlatformCapability.mouseInput);
  }

  /// 检查设备是否支持多窗口
  static bool hasMultiWindowSupport() {
    return PlatformDetector.hasCapability(PlatformCapability.multiWindow);
  }

  /// 检查PWA安装状态（仅Web）
  static bool isPWAInstalled() {
    if (!PlatformDetector.isWeb) return false;
    // TODO: 实现PWA安装状态检测
    // 可以通过检查display-mode或navigator.standalone
    return false;
  }

  /// 检查是否在PWA模式下运行
  static bool isRunningInPWA() {
    if (!PlatformDetector.isWeb) return false;
    // TODO: 实现PWA运行状态检测
    return false;
  }

  /// 检查设备性能等级
  static DevicePerformance getDevicePerformance() {
    // TODO: 基于硬件信息或性能基准测试评估设备性能
    if (PlatformDetector.isDesktop) {
      return DevicePerformance.high;
    } else if (PlatformDetector.isTablet) {
      return DevicePerformance.medium;
    } else {
      return DevicePerformance.low;
    }
  }

  /// 检查设备内存状况
  static MemoryStatus getMemoryStatus() {
    // TODO: 实现内存状况检测
    return MemoryStatus.sufficient;
  }

  /// 检查电池状况（移动设备）
  static Future<BatteryStatus> getBatteryStatus() async {
    if (!PlatformDetector.isMobile) {
      return BatteryStatus.notApplicable;
    }
    // TODO: 实现电池状况检测
    return BatteryStatus.sufficient;
  }

  /// 重置能力检测缓存
  static void resetCache() {
    _cachedCapabilities = null;
  }

  // 私有方法：检测所有能力
  static Map<String, dynamic> _detectAllCapabilities() {
    return {
      'platform_type': PlatformDetector.platformName,
      'is_mobile': PlatformDetector.isMobile,
      'is_tablet': PlatformDetector.isTablet,
      'is_desktop': PlatformDetector.isDesktop,
      'is_web': PlatformDetector.isWeb,
      'is_native_mobile': PlatformDetector.isNativeMobile,
      'is_native_desktop': PlatformDetector.isNativeDesktop,
      'has_touch_support': hasTouchSupport(),
      'has_mouse_support': hasMouseSupport(),
      'has_physical_keyboard': hasPhysicalKeyboard(),
      'has_multi_window_support': hasMultiWindowSupport(),
      'device_performance': getDevicePerformance().name,
      'memory_status': getMemoryStatus().name,
      'pwa_installed': isPWAInstalled(),
      'running_in_pwa': isRunningInPWA(),
      'platform_capabilities': PlatformDetector.getAllCapabilities(),
    };
  }

  /// 打印设备能力信息（调试用）
  static void printCapabilityInfo() {
    final capabilities = getAllCapabilities();
    print('=== Device Capabilities ===');
    capabilities.forEach((key, value) {
      if (key != 'platform_capabilities') {
        print('$key: $value');
      }
    });
    print('===========================');
  }
}

/// 设备性能等级枚举
enum DevicePerformance {
  low, // 低性能设备
  medium, // 中等性能设备
  high, // 高性能设备
}

/// 内存状况枚举
enum MemoryStatus {
  low, // 内存不足
  sufficient, // 内存充足
  abundant, // 内存充裕
}

/// 电池状况枚举
enum BatteryStatus {
  critical, // 电量严重不足
  low, // 电量不足
  sufficient, // 电量充足
  charging, // 正在充电
  notApplicable, // 不适用（如桌面设备）
}
