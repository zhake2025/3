import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 响应式主题定制系统
/// 支持动态主题切换、设备适配和用户偏好保存
class ResponsiveThemeManager extends ChangeNotifier {
  static ResponsiveThemeManager? _instance;
  static ResponsiveThemeManager get instance => 
      _instance ??= ResponsiveThemeManager._();
  
  ResponsiveThemeManager._();

  // 主题配置
  ThemeConfig _currentTheme = ThemeConfig.defaultLight();
  ThemeMode _themeMode = ThemeMode.system;
  DeviceType _deviceType = DeviceType.desktop;
  
  // 响应式断点
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  // 存储键
  static const String _themeStorageKey = 'kelivo_theme_config';
  static const String _themeModeStorageKey = 'kelivo_theme_mode';
  
  // 媒体查询监听
  html.MediaQueryList? _darkModeQuery;
  html.MediaQueryList? _reducedMotionQuery;
  html.MediaQueryList? _highContrastQuery;
  
  StreamController<ThemeChangeEvent>? _themeController;
  
  /// 主题变化事件流
  Stream<ThemeChangeEvent> get themeStream {
    _themeController ??= StreamController<ThemeChangeEvent>.broadcast();
    return _themeController!.stream;
  }
  
  /// 当前主题配置
  ThemeConfig get currentTheme => _currentTheme;
  
  /// 当前主题模式
  ThemeMode get themeMode => _themeMode;
  
  /// 当前设备类型
  DeviceType get deviceType => _deviceType;
  
  /// 是否为暗色主题
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return _darkModeQuery?.matches ?? false;
    }
  }
  
  /// 初始化主题管理器
  Future<void> initialize() async {
    try {
      // 检测设备类型
      _detectDeviceType();
      
      // 设置媒体查询监听
      _setupMediaQueryListeners();
      
      // 加载保存的主题配置
      await _loadThemeConfig();
      
      // 监听窗口大小变化
      _setupWindowListeners();
      
      debugPrint('Responsive Theme Manager initialized');
      _emitThemeChangeEvent('initialized');
      
    } catch (e) {
      debugPrint('Failed to initialize theme manager: $e');
    }
  }
  
  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _saveThemeMode();
    
    notifyListeners();
    _emitThemeChangeEvent('theme_mode_changed');
  }
  
  /// 设置主题配置
  Future<void> setThemeConfig(ThemeConfig config) async {
    _currentTheme = config;
    await _saveThemeConfig();
    
    notifyListeners();
    _emitThemeChangeEvent('theme_config_changed');
  }
  
  /// 切换主题模式
  Future<void> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }
  
  /// 获取当前Material主题数据
  ThemeData getMaterialTheme() {
    final baseTheme = isDarkMode ? _currentTheme.darkTheme : _currentTheme.lightTheme;
    
    return baseTheme.copyWith(
      // 根据设备类型调整组件大小
      visualDensity: _getVisualDensity(),
      // 根据设备类型调整字体大小
      textTheme: _getResponsiveTextTheme(baseTheme.textTheme),
      // 根据设备类型调整间距
      cardTheme: _getResponsiveCardThemeData(baseTheme.cardTheme),
      // 根据设备类型调整按钮样式
      elevatedButtonTheme: _getResponsiveButtonTheme(baseTheme.elevatedButtonTheme),
    );
  }
  
  /// 获取响应式布局配置
  ResponsiveLayoutConfig getLayoutConfig() {
    return ResponsiveLayoutConfig(
      deviceType: _deviceType,
      screenWidth: html.window.innerWidth?.toDouble() ?? 1920,
      screenHeight: html.window.innerHeight?.toDouble() ?? 1080,
      sidebarWidth: _getSidebarWidth(),
      contentPadding: _getContentPadding(),
      gridColumns: _getGridColumns(),
      cardAspectRatio: _getCardAspectRatio(),
    );
  }
  
  /// 创建自定义主题
  ThemeConfig createCustomTheme({
    required String name,
    required Color primaryColor,
    required Color secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? errorColor,
    String? fontFamily,
    double? fontSize,
  }) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
    );
    
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
    );
    
    final textTheme = _createTextTheme(fontFamily, fontSize);
    
    return ThemeConfig(
      name: name,
      lightTheme: ThemeData(
        colorScheme: lightColorScheme,
        textTheme: textTheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        textTheme: textTheme,
        useMaterial3: true,
      ),
    );
  }
  
  /// 获取预设主题列表
  List<ThemeConfig> getPresetThemes() {
    return [
      ThemeConfig.defaultLight(),
      ThemeConfig.defaultDark(),
      ThemeConfig.ocean(),
      ThemeConfig.forest(),
      ThemeConfig.sunset(),
      ThemeConfig.minimal(),
      ThemeConfig.highContrast(),
    ];
  }
  
  /// 导出主题配置
  String exportThemeConfig() {
    return jsonEncode(_currentTheme.toJson());
  }
  
  /// 导入主题配置
  Future<bool> importThemeConfig(String configJson) async {
    try {
      final json = jsonDecode(configJson) as Map<String, dynamic>;
      final config = ThemeConfig.fromJson(json);
      await setThemeConfig(config);
      return true;
    } catch (e) {
      debugPrint('Failed to import theme config: $e');
      return false;
    }
  }
  
  // 私有方法
  
  void _detectDeviceType() {
    final width = html.window.innerWidth ?? 1920;
    
    if (width < mobileBreakpoint) {
      _deviceType = DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      _deviceType = DeviceType.tablet;
    } else {
      _deviceType = DeviceType.desktop;
    }
  }
  
  void _setupMediaQueryListeners() {
    // 监听暗色模式偏好
    _darkModeQuery = html.window.matchMedia('(prefers-color-scheme: dark)');
    _darkModeQuery?.addListener(_handleDarkModeChange);
    
    // 监听减少动画偏好
    _reducedMotionQuery = html.window.matchMedia('(prefers-reduced-motion: reduce)');
    _reducedMotionQuery?.addListener(_handleAccessibilityChange);
    
    // 监听高对比度偏好
    _highContrastQuery = html.window.matchMedia('(prefers-contrast: high)');
    _highContrastQuery?.addListener(_handleAccessibilityChange);
  }
  
  void _setupWindowListeners() {
    html.window.onResize.listen((_) {
      final oldDeviceType = _deviceType;
      _detectDeviceType();
      
      if (oldDeviceType != _deviceType) {
        notifyListeners();
        _emitThemeChangeEvent('device_type_changed');
      }
    });
  }
  
  Future<void> _loadThemeConfig() async {
    try {
      // 加载主题模式
      final themeModeString = html.window.localStorage[_themeModeStorageKey];
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
      
      // 加载主题配置
      final themeConfigString = html.window.localStorage[_themeStorageKey];
      if (themeConfigString != null) {
        final json = jsonDecode(themeConfigString) as Map<String, dynamic>;
        _currentTheme = ThemeConfig.fromJson(json);
      }
    } catch (e) {
      debugPrint('Failed to load theme config: $e');
    }
  }
  
  Future<void> _saveThemeMode() async {
    try {
      html.window.localStorage[_themeModeStorageKey] = _themeMode.toString();
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }
  
  Future<void> _saveThemeConfig() async {
    try {
      html.window.localStorage[_themeStorageKey] = jsonEncode(_currentTheme.toJson());
    } catch (e) {
      debugPrint('Failed to save theme config: $e');
    }
  }
  
  VisualDensity _getVisualDensity() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return VisualDensity.comfortable;
      case DeviceType.tablet:
        return VisualDensity.standard;
      case DeviceType.desktop:
        return VisualDensity.compact;
    }
  }
  
  TextTheme _getResponsiveTextTheme(TextTheme baseTheme) {
    final scaleFactor = _getTextScaleFactor();
    
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (baseTheme.displayLarge?.fontSize ?? 57) * scaleFactor,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (baseTheme.displayMedium?.fontSize ?? 45) * scaleFactor,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (baseTheme.displaySmall?.fontSize ?? 36) * scaleFactor,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (baseTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (baseTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (baseTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
    );
  }
  
  double _getTextScaleFactor() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.0;
    }
  }
  
  CardThemeData _getResponsiveCardThemeData(CardThemeData? baseTheme) {
    final margin = _getCardMargin();
    
    return CardThemeData(
      margin: EdgeInsets.all(margin),
      elevation: baseTheme?.elevation,
      color: baseTheme?.color,
      shadowColor: baseTheme?.shadowColor,
      surfaceTintColor: baseTheme?.surfaceTintColor,
      shape: baseTheme?.shape,
      clipBehavior: baseTheme?.clipBehavior,
    );
  }
  
  double _getCardMargin() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 8.0;
      case DeviceType.tablet:
        return 12.0;
      case DeviceType.desktop:
        return 16.0;
    }
  }
  
  ElevatedButtonThemeData _getResponsiveButtonTheme(ElevatedButtonThemeData? baseTheme) {
    final padding = _getButtonPadding();
    
    return ElevatedButtonThemeData(
      style: (baseTheme?.style ?? ElevatedButton.styleFrom()).copyWith(
        padding: MaterialStateProperty.all(padding),
      ),
    );
  }
  
  EdgeInsets _getButtonPadding() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }
  
  double _getSidebarWidth() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 0; // 移动端不显示侧边栏
      case DeviceType.tablet:
        return 280;
      case DeviceType.desktop:
        return 320;
    }
  }
  
  EdgeInsets _getContentPadding() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(24);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }
  
  int _getGridColumns() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 3;
    }
  }
  
  double _getCardAspectRatio() {
    switch (_deviceType) {
      case DeviceType.mobile:
        return 16 / 9;
      case DeviceType.tablet:
        return 4 / 3;
      case DeviceType.desktop:
        return 3 / 2;
    }
  }
  
  TextTheme _createTextTheme(String? fontFamily, double? fontSize) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 4.0,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 3.2,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 2.6,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 2.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 2.0,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 1.7,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 1.6,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 1.1,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 14,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 1.1,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize ?? 14,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: (fontSize ?? 14) * 0.9,
      ),
    );
  }
  
  void _handleDarkModeChange(html.Event event) {
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
      _emitThemeChangeEvent('system_theme_changed');
    }
  }
  
  void _handleAccessibilityChange(html.Event event) {
    _emitThemeChangeEvent('accessibility_changed');
  }
  
  void _emitThemeChangeEvent(String type) {
    _themeController?.add(ThemeChangeEvent(
      type: type,
      themeConfig: _currentTheme,
      themeMode: _themeMode,
      deviceType: _deviceType,
      timestamp: DateTime.now(),
    ));
  }
  
  /// 清理资源
  void dispose() {
    _themeController?.close();
    super.dispose();
  }
}

/// 主题配置
class ThemeConfig {
  final String name;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  
  const ThemeConfig({
    required this.name,
    required this.lightTheme,
    required this.darkTheme,
  });
  
  factory ThemeConfig.defaultLight() {
    return ThemeConfig(
      name: 'Default Light',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  factory ThemeConfig.defaultDark() {
    return ThemeConfig(
      name: 'Default Dark',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  factory ThemeConfig.ocean() {
    return ThemeConfig(
      name: 'Ocean',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  factory ThemeConfig.forest() {
    return ThemeConfig(
      name: 'Forest',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  factory ThemeConfig.sunset() {
    return ThemeConfig(
      name: 'Sunset',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  factory ThemeConfig.minimal() {
    return ThemeConfig(
      name: 'Minimal',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  factory ThemeConfig.highContrast() {
    return ThemeConfig(
      name: 'High Contrast',
      lightTheme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          background: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          background: Colors.black,
          surface: Colors.black,
        ),
        useMaterial3: true,
      ),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // 注意：ThemeData无法直接序列化，这里需要提取关键属性
      'lightTheme': {
        'primaryColor': lightTheme.primaryColor.value,
        'colorScheme': {
          'primary': lightTheme.colorScheme.primary.value,
          'secondary': lightTheme.colorScheme.secondary.value,
          'background': lightTheme.colorScheme.background.value,
          'surface': lightTheme.colorScheme.surface.value,
        },
      },
      'darkTheme': {
        'primaryColor': darkTheme.primaryColor.value,
        'colorScheme': {
          'primary': darkTheme.colorScheme.primary.value,
          'secondary': darkTheme.colorScheme.secondary.value,
          'background': darkTheme.colorScheme.background.value,
          'surface': darkTheme.colorScheme.surface.value,
        },
      },
    };
  }
  
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    // 这里需要根据保存的属性重建ThemeData
    // 简化实现，实际使用时可能需要更复杂的序列化逻辑
    return ThemeConfig.defaultLight().copyWith(name: json['name']);
  }
  
  ThemeConfig copyWith({
    String? name,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeConfig(
      name: name ?? this.name,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// 设备类型
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// 响应式布局配置
class ResponsiveLayoutConfig {
  final DeviceType deviceType;
  final double screenWidth;
  final double screenHeight;
  final double sidebarWidth;
  final EdgeInsets contentPadding;
  final int gridColumns;
  final double cardAspectRatio;
  
  const ResponsiveLayoutConfig({
    required this.deviceType,
    required this.screenWidth,
    required this.screenHeight,
    required this.sidebarWidth,
    required this.contentPadding,
    required this.gridColumns,
    required this.cardAspectRatio,
  });
}

/// 主题变化事件
class ThemeChangeEvent {
  final String type;
  final ThemeConfig themeConfig;
  final ThemeMode themeMode;
  final DeviceType deviceType;
  final DateTime timestamp;
  
  const ThemeChangeEvent({
    required this.type,
    required this.themeConfig,
    required this.themeMode,
    required this.deviceType,
    required this.timestamp,
  });
}