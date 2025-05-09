import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/stats/bloc/setting_bloc.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import '../../../generated/l10n.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingBloc(billsRepository: context.read<BillsRepository>()),
      child: const StatsView(),
    );
  }
}

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['收支趋势', '收入分析', '支出分析', '资产负债'];
  int _selectedTimeRange = 1; // 0: 周, 1: 月, 2: 年
  final List<String> _timeRanges = ['周', '月', '年'];

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
    final state = context.watch<SettingBloc>().state;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.statsAppBarTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          isScrollable: true,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          _buildTimeRangeSelector(),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendsTab(context, state),
          _buildIncomeAnalysisTab(context, state),
          _buildExpenseAnalysisTab(context, state),
          _buildAssetsLiabilitiesTab(context, state),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: TextStyle(
            color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        dropdownColor: Theme.of(context).cardColor,
        items: List.generate(_timeRanges.length, (index) {
          return DropdownMenuItem(
            value: index,
            child: Text(_timeRanges[index],
                style: TextStyle(
                  color: index == _selectedTimeRange
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                )),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTimeRange = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildTrendsTab(BuildContext context, SettingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 24),
          Text(
            '收支趋势图',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildSimpleLineChart(context),
          const SizedBox(height: 24),
          _buildCompletionStats(context, state),
        ],
      ),
    );
  }

  Widget _buildIncomeAnalysisTab(BuildContext context, SettingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '收入分类占比',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildSimplePieChart(
            context,
            [
              {
                'name': '工资',
                'amount': 3500.0,
                'color': Colors.blue,
                'percent': 35
              },
              {
                'name': '投资',
                'amount': 2500.0,
                'color': Colors.green,
                'percent': 25
              },
              {
                'name': '兼职',
                'amount': 2000.0,
                'color': Colors.purple,
                'percent': 20
              },
              {
                'name': '其他',
                'amount': 1500.0,
                'color': Colors.orange,
                'percent': 15
              },
            ],
          ),
          const SizedBox(height: 24),
          _buildCategoryList(
            context,
            [
              {
                'name': '工资',
                'amount': 3500.0,
                'color': Colors.blue,
                'percent': 35
              },
              {
                'name': '投资',
                'amount': 2500.0,
                'color': Colors.green,
                'percent': 25
              },
              {
                'name': '兼职',
                'amount': 2000.0,
                'color': Colors.purple,
                'percent': 20
              },
              {
                'name': '其他',
                'amount': 1500.0,
                'color': Colors.orange,
                'percent': 15
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseAnalysisTab(BuildContext context, SettingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '支出分类占比',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildSimplePieChart(
            context,
            [
              {
                'name': '餐饮',
                'amount': 1800.0,
                'color': Colors.red,
                'percent': 30
              },
              {
                'name': '购物',
                'amount': 1500.0,
                'color': Colors.amber,
                'percent': 25
              },
              {
                'name': '交通',
                'amount': 1200.0,
                'color': Colors.cyan,
                'percent': 20
              },
              {
                'name': '娱乐',
                'amount': 900.0,
                'color': Colors.deepPurple,
                'percent': 15
              },
              {
                'name': '其他',
                'amount': 600.0,
                'color': Colors.teal,
                'percent': 10
              },
            ],
          ),
          const SizedBox(height: 24),
          _buildCategoryList(
            context,
            [
              {
                'name': '餐饮',
                'amount': 1800.0,
                'color': Colors.red,
                'percent': 30
              },
              {
                'name': '购物',
                'amount': 1500.0,
                'color': Colors.amber,
                'percent': 25
              },
              {
                'name': '交通',
                'amount': 1200.0,
                'color': Colors.cyan,
                'percent': 20
              },
              {
                'name': '娱乐',
                'amount': 900.0,
                'color': Colors.deepPurple,
                'percent': 15
              },
              {
                'name': '其他',
                'amount': 600.0,
                'color': Colors.teal,
                'percent': 10
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsLiabilitiesTab(BuildContext context, SettingState state) {
    // 模拟数据 - 实际应用中应从API获取
    final double totalAssets = 120000.0;
    final double totalLiabilities = 45000.0;
    final double netWorth = totalAssets - totalLiabilities;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '净资产',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${NumberFormat('#,##0.00').format(netWorth)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: netWorth >= 0 ? Colors.blue : Colors.red,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _buildAssetLiabilityRow(
                    context,
                    '总资产',
                    totalAssets,
                    Colors.green,
                    Icons.arrow_upward,
                  ),
                  const SizedBox(height: 16),
                  _buildAssetLiabilityRow(
                    context,
                    '总负债',
                    totalLiabilities,
                    Colors.red,
                    Icons.arrow_downward,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '资产分布',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildAssetsList(context),
          const SizedBox(height: 24),
          Text(
            '负债分布',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildLiabilitiesList(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    // 模拟数据 - 实际应用中应从API获取
    final double monthlyIncome = 9500.0;
    final double monthlyExpense = 7200.0;
    final double monthlyBalance = monthlyIncome - monthlyExpense;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本月收支概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(context, '收入', monthlyIncome, Colors.green),
                _buildSummaryItem(context, '支出', monthlyExpense, Colors.red),
                _buildSummaryItem(
                  context,
                  '结余',
                  monthlyBalance,
                  monthlyBalance >= 0 ? Colors.blue : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String label, double amount, Color color) {
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
          '¥${NumberFormat('#,##0.00').format(amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleLineChart(BuildContext context) {
    // 简单的图表替代，不使用fl_chart库
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 收入柱状图
                _buildBarGroup(
                    context, '1月', 2500, 1800, Colors.green, Colors.red),
                _buildBarGroup(
                    context, '2月', 1800, 2200, Colors.green, Colors.red),
                _buildBarGroup(
                    context, '3月', 3200, 1500, Colors.green, Colors.red),
                _buildBarGroup(
                    context, '4月', 2000, 2400, Colors.green, Colors.red),
                _buildBarGroup(
                    context, '5月', 2800, 1900, Colors.green, Colors.red),
                _buildBarGroup(
                    context, '6月', 3600, 2100, Colors.green, Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('收入'),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('支出'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarGroup(BuildContext context, String label, double income,
      double expense, Color incomeColor, Color expenseColor) {
    final maxValue = 4000.0; // 图表最大值
    final incomeHeight = (income / maxValue) * 200; // 200是图表高度
    final expenseHeight = (expense / maxValue) * 200;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 15,
                height: incomeHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: incomeColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              Container(
                width: 15,
                height: expenseHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: expenseColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePieChart(
      BuildContext context, List<Map<String, dynamic>> data) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: SimplePieChartPainter(data),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item['color'] as Color?,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${item['name']} (${item['percent']}%)'),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStats(BuildContext context, SettingState state) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '账单完成情况',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.green),
              ),
              title: Text(S.current.statsCompletedTodoCountLabel),
              trailing: Text(
                '',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.radio_button_unchecked_rounded,
                    color: Colors.orange),
              ),
              title: Text(S.current.statsActiveTodoCountLabel),
              trailing: Text(
                '',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      BuildContext context, List<Map<String, dynamic>> categories) {
    return Column(
      children: categories.map((category) {
        return ListTile(
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: category['color'] as Color?,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            category['name'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¥${NumberFormat('#,##0.00').format(category['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${category['percent']}%',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssetLiabilityRow(BuildContext context, String label,
      double amount, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        Text(
          '¥${NumberFormat('#,##0.00').format(amount)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildAssetsList(BuildContext context) {
    // 模拟数据 - 实际应用中应从API获取
    final List<Map<String, dynamic>> assets = [
      {'name': '现金', 'amount': 15000.0, 'icon': Icons.money},
      {'name': '银行存款', 'amount': 50000.0, 'icon': Icons.account_balance},
      {'name': '股票', 'amount': 35000.0, 'icon': Icons.trending_up},
      {'name': '基金', 'amount': 20000.0, 'icon': Icons.pie_chart},
    ];

    return Column(
      children: assets.map((asset) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(asset['icon'] as IconData?, color: Colors.green),
            ),
            title: Text(
              asset['name'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '¥${NumberFormat('#,##0.00').format(asset['amount'])}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiabilitiesList(BuildContext context) {
    // 模拟数据 - 实际应用中应从API获取
    final List<Map<String, dynamic>> liabilities = [
      {'name': '信用卡', 'amount': 5000.0, 'icon': Icons.credit_card},
      {'name': '房贷', 'amount': 30000.0, 'icon': Icons.home},
      {'name': '车贷', 'amount': 10000.0, 'icon': Icons.directions_car},
    ];

    return Column(
      children: liabilities.map((liability) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(liability['icon'] as IconData?, color: Colors.red),
            ),
            title: Text(
              liability['name'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              '¥${NumberFormat('#,##0.00').format(liability['amount'])}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 简单的饼图绘制器
class SimplePieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  SimplePieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        size.width < size.height ? size.width / 2 * 0.8 : size.height / 2 * 0.8;

    double startAngle = 0;

    for (var item in data) {
      final sweepAngle = (item['percent'] as num) / 100 * 2 * 3.14159;
      final paint = Paint()
        ..color = item['color'] as Color? ?? Colors.grey
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // 绘制中心空白
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
