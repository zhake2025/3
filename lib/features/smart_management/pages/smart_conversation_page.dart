import 'package:flutter/material.dart';
import '../../../platform/detector/platform_detector.dart';
import '../../../platform/features/feature_flags.dart';
import '../../../web/services/smart_conversation_manager.dart';
import '../../../shared/responsive/breakpoints.dart';

/// 智能会话管理页面
/// PWA专用的高级会话管理界面
class SmartConversationPage extends StatefulWidget {
  const SmartConversationPage({super.key});

  @override
  State<SmartConversationPage> createState() => _SmartConversationPageState();
}

class _SmartConversationPageState extends State<SmartConversationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<ConversationGroup> _groups = [];
  List<ConversationSuggestion> _suggestions = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: 从SmartConversationManager加载数据
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = screenTypeForContext(context);

    if (!PlatformDetector.isWeb) {
      return _buildNotSupportedView();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(screenType),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildNotSupportedView() {
    return Scaffold(
      appBar: AppBar(title: const Text('智能会话管理')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '智能会话管理功能仅在Web端可用',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '请在浏览器中访问以使用完整功能',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('智能会话管理'),
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_outlined), text: '概览'),
          Tab(icon: Icon(Icons.folder_outlined), text: '分组'),
          Tab(icon: Icon(Icons.lightbulb_outlined), text: '建议'),
          Tab(icon: Icon(Icons.analytics_outlined), text: '分析'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          tooltip: '智能搜索',
        ),
        IconButton(
          onPressed: _showExportDialog,
          icon: const Icon(Icons.download),
          tooltip: '导出会话',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'backup',
              child: ListTile(
                leading: Icon(Icons.backup),
                title: Text('备份数据'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('管理设置'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('使用帮助'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(ScreenType screenType) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载智能会话数据...'),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(screenType),
        _buildGroupsTab(screenType),
        _buildSuggestionsTab(screenType),
        _buildAnalyticsTab(screenType),
      ],
    );
  }

  Widget _buildOverviewTab(ScreenType screenType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
          const SizedBox(height: 24),
          if (screenType == ScreenType.desktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopGroups()),
                const SizedBox(width: 16),
                Expanded(child: _buildQuickActions()),
              ],
            ),
          ] else ...[
            _buildTopGroups(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {
        'title': '总会话',
        'value': '156',
        'icon': Icons.chat_outlined,
        'color': Colors.blue,
      },
      {
        'title': '活跃分组',
        'value': '8',
        'icon': Icons.folder_outlined,
        'color': Colors.green,
      },
      {
        'title': '智能建议',
        'value': '12',
        'icon': Icons.lightbulb_outlined,
        'color': Colors.orange,
      },
      {
        'title': '今日活动',
        'value': '23',
        'icon': Icons.trending_up,
        'color': Colors.purple,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速统计',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    screenTypeForContext(context) == ScreenType.mobile ? 2 : 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (stat['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat['value'] as String,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: stat['color'] as Color,
                            ),
                      ),
                      Text(
                        stat['title'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '最近活动',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: 查看所有活动
                  },
                  child: const Text('查看全部'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(
                      Icons.chat_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text('创建了新的会话分组 \"工作讨论\"'),
                  subtitle: Text('2小时前'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    // TODO: 跳转到具体活动
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGroups() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '热门分组',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ];
              final names = ['工作讨论', '学习笔记', '创意想法', '技术问题'];
              final counts = ['23', '18', '15', '12'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors[index].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.folder, color: colors[index], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            names[index],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${counts[index]} 个会话',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': '创建智能分组',
        'description': '基于规则自动分组',
        'icon': Icons.auto_awesome,
        'color': Colors.blue,
        'action': _createSmartGroup,
      },
      {
        'title': '批量标记',
        'description': '为多个会话添加标签',
        'icon': Icons.label_outline,
        'color': Colors.green,
        'action': _batchTagging,
      },
      {
        'title': '导出会话',
        'description': '将会话导出为文件',
        'icon': Icons.download,
        'color': Colors.orange,
        'action': _showExportDialog,
      },
      {
        'title': '清理建议',
        'description': '智能清理无用会话',
        'icon': Icons.cleaning_services,
        'color': Colors.red,
        'action': _showCleanupDialog,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快捷操作',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    action['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(action['description'] as String),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: action['action'] as VoidCallback,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsTab(ScreenType screenType) {
    return const Center(child: Text('分组管理功能开发中...'));
  }

  Widget _buildSuggestionsTab(ScreenType screenType) {
    return const Center(child: Text('智能建议功能开发中...'));
  }

  Widget _buildAnalyticsTab(ScreenType screenType) {
    return const Center(child: Text('数据分析功能开发中...'));
  }

  Widget? _buildFloatingActionButton() {
    if (!FeatureFlags.isPWAEnabled) return null;

    return FloatingActionButton.extended(
      onPressed: _createSmartGroup,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('智能分组'),
    );
  }

  // 事件处理方法
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('智能搜索'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: '输入关键词或使用高级语法...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 执行搜索
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    // TODO: 实现导出对话框
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'backup':
        _backupData();
        break;
      case 'settings':
        _showSettings();
        break;
      case 'help':
        _showHelp();
        break;
    }
  }

  void _createSmartGroup() {
    // TODO: 实现创建智能分组
  }

  void _batchTagging() {
    // TODO: 实现批量标记
  }

  void _showCleanupDialog() {
    // TODO: 实现清理对话框
  }

  void _backupData() {
    // TODO: 实现数据备份
  }

  void _showSettings() {
    // TODO: 显示设置页面
  }

  void _showHelp() {
    // TODO: 显示帮助页面
  }
}
