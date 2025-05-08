part of 'edit_bill_bloc.dart';

sealed class EditBillEvent extends Equatable {
  const EditBillEvent();

  @override
  List<Object> get props => [];
}

// 初始化数据
final class EditBillInitialized extends EditBillEvent {
  BillType type;
  EditBillInitialized(this.type);
  @override
  List<Object> get props => [type];
}

final class EditBillTypeChange extends EditBillEvent {
  BillType type;
  EditBillTypeChange(this.type);
  @override
  List<Object> get props => [type];
}

final class EditBillSubmitted extends EditBillEvent {
  final Map<String, dynamic> submitData;
  const EditBillSubmitted(this.submitData);
  @override
  List<Object> get props => [submitData];
}
