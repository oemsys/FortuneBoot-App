import 'dart:async';
import 'dart:core';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';
import 'package:hjproject/home/stats/models/bill_stats_chart_EI.dart';
import 'package:hjproject/home/stats/models/bill_stats_classification.dart';
import 'package:hjproject/home/bill_overview/models/bill_item.dart';
import 'package:hjproject/home/bill_overview/models/bill_statistics.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/request/include_request.dart';
import 'package:intl/intl.dart';
import 'package:time/time.dart';

part 'bills_stats_event.dart';
part 'bills_stats_state.dart';

class BillsStatsBloc extends Bloc<BillsStatsEvent, BillsStatsState> {
  BillsStatsBloc({
    required BillsRepository billsRepository,
  })  : _billsRepository = billsRepository,
        super(BillsStatsState(
            incomeList: [],
            expenseList: [],
            incomeCategarys: [],
            expenseCategarys: [])) {
    on<BillsStatsRequested>(_onSubscriptionRequested);
  }

  final IncludeService _includeService = IncludeService();

  final BillsRepository _billsRepository;

  Future<void> _onSubscriptionRequested(
    BillsStatsRequested event,
    Emitter<BillsStatsState> emit,
  ) async {
    emit(state.copyWith(status: () => BillsStatsStatus.loading));
    // 六个月前
    DateTime? startTime = event.startTime;
    DateTime? endTime = event.endTime;
    if (event.startTime == null || event.endTime == null) {
      endTime = DateTime.now();
      startTime = DateTime.now() - 24.weeks;
    }
    BillStatistics? statistics;
    List<BillStatsChartEi>? incomeTrends;
    List<BillStatsChartEi>? expenseTrends;
    List<BillStatsClassification>? incomeCategory;
    List<BillStatsClassification>? expenseCategory;

    /// 半年收支概览 收入 支出 结余 getBillStatistics
    {
      var billStatisticsResponse = await _includeService.getBillStatistics(
        _billsRepository.bookId() ?? 1,
        DateFormat('yyyy-MM-dd').format(startTime!),
        DateFormat('yyyy-MM-dd').format(endTime!),
      );

      if (billStatisticsResponse.code == 0) {
        if (billStatisticsResponse.data == null) {
          statistics = BillStatistics(
              income: 0, expense: 0, surplus: 0, staticTime: endTime);
          print('lxjtodo: $statistics startTime:$startTime, endTime:$endTime');
        } else {
          statistics = BillStatistics.fromJson(Map<String, dynamic>.from(
              billStatisticsResponse.data as Map? ?? {}));
          print('lxjtodo: $statistics startTime:$startTime, endTime:$endTime');
        }
      }
    }

    /// 收支趋势 getIncomeTrends 、 getExpenseTrends

    {
      var incomeTrendsResponse = await _includeService.getIncomeTrends(
          _billsRepository.bookId() ?? 1,
          3,
          DateFormat('yyyy-MM-dd HH:MM:ss').format(endTime));

      if (incomeTrendsResponse.code == 0) {
        if (incomeTrendsResponse.data == null) {
          incomeTrends = [];
          print('lxjtodo: incomeTrendsResponse $incomeTrends');
        } else {
          incomeTrends =
              List<dynamic>.from(incomeTrendsResponse.data as List? ?? [])
                  .map((ele) {
            return BillStatsChartEi.fromJson(
                Map<String, dynamic>.from(ele as Map? ?? {}));
          }).toList();
          print('lxjtodo: incomeTrendsResponse $incomeTrends');
        }
      }
    }

    {
      var expenseTrendsResponse = await _includeService.getExpenseTrends(
          _billsRepository.bookId() ?? 1,
          3,
          DateFormat('yyyy-MM-dd HH:MM:ss').format(endTime));
      if (expenseTrendsResponse.code == 0) {
        if (expenseTrendsResponse.data == null) {
          expenseTrends = [];
          print('lxjtodo: expenseTrendsResponse $expenseTrends');
        } else {
          expenseTrends =
              List<dynamic>.from(expenseTrendsResponse.data as List? ?? [])
                  .map((ele) {
            return BillStatsChartEi.fromJson(
                Map<String, dynamic>.from(ele as Map? ?? {}));
          }).toList();
          print('lxjtodo: expenseTrendsResponse $expenseTrends');
        }
      }
    }

    {
      /// 收入分析 getCategoryIncome
      var incomeCategoryResponse = await _includeService.getCategoryIncome(
          _billsRepository.bookId() ?? 1,
          DateFormat('yyyy-MM-dd').format(startTime),
          DateFormat('yyyy-MM-dd').format(endTime));

      if (incomeCategoryResponse.code == 0) {
        if (incomeCategoryResponse.data == null) {
          incomeCategory = [];
          print('lxjtodo: incomeCategoryResponse $incomeCategory');
        } else {
          incomeCategory =
              List<dynamic>.from(incomeCategoryResponse.data as List? ?? [])
                  .map((ele) {
            var incomeCate = BillStatsClassification.fromJson(
                Map<String, dynamic>.from(ele as Map? ?? {}));
            incomeCate.color = RandomColor.getColorObject(Options());
            return incomeCate;
          }).toList();
          print('lxjtodo: incomeCategoryResponse $incomeCategory');
        }
      }
    }
    {
      /// 支出分析 getCategoryExpense
      var expenseCategoryResponse = await _includeService.getCategoryExpense(
          _billsRepository.bookId() ?? 1,
          DateFormat('yyyy-MM-dd').format(startTime),
          DateFormat('yyyy-MM-dd').format(endTime));
      if (expenseCategoryResponse.code == 0) {
        if (expenseCategoryResponse.data == null) {
          expenseCategory = [];
          print('lxjtodo: expenseCategoryResponse $expenseCategory');
        } else {
          expenseCategory =
              List<dynamic>.from(expenseCategoryResponse.data as List? ?? [])
                  .map((ele) {
            var expenseCate = BillStatsClassification.fromJson(
                Map<String, dynamic>.from(ele as Map? ?? {}));
            expenseCate.color = RandomColor.getColorObject(Options());
            return expenseCate;
          }).toList();
          print('lxjtodo: expenseCategoryResponse $expenseCategory');
        }
      }
    }
    incomeCategory?.sort(
      (a, b) => a.percent! < b.percent! ? 1 : -1,
    );
    expenseCategory?.sort(
      (a, b) => a.percent! < b.percent! ? 1 : -1,
    );
    emit(state.copyWith(
        status: () => BillsStatsStatus.success,
        statistics: statistics,
        incomeList: incomeTrends,
        expenseList: expenseTrends,
        incomeCategarys: incomeCategory,
        expenseCategarys: expenseCategory));
  }
}
