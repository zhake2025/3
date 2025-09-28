import 'package:flutter/material.dart';
import '../services/web_service_registry.dart';
import '../services/pwa_service.dart';
import '../services/simple_offline_sync_manager.dart';
import '../services/simple_push_notification_service.dart';
import '../services/multi_window_chat_manager.dart';
import '../services/responsive_theme_manager.dart';
import '../services/todo_service.dart';


class WebFeaturesDemo extends StatefulWidget {
  const WebFeaturesDemo({super.key});

  @override
  State<WebFeaturesDemo> createState() => _WebFeaturesDemoState();
}

class _WebFeaturesDemoState extends State<WebFeaturesDemo> {
  final WebServiceRegistry _serviceRegistry = WebServiceRegistry.instance;

  bool _isLoading = true;
  String _statusMessage = '正在初始化服务...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _statusMessage = '正在初始化PWA服务...';
      });
      
      await _serviceRegistry.initializeServices();

      
      setState(() {
        _isLoading = false;
        _statusMessage = '所有服务已就绪';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '服务初始化失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web功能演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildDesktopLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 侧边栏
        Container(
          width: 300,
          color: Theme.of(context).colorScheme.surface,
          child: _buildFeatureList(),
        ),
        // 主内容区
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return ListView(
      shrinkWrap: true,
      children: [
        _buildFeatureCard(
          '离线访问',
          '测试应用的离线功能',
          Icons.offline_bolt,
          () => _testOfflineFeature(),
        ),
        _buildFeatureCard(
          '推送通知',
          '测试推送通知功能',
          Icons.notifications,
          () => _testPushNotification(),
        ),
        _buildFeatureCard(
          '多窗口同步',
          '测试多窗口数据同步',
          Icons.sync,
          () => _testMultiWindowSync(),
        ),
        _buildFeatureCard(
          '响应式主题',
          '测试主题自适应功能',
          Icons.palette,
          () => _testResponsiveTheme(),
        ),
        _buildFeatureCard(
          '待办事项',
          '测试待办事项管理',
          Icons.task_alt,
          () => _testTodoManager(),
        ),
        _buildFeatureCard(
          '服务健康检查',
          '检查所有服务状态',
          Icons.health_and_safety,
          () => _performHealthCheck(),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Web功能演示',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        _buildStatusCard(),
        const SizedBox(height: 24),
        Expanded(
          child: _buildFeatureList(),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.check_circle,
                  color: _isLoading ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '服务状态',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Future<void> _testOfflineFeature() async {
    try {
      final offlineManager = _serviceRegistry.getService<SimpleOfflineSyncManager>();

      if (offlineManager != null) {
        await offlineManager.storeOfflineData('test_key', {'test': 'data'});
        _showSnackBar('离线功能测试成功');
      } else {
        _showSnackBar('离线服务未初始化');
      }
    } catch (e) {
      _showSnackBar('离线功能测试失败: $e');
    }
  }

  Future<void> _testPushNotification() async {
    try {
      final pushService = _serviceRegistry.getService<SimplePushNotificationService>();

      if (pushService != null) {
        await pushService.requestPermission();
        await pushService.showLocalNotification(
          title: '测试通知',
          body: '这是一个测试推送通知',
        );
        _showSnackBar('推送通知测试成功');
      } else {
        _showSnackBar('推送服务未初始化');
      }
    } catch (e) {
      _showSnackBar('推送通知测试失败: $e');
    }
  }

  Future<void> _testMultiWindowSync() async {
    try {
      final multiWindowManager = _serviceRegistry.getService<MultiWindowChatManager>();

      if (multiWindowManager != null) {
        multiWindowManager.syncChatMessage(
          messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          content: '多窗口同步测试',
          sender: 'test_user',
          timestamp: DateTime.now(),
        );
        _showSnackBar('多窗口同步测试成功');
      } else {
        _showSnackBar('多窗口服务未初始化');
      }
    } catch (e) {
      _showSnackBar('多窗口同步测试失败: $e');
    }
  }

  Future<void> _testResponsiveTheme() async {
    try {
      final themeManager = _serviceRegistry.getService<ResponsiveThemeManager>();
      if (themeManager != null) {
        await themeManager.toggleThemeMode();
        _showSnackBar('响应式主题测试成功');
      } else {
        _showSnackBar('主题服务未初始化');
      }
    } catch (e) {
      _showSnackBar('响应式主题测试失败: $e');
    }
  }

  Future<void> _testTodoManager() async {
    try {
      final todoManager = _serviceRegistry.getService<TodoService>();

      if (todoManager != null) {
        await todoManager.addTodo(
          title: '测试待办事项',
          description: '这是一个测试待办事项',
        );
        final todos = todoManager.todos;
        _showSnackBar('待办事项测试成功，当前有 ${todos.length} 个待办事项');
      } else {
        _showSnackBar('待办事项服务未初始化');
      }
    } catch (e) {
      _showSnackBar('待办事项测试失败: $e');
    }
  }

  Future<void> _performHealthCheck() async {
    try {
      final healthStatus = await _serviceRegistry.getServiceHealth();
      final healthyServices = healthStatus.where((status) => status['healthy'] == true).length;
      final totalServices = healthStatus.length;
      
      _showSnackBar('服务健康检查完成: $healthyServices/$totalServices 个服务正常');
    } catch (e) {
      _showSnackBar('服务健康检查失败: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

// 移动端专用的Web功能演示组件
class MobileWebFeaturesDemo extends StatefulWidget {
  const MobileWebFeaturesDemo({super.key});

  @override
  State<MobileWebFeaturesDemo> createState() => _MobileWebFeaturesDemoState();
}

class _MobileWebFeaturesDemoState extends State<MobileWebFeaturesDemo> {
  final WebServiceRegistry _serviceRegistry = WebServiceRegistry.instance;
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _serviceRegistry.initializeServices();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          _buildFeaturesTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '概览',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.featured_play_list),
            label: '功能',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'PWA功能概览',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildServiceStatusCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            '功能测试',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildFeatureTestCards(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            '设置',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildSettingsCards(),
        ],
      ),
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '服务状态',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildServiceStatusItem('PWA服务', true),
            _buildServiceStatusItem('离线同步', true),
            _buildServiceStatusItem('推送通知', true),
            _buildServiceStatusItem('多窗口管理', true),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _performHealthCheck(),
              child: const Text('刷新状态'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusItem(String serviceName, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(serviceName),
          const Spacer(),
          Text(
            isHealthy ? '正常' : '异常',
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  Icons.sync,
                  '同步数据',
                  () => _testOfflineFeature(),
                ),
                _buildQuickActionButton(
                  Icons.notifications,
                  '测试通知',
                  () => _testPushNotification(),
                ),
                _buildQuickActionButton(
                  Icons.palette,
                  '切换主题',
                  () => _testResponsiveTheme(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 32,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFeatureTestCards() {
    return Column(
      children: [
        _buildTestCard(
          '离线访问测试',
          '测试应用在离线状态下的功能',
          Icons.offline_bolt,
          () => _testOfflineFeature(),
        ),
        _buildTestCard(
          '推送通知测试',
          '测试推送通知的发送和接收',
          Icons.notifications,
          () => _testPushNotification(),
        ),
        _buildTestCard(
          '多窗口同步测试',
          '测试多个窗口间的数据同步',
          Icons.sync,
          () => _testMultiWindowSync(),
        ),
        _buildTestCard(
          '响应式主题测试',
          '测试主题的自动适配功能',
          Icons.palette,
          () => _testResponsiveTheme(),
        ),
        _buildTestCard(
          '待办事项测试',
          '测试待办事项的管理功能',
          Icons.task_alt,
          () => _testTodoManager(),
        ),
      ],
    );
  }

  Widget _buildTestCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTest,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onTest,
                child: const Text('测试'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCards() {
    return Column(
      children: [
        _buildSettingCard(
          '通知设置',
          '管理推送通知权限和偏好',
          Icons.notifications_outlined,
          () => _openNotificationSettings(),
        ),
        _buildSettingCard(
          '主题设置',
          '自定义应用主题和外观',
          Icons.palette_outlined,
          () => _openThemeSettings(),
        ),
        _buildSettingCard(
          '离线设置',
          '配置离线数据同步选项',
          Icons.offline_bolt_outlined,
          () => _openOfflineSettings(),
        ),
        _buildSettingCard(
          '关于应用',
          '查看应用信息和版本',
          Icons.info_outline,
          () => _showAboutDialog(),
        ),
      ],
    );
  }

  Widget _buildSettingCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  // 测试方法
  Future<void> _testOfflineFeature() async {
    try {
      final offlineManager = _serviceRegistry.getService<SimpleOfflineSyncManager>();
      if (offlineManager != null) {
        await offlineManager.storeOfflineData('test_key', {'test': 'data'});
        _showSnackBar('离线功能测试成功');
      } else {
        _showSnackBar('离线服务未初始化');
      }
    } catch (e) {
      _showSnackBar('离线功能测试失败: $e');
    }
  }

  Future<void> _testPushNotification() async {
    try {
      final pushService = _serviceRegistry.getService<SimplePushNotificationService>();
      if (pushService != null) {
        await pushService.requestPermission();
        await pushService.showLocalNotification(
          title: '测试通知',
          body: '这是一个测试推送通知',
        );
        _showSnackBar('推送通知测试成功');
      } else {
        _showSnackBar('推送服务未初始化');
      }
    } catch (e) {
      _showSnackBar('推送通知测试失败: $e');
    }
  }

  Future<void> _testMultiWindowSync() async {
    try {
      final multiWindowManager = _serviceRegistry.getService<MultiWindowChatManager>();
      if (multiWindowManager != null) {
        multiWindowManager.syncChatMessage(
          messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          content: '多窗口同步测试',
          sender: 'test_user',
          timestamp: DateTime.now(),
        );
        _showSnackBar('多窗口同步测试成功');
      } else {
        _showSnackBar('多窗口服务未初始化');
      }
    } catch (e) {
      _showSnackBar('多窗口同步测试失败: $e');
    }
  }

  Future<void> _testResponsiveTheme() async {
    try {
      final themeManager = _serviceRegistry.getService<ResponsiveThemeManager>();
      if (themeManager != null) {
        await themeManager.toggleThemeMode();
        _showSnackBar('响应式主题测试成功');
      } else {
        _showSnackBar('主题服务未初始化');
      }
    } catch (e) {
      _showSnackBar('响应式主题测试失败: $e');
    }
  }

  Future<void> _testTodoManager() async {
    try {
      final todoManager = _serviceRegistry.getService<TodoService>();
      if (todoManager != null) {
        await todoManager.addTodo(
          title: '测试待办事项',
          description: '这是一个测试待办事项',
        );
        final todos = todoManager.todos;
        _showSnackBar('待办事项测试成功，当前有 ${todos.length} 个待办事项');
      } else {
        _showSnackBar('待办事项服务未初始化');
      }
    } catch (e) {
      _showSnackBar('待办事项测试失败: $e');
    }
  }

  Future<void> _performHealthCheck() async {
    try {
      final healthStatus = await _serviceRegistry.getServiceHealth();
      final healthyServices = healthStatus.where((status) => status['healthy'] == true).length;
      final totalServices = healthStatus.length;
      
      _showSnackBar('服务健康检查完成: $healthyServices/$totalServices 个服务正常');
    } catch (e) {
      _showSnackBar('服务健康检查失败: $e');
    }
  }

  // 设置方法
  void _openNotificationSettings() {
    _showSnackBar('通知设置功能开发中...');
  }

  void _openThemeSettings() {
    _showSnackBar('主题设置功能开发中...');
  }

  void _openOfflineSettings() {
    _showSnackBar('离线设置功能开发中...');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于应用'),
        content: const Text('PWA功能演示应用\n版本: 1.0.0\n构建时间: 2024-01-01'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}