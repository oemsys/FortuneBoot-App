import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item_add.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Request/bill_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import 'package:dio/dio.dart';

part 'edit_bill_event.dart';
part 'edit_bill_state.dart';

class EditBillBloc extends Bloc<EditBillEvent, EditBillState> {
  EditBillBloc({
    required BillsRepository billRepository,
    required BillItemAdd? initialBill,
  })  : _billRepository = billRepository,
        super(
          EditBillState(
            initialBill: initialBill,
          ),
        ) {
    on<EditBillSubmitted>(_onBillSubmitted);
  }

  final BillsRepository _billRepository;

  FutureOr<void> _onBillSubmitted(
      EditBillSubmitted event, Emitter<EditBillState> emit) async {
    Data data = Data.fromJson(
        Map<String, dynamic>.from(event.submitData['data'] as Map? ?? {}));
    print('lxjtodo: _onBillSubmitted request: ${data.toJson()}');
    FromBillAddRequest request = FromBillAddRequest();
    Response? response = (await request.submitBill(data.toJson()));
    if (response?.statusCode == 200) {
      print('lxjtodo _onBillSubmitte response: ${response?.data} ');
      var hjResponse = HJResponse.fromJson(
          Map<String, dynamic>.from(response?.data as Map? ?? {}));
      if (hjResponse.code == 0) {
        _billRepository.refreshBills();
        emit(state.copyWith(status: EditBillStatus.closed));
      } else {
        emit(state.copyWith(status: EditBillStatus.submitFailed));
      }
    }
    emit(state.copyWith(status: EditBillStatus.failure));
  }
}
