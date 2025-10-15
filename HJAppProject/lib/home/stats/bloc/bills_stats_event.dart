part of 'bills_stats_bloc.dart';

sealed class BillsStatsEvent extends Equatable {
  const BillsStatsEvent();

  @override
  List<Object> get props => [];
}

final class BillsStatsRequested extends BillsStatsEvent {
  DateTime? startTime;
  DateTime? endTime;
  BillsStatsRequested({this.startTime, this.endTime});
}
