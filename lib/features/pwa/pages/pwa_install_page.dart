import 'package:flutter/material.dart';
import '../../../platform/detector/platform_detector.dart';
import '../../../platform/features/feature_flags.dart';
import '../../../web/services/pwa_service.dart';

/// PWA安装页面
/// 提供PWA安装引导和管理功能
class PWAInstallPage extends StatefulWidget {
  const PWAInstallPage({super.key});

  @override
  State<PWAInstallPage> createState() => _PWAInstallPageState();
}

class _PWAInstallPageState extends State<PWAInstallPage> {
  bool _isInstalling = false;
  bool _isInstalled = false;
  bool _canInstall = false;

  @override
  void initState() {
    super.initState();
    _checkInstallStatus();
    _listenToInstallPrompt();
  }

  void _checkInstallStatus() {
    if (!PlatformDetector.isWeb) return;

    setState(() {
      _isInstalled = PWAService.instance.isPWAInstalled();
      _canInstall = FeatureFlags.shouldShowInstallPrompt && !_isInstalled;
    });
  }

  void _listenToInstallPrompt() {
    PWAService.instance.installPromptStream.listen((available) {
      if (mounted) {
        setState(() {
          _canInstall = available && !_isInstalled;
        });
      }
    });
  }

  Future<void> _installPWA() async {
    if (_isInstalling || !_canInstall) return;

    setState(() {
      _isInstalling = true;
    });

    try {
      final success = await PWAService.instance.installPWA();
      if (success) {
        setState(() {
          _isInstalled = true;
          _canInstall = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('应用安装成功！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('安装失败，请稍后重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInstalling = false;
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
      appBar: AppBar(title: const Text('PWA 安装'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildInstallSection(),
            const SizedBox(height: 32),
            _buildFeaturesSection(),
            const SizedBox(height: 32),
            _buildInstructionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSupportedView() {
    return Scaffold(
      appBar: AppBar(title: const Text('PWA 安装')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'PWA功能仅在Web浏览器中可用',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.install_mobile,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '安装 Kelivo PWA',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '获得类似原生应用的体验',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildInstallSection() {
    if (_isInstalled) {
      return _buildInstalledCard();
    } else if (_canInstall) {
      return _buildInstallCard();
    } else {
      return _buildUnavailableCard();
    }
  }

  Widget _buildInstalledCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              '应用已安装',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelivo PWA 已成功安装到您的设备上',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.download_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '立即安装',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '将 Kelivo 添加到您的主屏幕，享受更快的启动速度和离线访问',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isInstalling ? null : _installPWA,
                icon: _isInstalling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.install_mobile),
                label: Text(_isInstalling ? '安装中...' : '安装到设备'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂时无法安装',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '您的浏览器暂时不支持PWA安装，或者应用已经安装',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.offline_bolt,
        'title': '离线访问',
        'description': '无需网络连接即可使用核心功能',
      },
      {'icon': Icons.speed, 'title': '快速启动', 'description': '比网页版启动更快，体验更流畅'},
      {
        'icon': Icons.notifications,
        'title': '推送通知',
        'description': '及时接收重要消息和更新提醒',
      },
      {
        'icon': Icons.mobile_friendly,
        'title': '原生体验',
        'description': '类似原生应用的界面和交互体验',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PWA 功能特性',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        feature['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '手动安装指南',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep(
                  '1',
                  'Chrome 浏览器',
                  '点击地址栏右侧的安装图标，或使用菜单中的\"安装 Kelivo\"选项',
                ),
                const Divider(),
                _buildInstructionStep(
                  '2',
                  'Safari 浏览器',
                  '点击分享按钮，然后选择\"添加到主屏幕\"',
                ),
                const Divider(),
                _buildInstructionStep(
                  '3',
                  'Edge 浏览器',
                  '点击地址栏右侧的应用图标，选择\"安装此站点为应用\"',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(
    String step,
    String browser,
    String instruction,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                step,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  browser,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(instruction, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
