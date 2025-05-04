part of 'todos_overview_bloc.dart';

enum TodosOverviewStatus { initial, loading, success, failure }

final class TodosOverviewState extends Equatable {
  const TodosOverviewState({
    this.status = TodosOverviewStatus.initial,
    this.todos = const [],
    this.filter = TodosViewFilter.all,
    this.lastDeletedTodo,
    this.bills = const [],
    this.pageNum = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final TodosOverviewStatus status;
  final List<Todo> todos;
  final TodosViewFilter filter;
  final Todo? lastDeletedTodo;
  final List<BillItem>? bills;

  // 分页相关
  final int pageNum; // 当前页码
  final bool hasMore; // 是否还有更多数据
  final bool isLoadingMore; // 是否正在加载更多

  Iterable<Todo> get filteredTodos => filter.applyAll(todos);

  TodosOverviewState copyWith({
    TodosOverviewStatus Function()? status,
    List<Todo> Function()? todos,
    TodosViewFilter Function()? filter,
    Todo? Function()? lastDeletedTodo,
    List<BillItem>? bills,
    int? pageNum,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TodosOverviewState(
      status: status != null ? status() : this.status,
      todos: todos != null ? todos() : this.todos,
      filter: filter != null ? filter() : this.filter,
      lastDeletedTodo:
          lastDeletedTodo != null ? lastDeletedTodo() : this.lastDeletedTodo,
      bills: bills != null ? bills : this.bills,
      pageNum: pageNum ?? this.pageNum,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todos,
        filter,
        lastDeletedTodo,
        bills,
        pageNum,
        hasMore,
        isLoadingMore,
      ];
}
