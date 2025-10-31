import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hjproject/home/setting_page/bloc/setting_bloc.dart';
import 'package:hjproject/home/setting_page/models/mine_setting.dart';
import 'package:hjproject/home/setting_page/models/setting_select_item.dart';
import 'package:hjproject/login/model/users.dart';
import 'package:hjproject/login/view/base_url_config_page.dart';
import 'package:hjproject/request/book_request.dart';
import 'package:hjproject/request/group_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/util/dio_client.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import '../../../generated/l10n.dart';

import 'package:hjproject/home/setting_page/view/profile_page.dart';
import 'package:hjproject/home/setting_page/view/widgets/user_header.dart';
import 'package:hjproject/home/setting_page/view/widgets/book_config_group.dart';
import 'package:hjproject/home/setting_page/view/widgets/additional_options_group.dart';
import 'package:hjproject/home/setting_page/view/widgets/setting_group_card.dart';
import 'package:hjproject/home/setting_page/view/widgets/setting_item_tile.dart';
import 'package:hjproject/home/setting_page/view/widgets/donate_qr_sheet.dart';
import 'package:hjproject/home/setting_page/view/widgets/help_dialog.dart';
import 'package:hjproject/home/setting_page/view/widgets/api_info_dialog.dart';
import 'package:hjproject/home/setting_page/view/widgets/setting_detail_dialog.dart';
import 'package:hjproject/home/setting_page/view/widgets/theme_selection_sheet.dart';
import 'package:hjproject/home/setting_page/view/widgets/logout_confirm_dialog.dart';
import 'package:hjproject/home/setting_page/view/widgets/selection_bottom_sheet.dart';
import 'package:hjproject/home/setting_page/view/widgets/save_options_sheet.dart';
import 'package:hjproject/util/image_save_service.dart';
import 'package:hjproject/home/setting_page/view/widgets/language_selection_sheet.dart';
import 'package:hjproject/home/setting_page/utils/setting_filter.dart';

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

class _MineViewState extends State<MineView> {
  @override
  void initState() {
    super.initState();
    // 拉取账本信息
    context.read<SettingBloc>().add(GroupSettingFetched());
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[950] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          S.current.mine,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
          const SizedBox(width: 4),
        ],
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildUserHeader(context, elements),
            const SizedBox(height: 20),
            _buildSettingsGroups(context, elements),
            const SizedBox(height: 24),
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

    return MineUserHeader(
      username: username,
      onViewProfile: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
      },
      onShowQRCode: () => _showQRCode(context),
    );
  }

  Widget _buildSettingsGroups(BuildContext context, List<Setting> elements) {
    // 使用 SettingFilter 工具类进行高效的单次遍历分组
    final groups = SettingFilter.groupSettings(elements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.hasAccountSettings) ...[
          _buildSettingGroup(context, '账户设置', groups.accountSettings),
          const SizedBox(height: 14),
        ],
        _buildBookConfigGroup(context),
        const SizedBox(height: 14),
        if (groups.hasAppSettings) ...[
          _buildSettingGroup(context, '应用设置', groups.appSettings),
          const SizedBox(height: 14),
        ],
        if (groups.hasAboutSettings) ...[
          _buildSettingGroup(context, '关于', groups.aboutSettings),
          const SizedBox(height: 14),
        ],
        _buildAdditionalOptions(context),
      ],
    );
  }

  Widget _buildSettingGroup(
      BuildContext context, String title, List<Setting> settings) {
    return SettingGroupCard(
      title: title,
      children:
          settings.map((setting) => _getSettingItem(context, setting)).toList(),
    );
  }

  // 新增：账本配置分组（与账户设置、应用设置、关于同级）
  Widget _buildBookConfigGroup(BuildContext context) {
    return const BookConfigGroup();
  }

  // 通用设置项渲染：统一使用封装的 SettingItemTile，避免重复代码
  Widget _getSettingItem(BuildContext context, Setting element) {
    return SettingItemTile(
      element: element,
      onSelectSetting: (setting) {
        _showSelectionDialog(context, setting);
      },
      onTapSetting: (setting) {
        _handleSettingTap(context, setting);
      },
    );
  }

  // 通用点击处理：根据类型分派到对应的对话框/逻辑
  void _handleSettingTap(BuildContext context, Setting element) {
    switch (element.type) {
      case SettingType.currentTheme:
        emptyPage();
        break;
      case SettingType.currentLanguage:
        emptyPage();
        break;
      case SettingType.api:
        _showApiSettingDialog(context, element);
        break;
      default:
        _showSettingDetailDialog(context, element);
        break;
    }
  }

  // 更多操作分组：打赏、反馈、评分、退出登录
  Widget _buildAdditionalOptions(BuildContext context) {
    return AdditionalOptionsGroup(
      onDonate: () => _showQRCode(context),
      onFeedback: () {
        // 跳转到意见反馈页面
        emptyPage();
      },
      onRate: () {
        // 跳转到应用商店评分
        emptyPage();
      },
      onLogout: () => _showLogoutConfirmation(context),
    );
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
      final BookService bookService = BookService();
      final remoteBookResponse = await bookService
          .getEnableList(element.data!['groupId'] as int? ?? 0);
      if (remoteBookResponse.code == 0) {
        final remoteBookList = remoteBookResponse.data as List? ?? [];
        for (final remoteBookItem in remoteBookList) {
          final remoteBookName = remoteBookItem['bookName'] as String? ?? '';
          final bool selected = remoteBookName == element.content;
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
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无可选项'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    var settingBloc = context.read<SettingBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = items
            .map((item) => SelectionOption<SettingSelectItem>(
                  label: item.label,
                  value: item.value,
                  selected: item.selected,
                ))
            .toList();
        return SelectionBottomSheet<SettingSelectItem>(
          title: '选择${element.type.title}',
          options: options,
          onSelected: (selected) {
            Navigator.of(context).pop();
            if (element.type == SettingType.currentGroup) {
              settingBloc.add(
                GroupSettingFetched(groupId: selected.value.id),
              );
            } else if (element.type == SettingType.currentBook) {
              settingBloc.add(
                BookIdChanged(selected.value.id, selected.value.title),
              );
            }
          },
        );
      },
    );
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final themes = ['跟随系统', '浅色模式', '深色模式'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ThemeSelectionSheet(
          themes: themes,
          current: '跟随系统',
          onSelected: (selected) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已切换到$selected'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
            // TODO: 接入实际主题切换逻辑（如通过 Bloc/Provider 改变主题）
          },
        );
      },
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final languages = ['🇨🇳 简体中文', '🇺🇸 English'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LanguageSelectionSheet(
          languages: languages,
          current: '🇨🇳 简体中文',
          onSelected: (selected) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已切换到$selected'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
            // TODO: 接入实际语言切换逻辑（如通过 Bloc/Provider 改变 Locale）
          },
        );
      },
    );
  }

  void _showApiSettingDialog(BuildContext context, Setting element) {
    showDialog(
      context: context,
      builder: (context) => ApiInfoDialog(apiDetail: element.detail),
    );
  }

  void _showSettingDetailDialog(BuildContext context, Setting element) {
    showDialog(
      context: context,
      builder: (context) => SettingDetailDialog(
        title: element.type.title,
        contentText: element.content,
        detailText: element.detail,
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DonateQrSheet(
          onLongPressWechat: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => SaveOptionsSheet(
                assetPath: 'assets/images/donate_wechat.jpg',
                suggestedName: '微信收款码',
                onDownloadOrSave: () => ImageSaveService.saveAssetImage(
                    context, 'assets/images/donate_wechat.jpg', '微信收款码'),
              ),
            );
          },
          onLongPressAlipay: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => SaveOptionsSheet(
                assetPath: 'assets/images/donate_alipay.jpg',
                suggestedName: '支付宝收款码',
                onDownloadOrSave: () => ImageSaveService.saveAssetImage(
                    context, 'assets/images/donate_alipay.jpg', '支付宝收款码'),
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  void emptyPage() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('敬请期待...')),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmDialog(
        onConfirm: () {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已退出登录')),
          );
          UserDataSingleton().remove(UserDataSingleton.userInfo);
          DioClient().refreshToken({});
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const BaseUrlConfigPage(),
            ),
          );
        },
      ),
    );
  }
}
