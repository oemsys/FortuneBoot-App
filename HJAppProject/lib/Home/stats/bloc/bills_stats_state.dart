part of 'bills_stats_bloc.dart';

enum BillsStatsStatus { initial, loading, success, failure }

final class BillsStatsState extends Equatable {
  BillsStatsState({
    this.status = BillsStatsStatus.initial,
    this.statistics,
    required this.incomeList,
    required this.expenseList,
    required this.incomeCategarys,
    required this.expenseCategarys,
  });

  final BillsStatsStatus status;
  final BillStatistics? statistics;
  List<BillStatsChartEi> incomeList;
  List<BillStatsChartEi> expenseList;
  List<BillStatsClassification> incomeCategarys;
  List<BillStatsClassification> expenseCategarys;

  // 分页相关

  BillsStatsState copyWith({
    BillsStatsStatus Function()? status,
    BillStatistics? statistics,
    List<BillStatsChartEi>? incomeList,
    List<BillStatsChartEi>? expenseList,
    List<BillStatsClassification>? incomeCategarys,
    List<BillStatsClassification>? expenseCategarys,
  }) {
    return BillsStatsState(
        status: status != null ? status() : this.status,
        statistics: statistics ?? this.statistics,
        incomeList: incomeList ?? this.incomeList,
        expenseList: expenseList ?? this.expenseList,
        incomeCategarys: incomeCategarys ?? this.incomeCategarys,
        expenseCategarys: expenseCategarys ?? this.expenseCategarys);
  }

  @override
  List<Object?> get props => [
        status,
        incomeList,
        expenseList,
        incomeCategarys,
        expenseCategarys,
        statistics,
      ];
}
