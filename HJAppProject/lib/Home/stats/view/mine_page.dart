import 'dart:math';

import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/post/post_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/stats_bloc.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Home/stats/view/drop_down_animate.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:todos_repository/todos_repository.dart';
import '../../../generated/l10n.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:intl/intl.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingBloc()..add(SettingInitDataLoaded()),
      child: MineView(),
    );
  }
}

class MineView extends StatefulWidget {
  MineView({super.key});

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
    if (_isShowing.value)
      hide();
    else
      show();
  }

  void addListener(VoidCallback listener) => _isShowing.addListener(listener);
}

class _MineViewState extends State<MineView> {
  void getApiVersion() {}

  // final CustomOverlayController _controller = CustomOverlayController();

  // @override
  // void initState() {
  //   _controller.addListener(() {
  //     print('浮层状态变化：${_controller.isShowing}');
  //   });
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingBloc>().state;
    print('lxjtodo: ${state.settings}');
    var elements = [
      ...state.settings,
      ...state.remoteSettings,
      ...state.groupSettings
    ];
    Setting.sortList(elements);
    Widget lists = ListView.builder(
      itemBuilder: (context, index) {
        return _getItem(context, elements[index]);
      },
      itemCount: elements.length,
    );
    // 拉取账本信息
    context.read<SettingBloc>().add(GroupSettingFetched());
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.mine),
      ),
      body: lists,
    );
  }

  Widget _getItem(BuildContext ctx, Setting element) {
    final textTheme = Theme.of(ctx).textTheme;
    if (element.type == SettingType.currentGroup ||
        element.type == SettingType.currentBook) {
      var items = <String>[];
      var curItem = element.content;
      if (element.type == SettingType.currentGroup) {
        var groupList = element.data?['groupList'] as List? ?? [];
        for (var item in groupList) {
          items.add(item['groupName'] as String? ?? '');
        }
      }
      print('lxjtodo: $items, $curItem');
      if (!items.contains(curItem)) {
        items.add(curItem ?? '');
      }
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: SizedBox(
          child: ListTile(
            leading: element.leadingWidget ?? element.leadingWidget,
            title: Text('${element.type.title}:',
                style: textTheme.headlineSmall!.copyWith(fontSize: 16)),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 6),
              width: 100,
              height: 60,
              child: DropdownFlutter.search(
                decoration: CustomDropdownDecoration(
                    closedFillColor: Theme.of(context).cardColor,
                    expandedFillColor: Theme.of(context).cardColor,
                    searchFieldDecoration: SearchFieldDecoration(
                        fillColor: Theme.of(context).cardColor)),
                // overlayController: _controller,
                items: items,
                onChanged: (o) {
                  print('lxjtodo');
                },
                initialItem: curItem,
              ),
            ),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: SizedBox(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: element.leadingWidget ?? element.leadingWidget,
          title: Text('${element.type.title}:',
              style: textTheme.headlineSmall!.copyWith(fontSize: 16)),
          subtitle: (element.detail?.isNotEmpty == true)
              ? Text(element.detail ?? '',
                  style: textTheme.bodyMedium!
                      .copyWith(fontSize: 14, color: Colors.grey[500]))
              : null,
          trailing: (element.content?.isNotEmpty == true)
              ? Text(
                  element.content ?? '',
                  style: textTheme.headlineSmall!.copyWith(fontSize: 16),
                )
              : null,
        ),
      ),
    );
  }
}
