import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/Home/account_manage/models/fortune_account.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/Request/account_request.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_summary_bar.dart';

class AccountManagePage extends StatefulWidget {
  const AccountManagePage({Key? key}) : super(key: key);

  @override
  State<AccountManagePage> createState() => _AccountManagePageState();
}

class _AccountManagePageState extends State<AccountManagePage> {
  final AccountQueryService _service = AccountQueryService();

  bool _loading = true;
  String? _error;
  List<FortuneAccount> _rows = const <FortuneAccount>[];

  // 顶部类型切换：1活期、2信用、3资产、4贷款；默认资产(3)
  int _accountType = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groupId = context.read<BillsRepository>().groupId() ?? 1;
      final data = await _service.getPage(
        groupId: groupId,
        accountType: _accountType,
        pageNum: 1,
        pageSize: 50, // 保留分页参数，当前仅做首屏展示
      );
      setState(() {
        _rows = data.rows;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _onTypeChanged(int t) {
    if (_accountType == t) return;
    setState(() {
      _accountType = t;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    double horizontalPadding() {
      final width = MediaQuery.of(context).size.width;
      if (width < 600) return 16;
      if (width < 1024) return 20;
      return 24;
    }

    final hPadding = horizontalPadding();

    return Scaffold(
      appBar: AppBar(
        title: const Text('账户管理'),
      ),
      body: Column(
        children: [
          // 顶部类型切换
          Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, 8),
            child: _TypeSegmented(
              selected: _accountType,
              onChanged: _onTypeChanged,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(hPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double hPadding) {
    // 统一三态切换，风格参考“交易对象/分类管理”
    if (_loading) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              '正在加载账户...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      final theme = Theme.of(context);
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error ?? '加载失败',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ),
        ],
      );
    }

    if (_rows.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        children: const [
          SizedBox(height: 80),
          _EmptyState(),
          SizedBox(height: 16),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      itemCount: _rows.length + 2, // 顶部摘要 + 列表项 + 底部间距
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: CategorySummaryBar(
              typeText: _typeLabel(_accountType),
              total: _rows.length,
              currentPage: 1,
              // 暂无分页，展示当前数量即可
            ),
          );
        }
        if (index == _rows.length + 1) {
          return const SizedBox(height: 12);
        }
        final item = _rows[index - 1];
        return _AccountTile(item: item);
      },
    );
  }

  String _typeLabel(int t) {
    switch (t) {
      case 1:
        return '活期账户';
      case 2:
        return '信用账户';
      case 3:
        return '资产账户';
      case 4:
        return '贷款账户';
      default:
        return '账户';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 56, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(
          '暂无相关账户',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '请切换类型或稍后重试',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TypeSegmented extends StatelessWidget {
  const _TypeSegmented({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // 使用 SegmentedButton 以保持与工程现有风格一致（参考编辑账单页）
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 1, label: Text('活期')),
        ButtonSegment(value: 2, label: Text('信用')),
        ButtonSegment(value: 3, label: Text('资产')),
        ButtonSegment(value: 4, label: Text('贷款')),
      ],
      selected: {selected},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) onChanged(s.first);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.item});

  final FortuneAccount item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRemark = (item.remark != null) && (item.remark!.trim().isNotEmpty);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：名称 + 次要信息 + 标签
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.accountName ?? '未命名账户',
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
                  const SizedBox(height: 6),
                  _AbilityWrap(item: item),
                  const SizedBox(height: 4),
                  _MicroStatusRow(item: item),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右侧：金额
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.balanceText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if ((item.currencyCode ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.currencyCode!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityWrap extends StatelessWidget {
  const _AbilityWrap({required this.item});

  final FortuneAccount item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      _statusChip(
        context,
        label: item.canExpense ? '支出允许' : '支出禁止',
        color: item.canExpense ? Colors.redAccent : Colors.grey,
        icon: Icons.arrow_upward,
        tooltip: item.canExpense ? '可支出' : '不可支出',
      ),
      _statusChip(
        context,
        label: item.canIncome ? '收入允许' : '收入禁止',
        color: item.canIncome ? Colors.green : Colors.grey,
        icon: Icons.arrow_downward,
        tooltip: item.canIncome ? '可收入' : '不可收入',
      ),
      _statusChip(
        context,
        label: item.canTransferOut ? '转出允许' : '转出禁止',
        color: item.canTransferOut ? theme.colorScheme.primary : Colors.grey,
        icon: Icons.upload_outlined,
      ),
      _statusChip(
        context,
        label: item.canTransferIn ? '转入允许' : '转入禁止',
        color: item.canTransferIn ? theme.colorScheme.primary : Colors.grey,
        icon: Icons.download_outlined,
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

class _MicroStatusRow extends StatelessWidget {
  const _MicroStatusRow({required this.item});
  final FortuneAccount item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _microTag(
          context,
          label: item.enable ? '启用' : '停用',
          color: item.enable ? theme.colorScheme.primary : Colors.grey,
        ),
        const SizedBox(width: 6),
        _microTag(
          context,
          label: item.include ? '计入' : '不计入',
          color: item.include ? Colors.teal : Colors.grey,
        ),
      ],
    );
  }

  Widget _microTag(BuildContext context, {required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}