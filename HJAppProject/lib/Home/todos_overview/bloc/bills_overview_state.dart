part of 'bills_overview_bloc.dart';

enum BillsOverviewStatus { initial, loading, success, failure }

final class BillsOverviewState extends Equatable {
  const BillsOverviewState({
    this.status = BillsOverviewStatus.initial,
    this.lastDeletedBill,
    this.bills = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final BillsOverviewStatus status;
  final BillItem? lastDeletedBill;
  final List<BillItem>? bills;

  // 分页相关
  final bool hasMore; // 是否还有更多数据
  final bool isLoadingMore; // 是否正在加载更多

  BillsOverviewState copyWith({
    BillsOverviewStatus Function()? status,
    List<BillItem>? bills,
    BillItem? Function()? lastDeletedBill,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return BillsOverviewState(
      status: status != null ? status() : this.status,
      bills: bills ?? this.bills,
      lastDeletedBill:
          lastDeletedBill != null ? lastDeletedBill() : this.lastDeletedBill,
      hasMore: hasMore != null ? hasMore : this.hasMore,
      isLoadingMore: isLoadingMore != null ? isLoadingMore : this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bills,
        lastDeletedBill,
        bills,
        hasMore,
        isLoadingMore,
      ];
}
