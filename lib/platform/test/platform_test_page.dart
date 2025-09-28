import 'package:flutter/material.dart';
import '../detector/platform_detector.dart';
import '../features/feature_flags.dart';
import '../../web/services/pwa_service.dart';
import '../../features/pwa/pages/pwa_install_page.dart';
import '../../features/pwa/pages/offline_page.dart';

/// 平台架构测试页面
/// 用于验证新架构的各个组件是否正常工作
class PlatformTestPage extends StatefulWidget {
  const PlatformTestPage({super.key});

  @override
  State<PlatformTestPage> createState() => _PlatformTestPageState();
}

class _PlatformTestPageState extends State<PlatformTestPage> {
  Map<String, dynamic> _platformInfo = {};
  Map<String, bool> _featureFlags = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlatformInfo();
    _initializePWAService();
  }

  void _initializePlatformInfo() {
    setState(() {
      _platformInfo = {
        'platform_name': PlatformDetector.platformName,
        'platform_type': PlatformDetector.currentPlatform.name,
        'is_mobile': PlatformDetector.isMobile,
        'is_tablet': PlatformDetector.isTablet,
        'is_desktop': PlatformDetector.isDesktop,
        'is_web': PlatformDetector.isWeb,
        'is_native_mobile': PlatformDetector.isNativeMobile,
        'is_native_desktop': PlatformDetector.isNativeDesktop,
      };

      _featureFlags = FeatureFlags.getPlatformFeatures();
    });
  }

  Future<void> _initializePWAService() async {
    if (PlatformDetector.isWeb) {
      await PWAService.instance.initialize();
    }
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('平台架构测试'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              PlatformDetector.printPlatformInfo();
              FeatureFlags.printFeatureStatus();
            },
            icon: const Icon(Icons.bug_report),
            tooltip: '打印调试信息',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformInfoSection(),
            const SizedBox(height: 24),
            _buildFeatureFlagsSection(),
            const SizedBox(height: 24),
            _buildPWAFeaturesSection(),
            const SizedBox(height: 24),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.devices,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '平台信息',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._platformInfo.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        _formatKey(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getValueColor(entry.value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureFlagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '功能标志',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._featureFlags.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.cancel,
                      color: entry.value ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatKey(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      entry.value ? '启用' : '禁用',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: entry.value ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPWAFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.web, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'PWA 功能',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!PlatformDetector.isWeb)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PWA功能仅在Web环境下可用',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _buildFeatureRow(
                    'PWA服务初始化',
                    _isInitialized,
                    description: '基础PWA服务的初始化状态',
                  ),
                  _buildFeatureRow(
                    '安装提示',
                    FeatureFlags.shouldShowInstallPrompt,
                    description: '是否显示PWA安装提示',
                  ),
                  _buildFeatureRow(
                    '离线功能',
                    FeatureFlags.shouldEnableOfflineFeatures,
                    description: '离线数据存储和缓存功能',
                  ),
                  _buildFeatureRow(
                    '推送通知',
                    FeatureFlags.shouldEnablePushNotifications,
                    description: '浏览器推送通知支持',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title, bool enabled, {String? description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: enabled ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (description != null)
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            enabled ? '✓' : '✗',
            style: TextStyle(
              color: enabled ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '测试功能',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (PlatformDetector.isWeb) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PWAInstallPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.install_mobile),
                  label: const Text('PWA 安装页面'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfflinePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.offline_bolt),
                  label: const Text('离线功能页面'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showCapabilitiesDialog();
                },
                icon: const Icon(Icons.info),
                label: const Text('平台能力详情'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  Color _getValueColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  void _showCapabilitiesDialog() {
    final capabilities = PlatformDetector.getAllCapabilities();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('平台能力详情'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: capabilities.entries.map((entry) {
              return ListTile(
                dense: true,
                leading: Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  color: entry.value ? Colors.green : Colors.red,
                  size: 20,
                ),
                title: Text(
                  _formatKey(entry.key.toString().split('.').last),
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Text(
                  entry.value ? '支持' : '不支持',
                  style: TextStyle(
                    color: entry.value ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
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
}
