import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hjproject/home/edit_bill/models/edit_select_item.dart';
import 'package:hjproject/home/edit_bill/viewmodel/edit_field_cell_viewmodel.dart';
import 'package:hjproject/home/todos_overview/models/bill_item.dart';
import 'package:hjproject/home/todos_overview/models/bill_item_add.dart';
import 'package:hjproject/login/model/login_model.dart';
import 'package:hjproject/request/account_request.dart';
import 'package:hjproject/request/bill_request.dart';
import 'package:hjproject/request/book_request.dart';
import 'package:hjproject/request/category_request.dart';
import 'package:hjproject/request/payee_request.dart';
import 'package:hjproject/request/tag_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:dio/dio.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:intl/intl.dart';

part 'edit_bill_event.dart';
part 'edit_bill_state.dart';

class EditBillBloc extends Bloc<EditBillEvent, EditBillState> {
  EditBillBloc({
    required BillsRepository billRepository,
    required BillItemAdd? initialBill,
    bool isCopyBill = false,
  })  : _billRepository = billRepository,
        super(
          EditBillState.init(
            bookId: billRepository.bookId() ?? 1,
            initialBill: initialBill,
            isNewBill: initialBill == null || isCopyBill,
          ),
        ) {
    on<EditBillSubmitted>(_onBillSubmitted);
    on<EditBillInitialized>(_onBillInitialized);
    on<EditBillTypeChange>(_onBillTypeChange);
  }

  final BillsRepository _billRepository;

  FutureOr<void> _onBillSubmitted(
      EditBillSubmitted event, Emitter<EditBillState> emit) async {
    BillItemAddData data = state.editBill.data!;
    print('lxjtodo: _onBillSubmitted request: ${data.toJson()}');
    FromBillAddRequest request = FromBillAddRequest();
    Response? response =
        await request.submitBill(data.toJson(), modify: !state.isNewBill);
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
  }

  FutureOr<void> _onBillInitialized(
      EditBillInitialized event, Emitter<EditBillState> emit) async {
    await refreshData(event.type, emit);
  }

  FutureOr<void> refreshData(BillType type, Emitter<EditBillState> emit) async {
    var groupId = _billRepository.groupId();
    var bookId = _billRepository.bookId();
    var billType = type.value;
    var books = await bookItems(BookService(), id: groupId, type: billType);
    AccountService service = AccountService();
    var accountRes = await service.getEnableList(groupId ?? 0);
    List<DropdownItem<AccountSelectItem>> expenseAccountList = [];
    List<DropdownItem<AccountSelectItem>> incomeAccountList = [];
    List<DropdownItem<AccountSelectItem>> transferAccountList = [];
    List<DropdownItem<AccountSelectItem>> transferOutAccountList = [];
    if (accountRes.code == 0) {
      accountRes.data?.forEach((element) {
        String accountName = element['accountName'] as String? ?? '';
        DropdownItem<AccountSelectItem> account = DropdownItem(
            label: accountName,
            value: AccountSelectItem(
                accountName, element['accountId'] as int? ?? 0));
        if ((element['canExpense'] as bool? ?? false)) {
          expenseAccountList.add(account);
        }
        if ((element['canIncome'] as bool? ?? false)) {
          incomeAccountList.add(account);
        }
        if ((element['canTransferIn'] as bool? ?? false)) {
          transferAccountList.add(account);
        }
        if ((element['canTransferOut'] as bool? ?? false)) {
          transferOutAccountList.add(account);
        }
      });
    }
    var payees = await payeeItems(PayeeService(), id: bookId, type: billType);
    var categroies = await categroyFutureItems(type, bookId ?? 1);
    var tags = await tagFutureItems(type, bookId ?? 1);
    emit(state.copyWith(
      bookList: books,
      payeeList: payees,
      expenseAccountList: expenseAccountList,
      incomeAccountList: incomeAccountList,
      transferAccountList: transferAccountList,
      transferOutAccountList: transferOutAccountList,
      categoryList: categroies,
      tagList: tags,
      status: EditBillStatus.success,
    ));
  }

  FutureOr<void> _onBillTypeChange(
      EditBillTypeChange event, Emitter<EditBillState> emit) async {
    var editedBill = state.editBill.copyWith(
        data: state.editBill.data?.copyWith(
      billType: event.type.value,
      categoryAmountPair: [],
      tagIdList: [],
      accountId: -1,
      accountToId: -1,
      payeeId: -1,
    ));
    print('lxjtodo: _onBillTypeChange: ${editedBill}');
    emit(state.copyWith(
      editBill: editedBill,
      status: EditBillStatus.loading,
    ));
    await refreshData(event.type, emit);
  }
}

Future<List<CategorySelectItem>> categroyFutureItems(
    BillType billType, int bookId) async {
  CategoryService categoryService = CategoryService();
  var response =
      await categoryService.getEnableList(bookId, type: billType.value);
  List<CategorySelectItem> categroyItems = [];
  if (response.code == 0) {
    var list = response.data as List? ?? [];
    for (final item in list) {
      categroyItems.add(CategorySelectItem.fromJson(
          Map<String, dynamic>.from(item as Map? ?? {})));
    }
  }
  return categroyItems;
}

Future<List<TagSelectItem>> tagFutureItems(
    BillType billType, int bookId) async {
  TagService tagService = TagService();
  var response = await tagService.getEnableList(bookId, type: billType.value);
  List<TagSelectItem> tagItems = [];
  if (response.code == 0) {
    var list = response.data as List? ?? [];
    for (final item in list) {
      tagItems.add(TagSelectItem.fromJson(
          Map<String, dynamic>.from(item as Map? ?? {})));
    }
  }
  return tagItems;
}
