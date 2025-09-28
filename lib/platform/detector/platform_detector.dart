import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../../shared/responsive/breakpoints.dart'
    show ScreenType, screenTypeForWidth;

/// 平台类型枚举
enum PlatformType {
  /// 移动端 - Android
  mobileAndroid,

  /// 移动端 - iOS
  mobileIOS,

  /// Web - 移动浏览器
  webMobile,

  /// Web - 平板浏览器
  webTablet,

  /// Web - 桌面浏览器
  webDesktop,

  /// 桌面应用 - Windows
  desktopWindows,

  /// 桌面应用 - macOS
  desktopMacOS,

  /// 桌面应用 - Linux
  desktopLinux,

  /// 未知平台
  unknown,
}

/// 平台能力枚举
enum PlatformCapability {
  /// PWA功能支持
  pwaSupport,

  /// 推送通知支持
  pushNotifications,

  /// 离线存储支持
  offlineStorage,

  /// 文件系统访问
  fileSystemAccess,

  /// 摄像头访问
  cameraAccess,

  /// 地理位置访问
  geolocationAccess,

  /// 触摸支持
  touchInput,

  /// 键盘支持
  keyboardInput,

  /// 鼠标支持
  mouseInput,

  /// 多窗口支持
  multiWindow,

  /// 系统通知支持
  systemNotifications,

  /// 剪贴板访问
  clipboardAccess,
}

/// 平台检测器
/// 提供统一的平台检测和能力判断
class PlatformDetector {
  static PlatformType? _cachedPlatformType;
  static Map<PlatformCapability, bool>? _cachedCapabilities;

  /// 获取当前平台类型
  static PlatformType get currentPlatform {
    _cachedPlatformType ??= _detectPlatformType();
    return _cachedPlatformType!;
  }

  /// 获取平台名称
  static String get platformName {
    switch (currentPlatform) {
      case PlatformType.mobileAndroid:
        return 'Android';
      case PlatformType.mobileIOS:
        return 'iOS';
      case PlatformType.webMobile:
        return 'Web Mobile';
      case PlatformType.webTablet:
        return 'Web Tablet';
      case PlatformType.webDesktop:
        return 'Web Desktop';
      case PlatformType.desktopWindows:
        return 'Windows';
      case PlatformType.desktopMacOS:
        return 'macOS';
      case PlatformType.desktopLinux:
        return 'Linux';
      case PlatformType.unknown:
        return 'Unknown';
    }
  }

  /// 检查是否为移动平台
  static bool get isMobile {
    return [
      PlatformType.mobileAndroid,
      PlatformType.mobileIOS,
      PlatformType.webMobile,
    ].contains(currentPlatform);
  }

  /// 检查是否为平板平台
  static bool get isTablet {
    return currentPlatform == PlatformType.webTablet;
  }

  /// 检查是否为桌面平台
  static bool get isDesktop {
    return [
      PlatformType.webDesktop,
      PlatformType.desktopWindows,
      PlatformType.desktopMacOS,
      PlatformType.desktopLinux,
    ].contains(currentPlatform);
  }

  /// 检查是否为Web平台
  static bool get isWeb {
    return [
      PlatformType.webMobile,
      PlatformType.webTablet,
      PlatformType.webDesktop,
    ].contains(currentPlatform);
  }

  /// 检查是否为原生移动应用
  static bool get isNativeMobile {
    return [
      PlatformType.mobileAndroid,
      PlatformType.mobileIOS,
    ].contains(currentPlatform);
  }

  /// 检查是否为原生桌面应用
  static bool get isNativeDesktop {
    return [
      PlatformType.desktopWindows,
      PlatformType.desktopMacOS,
      PlatformType.desktopLinux,
    ].contains(currentPlatform);
  }

  /// 检查平台是否支持特定能力
  static bool hasCapability(PlatformCapability capability) {
    _cachedCapabilities ??= _detectCapabilities();
    return _cachedCapabilities![capability] ?? false;
  }

  /// 获取所有平台能力
  static Map<PlatformCapability, bool> getAllCapabilities() {
    _cachedCapabilities ??= _detectCapabilities();
    return Map.from(_cachedCapabilities!);
  }

  /// 检查屏幕尺寸类型（使用共享的breakpoints）
  static ScreenType getScreenType(double width) {
    return screenTypeForWidth(width);
  }

  /// 重置缓存（用于测试或强制重新检测）
  static void resetCache() {
    _cachedPlatformType = null;
    _cachedCapabilities = null;
  }

  // 私有方法：检测平台类型
  static PlatformType _detectPlatformType() {
    if (kIsWeb) {
      return _detectWebPlatformType();
    } else {
      try {
        if (Platform.isAndroid) return PlatformType.mobileAndroid;
        if (Platform.isIOS) return PlatformType.mobileIOS;
        if (Platform.isWindows) return PlatformType.desktopWindows;
        if (Platform.isMacOS) return PlatformType.desktopMacOS;
        if (Platform.isLinux) return PlatformType.desktopLinux;
      } catch (e) {
        // 在某些环境下Platform可能不可用
        if (kDebugMode) {
          print('Platform detection error: $e');
        }
      }
    }
    return PlatformType.unknown;
  }

  // 私有方法：检测Web平台类型
  static PlatformType _detectWebPlatformType() {
    // 在Web环境下，我们需要通过其他方式检测设备类型
    // 这里先返回webDesktop，后续可以通过用户代理字符串等方式精确检测
    // TODO: 实现基于用户代理字符串和屏幕尺寸的Web平台检测
    return PlatformType.webDesktop;
  }

  // 私有方法：检测平台能力
  static Map<PlatformCapability, bool> _detectCapabilities() {
    final capabilities = <PlatformCapability, bool>{};

    // 基于平台类型设置默认能力
    switch (currentPlatform) {
      case PlatformType.webMobile:
      case PlatformType.webTablet:
      case PlatformType.webDesktop:
        capabilities[PlatformCapability.pwaSupport] = true;
        capabilities[PlatformCapability.pushNotifications] = true;
        capabilities[PlatformCapability.offlineStorage] = true;
        capabilities[PlatformCapability.clipboardAccess] = true;
        capabilities[PlatformCapability.geolocationAccess] = true;
        capabilities[PlatformCapability.cameraAccess] = true;
        capabilities[PlatformCapability.fileSystemAccess] = false; // 有限支持
        capabilities[PlatformCapability.multiWindow] =
            currentPlatform == PlatformType.webDesktop;
        capabilities[PlatformCapability.touchInput] =
            currentPlatform != PlatformType.webDesktop;
        capabilities[PlatformCapability.keyboardInput] = true;
        capabilities[PlatformCapability.mouseInput] =
            currentPlatform == PlatformType.webDesktop;
        break;

      case PlatformType.mobileAndroid:
      case PlatformType.mobileIOS:
        capabilities[PlatformCapability.pwaSupport] = false;
        capabilities[PlatformCapability.pushNotifications] = true;
        capabilities[PlatformCapability.offlineStorage] = true;
        capabilities[PlatformCapability.systemNotifications] = true;
        capabilities[PlatformCapability.fileSystemAccess] = true;
        capabilities[PlatformCapability.cameraAccess] = true;
        capabilities[PlatformCapability.geolocationAccess] = true;
        capabilities[PlatformCapability.clipboardAccess] = true;
        capabilities[PlatformCapability.touchInput] = true;
        capabilities[PlatformCapability.keyboardInput] = true;
        capabilities[PlatformCapability.mouseInput] = false;
        capabilities[PlatformCapability.multiWindow] = false;
        break;

      case PlatformType.desktopWindows:
      case PlatformType.desktopMacOS:
      case PlatformType.desktopLinux:
        capabilities[PlatformCapability.pwaSupport] = false;
        capabilities[PlatformCapability.systemNotifications] = true;
        capabilities[PlatformCapability.fileSystemAccess] = true;
        capabilities[PlatformCapability.multiWindow] = true;
        capabilities[PlatformCapability.keyboardInput] = true;
        capabilities[PlatformCapability.mouseInput] = true;
        capabilities[PlatformCapability.touchInput] = false;
        capabilities[PlatformCapability.clipboardAccess] = true;
        capabilities[PlatformCapability.offlineStorage] = true;
        break;

      case PlatformType.unknown:
        // 对未知平台设置保守的默认值
        for (final capability in PlatformCapability.values) {
          capabilities[capability] = false;
        }
        break;
    }

    return capabilities;
  }

  /// 打印平台信息（调试用）
  static void printPlatformInfo() {
    if (!kDebugMode) return;

    print('=== Platform Information ===');
    print('Platform: $platformName (${currentPlatform.name})');
    print('Is Mobile: $isMobile');
    print('Is Tablet: $isTablet');
    print('Is Desktop: $isDesktop');
    print('Is Web: $isWeb');
    print('Is Native Mobile: $isNativeMobile');
    print('Is Native Desktop: $isNativeDesktop');
    print('');
    print('Capabilities:');
    getAllCapabilities().forEach((capability, supported) {
      print('  ${capability.name}: ${supported ? "✓" : "✗"}');
    });
    print('============================');
  }
}
