import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_summary_bar.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_loading_indicator.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_error_view.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_empty_state.dart';
import 'package:hjproject/Home/payee_manage/model/payee.dart';
import 'package:hjproject/Home/payee_manage/data/payee_service.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_edit_dialog.dart';

/// 交易对象列表视图：统一三态切换 + 列表渲染
class PayeeListView extends StatelessWidget {
  const PayeeListView({
    super.key,
    required this.loading,
    required this.error,
    required this.total,
    required this.currentPage,
    required this.rows,
    required this.onRetry,
    required this.onMovedToRecycleBin,
  });

  final bool loading;
  final String? error;
  final int total;
  final int currentPage;
  final List<Payee> rows;
  final VoidCallback onRetry;
  final VoidCallback onMovedToRecycleBin;

  @override
  Widget build(BuildContext context) {
    // 自适应横向边距
    double horizontalPadding() {
      final width = MediaQuery.of(context).size.width;
      if (width < 600) return 16;
      if (width < 1024) return 20;
      return 24;
    }

    // 构建列表/空态
    Widget buildListOrEmpty() {
      final double hPadding = horizontalPadding();
      if (rows.isEmpty) {
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          children: const [
            SizedBox(height: 80),
            PayeeEmptyState(),
            SizedBox(height: 16),
          ],
        );
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        itemCount: rows.length + 2, // 顶部摘要 + 列表项 + 底部间距
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: CategorySummaryBar(
                typeText: '交易对象',
                total: total,
                currentPage: currentPage,
              ),
            );
          }
          if (index == rows.length + 1) {
            return const SizedBox(height: 12);
          }
          final payee = rows[index - 1];
          return _PayeeTile(item: payee, onMovedToRecycleBin: onMovedToRecycleBin);
        },
      );
    }

    // 状态切换
    if (loading) {
      return const PayeeLoadingIndicator();
    }
    if (error != null) {
      return PayeeErrorView(message: error ?? '加载失败', onRetry: onRetry);
    }
    return buildListOrEmpty();
  }
}

class _PayeeTile extends StatelessWidget {
  const _PayeeTile({required this.item, required this.onMovedToRecycleBin});

  final Payee item;
  final VoidCallback onMovedToRecycleBin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRemark = (item.remark != null) && (item.remark!.trim().isNotEmpty);

    // 使用自定义容器 + Row/Column + Wrap 避免 ListTile 布局压缩导致的溢出
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧主信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 仅占所需高度，避免被强行压缩
                children: [
                  Text(
                    item.payeeName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (hasRemark) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.remark!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6), // 为标签区域留出垂直空间
                  _StatusWrap(item: item),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右侧排序号（独立列，避免与标签争抢空间）
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  tooltip: '更多操作',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // 打开编辑对话框
                      final edited = await showDialog<Map<String, dynamic>?>(
                        context: context,
                        builder: (ctx) => PayeeEditDialog(initial: item),
                      );
                      if (edited == null) return;
                      // 组装请求体并调用修改接口
                      try {
                        final bookId = context.read<BillsRepository>().bookId() ?? item.bookId;
                        await PayeeService().modify(
                          payeeId: item.payeeId,
                          bookId: bookId,
                          payeeName: (edited['payeeName'] as String?) ?? item.payeeName,
                          sort: (edited['sort'] as int?) ?? item.sort,
                          canExpense: (edited['canExpense'] as bool?) ?? item.canExpense,
                          canIncome: (edited['canIncome'] as bool?) ?? item.canIncome,
                          enable: (edited['enable'] as bool?) ?? item.enable,
                          remark: edited.containsKey('remark') ? edited['remark'] as String? : item.remark,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存修改')));
                        onMovedToRecycleBin(); // 复用刷新回调，仅刷新当前页
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    } else if (value == 'move') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) {
                          final cs = Theme.of(ctx).colorScheme;
                          final tt = Theme.of(ctx).textTheme;
                          return AlertDialog(
                            title: Text('移入回收站', style: tt.titleMedium),
                            content: Text(
                              '确认将“${item.payeeName}”移入回收站？该操作可在回收站中恢复。',
                              style: tt.bodyMedium,
                            ),
                            actions: [
                              OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: cs.outlineVariant),
                                  foregroundColor: cs.onSurfaceVariant,
                                ),
                                child: Text('取消', style: tt.labelLarge),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: cs.error),
                                  foregroundColor: cs.error,
                                ),
                                child: Text('确认', style: tt.labelLarge),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed != true) return;
                      try {
                        final bookId = context.read<BillsRepository>().bookId() ?? item.bookId;
                        await PayeeService().moveToRecycleBin(bookId: bookId, payeeId: item.payeeId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已移入回收站')));
                        onMovedToRecycleBin();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem<String>(value: 'move', child: Text('移入回收站')),
                  ],
                  icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                ),
                const SizedBox(height: 8),
                Text(
                  '#${item.sort}',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusWrap extends StatelessWidget {
  const _StatusWrap({required this.item});

  final Payee item;

  @override
  Widget build(BuildContext context) {
    // 标签常显 + 色彩编码
    final expenseColor = item.canExpense ? Colors.redAccent : Colors.grey;
    final incomeColor = item.canIncome ? Colors.green : Colors.grey;
    final theme = Theme.of(context);

    final chips = <Widget>[
      _statusChip(
        context,
        label: item.canExpense ? '支出允许' : '支出禁止',
        color: expenseColor,
        icon: Icons.arrow_upward,
        tooltip: item.canExpense ? '可支出' : '不可支出',
      ),
      _statusChip(
        context,
        label: item.canIncome ? '收入允许' : '收入禁止',
        color: incomeColor,
        icon: Icons.arrow_downward,
        tooltip: item.canIncome ? '可收入' : '不可收入',
      ),
      _statusChip(
        context,
        label: item.enable ? '启用' : '停用',
        color: item.enable ? theme.colorScheme.primary : Colors.grey,
        icon: item.enable ? Icons.check_circle : Icons.pause_circle_filled,
      ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _statusChip(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    String? tooltip,
  }) {
    final bg = color.withOpacity(0.12);
    final fg = color;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }
}