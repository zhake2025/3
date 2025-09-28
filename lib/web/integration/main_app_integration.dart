import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/web_service_registry.dart';
import '../services/responsive_theme_manager.dart';
import '../services/simple_push_notification_service.dart';
import '../../web/components/todo_management_panel.dart';
import '../widgets/web_service_status_widget.dart';

/// 主应用集成类
/// 负责将Web服务集成到主应用中
class MainAppIntegration {
  static MainAppIntegration? _instance;
  static MainAppIntegration get instance => _instance ??= MainAppIntegration._();
  
  MainAppIntegration._();
  
  bool _isIntegrated = false;
  
  /// 集成Web服务到主应用
  Future<void> integrateWebServices(BuildContext context) async {
    if (_isIntegrated) return;
    
    try {
      debugPrint('Starting Web Services integration...');
      
      // 确保Web服务已初始化
      if (!WebServiceRegistry.instance.isInitialized) {
        await WebServiceRegistry.instance.initializeServices();
      }
      
      // 注册全局服务访问器
      _registerGlobalAccessors();
      
      // 设置主题监听器
      _setupThemeListener(context);
      
      // 设置推送通知监听器
      _setupPushNotificationListener(context);
      
      // 设置多窗口同步监听器
      _setupMultiWindowListener(context);
      
      _isIntegrated = true;
      debugPrint('Web Services integration completed successfully');
      
    } catch (e) {
      debugPrint('Failed to integrate Web Services: $e');
      rethrow;
    }
  }
  
  /// 注册全局服务访问器
  void _registerGlobalAccessors() {
    // 这里可以注册全局的服务访问方法
    // 例如：注册到GetIt、Provider等状态管理工具
  }
  
  /// 设置主题监听器
  void _setupThemeListener(BuildContext context) {
    try {
      final themeManager = WebServiceRegistry.instance.themeManager;
      themeManager.addListener(() {
        // 主题变化时的处理逻辑
        debugPrint('Theme changed to: ${themeManager.currentTheme.name}');
      });
    } catch (e) {
      debugPrint('Failed to setup theme listener: $e');
    }
  }
  
  /// 设置推送通知监听器
  void _setupPushNotificationListener(BuildContext context) {
    try {
      final pushService = WebServiceRegistry.instance.pushNotificationService;
      // 这里可以设置推送通知的全局处理逻辑
      debugPrint('Push notification listener setup completed');
    } catch (e) {
      debugPrint('Failed to setup push notification listener: $e');
    }
  }
  
  /// 设置多窗口同步监听器
  void _setupMultiWindowListener(BuildContext context) {
    try {
      final multiWindowManager = WebServiceRegistry.instance.multiWindowManager;
      // 这里可以设置多窗口同步的全局处理逻辑
      debugPrint('Multi-window listener setup completed');
    } catch (e) {
      debugPrint('Failed to setup multi-window listener: $e');
    }
  }
  
  /// 获取Web功能页面
  List<WebFeaturePage> getWebFeaturePages() {
    return [
      WebFeaturePage(
        title: '待办事项管理',
        icon: Icons.task_alt,
        description: '管理您的待办事项和任务',
        builder: (context) => const Placeholder(child: Text('待办事项管理面板')),
      ),
      WebFeaturePage(
        title: '服务状态监控',
        icon: Icons.monitor_heart,
        description: '查看Web服务的运行状态',
        builder: (context) => const WebServiceStatusWidget(),
      ),
      WebFeaturePage(
        title: '主题定制',
        icon: Icons.palette,
        description: '自定义应用主题和外观',
        builder: (context) => const ThemeCustomizationPanel(),
      ),
      WebFeaturePage(
        title: '推送通知设置',
        icon: Icons.notifications,
        description: '管理推送通知设置',
        builder: (context) => const PushNotificationPanel(),
      ),
    ];
  }
  
  /// 检查集成状态
  bool get isIntegrated => _isIntegrated;
  
  /// 重置集成状态
  void reset() {
    _isIntegrated = false;
  }
}

/// Web功能页面模型
class WebFeaturePage {
  final String title;
  final IconData icon;
  final String description;
  final Widget Function(BuildContext) builder;
  
  const WebFeaturePage({
    required this.title,
    required this.icon,
    required this.description,
    required this.builder,
  });
}

/// 主题定制面板
class ThemeCustomizationPanel extends StatefulWidget {
  const ThemeCustomizationPanel({super.key});

  @override
  State<ThemeCustomizationPanel> createState() => _ThemeCustomizationPanelState();
}

class _ThemeCustomizationPanelState extends State<ThemeCustomizationPanel> {
  late ResponsiveThemeManager _themeManager;
  
  @override
  void initState() {
    super.initState();
    _themeManager = WebServiceRegistry.instance.getService<ResponsiveThemeManager>()!;
    _themeManager.addListener(_onThemeChanged);
  }
  
  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主题定制',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '当前主题: ${_themeManager.currentTheme.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('浅色主题'),
                  selected: !_themeManager.isDarkMode,
                  onSelected: (selected) {
                    if (selected) {
                      _themeManager.setThemeMode(ThemeMode.light);
                    }
                  },
                ),
                FilterChip(
                  label: const Text('深色主题'),
                  selected: _themeManager.isDarkMode,
                  onSelected: (selected) {
                    if (selected) {
                      _themeManager.setThemeMode(ThemeMode.dark);
                    }
                  },
                ),
                FilterChip(
                  label: const Text('跟随系统'),
                  selected: _themeManager.themeMode == ThemeMode.system,
                  onSelected: (selected) {
                    if (selected) {
                      _themeManager.setThemeMode(ThemeMode.system);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '主题预览',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '这是当前主题的预览',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 推送通知面板
class PushNotificationPanel extends StatefulWidget {
  const PushNotificationPanel({super.key});

  @override
  State<PushNotificationPanel> createState() => _PushNotificationPanelState();
}

class _PushNotificationPanelState extends State<PushNotificationPanel> {
  late SimplePushNotificationService _pushService;
  
  @override
  void initState() {
    super.initState();
    _pushService = WebServiceRegistry.instance.getService<SimplePushNotificationService>()!;
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '推送通知设置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '推送通知权限',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Switch(
                  value: _pushService.hasPermission,
                  onChanged: (value) async {
                    if (value) {
                      await _pushService.requestPermission();
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _pushService.showLocalNotification(
                  title: '测试通知',
                  body: '这是一个测试推送通知',
                );
              },
              child: const Text('发送测试通知'),
            ),
          ],
        ),
      ),
    );
  }
}