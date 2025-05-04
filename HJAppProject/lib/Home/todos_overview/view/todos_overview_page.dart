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
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
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

class TodosOverviewView extends StatelessWidget {
  const TodosOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.todosOverviewAppBarTitle),
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
            if (state.todos.isEmpty) {
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
            return StickyGroupedListView<BillItem, DateTime>(
                elements: state.bills ?? [],
                groupBy: (BillItem element) => DateTime(
                      element.tradeTime!.year,
                      element.tradeTime!.month,
                      element.tradeTime!.day,
                    ),
                groupComparator: (DateTime value1, DateTime value2) =>
                    value2.compareTo(value1),
                itemComparator: (BillItem element1, BillItem element2) =>
                    element1.tradeTime!.compareTo(element2.tradeTime!),
                floatingHeader: true,
                itemBuilder: (context, element) => BillListTile(
                      bill: element,
                    ),
                groupSeparatorBuilder: _getGroupSeparator);

            return CupertinoScrollbar(
              child: ListView.builder(
                itemCount: state.bills?.length,
                itemBuilder: (_, index) {
                  final bill = state.bills?.elementAt(index);
                  return BillListTile(
                    bill: bill!,
                    onToggleCompleted: (isCompleted) {
                      // context.read<TodosOverviewBloc>().add(
                      //       TodosOverviewTodoCompletionToggled(
                      //         todo: todo,
                      //         isCompleted: isCompleted,
                      //       ),
                      //     );
                    },
                    onDismissed: (_) {
                      // context
                      //     .read<TodosOverviewBloc>()
                      //     .add(TodosOverviewTodoDeleted(todo));
                    },
                    onTap: () {
                      // Navigator.of(context).push(
                      //   EditTodoPage.route(initialTodo: todo),
                      // );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getGroupSeparator(BillItem element) {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String formattedDate =
        formatter.format(element.tradeTime ?? DateTime.now());
    return SizedBox(
      height: 50,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.blue[300],
            border: Border.all(
              color: Colors.blue[300]!,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
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
