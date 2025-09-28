import 'package:flutter/material.dart';
import '../../platform/detector/platform_detector.dart';
import '../../platform/features/feature_flags.dart';

/// 离线指示器组件
/// 显示网络连接状态和离线模式提示
class OfflineIndicator extends StatefulWidget {
  /// 离线时显示的消息
  final String offlineMessage;

  /// 在线时显示的消息
  final String onlineMessage;

  /// 是否显示详细状态
  final bool showDetails;

  /// 自定义样式
  final IndicatorStyle? style;

  const OfflineIndicator({
    super.key,
    this.offlineMessage = '当前处于离线模式',
    this.onlineMessage = '网络连接正常',
    this.showDetails = false,
    this.style,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  bool _isOfflineModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeNetworkStatus();
  }

  void _initializeNetworkStatus() {
    if (!PlatformDetector.isWeb) return;

    _isOfflineModeEnabled = FeatureFlags.shouldEnableOfflineFeatures;

    // TODO: 实现网络状态监听
    // 监听online/offline事件
    _checkNetworkStatus();
  }

  void _checkNetworkStatus() {
    // TODO: 实现实际的网络状态检测
    // 可以使用navigator.onLine或connectivity_plus包
    setState(() {
      _isOnline = true; // 暂时设为true
    });
  }

  void _toggleOfflineMode() {
    setState(() {
      _isOnline = !_isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOfflineModeEnabled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final style = widget.style ?? IndicatorStyle.defaultStyle(theme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isOnline ? 0 : null,
      child: _isOnline ? null : _buildOfflineBar(context, style),
    );
  }

  Widget _buildOfflineBar(BuildContext context, IndicatorStyle style) {
    return Container(
      width: double.infinity,
      padding: style.padding,
      color: style.backgroundColor,
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: style.iconColor,
            size: style.iconSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOnline ? widget.onlineMessage : widget.offlineMessage,
                  style: style.titleStyle,
                ),
                if (widget.showDetails && !_isOnline) ...[
                  const SizedBox(height: 4),
                  Text('部分功能可能受限，数据将在恢复连接后同步', style: style.detailStyle),
                ],
              ],
            ),
          ),
          if (widget.showDetails) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _checkNetworkStatus,
              icon: Icon(
                Icons.refresh,
                color: style.iconColor,
                size: style.iconSize,
              ),
              tooltip: '检查网络状态',
            ),
          ],
        ],
      ),
    );
  }
}

/// 指示器样式配置
class IndicatorStyle {
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;
  final TextStyle titleStyle;
  final TextStyle detailStyle;
  final EdgeInsets padding;

  const IndicatorStyle({
    required this.backgroundColor,
    required this.iconColor,
    required this.iconSize,
    required this.titleStyle,
    required this.detailStyle,
    required this.padding,
  });

  factory IndicatorStyle.defaultStyle(ThemeData theme) {
    return IndicatorStyle(
      backgroundColor: theme.colorScheme.errorContainer,
      iconColor: theme.colorScheme.onErrorContainer,
      iconSize: 20,
      titleStyle: theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onErrorContainer,
        fontWeight: FontWeight.w500,
      ),
      detailStyle: theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  factory IndicatorStyle.warning(ThemeData theme) {
    return IndicatorStyle(
      backgroundColor: const Color(0xFFFFF3CD),
      iconColor: const Color(0xFF856404),
      iconSize: 20,
      titleStyle: theme.textTheme.bodyMedium!.copyWith(
        color: const Color(0xFF856404),
        fontWeight: FontWeight.w500,
      ),
      detailStyle: theme.textTheme.bodySmall!.copyWith(
        color: const Color(0xFF856404).withOpacity(0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
