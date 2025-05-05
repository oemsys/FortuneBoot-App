import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Home/todos_overview/models/todos_view_filter.dart';
import 'package:flutter_login_example/Request/bill_request.dart';
import 'package:todos_repository/todos_repository.dart';

part 'todos_overview_event.dart';
part 'todos_overview_state.dart';

class TodosOverviewBloc extends Bloc<TodosOverviewEvent, TodosOverviewState> {
  TodosOverviewBloc({
    required TodosRepository todosRepository,
  })  : _todosRepository = todosRepository,
        super(const TodosOverviewState()) {
    on<TodosOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TodosOverviewTodoCompletionToggled>(_onTodoCompletionToggled);
    on<TodosOverviewTodoDeleted>(_onTodoDeleted);
    on<TodosOverviewUndoDeletionRequested>(_onUndoDeletionRequested);
    on<TodosOverviewFilterChanged>(_onFilterChanged);
    on<TodosOverviewToggleAllRequested>(_onToggleAllRequested);
    on<TodosOverviewClearCompletedRequested>(_onClearCompletedRequested);
    on<TodosOverviewLoadMoreRequested>(_onLoadMoreRequested);
  }
  final BillService _billService = BillService();

  final TodosRepository _todosRepository;

  Future<void> _onSubscriptionRequested(
    TodosOverviewSubscriptionRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    emit(state.copyWith(status: () => TodosOverviewStatus.loading));

    var billResponse =
        await _billService.getPage(pageNum: 1, pageSize: 20, bookId: '1');
    if (billResponse.code == 0) {
      var billList = billResponse.data['rows'] as List? ?? [];
      List<BillItem> items = billList.map((ele) {
        return BillItem.fromJson(Map<String, dynamic>.from(ele as Map? ?? {}));
      }).toList();
      print('lxjtodo $items');
      emit(state.copyWith(
          status: () => TodosOverviewStatus.success, bills: items));
    }

    await emit.forEach<List<Todo>>(
      _todosRepository.getTodos(),
      onData: (todos) => state.copyWith(
        status: () => TodosOverviewStatus.success,
        todos: () => todos,
      ),
      onError: (_, __) => state.copyWith(
        status: () => TodosOverviewStatus.failure,
      ),
    );
  }

  Future<void> _onTodoCompletionToggled(
    TodosOverviewTodoCompletionToggled event,
    Emitter<TodosOverviewState> emit,
  ) async {
    final newTodo = event.todo.copyWith(isCompleted: event.isCompleted);
    await _todosRepository.saveTodo(newTodo);
  }

  Future<void> _onTodoDeleted(
    TodosOverviewTodoDeleted event,
    Emitter<TodosOverviewState> emit,
  ) async {
    emit(state.copyWith(lastDeletedTodo: () => event.todo));
    await _todosRepository.deleteTodo(event.todo.id);
  }

  Future<void> _onUndoDeletionRequested(
    TodosOverviewUndoDeletionRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    assert(
      state.lastDeletedTodo != null,
      'Last deleted todo can not be null.',
    );

    final todo = state.lastDeletedTodo!;
    emit(state.copyWith(lastDeletedTodo: () => null));
    await _todosRepository.saveTodo(todo);
  }

  void _onFilterChanged(
    TodosOverviewFilterChanged event,
    Emitter<TodosOverviewState> emit,
  ) {
    emit(state.copyWith(filter: () => event.filter));
  }

  Future<void> _onToggleAllRequested(
    TodosOverviewToggleAllRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    final areAllCompleted = state.todos.every((todo) => todo.isCompleted);
    await _todosRepository.completeAll(isCompleted: !areAllCompleted);
  }

  Future<void> _onClearCompletedRequested(
    TodosOverviewClearCompletedRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    await _todosRepository.clearCompleted();
  }

  /// 上拉加载更多处理
  Future<void> _onLoadMoreRequested(
    TodosOverviewLoadMoreRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.pageNum + 1;
    var billResponse = await _billService.getPage(
        pageNum: nextPage, pageSize: 20, bookId: '1');
    if (billResponse.code == 0) {
      var billList = billResponse.data['rows'] as List? ?? [];
      List<BillItem> items = billList.map((ele) {
        return BillItem.fromJson(Map<String, dynamic>.from(ele as Map? ?? {}));
      }).toList();

      final allBills = List<BillItem>.from(state.bills ?? [])..addAll(items);
      final allBillsCount = billResponse.data['total'] as int? ?? 20;
      final hasMore = allBills.length < allBillsCount; 

      emit(state.copyWith(
        bills: allBills,
        pageNum: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } else {
      emit(state.copyWith(isLoadingMore: false, hasMore: false));
    }
  }
}
