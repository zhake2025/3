import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_multi_window_manager.dart';
import '../../l10n/app_localizations.dart';

/// 多窗口控制面板
/// 提供窗口管理、布局控制和状态监控功能
class MultiWindowControlPanel extends StatefulWidget {
  const MultiWindowControlPanel({super.key});

  @override
  State<MultiWindowControlPanel> createState() => _MultiWindowControlPanelState();
}

class _MultiWindowControlPanelState extends State<MultiWindowControlPanel>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final EnhancedMultiWindowManager _windowManager;
  WindowStatistics? _statistics;
  List<EnhancedChatWindow> _windows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _windowManager = EnhancedMultiWindowManager.instance;
    _refreshData();
    
    // 监听窗口事件
    _windowManager.addListener(_WindowEventListener(onEvent: _refreshData));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (mounted) {
      setState(() {
        _windows = _windowManager.getActiveWindows();
        _statistics = _windowManager.getStatistics();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(l10n, theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWindowsTab(l10n, theme),
                _buildLayoutTab(l10n, theme),
                _buildStatisticsTab(l10n, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.window,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '多窗口控制面板',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshData,
                icon: Icon(
                  Icons.refresh,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                tooltip: '刷新',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '窗口', icon: Icon(Icons.list)),
              Tab(text: '布局', icon: Icon(Icons.dashboard)),
              Tab(text: '统计', icon: Icon(Icons.analytics)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsTab(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        _buildQuickActions(l10n, theme),
        Expanded(
          child: _windows.isEmpty
              ? _buildEmptyState(l10n, theme)
              : _buildWindowsList(l10n, theme),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openNewWindow,
              icon: const Icon(Icons.add),
              label: const Text('新建窗口'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _windows.length > 1 ? _closeAllWindows : null,
            icon: const Icon(Icons.close_fullscreen),
            label: const Text('关闭全部'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.window_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无活跃窗口',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击"新建窗口"开始多窗口聊天',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsList(AppLocalizations l10n, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _windows.length,
      itemBuilder: (context, index) {
        final window = _windows[index];
        return _buildWindowCard(window, l10n, theme);
      },
    );
  }

  Widget _buildWindowCard(
    EnhancedChatWindow window,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isActive = window.isActive;
    final isReady = window.isReady;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          child: Icon(
            isReady ? Icons.window : Icons.hourglass_empty,
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
        title: Text(
          window.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '会话: ${window.conversationId.substring(0, 8)}...',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '创建: ${_formatTime(window.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (action) => _handleWindowAction(window, action),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'focus',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('聚焦'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'close',
                  child: ListTile(
                    leading: Icon(Icons.close),
                    title: Text('关闭'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'info',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('详情'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutTab(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '布局选项',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLayoutOption(
            '居中布局',
            '单窗口居中显示',
            Icons.center_focus_strong,
            () => _applyLayout('centered'),
            theme,
          ),
          _buildLayoutOption(
            '并排布局',
            '两个窗口左右并排',
            Icons.view_column,
            () => _applyLayout('sideBySide'),
            theme,
          ),
          _buildLayoutOption(
            '网格布局',
            '多窗口网格排列',
            Icons.grid_view,
            () => _applyLayout('grid'),
            theme,
          ),
          _buildLayoutOption(
            '层叠布局',
            '窗口层叠排列',
            Icons.layers,
            () => _applyLayout('cascade'),
            theme,
          ),
          const SizedBox(height: 24),
          Text(
            '自动布局',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('启用智能布局'),
            subtitle: const Text('根据窗口数量自动选择最佳布局'),
            value: true, // TODO: 从设置中获取
            onChanged: (value) {
              // TODO: 保存设置
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatisticsTab(AppLocalizations l10n, ThemeData theme) {
    if (_statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '窗口统计',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard('总窗口数', '${_statistics!.totalWindows}', Icons.window, theme),
          _buildStatCard('活跃窗口', '${_statistics!.activeWindows}', Icons.flash_on, theme),
          _buildStatCard(
            '平均年龄',
            '${_statistics!.averageWindowAge.toStringAsFixed(1)} 分钟',
            Icons.access_time,
            theme,
          ),
          const SizedBox(height: 16),
          Text(
            '会话分布',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._statistics!.conversationCounts.entries.map(
            (entry) => _buildConversationStat(entry.key, entry.value, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationStat(String conversationId, int count, ThemeData theme) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        '会话 ${conversationId.substring(0, 8)}...',
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text('$count 个窗口'),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else {
      return '${diff.inDays} 天前';
    }
  }

  Future<void> _openNewWindow() async {
    try {
      // TODO: 获取当前会话ID或让用户选择
      final conversationId = 'new_conversation_${DateTime.now().millisecondsSinceEpoch}';
      
      final window = await _windowManager.openChatWindow(
        conversationId: conversationId,
        title: '新聊天窗口',
      );

      if (window != null) {
        _showMessage('新窗口已打开');
        _refreshData();
      } else {
        _showMessage('无法打开新窗口', isError: true);
      }
    } catch (e) {
      _showMessage('打开窗口失败: $e', isError: true);
    }
  }

  Future<void> _closeAllWindows() async {
    try {
      final windows = List.of(_windows);
      for (final window in windows) {
        await _windowManager.closeChatWindow(window.id);
      }
      _showMessage('已关闭所有窗口');
      _refreshData();
    } catch (e) {
      _showMessage('关闭窗口失败: $e', isError: true);
    }
  }

  Future<void> _handleWindowAction(EnhancedChatWindow window, String action) async {
    try {
      switch (action) {
        case 'focus':
          await _windowManager.focusWindow(window.id);
          _showMessage('窗口已聚焦');
          break;
        case 'close':
          await _windowManager.closeChatWindow(window.id);
          _showMessage('窗口已关闭');
          _refreshData();
          break;
        case 'info':
          _showWindowInfo(window);
          break;
      }
    } catch (e) {
      _showMessage('操作失败: $e', isError: true);
    }
  }

  Future<void> _applyLayout(String layoutType) async {
    try {
      // TODO: 实现布局应用逻辑
      _showMessage('布局已应用');
    } catch (e) {
      _showMessage('应用布局失败: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  void _showWindowInfo(EnhancedChatWindow window) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('窗口详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('窗口ID', window.id),
            _buildInfoRow('标题', window.title),
            _buildInfoRow('会话ID', window.conversationId),
            _buildInfoRow('创建时间', window.createdAt.toString()),
            _buildInfoRow('最后活动', window.lastActivity.toString()),
            _buildInfoRow('状态', window.isReady ? '就绪' : '准备中'),
            _buildInfoRow('活跃', window.isActive ? '是' : '否'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowEventListener implements MultiWindowEventListener {
  final VoidCallback onEvent;

  _WindowEventListener({required this.onEvent});

  @override
  void onMultiWindowEvent(MultiWindowEvent event, EnhancedChatWindow window) {
    onEvent();
  }
}