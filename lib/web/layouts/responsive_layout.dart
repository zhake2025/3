import 'package:flutter/material.dart';
import '../../platform/detector/platform_detector.dart';
import '../../shared/responsive/breakpoints.dart';

/// 桌面布局组件
/// 为Web桌面环境提供专门的布局结构
class DesktopLayout extends StatefulWidget {
  final Widget child;
  final Widget? sidebar;
  final Widget? topBar;
  final List<Widget>? actions;
  final bool sidebarCollapsed;
  final VoidCallback? onSidebarToggle;

  const DesktopLayout({
    super.key,
    required this.child,
    this.sidebar,
    this.topBar,
    this.actions,
    this.sidebarCollapsed = false,
    this.onSidebarToggle,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  late bool _sidebarCollapsed;

  @override
  void initState() {
    super.initState();
    _sidebarCollapsed = widget.sidebarCollapsed;
  }

  @override
  void didUpdateWidget(DesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sidebarCollapsed != oldWidget.sidebarCollapsed) {
      _sidebarCollapsed = widget.sidebarCollapsed;
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
    widget.onSidebarToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = screenTypeForContext(context);

    // 在小屏幕上不使用桌面布局
    if (screenType == ScreenType.mobile) {
      return widget.child;
    }

    return Scaffold(
      body: Column(
        children: [
          if (widget.topBar != null) widget.topBar!,
          Expanded(
            child: Row(
              children: [
                // 侧边栏
                if (widget.sidebar != null) _buildSidebar(),

                // 主内容区域
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarWidth = _sidebarCollapsed ? 72.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: Column(
          children: [
            // 侧边栏头部
            _buildSidebarHeader(),

            // 侧边栏内容
            Expanded(child: widget.sidebar!),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!_sidebarCollapsed) ...[
            Text(
              'Kelivo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
          ],
          IconButton(
            onPressed: _toggleSidebar,
            icon: Icon(_sidebarCollapsed ? Icons.menu_open : Icons.menu),
            tooltip: _sidebarCollapsed ? '展开侧边栏' : '收起侧边栏',
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: widget.child,
    );
  }
}

/// 平板布局组件
/// 为平板设备提供适配的布局
class TabletLayout extends StatelessWidget {
  final Widget child;
  final Widget? navigationRail;
  final Widget? topBar;

  const TabletLayout({
    super.key,
    required this.child,
    this.navigationRail,
    this.topBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (topBar != null) topBar!,
          Expanded(
            child: Row(
              children: [
                if (navigationRail != null) navigationRail!,
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 响应式容器组件
/// 根据屏幕尺寸自动调整布局
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = screenTypeForContext(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    double containerMaxWidth;
    EdgeInsets containerPadding;

    switch (screenType) {
      case ScreenType.mobile:
        containerMaxWidth = screenWidth;
        containerPadding = const EdgeInsets.all(16);
        break;
      case ScreenType.tablet:
        containerMaxWidth = maxWidth ?? 900;
        containerPadding = const EdgeInsets.all(24);
        break;
      case ScreenType.desktop:
      case ScreenType.wide:
        containerMaxWidth = maxWidth ?? 1200;
        containerPadding = const EdgeInsets.all(32);
        break;
    }

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: containerMaxWidth),
      padding: padding ?? containerPadding,
      child: child,
    );

    if (centerContent && screenType != ScreenType.mobile) {
      content = Center(child: content);
    }

    return content;
  }
}

/// 多列网格布局组件
/// 根据屏幕尺寸自动调整列数
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = screenTypeForContext(context);

    int columns;
    switch (screenType) {
      case ScreenType.mobile:
        columns = mobileColumns ?? 1;
        break;
      case ScreenType.tablet:
        columns = tabletColumns ?? 2;
        break;
      case ScreenType.desktop:
      case ScreenType.wide:
        columns = desktopColumns ?? 3;
        break;
    }

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 1.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
