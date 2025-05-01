import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/post/post_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/stats_bloc.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
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
      child: const MineView(),
    );
  }
}

class MineView extends StatelessWidget {
  const MineView({super.key});

  void getApiVersion() {}

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingBloc>().state;
    print('lxjtodo: ${state.settings}');
    var elements = state.settings;
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
