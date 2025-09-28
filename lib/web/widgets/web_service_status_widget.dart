import 'package:flutter/material.dart';
import '../services/web_service_registry.dart';

/// Web服务状态显示组件
/// 用于调试和监控Web服务的运行状态
class WebServiceStatusWidget extends StatefulWidget {
  const WebServiceStatusWidget({super.key});

  @override
  State<WebServiceStatusWidget> createState() => _WebServiceStatusWidgetState();
}

class _WebServiceStatusWidgetState extends State<WebServiceStatusWidget> {
  Map<String, dynamic>? _serviceHealth;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkServiceHealth();
  }
  
  Future<void> _checkServiceHealth() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final health = await WebServiceRegistry.instance.checkServiceHealth();
      setState(() {
        _serviceHealth = health;
      });
    } catch (e) {
      setState(() {
        _serviceHealth = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Web服务状态',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: _isLoading ? null : _checkServiceHealth,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_serviceHealth == null)
              const Center(child: CircularProgressIndicator())
            else if (_serviceHealth!.containsKey('error'))
              _buildErrorWidget(_serviceHealth!['error'])
            else
              _buildServiceList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '错误: $error',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceList() {
    return Column(
      children: _serviceHealth!.entries.map((entry) {
        if (entry.key == 'error') return const SizedBox.shrink();
        
        final serviceName = entry.key;
        final serviceData = entry.value as Map<String, dynamic>;
        final isInitialized = serviceData['initialized'] as bool? ?? false;
        
        return _buildServiceItem(serviceName, serviceData, isInitialized);
      }).toList(),
    );
  }
  
  Widget _buildServiceItem(String serviceName, Map<String, dynamic> data, bool isInitialized) {
    final displayName = _getServiceDisplayName(serviceName);
    final statusColor = isInitialized ? Colors.green : Colors.red;
    final statusIcon = isInitialized ? Icons.check_circle : Icons.error;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isInitialized ? '运行中' : '未初始化',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (data.length > 1) ...[
            const SizedBox(height: 8),
            _buildServiceDetails(data),
          ],
        ],
      ),
    );
  }
  
  Widget _buildServiceDetails(Map<String, dynamic> data) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: data.entries
          .where((entry) => entry.key != 'initialized')
          .map((entry) => _buildDetailChip(entry.key, entry.value))
          .toList(),
    );
  }
  
  Widget _buildDetailChip(String key, dynamic value) {
    String displayValue;
    Color chipColor;
    
    if (value is bool) {
      displayValue = value ? '是' : '否';
      chipColor = value ? Colors.green : Colors.orange;
    } else if (value is int) {
      displayValue = value.toString();
      chipColor = Colors.blue;
    } else {
      displayValue = value.toString();
      chipColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        '${_getDetailDisplayName(key)}: $displayValue',
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
        ),
      ),
    );
  }
  
  String _getServiceDisplayName(String serviceName) {
    switch (serviceName) {
      case 'multiWindowManager':
        return '多窗口管理器';
      case 'offlineSyncManager':
        return '离线同步管理器';
      case 'pushNotificationService':
        return '推送通知服务';
      case 'themeManager':
        return '主题管理器';
      case 'todoService':
        return '待办事项服务';
      case 'pwaService':
        return 'PWA服务';
      default:
        return serviceName;
    }
  }
  
  String _getDetailDisplayName(String key) {
    switch (key) {
      case 'active':
        return '活跃状态';
      case 'online':
        return '在线状态';
      case 'hasPermission':
        return '权限状态';
      case 'currentTheme':
        return '当前主题';
      case 'todoCount':
        return '待办数量';
      case 'isInstallable':
        return '可安装';
      default:
        return key;
    }
  }
}