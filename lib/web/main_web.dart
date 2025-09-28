import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/web_service_registry.dart';
import 'services/multi_window_chat_manager.dart';
import 'services/simple_offline_sync_manager.dart';
import 'services/simple_push_notification_service.dart';
import 'services/responsive_theme_manager.dart';
import 'services/todo_service.dart';
import 'services/pwa_service.dart';
import 'widgets/web_service_status_widget.dart';
import '../main.dart' as main_app;

/// Web平台主入口
/// 负责初始化Web特有的服务和功能
class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  bool _isInitializing = true;
  String? _initError;
  
  @override
  void initState() {
    super.initState();
    _initializeWebServices();
  }
  
  Future<void> _initializeWebServices() async {
    try {
      debugPrint('Starting Web App initialization...');
      
      // 使用安全初始化方法，带重试机制
      await WebServiceRegistry.instance.safeInitializeServices(
        maxRetries: 3,
        retryDelay: const Duration(seconds: 1),
      );
      
      debugPrint('Web App initialization completed successfully');
      
      setState(() {
        _isInitializing = false;
      });
      
    } catch (e) {
      debugPrint('Web App initialization failed: $e');
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return MaterialApp(
        title: 'Kelivo PWA',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '正在初始化Web服务...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_initError != null) {
      return MaterialApp(
        title: 'Kelivo PWA',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '初始化失败',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitializing = true;
                      _initError = null;
                    });
                    _initializeWebServices();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Web服务初始化成功，启动主应用
    return WebServiceProvider(
      child: main_app.MyApp(),
    );
  }
}

/// Web服务提供者
/// 为整个应用提供Web服务的访问
class WebServiceProvider extends InheritedWidget {
  const WebServiceProvider({
    super.key,
    required super.child,
  });

  static WebServiceProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WebServiceProvider>();
  }
  
  /// 获取Web服务注册中心
  WebServiceRegistry get services => WebServiceRegistry.instance;

  @override
  bool updateShouldNotify(WebServiceProvider oldWidget) => false;
}

/// Web服务访问扩展
extension WebServiceAccess on BuildContext {
  /// 获取Web服务注册中心
  WebServiceRegistry get webServices {
    final provider = WebServiceProvider.of(this);
    if (provider == null) {
      throw StateError('WebServiceProvider not found in widget tree');
    }
    return provider.services;
  }
  
  /// 快速访问多窗口管理器
  MultiWindowChatManager get multiWindowManager => webServices.multiWindowManager;
  
  /// 快速访问离线同步管理器
  SimpleOfflineSyncManager get offlineSyncManager => webServices.offlineSyncManager;
  
  /// 快速访问推送通知服务
  SimplePushNotificationService get pushNotificationService => webServices.pushNotificationService;
  
  /// 快速访问主题管理器
  ResponsiveThemeManager get themeManager => webServices.themeManager;
  
  /// 快速访问待办事项服务
  TodoService get todoService => webServices.todoService;
  
  /// 快速访问PWA服务
  PWAService get pwaService => webServices.pwaService;
}

/// Web开发者工具
/// 仅在调试模式下显示
class WebDeveloperTools extends StatelessWidget {
  const WebDeveloperTools({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 16,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Container(
                width: 600,
                height: 400,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Web开发者工具',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Expanded(
                      child: SingleChildScrollView(
                        child: WebServiceStatusWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.developer_mode),
      ),
    );
  }
}

/// Web应用包装器
/// 添加Web特有的功能和工具
class WebAppWrapper extends StatelessWidget {
  final Widget child;
  
  const WebAppWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const WebDeveloperTools(),
      ],
    );
  }
}