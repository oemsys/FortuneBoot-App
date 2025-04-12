import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/stats_bloc.dart';
import 'package:flutter_login_example/Login/model/login_constants.dart';
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
      create: (context) => StatsBloc(
        todosRepository: context.read<TodosRepository>(),
      )..add(const StatsSubscriptionRequested()),
      child: const MineView(),
    );
  }
}

class MineView extends StatelessWidget {
  const MineView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StatsBloc>().state;
    final textTheme = Theme.of(context).textTheme;

    // nickname
    // 用户名
    // 账户概览
    // 当前账本
    // 当前主题
    // 当前语言
    // API：
    // 当前版本
    // API版本
    // 退出登录
    var user = UserDataSingleton();
    debugPrint('lxjtodo ${user.get(UserDataSingleton.userInfo)}');
    List<Element> elements = [];
    var curUser = user.get(UserDataSingleton.userInfo);
    var userInfo = Map<String, dynamic>.from(curUser['userInfo'] as Map? ?? {});
    var nickName = userInfo['nickname'] as String? ?? '';
    elements.add(Element('用户名', content: nickName, leadingWidget: Icon(Icons.face_retouching_natural)));
    elements
        .add(Element('账户概览', detail: '资产：0.00，负债：0.00，净资产：0.00', leadingWidget:Icon(Icons.paid) )); // todo：接口
    elements.add(Element('当前主题', content: '跟随系统', leadingWidget:Icon(Icons.dark_mode))); // todo：主题
    String currentLocale =
        (Intl.defaultLocale ?? 'en') == 'en' ? '🇺🇸 English' : '🇨🇳 简体中文';
    elements.add(Element('当前语言', content: currentLocale, leadingWidget: Icon(Icons.translate)));
    elements.add(Element('API', content: LoginConstants.baseUrl, leadingWidget: Icon(Icons.edit_note))); // todo：调接口
    elements.add(Element('当前版本', content: '99.99', leadingWidget: Icon(Icons.abc))); // todo：当前版本号
    elements.add(Element('API版本', content: '99.99', leadingWidget: Icon(Icons.cloud_queue))); // todo：调接口

    Widget lists = ListView.builder(
      itemBuilder: (context, index) {
        return _getItem(context, elements[index]);
      },
      itemCount: elements.length,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.mine),
      ),
      body: lists,
    );
  }

  Widget _getItem(BuildContext ctx, Element element) {
    final textTheme = Theme.of(ctx).textTheme;
    return Card(
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(6.0),
      // ),
      // elevation: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: SizedBox(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: element.leadingWidget ?? element.leadingWidget,
          title: Text('${element.title}:',
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

class Element {
  String title;
  String? detail;
  String? content;
  Widget? leadingWidget;

  Element(this.title, {this.detail, this.content, this.leadingWidget});
}
