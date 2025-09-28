import 'package:flutter/material.dart';
import '../../../platform/detector/platform_detector.dart';
import '../../../platform/features/feature_flags.dart';
import '../../../web/services/pwa_service.dart';

/// 离线功能管理页面
/// 提供离线功能的配置和状态查看
class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  bool _isOnline = true;
  bool _offlineEnabled = false;
  CacheInfo _cacheInfo = const CacheInfo(used: 0, available: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeOfflineStatus();
    _loadCacheInfo();
    _listenToNetworkStatus();
  }

  void _initializeOfflineStatus() {
    if (!PlatformDetector.isWeb) return;

    setState(() {
      _offlineEnabled = FeatureFlags.shouldEnableOfflineFeatures;
      _isOnline = !PWAService.instance.isOffline();
    });
  }

  Future<void> _loadCacheInfo() async {
    if (!_offlineEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cacheInfo = await PWAService.instance.getCacheInfo();
      setState(() {
        _cacheInfo = cacheInfo;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenToNetworkStatus() {
    PWAService.instance.networkStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  Future<void> _clearCache() async {
    if (!_offlineEnabled) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存数据吗？这将删除所有离线可用的内容。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PWAService.instance.clearCache();
        await _loadCacheInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('缓存已清除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('清除缓存失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isWeb) {
      return _buildNotSupportedView();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('离线功能'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadCacheInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusSection(),
              const SizedBox(height: 32),
              if (_offlineEnabled) ...[
                _buildCacheSection(),
                const SizedBox(height: 32),
                _buildFeaturesSection(),
                const SizedBox(height: 32),
                _buildManagementSection(),
              ] else
                _buildDisabledSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotSupportedView() {
    return Scaffold(
      appBar: AppBar(title: const Text('离线功能')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '离线功能仅在Web浏览器中可用',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '网络状态',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isOnline ? '已连接' : '离线模式',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _isOnline ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isOnline ? '在线' : '离线',
                    style: TextStyle(
                      color: _isOnline ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isOnline) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '当前处于离线模式，某些功能可能受限',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '缓存使用情况',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildCacheProgressBar(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已使用',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _cacheInfo.usedFormatted,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '总容量',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _cacheInfo.availableFormatted,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheProgressBar() {
    final percentage = _cacheInfo.usagePercentage;

    return Column(
      children: [
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 80
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${percentage.toStringAsFixed(1)}% 已使用',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.offline_pin,
        'title': '离线聊天记录',
        'description': '查看已缓存的聊天记录',
        'enabled': true,
      },
      {
        'icon': Icons.sync,
        'title': '自动同步',
        'description': '网络恢复时自动同步数据',
        'enabled': true,
      },
      {
        'icon': Icons.save,
        'title': '离线草稿',
        'description': '离线时保存未发送的消息',
        'enabled': true,
      },
      {
        'icon': Icons.cached,
        'title': '智能缓存',
        'description': '自动缓存常用功能和数据',
        'enabled': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '离线功能',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              final isLast = index == features.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: feature['enabled'] as bool
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['enabled'] as bool
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(feature['description'] as String),
                    trailing: feature['enabled'] as bool
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : Icon(
                            Icons.schedule,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '缓存管理',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('刷新缓存'),
                subtitle: const Text('重新加载缓存信息'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _loadCacheInfo,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('清除缓存', style: TextStyle(color: Colors.red)),
                subtitle: const Text('删除所有离线缓存数据'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearCache,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '离线功能未启用',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '当前环境不支持离线功能，或者该功能已被禁用',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
