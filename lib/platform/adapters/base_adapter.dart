import 'package:flutter/material.dart';
import '../detector/platform_detector.dart';
import '../features/feature_flags.dart';

/// 基础适配器抽象类
/// 定义了所有平台适配器必须实现的基本接口
abstract class BaseAdapter {
  /// 适配器名称
  String get name;

  /// 支持的平台类型
  Set<PlatformType> get supportedPlatforms;

  /// 检查当前平台是否支持此适配器
  bool get isSupported =>
      supportedPlatforms.contains(PlatformDetector.currentPlatform);

  /// 初始化适配器
  Future<void> initialize();

  /// 清理适配器资源
  Future<void> dispose();

  /// 获取适配器配置
  Map<String, dynamic> getConfiguration();
}

/// 布局适配器接口
/// 定义布局相关的适配方法
abstract class LayoutAdapter extends BaseAdapter {
  /// 构建主布局结构
  Widget buildMainLayout({
    required Widget child,
    Widget? navigationRail,
    Widget? bottomNavigation,
    Widget? drawer,
  });

  /// 构建导航组件
  Widget buildNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
  });

  /// 构建应用栏
  Widget buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  });

  /// 获取布局参数
  LayoutParameters getLayoutParameters(BuildContext context);
}

/// 聊天适配器接口
/// 定义聊天界面相关的适配方法
abstract class ChatAdapter extends BaseAdapter {
  /// 构建聊天界面
  Widget buildChatInterface({
    required Widget messageList,
    required Widget inputArea,
    Widget? sidebar,
  });

  /// 构建消息列表
  Widget buildMessageList({
    required List<Widget> messages,
    required ScrollController scrollController,
  });

  /// 构建输入区域
  Widget buildInputArea({
    required TextEditingController controller,
    required VoidCallback onSend,
    List<Widget>? actions,
  });

  /// 构建消息气泡
  Widget buildMessageBubble({
    required String content,
    required bool isUser,
    DateTime? timestamp,
    Widget? avatar,
  });
}

/// 主题适配器接口
/// 定义主题相关的适配方法
abstract class ThemeAdapter extends BaseAdapter {
  /// 获取主题数据
  ThemeData getThemeData({
    required Brightness brightness,
    ColorScheme? colorScheme,
  });

  /// 获取文本主题
  TextTheme getTextTheme();

  /// 获取颜色方案
  ColorScheme getColorScheme(Brightness brightness);

  /// 获取组件主题
  Map<String, dynamic> getComponentThemes();
}

/// 导航适配器接口
/// 定义导航相关的适配方法
abstract class NavigationAdapter extends BaseAdapter {
  /// 构建导航结构
  Widget buildNavigationStructure({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
    required Widget body,
  });

  /// 获取导航样式
  NavigationStyle getNavigationStyle(BuildContext context);

  /// 处理导航动画
  PageRoute<T> createRoute<T extends Object?>(
    RouteSettings settings,
    WidgetBuilder builder,
  );
}

/// 适配器工厂
/// 根据当前平台和功能标志创建合适的适配器
class AdapterFactory {
  static final Map<Type, BaseAdapter> _adapters = {};

  /// 获取布局适配器
  static LayoutAdapter getLayoutAdapter() {
    return _getOrCreateAdapter<LayoutAdapter>(() {
      if (FeatureFlags.shouldUseDesktopLayout(1200)) {
        return DesktopLayoutAdapter();
      } else if (PlatformDetector.isTablet) {
        return TabletLayoutAdapter();
      } else {
        return MobileLayoutAdapter();
      }
    });
  }

  /// 获取聊天适配器
  static ChatAdapter getChatAdapter() {
    return _getOrCreateAdapter<ChatAdapter>(() {
      if (PlatformDetector.isDesktop) {
        return DesktopChatAdapter();
      } else if (PlatformDetector.isTablet) {
        return TabletChatAdapter();
      } else {
        return MobileChatAdapter();
      }
    });
  }

  /// 获取主题适配器
  static ThemeAdapter getThemeAdapter() {
    return _getOrCreateAdapter<ThemeAdapter>(() {
      if (PlatformDetector.isWeb) {
        return WebThemeAdapter();
      } else {
        return NativeThemeAdapter();
      }
    });
  }

  /// 获取导航适配器
  static NavigationAdapter getNavigationAdapter() {
    return _getOrCreateAdapter<NavigationAdapter>(() {
      if (PlatformDetector.isDesktop) {
        return DesktopNavigationAdapter();
      } else if (PlatformDetector.isTablet) {
        return TabletNavigationAdapter();
      } else {
        return MobileNavigationAdapter();
      }
    });
  }

  /// 通用适配器获取方法
  static T _getOrCreateAdapter<T extends BaseAdapter>(T Function() factory) {
    if (_adapters.containsKey(T)) {
      return _adapters[T] as T;
    }

    final adapter = factory();
    _adapters[T] = adapter;
    return adapter;
  }

  /// 清理所有适配器
  static Future<void> disposeAll() async {
    for (final adapter in _adapters.values) {
      await adapter.dispose();
    }
    _adapters.clear();
  }

  /// 重置适配器工厂（用于测试）
  static void reset() {
    _adapters.clear();
  }
}

/// 导航项数据类
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
  final bool enabled;

  const NavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.route,
    this.enabled = true,
  });
}

/// 布局参数数据类
class LayoutParameters {
  final double sidebarWidth;
  final double contentMaxWidth;
  final EdgeInsets padding;
  final bool shouldShowSidebar;
  final bool shouldShowBottomNav;
  final NavigationStyle navigationStyle;

  const LayoutParameters({
    required this.sidebarWidth,
    required this.contentMaxWidth,
    required this.padding,
    required this.shouldShowSidebar,
    required this.shouldShowBottomNav,
    required this.navigationStyle,
  });
}

/// 导航样式枚举
enum NavigationStyle {
  sidebar, // 侧边栏导航
  bottomNav, // 底部导航
  rail, // 导航栏
  drawer, // 抽屉导航
  tabs, // 标签导航
}

// 前向声明 - 具体实现将在后续创建
class DesktopLayoutAdapter extends LayoutAdapter {
  @override
  String get name => 'Desktop Layout Adapter';

  @override
  Set<PlatformType> get supportedPlatforms => {
    PlatformType.webDesktop,
    PlatformType.desktopWindows,
    PlatformType.desktopMacOS,
    PlatformType.desktopLinux,
  };

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> getConfiguration() => {};

  @override
  Widget buildMainLayout({
    required Widget child,
    Widget? navigationRail,
    Widget? bottomNavigation,
    Widget? drawer,
  }) {
    // TODO: 实现桌面布局
    return child;
  }

  @override
  Widget buildNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
  }) {
    // TODO: 实现桌面导航
    return Container();
  }

  @override
  Widget buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    // TODO: 实现桌面应用栏
    return Container();
  }

  @override
  LayoutParameters getLayoutParameters(BuildContext context) {
    // TODO: 实现桌面布局参数
    return const LayoutParameters(
      sidebarWidth: 280,
      contentMaxWidth: 1200,
      padding: EdgeInsets.all(16),
      shouldShowSidebar: true,
      shouldShowBottomNav: false,
      navigationStyle: NavigationStyle.sidebar,
    );
  }
}

class TabletLayoutAdapter extends LayoutAdapter {
  @override
  String get name => 'Tablet Layout Adapter';

  @override
  Set<PlatformType> get supportedPlatforms => {PlatformType.webTablet};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> getConfiguration() => {};

  @override
  Widget buildMainLayout({
    required Widget child,
    Widget? navigationRail,
    Widget? bottomNavigation,
    Widget? drawer,
  }) {
    return child;
  }

  @override
  Widget buildNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
  }) {
    return Container();
  }

  @override
  Widget buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return Container();
  }

  @override
  LayoutParameters getLayoutParameters(BuildContext context) {
    return const LayoutParameters(
      sidebarWidth: 240,
      contentMaxWidth: 900,
      padding: EdgeInsets.all(12),
      shouldShowSidebar: false,
      shouldShowBottomNav: true,
      navigationStyle: NavigationStyle.rail,
    );
  }
}

class MobileLayoutAdapter extends LayoutAdapter {
  @override
  String get name => 'Mobile Layout Adapter';

  @override
  Set<PlatformType> get supportedPlatforms => {
    PlatformType.mobileAndroid,
    PlatformType.mobileIOS,
    PlatformType.webMobile,
  };

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> getConfiguration() => {};

  @override
  Widget buildMainLayout({
    required Widget child,
    Widget? navigationRail,
    Widget? bottomNavigation,
    Widget? drawer,
  }) {
    return child;
  }

  @override
  Widget buildNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
  }) {
    return Container();
  }

  @override
  Widget buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return Container();
  }

  @override
  LayoutParameters getLayoutParameters(BuildContext context) {
    return const LayoutParameters(
      sidebarWidth: 0,
      contentMaxWidth: 600,
      padding: EdgeInsets.all(8),
      shouldShowSidebar: false,
      shouldShowBottomNav: true,
      navigationStyle: NavigationStyle.bottomNav,
    );
  }
}

// 其他适配器的占位符实现
class DesktopChatAdapter extends ChatAdapter {
  @override
  String get name => 'Desktop Chat Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {PlatformType.webDesktop};
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  Widget buildChatInterface({
    required Widget messageList,
    required Widget inputArea,
    Widget? sidebar,
  }) => Container();
  @override
  Widget buildMessageList({
    required List<Widget> messages,
    required ScrollController scrollController,
  }) => Container();
  @override
  Widget buildInputArea({
    required TextEditingController controller,
    required VoidCallback onSend,
    List<Widget>? actions,
  }) => Container();
  @override
  Widget buildMessageBubble({
    required String content,
    required bool isUser,
    DateTime? timestamp,
    Widget? avatar,
  }) => Container();
}

class TabletChatAdapter extends ChatAdapter {
  @override
  String get name => 'Tablet Chat Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {PlatformType.webTablet};
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  Widget buildChatInterface({
    required Widget messageList,
    required Widget inputArea,
    Widget? sidebar,
  }) => Container();
  @override
  Widget buildMessageList({
    required List<Widget> messages,
    required ScrollController scrollController,
  }) => Container();
  @override
  Widget buildInputArea({
    required TextEditingController controller,
    required VoidCallback onSend,
    List<Widget>? actions,
  }) => Container();
  @override
  Widget buildMessageBubble({
    required String content,
    required bool isUser,
    DateTime? timestamp,
    Widget? avatar,
  }) => Container();
}

class MobileChatAdapter extends ChatAdapter {
  @override
  String get name => 'Mobile Chat Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {
    PlatformType.mobileAndroid,
    PlatformType.mobileIOS,
    PlatformType.webMobile,
  };
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  Widget buildChatInterface({
    required Widget messageList,
    required Widget inputArea,
    Widget? sidebar,
  }) => Container();
  @override
  Widget buildMessageList({
    required List<Widget> messages,
    required ScrollController scrollController,
  }) => Container();
  @override
  Widget buildInputArea({
    required TextEditingController controller,
    required VoidCallback onSend,
    List<Widget>? actions,
  }) => Container();
  @override
  Widget buildMessageBubble({
    required String content,
    required bool isUser,
    DateTime? timestamp,
    Widget? avatar,
  }) => Container();
}

class WebThemeAdapter extends ThemeAdapter {
  @override
  String get name => 'Web Theme Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {
    PlatformType.webMobile,
    PlatformType.webTablet,
    PlatformType.webDesktop,
  };
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  ThemeData getThemeData({
    required Brightness brightness,
    ColorScheme? colorScheme,
  }) => ThemeData();
  @override
  TextTheme getTextTheme() => const TextTheme();
  @override
  ColorScheme getColorScheme(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness);
  @override
  Map<String, dynamic> getComponentThemes() => {};
}

class NativeThemeAdapter extends ThemeAdapter {
  @override
  String get name => 'Native Theme Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {
    PlatformType.mobileAndroid,
    PlatformType.mobileIOS,
  };
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  ThemeData getThemeData({
    required Brightness brightness,
    ColorScheme? colorScheme,
  }) => ThemeData();
  @override
  TextTheme getTextTheme() => const TextTheme();
  @override
  ColorScheme getColorScheme(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness);
  @override
  Map<String, dynamic> getComponentThemes() => {};
}

class DesktopNavigationAdapter extends NavigationAdapter {
  @override
  String get name => 'Desktop Navigation Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {PlatformType.webDesktop};
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  Widget buildNavigationStructure({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
    required Widget body,
  }) => Container();
  @override
  NavigationStyle getNavigationStyle(BuildContext context) =>
      NavigationStyle.sidebar;
  @override
  PageRoute<T> createRoute<T extends Object?>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => MaterialPageRoute<T>(settings: settings, builder: builder);
}

class TabletNavigationAdapter extends NavigationAdapter {
  @override
  String get name => 'Tablet Navigation Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {PlatformType.webTablet};
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  Widget buildNavigationStructure({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
    required Widget body,
  }) => Container();
  @override
  NavigationStyle getNavigationStyle(BuildContext context) =>
      NavigationStyle.rail;
  @override
  PageRoute<T> createRoute<T extends Object?>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => MaterialPageRoute<T>(settings: settings, builder: builder);
}

class MobileNavigationAdapter extends NavigationAdapter {
  @override
  String get name => 'Mobile Navigation Adapter';
  @override
  Set<PlatformType> get supportedPlatforms => {
    PlatformType.mobileAndroid,
    PlatformType.mobileIOS,
    PlatformType.webMobile,
  };
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Map<String, dynamic> getConfiguration() => {};
  @override
  Widget buildNavigationStructure({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
    required Widget body,
  }) => Container();
  @override
  NavigationStyle getNavigationStyle(BuildContext context) =>
      NavigationStyle.bottomNav;
  @override
  PageRoute<T> createRoute<T extends Object?>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => MaterialPageRoute<T>(settings: settings, builder: builder);
}
