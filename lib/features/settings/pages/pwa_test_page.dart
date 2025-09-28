import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/pwa_provider.dart';
import '../../../shared/widgets/offline_indicator.dart';

/// PWA功能测试页面
class PWATestPage extends StatefulWidget {
  const PWATestPage({super.key});

  @override
  State<PWATestPage> createState() => _PWATestPageState();
}

class _PWATestPageState extends State<PWATestPage> {
  final TextEditingController _notificationTitleController = TextEditingController();
  final TextEditingController _notificationBodyController = TextEditingController();
  final TextEditingController _cacheKeyController = TextEditingController();
  final TextEditingController _cacheDataController = TextEditingController();
  
  String _cachedDataResult = '';

  @override
  void initState() {
    super.initState();
    _notificationTitleController.text = 'Kelivo 测试通知';
    _notificationBodyController.text = '这是一条测试通知消息';
    _cacheKeyController.text = 'test_data';
    _cacheDataController.text = '{"message": "Hello PWA!", "timestamp": "${DateTime.now().toIso8601String()}"}';
  }

  @override
  void dispose() {
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    _cacheKeyController.dispose();
    _cacheDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PWA测试'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.web, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'PWA功能仅在Web平台可用',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PWA功能测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<PWAProvider>(
        builder: (context, pwaProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态显示区域
                _buildStatusSection(pwaProvider),
                const SizedBox(height: 24),
                
                // 通知测试区域
                _buildNotificationSection(pwaProvider),
                const SizedBox(height: 24),
                
                // 缓存测试区域
                _buildCacheSection(pwaProvider),
                const SizedBox(height: 24),
                
                // 离线功能测试
                _buildOfflineSection(pwaProvider),
                const SizedBox(height: 24),
                
                // PWA功能测试
                _buildPWAFeaturesSection(pwaProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PWA状态',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow('网络状态', pwaProvider.isOnline ? '在线' : '离线', 
                pwaProvider.isOnline ? Colors.green : Colors.red),
            _buildStatusRow('安装状态', pwaProvider.isInstalled ? '已安装' : '未安装',
                pwaProvider.isInstalled ? Colors.green : Colors.orange),
            _buildStatusRow('更新状态', pwaProvider.updateAvailable ? '有更新' : '最新版本',
                pwaProvider.updateAvailable ? Colors.blue : Colors.green),
            _buildStatusRow('通知权限', pwaProvider.notificationPermissionGranted ? '已授权' : '未授权',
                pwaProvider.notificationPermissionGranted ? Colors.green : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '通知测试',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _notificationTitleController,
              decoration: const InputDecoration(
                labelText: '通知标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _notificationBodyController,
              decoration: const InputDecoration(
                labelText: '通知内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                if (!pwaProvider.notificationPermissionGranted)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _requestNotificationPermission(pwaProvider),
                      child: const Text('请求通知权限'),
                    ),
                  ),
                if (pwaProvider.notificationPermissionGranted) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _sendTestNotification(pwaProvider),
                      child: const Text('发送测试通知'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSection(PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '缓存测试',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _cacheKeyController,
              decoration: const InputDecoration(
                labelText: '缓存键',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _cacheDataController,
              decoration: const InputDecoration(
                labelText: '缓存数据 (JSON格式)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _testCacheData(pwaProvider),
                    child: const Text('缓存数据'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _testGetCachedData(pwaProvider),
                    child: const Text('读取缓存'),
                  ),
                ),
              ],
            ),
            
            if (_cachedDataResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '缓存结果:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cachedDataResult,
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildOfflineSection(PWAProvider pwaProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '离线功能测试',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const OfflineIndicator(),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () => _testOfflineAction(pwaProvider),
              child: const Text('模拟离线操作'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPWAFeaturesSection(PWAProvider pwaProvider) {
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
            
            ListTile(
              leading: const Icon(Icons.install_mobile),
              title: const Text('触发安装提示'),
              subtitle: const Text('显示PWA安装横幅'),
              trailing: ElevatedButton(
                onPressed: pwaProvider.isInstalled ? null : () => pwaProvider.triggerInstallPrompt(),
                child: Text(pwaProvider.isInstalled ? '已安装' : '显示'),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('强制刷新应用'),
              subtitle: const Text('重新加载应用'),
              trailing: ElevatedButton(
                onPressed: () => _confirmRefresh(pwaProvider),
                child: const Text('刷新'),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('清除所有缓存'),
              subtitle: const Text('删除所有本地缓存数据'),
              trailing: ElevatedButton(
                onPressed: () => _confirmClearCache(pwaProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('清除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestNotificationPermission(PWAProvider pwaProvider) async {
    final granted = await pwaProvider.requestNotificationPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? '通知权限已授权' : '通知权限被拒绝'),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _sendTestNotification(PWAProvider pwaProvider) async {
    await pwaProvider.showNotification(
      title: _notificationTitleController.text,
      body: _notificationBodyController.text,
      tag: 'test-notification',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('测试通知已发送'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _testCacheData(PWAProvider pwaProvider) async {
    try {
      final data = {
        'content': _cacheDataController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await pwaProvider.cacheData(_cacheKeyController.text, data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据已缓存'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('缓存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testGetCachedData(PWAProvider pwaProvider) async {
    try {
      final data = await pwaProvider.getCachedData(_cacheKeyController.text);
      
      setState(() {
        _cachedDataResult = data != null ? data.toString() : '未找到缓存数据';
      });
    } catch (e) {
      setState(() {
        _cachedDataResult = '读取失败: $e';
      });
    }
  }

  void _testOfflineAction(PWAProvider pwaProvider) async {
    await pwaProvider.saveOfflineAction(
      type: 'test_action',
      data: {
        'action': 'test',
        'message': '这是一个测试离线操作',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('离线操作已保存'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmRefresh(PWAProvider pwaProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认刷新'),
        content: const Text('这将重新加载整个应用，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              pwaProvider.refreshApp();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(PWAProvider pwaProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('确认清除缓存'),
          ],
        ),
        content: const Text('这将删除所有本地缓存数据，包括离线内容。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await pwaProvider.clearAllCache();
              if (mounted) {
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