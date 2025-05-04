import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/view/edit_todo_page.dart';
import 'package:flutter_login_example/Home/todos_overview/bloc/todos_overview_bloc.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Home/todos_overview/widgets/bill_list_tile.dart';
import 'package:flutter_login_example/Home/todos_overview/widgets/todo_list_tile.dart';
import 'package:flutter_login_example/Home/todos_overview/widgets/todos_overview_filter_button.dart';
import 'package:flutter_login_example/Home/todos_overview/widgets/todos_overview_options_button.dart';
import 'package:todos_repository/todos_repository.dart';
import 'package:intl/intl.dart';

import '../../../generated/l10n.dart';

class TodosOverviewPage extends StatelessWidget {
  const TodosOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodosOverviewBloc(
        todosRepository: context.read<TodosRepository>(),
      )..add(const TodosOverviewSubscriptionRequested()),
      child: const TodosOverviewView(),
    );
  }
}

class TodosOverviewView extends StatefulWidget {
  const TodosOverviewView({super.key});

  @override
  State<TodosOverviewView> createState() => _TodosOverviewViewState();
}

class _TodosOverviewViewState extends State<TodosOverviewView> {
  DateTime? _currentGroupDate;
  final Map<String, GlobalKey> _groupKeys = {};
  List<DateTime> _groupDates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          children: [
            Text(S.current.todosOverviewAppBarTitle,
                style: Theme.of(context).appBarTheme.titleTextStyle),
            Expanded(
              child: Center(
                child: _buildDateTitle(context),
              ),
            ),
          ],
        ),
        actions: const [
          TodosOverviewFilterButton(),
          TodosOverviewOptionsButton(),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TodosOverviewBloc, TodosOverviewState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == TodosOverviewStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(S.current.todosOverviewErrorSnackbarText),
                    ),
                  );
              }
            },
          ),
          BlocListener<TodosOverviewBloc, TodosOverviewState>(
            listenWhen: (previous, current) =>
                previous.lastDeletedTodo != current.lastDeletedTodo &&
                current.lastDeletedTodo != null,
            listener: (context, state) {
              final deletedTodo = state.lastDeletedTodo!;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      S.current.todosOverviewTodoDeletedSnackbarText(
                        deletedTodo.title,
                      ),
                    ),
                    action: SnackBarAction(
                      label: S.current.todosOverviewUndoDeletionButtonText,
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        context
                            .read<TodosOverviewBloc>()
                            .add(const TodosOverviewUndoDeletionRequested());
                      },
                    ),
                  ),
                );
            },
          ),
        ],
        child: BlocBuilder<TodosOverviewBloc, TodosOverviewState>(
          builder: (context, state) {
            if (!(state.bills?.isNotEmpty == true)) {
              if (state.status == TodosOverviewStatus.loading) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (state.status != TodosOverviewStatus.success) {
                return const SizedBox();
              } else {
                return Center(
                  child: Text(
                    S.current.todosOverviewEmptyText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
            }

            final bills = state.bills ?? [];
            // 按日期分组
            final Map<String, List<BillItem>> grouped = {};
            final Map<String, DateTime> groupDateMap = {};
            for (var bill in bills) {
              final date = DateTime(
                bill.tradeTime!.year,
                bill.tradeTime!.month,
                bill.tradeTime!.day,
              );
              final key = _dateKey(date);
              groupDateMap[key] = date;
              grouped.putIfAbsent(key, () => []).add(bill);
            }
            _groupDates = groupDateMap.values.toList()
              ..sort((a, b) => b.compareTo(a));
            // 初始化当前分组日期
            if (_currentGroupDate == null && _groupDates.isNotEmpty) {
              _currentGroupDate = _groupDates.first;
            }

            final groupKeys = _groupDates
                .map((d) =>
                    _groupKeys.putIfAbsent(_dateKey(d), () => GlobalKey()))
                .toList();

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _updateCurrentGroupDate(context));
                // 上拉触底加载更多
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 50) {
                  if (!state.isLoadingMore && state.hasMore) {
                    context
                        .read<TodosOverviewBloc>()
                        .add(const TodosOverviewLoadMoreRequested());
                  }
                }
                return false;
              },
              child: ListView.builder(
                itemCount: _groupDates.length + 1, // +1 for footer
                itemBuilder: (context, groupIdx) {
                  if (groupIdx == _groupDates.length) {
                    // footer
                    return _buildFooterWidget(state);
                  }
                  final date = _groupDates[groupIdx];
                  final key = _groupKeys[_dateKey(date)]!;
                  final billsInGroup = grouped[_dateKey(date)] ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _getGroupSeparator(context, date, key),
                      ...billsInGroup
                          .map((bill) => BillListTile(bill: bill))
                          .toList(),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateCurrentGroupDate(BuildContext context) {
    if (_groupDates.isEmpty) return;
    RenderBox? listBox = context.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    double listTop = listBox.localToGlobal(Offset.zero).dy;

    DateTime? newGroup;
    for (var date in _groupDates) {
      final key = _groupKeys[_dateKey(date)];
      if (key == null) continue;
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final offset = box.localToGlobal(Offset.zero).dy - listTop;
      if (offset <= 0) {
        newGroup = date;
      } else {
        break;
      }
    }
    if (newGroup != null && newGroup != _currentGroupDate) {
      setState(() {
        _currentGroupDate = newGroup;
      });
    }
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Widget _buildFooterWidget(TodosOverviewState state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(bottom: 32),
        height: 56,
        child: state.isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 1.5))
            : !state.hasMore
                ? const Text('我是有底线的')
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDateTitle(BuildContext context) {
    if (_currentGroupDate == null) {
      return const SizedBox.shrink();
    }
    final formatter = DateFormat('yyyy-MM-dd');
    return Text(
      formatter.format(_currentGroupDate!),
      style: Theme.of(context).appBarTheme.titleTextStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _getGroupSeparator(BuildContext context, DateTime date, Key key) {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(date);
    Color bkColor = Theme.of(context).appBarTheme.backgroundColor!;
    return SizedBox(
      key: key,
      height: 50,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: bkColor.withOpacity(0.5),
            border: Border.all(
              color: bkColor.withOpacity(0.5),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            boxShadow: [
              BoxShadow(
                color: bkColor.withOpacity(0.3),
                offset: Offset(4, 4),
                blurRadius: 8.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              formattedDate,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
