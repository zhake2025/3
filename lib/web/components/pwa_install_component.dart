import 'package:flutter/material.dart';
import '../../platform/detector/platform_detector.dart';
import '../../platform/features/feature_flags.dart';

/// PWA安装组件
/// 处理PWA应用的安装和安装提示
class PWAInstallComponent extends StatefulWidget {
  /// 自定义安装按钮样式
  final Widget? customButton;

  /// 安装成功回调
  final VoidCallback? onInstallSuccess;

  /// 安装失败回调
  final VoidCallback? onInstallFailed;

  /// 是否自动显示安装提示
  final bool autoPrompt;

  const PWAInstallComponent({
    super.key,
    this.customButton,
    this.onInstallSuccess,
    this.onInstallFailed,
    this.autoPrompt = true,
  });

  @override
  State<PWAInstallComponent> createState() => _PWAInstallComponentState();
}

class _PWAInstallComponentState extends State<PWAInstallComponent> {
  bool _canInstall = false;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _checkInstallability();
  }

  void _checkInstallability() {
    if (!PlatformDetector.isWeb || !FeatureFlags.shouldShowInstallPrompt) {
      return;
    }

    // TODO: 实现PWA安装检测逻辑
    // 检查beforeinstallprompt事件和navigator.standalone
    setState(() {
      _canInstall = FeatureFlags.shouldShowInstallPrompt;
    });
  }

  Future<void> _installPWA() async {
    if (!_canInstall || _isInstalling) return;

    setState(() {
      _isInstalling = true;
    });

    try {
      // TODO: 实现PWA安装逻辑
      // 调用deferredPrompt.prompt()
      await Future.delayed(const Duration(seconds: 1)); // 模拟安装过程

      widget.onInstallSuccess?.call();
      setState(() {
        _canInstall = false;
      });
    } catch (e) {
      widget.onInstallFailed?.call();
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canInstall) {
      return const SizedBox.shrink();
    }

    if (widget.customButton != null) {
      return GestureDetector(onTap: _installPWA, child: widget.customButton!);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.download_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('安装应用', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '添加到主屏幕以获得更好的体验',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isInstalling ? null : _installPWA,
              child: _isInstalling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('安装'),
            ),
          ],
        ),
      ),
    );
  }
}
