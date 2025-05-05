import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/post/post_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/stats_bloc.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Home/stats/models/setting_select_item.dart';
import 'package:flutter_login_example/Home/stats/view/drop_down_animate.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/group_request.dart';
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

  final Map<String, int> itemsMap = {};

  // final CustomOverlayController _controller = CustomOverlayController();

  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        print('lxjtodo:焦点已获取'); // 触发获取焦点的逻辑
      } else {
        print('lxjtodo:焦点已失去'); // 触发失去焦点的逻辑
      }
      super.initState();
    });
  }

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
      var curItem = element.content;
      // 1.下拉的时候搜索
      // 2.改选项的时候更新bloc
      // print('lxjtodo:items $items, $curItem');
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${element.type.title}:',
                style: textTheme.headlineSmall!.copyWith(fontSize: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MultiDropdown<SettingSelectItem>.future(
                  onSelectionChange: (selectedItems) {
                    if (element.type == SettingType.currentGroup) {
                      context.read<SettingBloc>().add(
                          GroupSettingFetched(groupId: selectedItems.first.id));
                    }
                  },
                  future: () async {
                    List<DropdownItem<SettingSelectItem>> items = [];
                    if (element.type == SettingType.currentGroup) {
                      GroupService groupService = GroupService();
                      var res = await groupService.getEnableList();
                      if (res.code == 0) {
                        var remoteList = res.data as List? ?? [];
                        for (final remoteItem in remoteList) {
                          var remoteGroupName =
                              remoteItem['groupName'] as String? ?? '';
                          bool selected = false;
                          if (remoteGroupName == element.content) {
                            selected = true;
                          }
                          var groupId = remoteItem['groupId'] as int? ?? 0;
                          items.add(DropdownItem(
                              label: remoteGroupName,
                              value: SettingSelectItem(remoteGroupName, groupId),
                              selected: selected));
                        }
                      }
                    } else {
                      BookService bookService = BookService();
                      var remoteBookResponse = await bookService
                          .getByGroupId(element.data!['groupId'] as int? ?? 0);
                      if (remoteBookResponse.code == 0) {
                        var remoteBookList = remoteBookResponse.data as List? ?? [];
                        for (final remoteBookItem in remoteBookList) {
                          var remoteBookName =
                              remoteBookItem['bookName'] as String? ?? '';
                          bool selected = false;
                          if (remoteBookName == element.content) {
                            selected = true;
                          }
                          items.add(
                            DropdownItem(
                                label: remoteBookName,
                                value: SettingSelectItem(remoteBookName,
                                    remoteBookItem['bookId'] as int? ?? 0),
                                selected: selected),
                          );
                        }
                      }
                    }
                    return items;
                  },
                  key: GlobalKey(),
                  dropdownItemDecoration: DropdownItemDecoration(
                    selectedBackgroundColor: Theme.of(context).focusColor
                  ),
                  fieldDecoration: FieldDecoration(
                    hintText: curItem,
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: element.leadingWidget,
                    showClearIcon: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      // borderSide: const BorderSide(
                      //   color: Colors.black87,
                      // ),
                    ),
                  ),
                  focusNode:
                  element.type == SettingType.currentGroup ? _focusNode : null,
                  dropdownDecoration: DropdownDecoration(
                    backgroundColor: Theme.of(context).cardColor,
                    marginTop: 2,
                    maxHeight: 500,
                    header: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        element.type.title,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a country';
                    }
                    return null;
                  },
                  searchEnabled: true,
                  singleSelect: true,
                  // items: items,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          children: [
            if (element.leadingWidget != null) ...[
              element.leadingWidget!,
              const SizedBox(width: 16),
            ],
            Text(
              '${element.type.title}:',
              style: textTheme.headlineSmall!.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (element.content?.isNotEmpty == true)
                    Text(
                      element.content ?? '',
                      style: textTheme.headlineSmall!.copyWith(fontSize: 16),
                    ),
                  if (element.detail?.isNotEmpty == true)
                    Text(
                      element.detail ?? '',
                      style: textTheme.bodyMedium!
                          .copyWith(fontSize: 14, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
