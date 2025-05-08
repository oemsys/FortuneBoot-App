part of 'edit_bill_bloc.dart';

sealed class EditBillEvent extends Equatable {
  const EditBillEvent();

  @override
  List<Object> get props => [];
}

final class EditBillSubmitted extends EditBillEvent {
  final Map<String, dynamic> submitData;
  const EditBillSubmitted(this.submitData);
  @override
  List<Object> get props => [submitData];
}
