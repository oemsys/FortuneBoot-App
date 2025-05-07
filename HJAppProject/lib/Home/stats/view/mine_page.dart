import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/post/post_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/stats_bloc.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Home/stats/models/setting_select_item.dart';
import 'package:flutter_login_example/Home/stats/view/drop_down_animate.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/group_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:todos_repository/todos_repository.dart';
import '../../../generated/l10n.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:intl/intl.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingBloc(
        billsRepository: context.read<BillsRepository>(),
      )..add(SettingInitDataLoaded()),
      child: const MineView(),
    );
  }
}

class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class CustomOverlayController extends OverlayPortalController {
  final ValueNotifier<bool> _isShowing = ValueNotifier(false);

  void show() {
    if (_isShowing.value) return;
    _isShowing.value = true;
    super.show();
  }

  void hide() {
    if (!_isShowing.value) return;
    _isShowing.value = false;
    super.hide();
  }

  void toggle() {
    if (_isShowing.value) {
      hide();
    } else {
      show();
    }
  }

  void addListener(VoidCallback listener) => _isShowing.addListener(listener);
}

class _MineViewState extends State<MineView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        print('lxjtodo:焦点已获取'); // 触发获取焦点的逻辑
      } else {
        print('lxjtodo:焦点已失去'); // 触发失去焦点的逻辑
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingBloc>().state;
    var elements = [
      ...state.settings,
      ...state.remoteSettings,
      ...state.groupSettings
    ];
    Setting.sortList(elements);

    // 拉取账本信息
    context.read<SettingBloc>().add(GroupSettingFetched());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(S.current.mine),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(context, elements),
            const SizedBox(height: 12),
            _buildSettingsGroups(context, elements),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, List<Setting> elements) {
    // 查找用户名设置项
    final usernameSetting = elements.firstWhere(
      (element) => element.type == SettingType.username,
      orElse: () => const Setting(SettingType.username, content: '未登录用户'),
    );

    final username = usernameSetting.content ?? '未登录用户';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              username.isNotEmpty
                  ? username.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    // 跳转到个人资料页面
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('敬请期待...')),
                    );
                  },
                  child: Row(
                    children: [
                      const Text(
                        '查看个人资料',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            onPressed: () {
              // 显示二维码
              _showQRCode(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroups(BuildContext context, List<Setting> elements) {
    // 将设置项分组
    final accountSettings = elements
        .where((e) =>
            e.type == SettingType.currentGroup ||
            e.type == SettingType.currentBook ||
            e.type == SettingType.accountOverview)
        .toList();

    final appSettings = elements
        .where((e) =>
            e.type == SettingType.currentTheme ||
            e.type == SettingType.currentLanguage)
        .toList();

    final aboutSettings = elements
        .where((e) =>
            e.type == SettingType.api ||
            e.type == SettingType.currentVersion ||
            e.type == SettingType.apiVersion)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accountSettings.isNotEmpty) ...[
          _buildSettingGroup(context, '账户设置', accountSettings),
          const SizedBox(height: 16),
        ],
        if (appSettings.isNotEmpty) ...[
          _buildSettingGroup(context, '应用设置', appSettings),
          const SizedBox(height: 16),
        ],
        if (aboutSettings.isNotEmpty) ...[
          _buildSettingGroup(context, '关于', aboutSettings),
          const SizedBox(height: 16),
        ],
        _buildAdditionalOptions(context),
      ],
    );
  }

  Widget _buildSettingGroup(
      BuildContext context, String title, List<Setting> settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const Divider(height: 1),
          ...settings
              .map((setting) => _getSettingItem(context, setting))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading:
                Icon(Icons.feedback, color: Theme.of(context).primaryColor),
            title: const Text('意见反馈'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 跳转到意见反馈页面
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.star, color: Theme.of(context).primaryColor),
            title: const Text('给应用评分'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 跳转到应用商店评分
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _getSettingItem(BuildContext context, Setting element) {
    final textTheme = Theme.of(context).textTheme;

    if (element.type == SettingType.currentGroup ||
        element.type == SettingType.currentBook) {
      var curItem = element.content;

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
            subtitle: Text(curItem ?? '未选择',
                style: TextStyle(color: Colors.grey[600])),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showSelectionDialog(context, element);
            },
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
                Icon(Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor),
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
            onTap: () {
              // 跳转到账户概览详情页
            },
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
                _getIconForSettingType(element.type),
                color: Theme.of(context).primaryColor,
              ),
          title: Text(element.type.title),
          subtitle: element.content != null || element.detail != null
              ? Text(
                  element.content ?? element.detail ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                )
              : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // 处理点击事件
            _handleSettingTap(context, element);
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  IconData _getIconForSettingType(SettingType type) {
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

  void _handleSettingTap(BuildContext context, Setting element) {
    switch (element.type) {
      case SettingType.currentTheme:
        _showThemeSelectionDialog(context);
        break;
      case SettingType.currentLanguage:
        _showLanguageSelectionDialog(context);
        break;
      case SettingType.api:
        _showApiSettingDialog(context, element);
        break;
      default:
        // 显示详情对话框
        _showSettingDetailDialog(context, element);
        break;
    }
  }

  void _showSelectionDialog(BuildContext context, Setting element) async {
    List<DropdownItem<SettingSelectItem>> items = [];

    if (element.type == SettingType.currentGroup) {
      GroupService groupService = GroupService();
      var res = await groupService.getEnableList();
      if (res.code == 0) {
        var remoteList = res.data as List? ?? [];
        for (final remoteItem in remoteList) {
          var remoteGroupName = remoteItem['groupName'] as String? ?? '';
          bool selected = remoteGroupName == element.content;
          var groupId = remoteItem['groupId'] as int? ?? 0;
          items.add(DropdownItem(
            label: remoteGroupName,
            value: SettingSelectItem(remoteGroupName, groupId),
            selected: selected,
          ));
        }
      }
    } else if (element.type == SettingType.currentBook) {
      BookService bookService = BookService();
      var remoteBookResponse =
          await bookService.getByGroupId(element.data!['groupId'] as int? ?? 0);
      if (remoteBookResponse.code == 0) {
        var remoteBookList = remoteBookResponse.data as List? ?? [];
        for (final remoteBookItem in remoteBookList) {
          var remoteBookName = remoteBookItem['bookName'] as String? ?? '';
          bool selected = remoteBookName == element.content;
          items.add(
            DropdownItem(
              label: remoteBookName,
              value: SettingSelectItem(
                remoteBookName,
                remoteBookItem['bookId'] as int? ?? 0,
              ),
              selected: selected,
            ),
          );
        }
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可选项')),
      );
      return;
    }
    var settingBloc = context.read<SettingBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择${element.type.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.label),
                    trailing: item.selected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (element.type == SettingType.currentGroup) {
                        settingBloc.add(
                          GroupSettingFetched(groupId: item.value.id),
                        );
                      } else if (element.type == SettingType.currentBook) {
                        settingBloc.add(
                          BookIdChanged(item.value.id),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final themes = ['跟随系统', '浅色模式', '深色模式'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择主题',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ...themes.map((theme) => ListTile(
                  title: Text(theme),
                  trailing: theme == '跟随系统'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    // 应用主题
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已切换到$theme')),
                    );
                  },
                )),
          ],
        );
      },
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final languages = ['🇨🇳 简体中文', '🇺🇸 English'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择语言',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ...languages.map((language) => ListTile(
                  title: Text(language),
                  trailing: language == '🇨🇳 简体中文'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    // 应用语言
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已切换到$language')),
                    );
                  },
                )),
          ],
        );
      },
    );
  }

  void _showApiSettingDialog(BuildContext context, Setting element) {
    // final TextEditingController controller = TextEditingController(
    //   text: element.detail,
    // );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('API'),
          content: Text('${element.detail}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 复制到剪贴板
                Clipboard.setData(ClipboardData(text: element.detail ?? ''));
                Navigator.pop(context);
                // 显示复制成功的提示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板')),
                );
              },
              child: const Text('复制'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingDetailDialog(BuildContext context, Setting element) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(element.type.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (element.content != null) Text('内容: ${element.content}'),
              if (element.detail != null) ...[
                const SizedBox(height: 8),
                Text('详情: ${element.detail}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('我的二维码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Text('二维码占位图'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('扫描二维码添加好友'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('帮助中心'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. 如何切换账本?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('点击"当前账本"选项，在弹出的列表中选择需要的账本。'),
              SizedBox(height: 12),
              Text('2. 如何修改个人资料?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('点击头像或"查看个人资料"进入个人资料页面进行修改。'),
              SizedBox(height: 12),
              Text('3. 遇到问题怎么办?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('可以通过"意见反馈"功能向我们反馈问题，我们会尽快处理。'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 执行退出登录操作
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已退出登录')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
  }
}
