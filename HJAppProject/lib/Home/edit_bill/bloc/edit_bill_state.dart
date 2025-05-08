part of 'edit_bill_bloc.dart';

enum EditBillStatus { initial, loading, success, failure, closed, submitFailed }

extension EditBillStatusX on EditBillStatus {
  bool get isLoadingOrSuccess => [
        EditBillStatus.loading,
        EditBillStatus.success,
      ].contains(this);
}

final class EditBillState extends Equatable {
  const EditBillState({
    this.status = EditBillStatus.initial,
    this.initialBill,
    this.title = '',
    this.description = '',
  });

  final EditBillStatus status;
  final BillItemAdd? initialBill;
  final String title;
  final String description;

  bool get isNewBill => initialBill == null;

  EditBillState copyWith({
    EditBillStatus? status,
    BillItemAdd? initialBill,
    String? title,
    String? description,
  }) {
    return EditBillState(
      status: status ?? this.status,
      initialBill: initialBill ?? this.initialBill,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [status, initialBill, title, description];
}
