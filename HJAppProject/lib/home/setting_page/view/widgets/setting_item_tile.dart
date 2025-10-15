import 'package:flutter/material.dart';
import 'package:hjproject/home/setting_page/models/mine_setting.dart';

/// 通用的设置项列表组件，封装了不同 SettingType 的展示与交互：
/// - currentGroup / currentBook：展示副标题为当前选择项，点击触发选择逻辑
/// - accountOverview：展示账户概览信息，点击进入详情
/// - 其它类型：展示通用标题、副标题和图标，点击触发通用处理
class SettingItemTile extends StatelessWidget {
  final Setting element;
  final ValueChanged<Setting> onSelectSetting; // 针对 currentGroup/currentBook
  final ValueChanged<Setting> onTapSetting; // 其它通用点击

  const SettingItemTile({
    super.key,
    required this.element,
    required this.onSelectSetting,
    required this.onTapSetting,
  });

  @override
  Widget build(BuildContext context) {
    if (element.type == SettingType.currentGroup ||
        element.type == SettingType.currentBook) {
      final curItem = element.content;
      return Column(
        children: [
          ListTile(
            leading: element.leadingWidget ??
                Icon(
                  element.type == SettingType.currentGroup
                      ? Icons.group
                      : Icons.book,
                  color: Theme.of(context).primaryColor,
                ),
            title: Text(element.type.title),
            subtitle: Text(
              curItem ?? '未选择',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onSelectSetting(element),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
    }

    if (element.type == SettingType.accountOverview) {
      return Column(
        children: [
          ListTile(
            leading: element.leadingWidget ??
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                ),
            title: const Text('账户概览'),
            subtitle: element.detail != null
                ? Text(
                    element.detail!,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onTapSetting(element),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
    }

    return Column(
      children: [
        ListTile(
          leading: element.leadingWidget ??
              Icon(
                _iconForType(element.type),
                color: Theme.of(context).primaryColor,
              ),
          title: Text(element.type.title),
          subtitle: (element.content != null || element.detail != null)
              ? Text(
                  element.content ?? element.detail ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                )
              : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => onTapSetting(element),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  IconData _iconForType(SettingType type) {
    switch (type) {
      case SettingType.username:
        return Icons.person;
      case SettingType.accountOverview:
        return Icons.account_balance_wallet;
      case SettingType.currentGroup:
        return Icons.group;
      case SettingType.currentBook:
        return Icons.book;
      case SettingType.currentTheme:
        return Icons.color_lens;
      case SettingType.currentLanguage:
        return Icons.language;
      case SettingType.api:
        return Icons.api;
      case SettingType.currentVersion:
        return Icons.info;
      case SettingType.apiVersion:
        return Icons.cloud;
      default:
        return Icons.settings;
    }
  }
}