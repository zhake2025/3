import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/pwa_provider.dart';
import '../../../shared/widgets/offline_indicator.dart';

/// PWA设置页面
class PWASettingsPage extends StatelessWidget {
  const PWASettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PWA设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<PWAProvider>(
        builder: (context, pwaProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 应用状态卡片
                _buildStatusCard(context, pwaProvider),
                const SizedBox(height: 16),
                
                // 功能设置
                _buildFeaturesSection(context, pwaProvider),
                const SizedBox(height: 16),
                
                // 离线功能
                _buildOfflineFeaturesSection(context, pwaProvider),
                const SizedBox(height: 16),
                
                // 缓存管理
                _buildCacheManagementSection(context, pwaProvider),
                const SizedBox(height: 16),
                
                // 关于PWA
                _buildAboutSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.web,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'PWA状态',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 网络状态
            _buildStatusItem(
              context,
              '网络连接',
              pwaProvider.isOnline ? '在线' : '离线',
              pwaProvider.isOnline ? Colors.green : Colors.red,
              pwaProvider.isOnline ? Icons.wifi : Icons.wifi_off,
            ),
            
            // 安装状态
            _buildStatusItem(
              context,
              '安装状态',
              pwaProvider.isInstalled ? '已安装' : '未安装',
              pwaProvider.isInstalled ? Colors.green : Colors.orange,
              pwaProvider.isInstalled ? Icons.check_circle : Icons.download,
            ),
            
            // 更新状态
            _buildStatusItem(
              context,
              '应用版本',
              pwaProvider.updateAvailable ? '有更新' : '最新版本',
              pwaProvider.updateAvailable ? Colors.blue : Colors.green,
              pwaProvider.updateAvailable ? Icons.system_update : Icons.check,
            ),
            
            // 通知权限
            _buildStatusItem(
              context,
              '通知权限',
              pwaProvider.notificationPermissionGranted ? '已授权' : '未授权',
              pwaProvider.notificationPermissionGranted ? Colors.green : Colors.grey,
              pwaProvider.notificationPermissionGranted ? Icons.notifications : Icons.notifications_off,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PWA功能',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 安装应用
            if (!pwaProvider.isInstalled)
              ListTile(
                leading: const Icon(Icons.install_mobile),
                title: const Text('安装到桌面'),
                subtitle: const Text('获得原生应用般的体验'),
                trailing: ElevatedButton(
                  onPressed: () => pwaProvider.triggerInstallPrompt(),
                  child: const Text('安装'),
                ),
              ),
            
            // 通知权限
            if (!pwaProvider.notificationPermissionGranted)
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('启用通知'),
                subtitle: const Text('接收重要消息和更新提醒'),
                trailing: ElevatedButton(
                  onPressed: () => _requestNotificationPermission(context, pwaProvider),
                  child: const Text('启用'),
                ),
              ),
            
            // 应用更新
            if (pwaProvider.updateAvailable)
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('更新应用'),
                subtitle: const Text('发现新版本，建议立即更新'),
                trailing: ElevatedButton(
                  onPressed: () => _showUpdateDialog(context, pwaProvider),
                  child: const Text('更新'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineFeaturesSection(BuildContext context, PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '离线功能',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            OfflineFeatureCard(
              title: '离线聊天',
              description: '查看已缓存的对话记录',
              icon: Icons.chat,
              isAvailable: true,
              onTap: () => _showFeatureInfo(context, '离线聊天', '您可以查看之前的对话记录，但无法发送新消息。'),
            ),
            
            const SizedBox(height: 8),
            
            OfflineFeatureCard(
              title: '文档查看',
              description: '访问已下载的文档',
              icon: Icons.description,
              isAvailable: true,
              onTap: () => _showFeatureInfo(context, '文档查看', '已缓存的文档可以离线查看和搜索。'),
            ),
            
            const SizedBox(height: 8),
            
            OfflineFeatureCard(
              title: 'AI对话',
              description: '需要网络连接',
              icon: Icons.psychology,
              isAvailable: pwaProvider.isOnline,
              onTap: pwaProvider.isOnline ? null : () => _showNetworkRequiredDialog(context),
            ),
            
            const SizedBox(height: 8),
            
            OfflineFeatureCard(
              title: '文件上传',
              description: '需要网络连接',
              icon: Icons.upload_file,
              isAvailable: pwaProvider.isOnline,
              onTap: pwaProvider.isOnline ? null : () => _showNetworkRequiredDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheManagementSection(BuildContext context, PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '缓存管理',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('缓存大小'),
              subtitle: const Text('约 15.2 MB'),
              trailing: TextButton(
                onPressed: () => _showCacheInfo(context),
                child: const Text('详情'),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('清除缓存'),
              subtitle: const Text('清除所有离线数据和缓存'),
              trailing: TextButton(
                onPressed: () => _showClearCacheDialog(context, pwaProvider),
                child: const Text('清除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关于PWA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Progressive Web App (PWA) 是一种使用现代Web技术构建的应用程序，'
              '它结合了Web和原生应用的最佳特性，提供快速、可靠、引人入胜的用户体验。',
              style: TextStyle(height: 1.5),
            ),
            
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('离线访问'),
                _buildFeatureChip('快速加载'),
                _buildFeatureChip('推送通知'),
                _buildFeatureChip('安装到桌面'),
                _buildFeatureChip('自动更新'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue.withOpacity(0.1),
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }

  void _requestNotificationPermission(BuildContext context, PWAProvider pwaProvider) async {
    final granted = await pwaProvider.requestNotificationPermission();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? '通知权限已授权' : '通知权限被拒绝'),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showUpdateDialog(BuildContext context, PWAProvider pwaProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新应用'),
        content: const Text('发现新版本，是否立即更新？更新过程中应用将重新加载。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              pwaProvider.refreshApp();
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  void _showFeatureInfo(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  void _showNetworkRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('需要网络连接'),
          ],
        ),
        content: const Text('此功能需要网络连接才能使用，请检查您的网络设置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  void _showCacheInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存详情'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('应用资源: 8.5 MB'),
            Text('对话记录: 4.2 MB'),
            Text('文档缓存: 2.1 MB'),
            Text('图片缓存: 0.4 MB'),
            SizedBox(height: 16),
            Text(
              '缓存可以让应用在离线时正常工作，但会占用设备存储空间。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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

  void _showClearCacheDialog(BuildContext context, PWAProvider pwaProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('清除缓存'),
          ],
        ),
        content: const Text(
          '这将清除所有离线数据和缓存，包括对话记录、文档等。'
          '清除后需要重新下载内容才能离线使用。\n\n'
          '确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await pwaProvider.clearAllCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('缓存已清除'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定清除'),
          ),
        ],
      ),
    );
  }
}