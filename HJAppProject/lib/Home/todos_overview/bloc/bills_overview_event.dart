part of 'bills_overview_bloc.dart';

sealed class BillsOverviewEvent extends Equatable {
  const BillsOverviewEvent();

  @override
  List<Object> get props => [];
}

final class BillsOverviewSubscriptionRequested extends BillsOverviewEvent {
  const BillsOverviewSubscriptionRequested();
}

final class BillsOverviewUndoDeletionRequested extends BillsOverviewEvent {
  const BillsOverviewUndoDeletionRequested();
}

/// 上拉加载更多事件
class BillsOverviewLoadMoreRequested extends BillsOverviewEvent {
  const BillsOverviewLoadMoreRequested();
}
