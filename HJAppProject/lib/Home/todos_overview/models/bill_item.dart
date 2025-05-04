import 'package:json_annotation/json_annotation.dart';

part 'bill_item.g.dart';

enum BillType {
  @JsonValue(1)
  expenditure(1, '支出'), // 支出
  @JsonValue(2)
  income(2, '收入'), // 收入
  @JsonValue(3)
  transfer(3, '转账'), // 转账
  @JsonValue(4)
  adjust(4, '余额调整'); // 余额调整

  final int value;
  final String title;
  const BillType(this.value, this.title);
}

// 使用下面命令自动生成代码
// flutter pub run build_runner build
@JsonSerializable()
class BillItem {
  int? billId;
  int? bookId;
  String? bookName;
  String? title;
  DateTime? tradeTime;
  int? accountId;
  String? accountName;
  double? amount;
  String? currencyCode;
  double? convertedAmount;
  int? payeeId;
  String? payeeName;
  BillType? billType;
  int? toAccountId;
  String? toAccountName;
  bool? confirm;
  bool? include;
  String? remark;
  List<CategoryAmountPair>? categoryAmountPair;
  List<TagList>? tagList;

  BillItem(
      {this.billId,
      this.bookId,
      this.bookName,
      this.title,
      this.tradeTime,
      this.accountId,
      this.accountName,
      this.amount,
      this.currencyCode,
      this.convertedAmount,
      this.payeeId,
      this.payeeName,
      this.billType,
      this.toAccountId,
      this.toAccountName,
      this.confirm,
      this.include,
      this.remark,
      this.categoryAmountPair,
      this.tagList});

  factory BillItem.fromJson(Map<String, dynamic> json) =>
      _$BillItemFromJson(json);
  Map<String, dynamic> toJson() => _$BillItemToJson(this);

  @override
  String toString() {
    return 'BillItem{billId: $billId, bookId: $bookId, bookName: $bookName, title: $title, tradeTime: $tradeTime, accountId: $accountId, accountName: $accountName, amount: $amount, currencyCode: $currencyCode, convertedAmount: $convertedAmount, payeeId: $payeeId, payeeName: $payeeName, billType: $billType, toAccountId: $toAccountId, toAccountName: $toAccountName, confirm: $confirm, include: $include, remark: $remark, categoryAmountPair: $categoryAmountPair, tagList: $tagList}';
  }
}

@JsonSerializable()
class CategoryAmountPair {
  int? categoryId;
  String? categoryName;
  int? amount;

  CategoryAmountPair({this.categoryId, this.categoryName, this.amount});

  factory CategoryAmountPair.fromJson(Map<String, dynamic> json) =>
      _$CategoryAmountPairFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryAmountPairToJson(this);

  @override
  String toString() {
    return 'CategoryAmountPair{categoryId: $categoryId, categoryName: $categoryName, amount: $amount}';
  }
}

@JsonSerializable()
class TagList {
  List<dynamic>? children;
  int? tagId;
  String? tagName;
  int? bookId;
  int? parentId;
  bool? canExpense;
  bool? canIncome;
  bool? canTransfer;
  bool? enable;
  int? sort;
  String? remark;
  int? id;

  TagList(
      {this.children,
      this.tagId,
      this.tagName,
      this.bookId,
      this.parentId,
      this.canExpense,
      this.canIncome,
      this.canTransfer,
      this.enable,
      this.sort,
      this.remark,
      this.id});

  factory TagList.fromJson(Map<String, dynamic> json) =>
      _$TagListFromJson(json);
  Map<String, dynamic> toJson() => _$TagListToJson(this);

  @override
  String toString() {
    return 'TagList{children: $children, tagId: $tagId, tagName: $tagName, bookId: $bookId, parentId: $parentId, canExpense: $canExpense, canIncome: $canIncome, canTransfer: $canTransfer, enable: $enable, sort: $sort, remark: $remark, id: $id}';
  }
}
