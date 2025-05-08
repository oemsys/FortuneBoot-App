import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item_add.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Request/bill_request.dart';
import 'package:todos_repository/todos_repository.dart';
import 'package:dio/dio.dart';

part 'edit_todo_event.dart';
part 'edit_todo_state.dart';

class EditTodoBloc extends Bloc<EditTodoEvent, EditTodoState> {
  EditTodoBloc({
    required TodosRepository todosRepository,
    required Todo? initialTodo,
  })  : _todosRepository = todosRepository,
        super(
          EditTodoState(
            initialTodo: initialTodo,
            title: initialTodo?.title ?? '',
            description: initialTodo?.description ?? '',
          ),
        ) {
    on<EditTodoTitleChanged>(_onTitleChanged);
    on<EditTodoDescriptionChanged>(_onDescriptionChanged);
    on<EditTodoSubmitted>(_onSubmitted);
    on<EditBillSubmitted>(_onBillSubmitted);
  }

  final TodosRepository _todosRepository;

  void _onTitleChanged(
    EditTodoTitleChanged event,
    Emitter<EditTodoState> emit,
  ) {
    emit(state.copyWith(title: event.title));
  }

  void _onDescriptionChanged(
    EditTodoDescriptionChanged event,
    Emitter<EditTodoState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onSubmitted(
    EditTodoSubmitted event,
    Emitter<EditTodoState> emit,
  ) async {
    emit(state.copyWith(status: EditTodoStatus.loading));
    final todo = (state.initialTodo ?? Todo(title: '')).copyWith(
      title: state.title,
      description: state.description,
    );

    try {
      await _todosRepository.saveTodo(todo);
      emit(state.copyWith(status: EditTodoStatus.success));
    } catch (e) {
      emit(state.copyWith(status: EditTodoStatus.failure));
    }
  }

  FutureOr<void> _onBillSubmitted(
      EditBillSubmitted event, Emitter<EditTodoState> emit) async {
    // lxjtodo：提交账单，刷新列表
    BillService billService = BillService();
    BillItemAdd billItemAdd = BillItemAdd.fromJson(event.submitData);
    Data data = Data.fromJson(
        Map<String, dynamic>.from(event.submitData['data'] as Map? ?? {}));
    print('lxjtodo: _onBillSubmitted request: ${data.toJson()}');
    // var result = await billService.addBill(data.toJson());
    FromBillAddRequest request = FromBillAddRequest();
    Response? response = (await request.submitBill(data.toJson()));
    if (response?.statusCode == 200) {
      print('lxjtodo _onBillSubmitte response: ${response?.data} ');
      var hjResponse = HJResponse.fromJson(
          Map<String, dynamic>.from(response?.data as Map? ?? {}));
      if (hjResponse.code == 0) {
        emit(state.copyWith(status: EditTodoStatus.closed));
      } else {
        emit(state.copyWith(status: EditTodoStatus.submitFailed));
      }
    }
    emit(state.copyWith(status: EditTodoStatus.failure));
  }
}
