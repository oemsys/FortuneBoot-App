import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/todos_overview/bloc/bills_overview_bloc.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Home/todos_overview/widgets/bill_list_tile.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import 'package:intl/intl.dart';

import '../../../generated/l10n.dart';

class BillsOverviewPage extends StatelessWidget {
  const BillsOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BillsOverviewBloc(
        billsRepository: context.read<BillsRepository>(),
      )..add(const BillsOverviewSubscriptionRequested()),
      child: const BillsOverviewView(),
    );
  }
}

class BillsOverviewView extends StatefulWidget {
  const BillsOverviewView({super.key});

  @override
  State<BillsOverviewView> createState() => _BillsOverviewViewState();
}

class _BillsOverviewViewState extends State<BillsOverviewView> with SingleTickerProviderStateMixin {
  DateTime? _currentGroupDate;
  final Map<String, GlobalKey> _groupKeys = {};
  List<DateTime> _groupDates = [];
  late TabController _tabController;
  final List<String> _tabs = ['日', '周', '月', '年'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(S.current.todosOverviewAppBarTitle,
            style: Theme.of(context).appBarTheme.titleTextStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              onTap: (index) {
                // 可以在这里处理不同时间范围的数据加载
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: S.current.todosOverviewFilterTooltip,
            onPressed: () {
              // 显示筛选选项
              _showFilterOptions(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 实现搜索功能
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(context),
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<BillsOverviewBloc, BillsOverviewState>(
                  listenWhen: (previous, current) =>
                      previous.status != current.status,
                  listener: (context, state) {
                    if (state.status == BillsOverviewStatus.failure) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(S.current.todosOverviewErrorSnackbarText),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  },
                ),
                BlocListener<BillsOverviewBloc, BillsOverviewState>(
                  listenWhen: (previous, current) =>
                      previous.lastDeletedBill != current.lastDeletedBill &&
                      current.lastDeletedBill != null,
                  listener: (context, state) {
                    final deletedBill = state.lastDeletedBill!;
                    final messenger = ScaffoldMessenger.of(context);
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            S.current.todosOverviewTodoDeletedSnackbarText(
                              deletedBill.title ?? '',
                            ),
                          ),
                          action: SnackBarAction(
                            label: S.current.todosOverviewUndoDeletionButtonText,
                            onPressed: () {
                              messenger.hideCurrentSnackBar();
                              context
                                  .read<BillsOverviewBloc>()
                                  .add(const BillsOverviewUndoDeletionRequested());
                            },
                          ),
                        ),
                      );
                  },
                ),
              ],
              child: BlocBuilder<BillsOverviewBloc, BillsOverviewState>(
                builder: (context, state) {
                  if (!(state.bills?.isNotEmpty == true)) {
                    if (state.status == BillsOverviewStatus.loading) {
                      return const Center(child: CupertinoActivityIndicator());
                    } else if (state.status != BillsOverviewStatus.success) {
                      return const SizedBox();
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              S.current.todosOverviewEmptyText,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
  
                  final bills = state.bills ?? [];
                  // 按日期分组
                  final Map<String, List<BillItem>> grouped = {};
                  final Map<String, DateTime> groupDateMap = {};
                  for (var bill in bills) {
                    final date = DateTime(
                      bill.tradeTime!.year,
                      bill.tradeTime!.month,
                      bill.tradeTime!.day,
                    );
                    final key = _dateKey(date);
                    groupDateMap[key] = date;
                    grouped.putIfAbsent(key, () => []).add(bill);
                  }
                  _groupDates = groupDateMap.values.toList()
                    ..sort((a, b) => b.compareTo(a));
                  // 初始化当前分组日期
                  if (_currentGroupDate == null && _groupDates.isNotEmpty) {
                    _currentGroupDate = _groupDates.first;
                  }
  
                  final groupKeys = _groupDates
                      .map((d) =>
                          _groupKeys.putIfAbsent(_dateKey(d), () => GlobalKey()))
                      .toList();
  
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _updateCurrentGroupDate(context));
                      // 上拉触底加载更多
                      if (notification is ScrollEndNotification &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 50) {
                        if (!state.isLoadingMore && state.hasMore) {
                          context
                              .read<BillsOverviewBloc>()
                              .add(const BillsOverviewLoadMoreRequested());
                        }
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<BillsOverviewBloc>()
                            .add(const BillsOverviewSubscriptionRequested());
                      },
                      child: ListView.builder(
                        itemCount: _groupDates.length + 1, // +1 for footer
                        itemBuilder: (context, groupIdx) {
                          if (groupIdx == _groupDates.length) {
                            // footer
                            return _buildFooterWidget(state);
                          }
                          final date = _groupDates[groupIdx];
                          final key = _groupKeys[_dateKey(date)]!;
                          final billsInGroup = grouped[_dateKey(date)] ?? [];
                          
                          // 计算当日收支总额
                          double dayIncome = 0;
                          double dayExpense = 0;
                          for (var bill in billsInGroup) {
                            if (bill.billType == BillType.income) {
                              dayIncome += bill.convertedAmount ?? 0;
                            } else if (bill.billType == BillType.expenditure) {
                              dayExpense += bill.convertedAmount ?? 0;
                            }
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _getGroupSeparator(context, date, key, dayIncome, dayExpense),
                              ...billsInGroup
                                  .map((bill) => BillListTile(
                                    bill: bill,
                                    onTap: () {
                                      // 点击账单项跳转到详情页
                                      _showBillDetails(context, bill);
                                    },
                                    onDismissed: (direction) {
                                      // 实现左滑删除功能
                                      // 这里需要添加删除账单的逻辑
                                    },
                                  ))
                                  .toList(),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加新账单
          Navigator.of(context).pushNamed('/edit-bill');
        },
        child: const Icon(Icons.add),
        tooltip: '添加账单',
      ),
    );
  }

  // 更新当前分组日期
  void _updateCurrentGroupDate(BuildContext context) {
    if (_groupDates.isEmpty) return;
    RenderBox? listBox = context.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    double listTop = listBox.localToGlobal(Offset.zero).dy;

    DateTime? newGroup;
    for (var date in _groupDates) {
      final key = _groupKeys[_dateKey(date)];
      if (key == null) continue;
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final offset = box.localToGlobal(Offset.zero).dy - listTop;
      if (offset <= 0) {
        newGroup = date;
      } else {
        break;
      }
    }
    if (newGroup != null && newGroup != _currentGroupDate) {
      setState(() {
        _currentGroupDate = newGroup;
      });
    }
  }

  // 日期格式化为字符串键
  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // 构建底部加载更多组件
  Widget _buildFooterWidget(BillsOverviewState state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.only(bottom: 32),
        height: 56,
        child: state.isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 1.5))
            : !state.hasMore
                ? Text(
                    '我是有底线的',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }

  // 构建顶部汇总卡片
  Widget _buildSummaryCard(BuildContext context) {
    return BlocBuilder<BillsOverviewBloc, BillsOverviewState>(
      builder: (context, state) {
        if (state.status != BillsOverviewStatus.success || state.bills == null) {
          return const SizedBox.shrink();
        }
        
        // 计算本月收支
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        double monthIncome = 0;
        double monthExpense = 0;
        
        for (var bill in state.bills!) {
          if (bill.tradeTime == null) continue;
          
          final billMonth = DateTime(bill.tradeTime!.year, bill.tradeTime!.month);
          if (billMonth.isAtSameMomentAs(currentMonth)) {
            if (bill.billType == BillType.income) {
              monthIncome += bill.convertedAmount ?? 0;
            } else if (bill.billType == BillType.expenditure) {
              monthExpense += bill.convertedAmount ?? 0;
            }
          }
        }
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${now.year}年${now.month}月收支',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // 跳转到月度报表
                      },
                      child: const Text('查看报表'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('收入', monthIncome, Colors.green),
                    _buildSummaryItem('支出', monthExpense, Colors.red),
                    _buildSummaryItem('结余', monthIncome - monthExpense, 
                      (monthIncome - monthExpense) >= 0 ? Colors.blue : Colors.red),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 构建汇总项
  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 构建日期分组标题
  Widget _getGroupSeparator(BuildContext context, DateTime date, Key key, double income, double expense) {
    // 使用更符合中国人习惯的日期格式
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    String dateText;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      dateText = '今天';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dateText = '昨天';
    } else {
      // 使用中文日期格式
      dateText = '${date.year}年${date.month}月${date.day}日';
      // 添加星期
      final weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
      dateText += ' ${weekdays[date.weekday % 7]}';
    }
    
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Row(
            children: [
              if (income > 0)
                Text(
                  '收入: ¥${income.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              if (income > 0 && expense > 0)
                const SizedBox(width: 8),
              if (expense > 0)
                Text(
                  '支出: ¥${expense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 显示筛选选项
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '筛选账单',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              _buildFilterOption(context, '全部', Icons.all_inclusive),
              _buildFilterOption(context, '收入', Icons.arrow_downward, color: Colors.green),
              _buildFilterOption(context, '支出', Icons.arrow_upward, color: Colors.red),
              _buildFilterOption(context, '转账', Icons.swap_horiz, color: Colors.blue),
              _buildFilterOption(context, '余额调整', Icons.settings, color: Colors.orange),
            ],
          ),
        );
      },
    );
  }
  
  // 构建筛选选项
  Widget _buildFilterOption(BuildContext context, String title, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        // 应用筛选
      },
    );
  }
  
  // 显示搜索对话框
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('搜索账单'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: '输入关键词搜索',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              // 执行搜索
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 执行搜索
              },
              child: const Text('搜索'),
            ),
          ],
        );
      },
    );
  }
  
  // 显示账单详情
  void _showBillDetails(BuildContext context, BillItem bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '账单详情',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildDetailItem('金额', '¥${bill.convertedAmount?.toStringAsFixed(2) ?? "0.00"}'),
                    _buildDetailItem('类型', bill.billType?.title ?? '未知'),
                    _buildDetailItem('分类', _getCategoryNames(bill)),
                    _buildDetailItem('账户', bill.accountName ?? '未知'),
                    if (bill.billType == BillType.transfer)
                      _buildDetailItem('转入账户', bill.toAccountName ?? '未知'),
                    _buildDetailItem('时间', DateFormat('yyyy-MM-dd HH:mm:ss').format(bill.tradeTime ?? DateTime.now())),
                    if (bill.remark != null && bill.remark!.isNotEmpty)
                      _buildDetailItem('备注', bill.remark!),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('编辑'),
                      onPressed: () {
                        Navigator.pop(context);
                        // 跳转到编辑页面
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('删除', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(context);
                        // 删除账单
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 构建详情项
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 获取分类名称
  String _getCategoryNames(BillItem bill) {
    if (bill.categoryAmountPair == null || bill.categoryAmountPair!.isEmpty) {
      return '未分类';
    }
    return bill.categoryAmountPair!
        .map((cat) => cat.categoryName)
        .where((name) => name != null && name.isNotEmpty)
        .join(', ');
  }
}
