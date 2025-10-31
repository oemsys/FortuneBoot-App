import 'package:flutter/material.dart';
import 'package:hjproject/home/setting_page/models/mine_setting.dart';

/// 通用的设置项列表组件，封装了不同 SettingType 的展示与交互：
/// - currentGroup / currentBook：展示副标题为当前选择项，点击触发选择逻辑
/// - accountOverview：展示账户概览信息，点击进入详情
/// - 其它类型：展示通用标题、副标题和图标，点击触发通用处理
class SettingItemTile extends StatefulWidget {
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
  State<SettingItemTile> createState() => _SettingItemTileState();
}

class _SettingItemTileState extends State<SettingItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _animationController.forward();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTile(context);
  }

  Widget _buildTile(BuildContext context) {
    final element = widget.element;
    if (element.type == SettingType.currentGroup ||
        element.type == SettingType.currentBook) {
      final curItem = element.content;
      return _buildTileWithAnimation(
        context,
        leading: element.leadingWidget ??
            Icon(
              element.type == SettingType.currentGroup
                  ? Icons.group
                  : Icons.book,
              color: Theme.of(context).primaryColor,
            ),
        title: element.type.title,
        subtitle: curItem ?? '未选择',
        onTap: () => widget.onSelectSetting(element),
      );
    }

    if (element.type == SettingType.accountOverview) {
      return _buildTileWithAnimation(
        context,
        leading: element.leadingWidget ??
            Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).primaryColor,
            ),
        title: '账户概览',
        subtitle: element.detail,
        onTap: () => widget.onTapSetting(element),
      );
    }

    return _buildTileWithAnimation(
      context,
      leading: element.leadingWidget ??
          Icon(
            _iconForType(element.type),
            color: Theme.of(context).primaryColor,
          ),
      title: element.type.title,
      subtitle: element.content ?? element.detail,
      onTap: () => widget.onTapSetting(element),
    );
  }

  Widget _buildTileWithAnimation(
    BuildContext context, {
    required Widget leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
              },
              onExit: (_) {
                setState(() => _isHovered = false);
              },
              child: GestureDetector(
                onTapDown: (_) => _onTapDown(),
                onTapCancel: _onTapCancel,
                onTap: () {
                  _onTapCancel();
                  onTap();
                },
                child: Container(
                  color: _isHovered
                      ? Colors.grey[100]
                      : Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: leading,
                    title: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: subtitle != null
                        ? Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 56,
          endIndent: 16,
          color: Colors.grey[200],
        ),
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
