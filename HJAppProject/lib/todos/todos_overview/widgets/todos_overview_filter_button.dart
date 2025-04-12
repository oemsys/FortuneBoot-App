import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/todos/todos_overview/bloc/todos_overview_bloc.dart';
import 'package:flutter_login_example/todos/todos_overview/models/todos_view_filter.dart';

import '../../../generated/l10n.dart';

class TodosOverviewFilterButton extends StatelessWidget {
  const TodosOverviewFilterButton({super.key});

  @override
  Widget build(BuildContext context) {

    final activeFilter =
        context.select((TodosOverviewBloc bloc) => bloc.state.filter);

    return PopupMenuButton<TodosViewFilter>(
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      initialValue: activeFilter,
      tooltip: S.current.todosOverviewFilterTooltip,
      onSelected: (filter) {
        context
            .read<TodosOverviewBloc>()
            .add(TodosOverviewFilterChanged(filter));
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: TodosViewFilter.all,
            child: Text(S.current.todosOverviewFilterAll),
          ),
          PopupMenuItem(
            value: TodosViewFilter.activeOnly,
            child: Text(S.current.todosOverviewFilterActiveOnly),
          ),
          PopupMenuItem(
            value: TodosViewFilter.completedOnly,
            child: Text(S.current.todosOverviewFilterCompletedOnly),
          ),
        ];
      },
      icon: const Icon(Icons.filter_list_rounded),
    );
  }
}
