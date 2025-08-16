import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hjproject/home/todos_overview/models/bill_file_item.dart';
import 'package:hjproject/home/todos_overview/models/bill_item.dart';
import 'package:hjproject/login/model/login_model.dart';
import 'package:hjproject/request/bill_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';

part 'bill_detail_event.dart';

part 'bill_detail_state.dart';

class BillDetailBloc extends Bloc<BillDetailEvent, BillDetailState> {
  BillDetailBloc({
    required BillItem initialBill,
  }) : super(
          BillDetailState(
            initialBill: initialBill,
          ),
        ) {
    on<BillLoadFile>(_onLoadFileData);
  }

  final BillService _billService = BillService();

  FutureOr<void> _onLoadFileData(
      BillLoadFile event, Emitter<BillDetailState> emit) async {
    HJResponse response = await _billService.getByBillFileId(event.billId);
    if (response.code == 0) {
      print('lxjtodo _onLoadFileData response: $response');
      final list = response.data as List? ?? [];
      List<BillFileItem> files = [];
      for (final item in list) {
        files.add(BillFileItem.fromJson(
            Map<String, dynamic>.from(item as Map? ?? {})));
      }
      print('lxjtodo: files: $files');
      state.initialBill.fileList = files;
      emit(state.copyWith(initialBill: state.initialBill));
    }
  }
}
