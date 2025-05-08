part of 'edit_bill_bloc.dart';

enum EditBillStatus { initial, loading, success, failure, closed, submitFailed }

extension EditBillStatusX on EditBillStatus {
  bool get isLoadingOrInit => [
        EditBillStatus.loading,
        EditBillStatus.initial,
      ].contains(this);
}

final class EditBillState extends Equatable {
  EditBillState({
    this.status = EditBillStatus.initial,
    this.initialBill,
    this.bookList = const [],
    this.expenseAccountList = const [],
    this.transferAccountList = const [],
    this.incomeAccountList = const [],
    this.transferOutAccountList = const [],
    this.payeeList = const [],
    this.tagList = const [],
    this.categoryList = const [],
    required this.editBill,
  });

  EditBillState.init({
    this.status = EditBillStatus.initial,
    this.initialBill,
    this.bookList = const [],
    this.expenseAccountList = const [],
    this.transferAccountList = const [],
    this.incomeAccountList = const [],
    this.transferOutAccountList = const [],
    this.payeeList = const [],
    this.tagList = const [],
    this.categoryList = const [],
  }) {
    if (initialBill != null) {
      editBill = initialBill!.copyWith();
    } else {
      editBill = BillItemAdd(
          data: BillItemAddData(billType: BillType.expenditure.value));
    }
  }

  final EditBillStatus status;
  final BillItemAdd? initialBill;
  late BillItemAdd editBill;
  // 账单类型
  List<DropdownItem<BookSelectItem>> bookList;
  // 支出账户
  List<DropdownItem<AccountSelectItem>> expenseAccountList;
  // 转入账户
  List<DropdownItem<AccountSelectItem>> transferAccountList;
  // 收入账户
  List<DropdownItem<AccountSelectItem>> incomeAccountList;
  // 转出账户
  List<DropdownItem<AccountSelectItem>> transferOutAccountList;
  // 收款人
  List<DropdownItem<PayeeSelectItem>> payeeList;
  // 标签
  List<TagSelectItem> tagList;
  // 类别
  List<CategorySelectItem> categoryList;

  bool get isNewBill => initialBill == null;

  EditBillState copyWith({
    EditBillStatus? status,
    BillItemAdd? initialBill,
    List<DropdownItem<BookSelectItem>>? bookList,
    List<DropdownItem<AccountSelectItem>>? expenseAccountList,
    List<DropdownItem<AccountSelectItem>>? transferAccountList,
    List<DropdownItem<AccountSelectItem>>? incomeAccountList,
    List<DropdownItem<AccountSelectItem>>? transferOutAccountList,
    List<DropdownItem<PayeeSelectItem>>? payeeList,
    List<TagSelectItem>? tagList,
    List<CategorySelectItem>? categoryList,
    BillItemAdd? editBill,
  }) {
    return EditBillState(
      status: status ?? this.status,
      initialBill: initialBill ?? this.initialBill,
      bookList: bookList ?? this.bookList,
      expenseAccountList: expenseAccountList ?? this.expenseAccountList,
      transferAccountList: transferAccountList ?? this.transferAccountList,
      incomeAccountList: incomeAccountList ?? this.incomeAccountList,
      transferOutAccountList:
          transferOutAccountList ?? this.transferOutAccountList,
      payeeList: payeeList ?? this.payeeList,
      tagList: tagList ?? this.tagList,
      categoryList: categoryList ?? this.categoryList,
      editBill: editBill ?? this.editBill,
    );
  }

  @override
  List<Object?> get props => [
        status,
        initialBill,
        bookList,
        expenseAccountList,
        transferAccountList,
        incomeAccountList,
        transferOutAccountList,
        payeeList,
        tagList,
        categoryList,
        editBill,
      ];
}
