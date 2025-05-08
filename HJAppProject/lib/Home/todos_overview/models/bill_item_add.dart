import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bill_item_add.g.dart';

@immutable
@JsonSerializable()
class BillItemAdd {
  Data? data;
  List<String>? files;

  BillItemAdd({this.data, this.files});
  factory BillItemAdd.fromJson(Map<String, dynamic> json) =>
      _$BillItemAddFromJson(json);
  Map<String, dynamic> toJson() => _$BillItemAddToJson(this);

  // BillItemAdd.fromBillItem(BillItem billItem) {
  //   // data = Data(
  //   //   bookId: billItem.bookId,
  //   //   title: billItem.title,
  //   //   tradeTime: billItem.tradeTime,
  //   //   accountId: billItem.accountId,
  //   //   accountToId: billItem.accountToId,
  //   //   categoryAmountPair: billItem.categoryAmountPair,
  //   //   amount: billItem.amount,
  //   //   convertedAmount: billItem.convertedAmount,
  //   //   payeeId: billItem.payeeId,
  //   //   billType: billItem.billType,
  //   // );
  // }
}

@JsonSerializable()
class Data {
  int? bookId;
  String? title;
  String? tradeTime;
  int? accountId;
  int? accountToId;
  List<Map<String, num>>? categoryAmountPair;
  int? amount;
  int? convertedAmount;
  int? payeeId;
  int? billType;
  int? toAccountId;
  bool? confirm;
  bool? include;
  String? remark;
  List<int>? tagIdList;
  List<String>? fileList;

  Data(
      {this.bookId,
      this.title,
      this.tradeTime,
      this.accountId,
      this.accountToId,
      this.categoryAmountPair,
      this.amount,
      this.convertedAmount,
      this.payeeId,
      this.billType,
      this.toAccountId,
      this.confirm,
      this.include,
      this.remark,
      this.tagIdList,
      this.fileList});

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
  Map<String, dynamic> toJson() => _$DataToJson(this);
}
