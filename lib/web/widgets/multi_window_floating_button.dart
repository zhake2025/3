import 'package:flutter/material.dart';
import '../services/enhanced_multi_window_manager.dart';

/// 多窗口浮动按钮
/// 提供快速访问多窗口功能的入口
class MultiWindowFloatingButton extends StatefulWidget {
  const MultiWindowFloatingButton({super.key});

  @override
  State<MultiWindowFloatingButton> createState() => _MultiWindowFloatingButtonState();
}

class _MultiWindowFloatingButtonState extends State<MultiWindowFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late final EnhancedMultiWindowManager _windowManager;
  
  bool _isExpanded = false;
  int _windowCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _windowManager = EnhancedMultiWindowManager.instance;
    _updateWindowCount();
    
    // 监听窗口变化
    _windowManager.addListener(_WindowCountListener(onUpdate: _updateWindowCount));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateWindowCount() {
    if (mounted) {
      setState(() {
        _windowCount = _windowManager.getActiveWindows().length;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // 背景遮罩
        if (_isExpanded)
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        
        // 浮动按钮组
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 扩展按钮
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Opacity(
                    opacity: _animation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.add,
                          label: '新建窗口',
                          onPressed: _openNewWindow,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          icon: Icons.dashboard,
                          label: '控制面板',
                          onPressed: _showControlPanel,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          icon: Icons.view_column,
                          label: '整理布局',
                          onPressed: _organizeLayout,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // 主按钮
            FloatingActionButton(
              onPressed: _toggleExpanded,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0.125 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.window),
                  ),
                  if (_windowCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_windowCount',
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }

  Future<void> _openNewWindow() async {
    _toggleExpanded();
    
    try {
      // 获取当前会话ID或创建新的
      final conversationId = 'new_conversation_${DateTime.now().millisecondsSinceEpoch}';
      
      final window = await _windowManager.openChatWindow(
        conversationId: conversationId,
        title: '新聊天窗口',
      );

      if (window != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('新窗口已打开'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开窗口失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showControlPanel() {
    _toggleExpanded();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '多窗口控制面板',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildSimpleControlPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleControlPanel() {
    final windows = _windowManager.getActiveWindows();
    final statistics = _windowManager.getStatistics();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '窗口统计',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('总数', '${statistics.totalWindows}'),
                      _buildStatItem('活跃', '${statistics.activeWindows}'),
                      _buildStatItem('会话', '${statistics.conversationCounts.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 窗口列表
          Text(
            '活跃窗口',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: windows.isEmpty
                ? const Center(
                    child: Text('暂无活跃窗口'),
                  )
                : ListView.builder(
                    itemCount: windows.length,
                    itemBuilder: (context, index) {
                      final window = windows[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: window.isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            child: Icon(
                              window.isReady ? Icons.window : Icons.hourglass_empty,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            window.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '会话: ${window.conversationId.substring(0, 8)}...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: PopupMenuButton<String>(
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Future<void> _organizeLayout() async {
    _toggleExpanded();
    
    try {
      // TODO: 实现布局整理逻辑
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('布局已整理'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('整理布局失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleWindowAction(EnhancedChatWindow window, String action) async {
    try {
      switch (action) {
        case 'focus':
          await _windowManager.focusWindow(window.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('窗口已聚焦')),
            );
          }
          break;
        case 'close':
          await _windowManager.closeChatWindow(window.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('窗口已关闭')),
            );
            Navigator.of(context).pop(); // 关闭对话框
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _WindowCountListener implements MultiWindowEventListener {
  final VoidCallback onUpdate;

  _WindowCountListener({required this.onUpdate});

  @override
  void onMultiWindowEvent(MultiWindowEvent event, EnhancedChatWindow window) {
    onUpdate();
  }
}