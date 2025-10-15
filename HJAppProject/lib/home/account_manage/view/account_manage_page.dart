import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/Home/account_manage/models/fortune_account.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/Request/account_request.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_summary_bar.dart';
import 'package:hjproject/Home/tag_manage/view/widgets/tag_pager.dart';

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

  // 分页状态
  int _pageNum = 1;
  int _pageSize = 20;
  int _total = 0;

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
        pageNum: _pageNum,
        pageSize: _pageSize,
      );
      setState(() {
        _rows = data.rows;
        _total = data.total;
        _pageNum = data.pageNum ?? _pageNum;
        _pageSize = data.pageSize ?? _pageSize;
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
      _pageNum = 1; // 切换类型回到第一页
    });
    _load();
  }

  void _prevPage() {
    if (_pageNum <= 1) return;
    setState(() {
      _pageNum -= 1;
    });
    _load();
  }

  void _nextPage() {
    final hasNext = _pageNum * _pageSize < _total;
    if (!hasNext) return;
    setState(() {
      _pageNum += 1;
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
        children: [
          const SizedBox(height: 80),
          const _EmptyState(),
          const SizedBox(height: 8),
          TagPager(
            total: _total,
            hasPrev: _pageNum > 1,
            hasNext: _pageNum * _pageSize < _total,
            onPrev: _prevPage,
            onNext: _nextPage,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      itemCount: _rows.length + 3, // 顶部摘要 + 列表项 + 翻页 + 底部间距
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: CategorySummaryBar(
              typeText: _typeLabel(_accountType),
              total: _total,
              currentPage: _pageNum,
            ),
          );
        }
        if (index == _rows.length + 1) {
          // 翻页控件
          return TagPager(
            total: _total,
            hasPrev: _pageNum > 1,
            hasNext: _pageNum * _pageSize < _total,
            onPrev: _prevPage,
            onNext: _nextPage,
          );
        }
        if (index == _rows.length + 2) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：左侧主信息（账户名） + 右侧金额/币种（紧凑对齐）
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.accountName ?? '未命名账户',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
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
            // 第二行：整行用于状态区（可选备注 + 状态 Wrap），与右侧金额宽度解耦
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasRemark) ...[
                    Text(
                      item.remark!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  _StatusWrap(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StatusKind {
  expenseAllowed,
  incomeAllowed,
  transferOutAllowed,
  transferInAllowed,
  enabled,
  includeInNetWorth,
}

class _ChipStyle {
  final Color background;
  final Color foreground;
  final Color border;
  final bool filled; // true = filled/tonal, false = outlined/tonal-variant

  const _ChipStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.filled,
  });
}

class _StatusWrap extends StatelessWidget {
  const _StatusWrap({required this.item});

  final FortuneAccount item;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _buildChip(
        context,
        label: '支出允许',
        kind: _StatusKind.expenseAllowed,
        active: item.canExpense,
      ),
      _buildChip(
        context,
        label: '收入允许',
        kind: _StatusKind.incomeAllowed,
        active: item.canIncome,
      ),
      _buildChip(
        context,
        label: '转出允许',
        kind: _StatusKind.transferOutAllowed,
        active: item.canTransferOut,
      ),
      _buildChip(
        context,
        label: '转入允许',
        kind: _StatusKind.transferInAllowed,
        active: item.canTransferIn,
      ),
      _buildChip(
        context,
        label: item.enable ? '启用账户' : '停用账户',
        kind: _StatusKind.enabled,
        active: item.enable,
      ),
      _buildChip(
        context,
        label: '计入资产',
        kind: _StatusKind.includeInNetWorth,
        active: item.include,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required _StatusKind kind,
    required bool active,
  }) {
    final style = _styleFor(context, kind: kind, active: active);
    // 统一 Chip 外观：高度、圆角、内边距、字重
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.filled ? style.background : style.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.border, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: style.foreground,
          ),
        ),
      ),
    );
  }

  _ChipStyle _disabledStyle(ColorScheme cs) {
    return _ChipStyle(
      background: cs.surfaceVariant.withOpacity(0.12),
      foreground: cs.onSurfaceVariant,
      border: cs.outline,
      filled: false,
    );
  }

  _ChipStyle _styleFor(
    BuildContext context, {
    required _StatusKind kind,
    required bool active,
  }) {
    final cs = Theme.of(context).colorScheme;

    switch (kind) {
      // 危险/红系：支出允许
      case _StatusKind.expenseAllowed:
        if (!active) return _disabledStyle(cs);
        return _ChipStyle(
          background: cs.errorContainer,
          foreground: cs.onErrorContainer,
          border: cs.error,
          filled: true,
        );

      // 成功/绿系：收入允许（使用 secondary 派生）
      case _StatusKind.incomeAllowed:
        if (!active) return _disabledStyle(cs);
        return _ChipStyle(
          background: cs.secondaryContainer,
          foreground: cs.onSecondaryContainer,
          border: cs.secondary,
          filled: true,
        );

      // 警示/橙系：转出允许（使用 tertiary 派生，确保与其它不冲突）
      case _StatusKind.transferOutAllowed:
        if (!active) return _disabledStyle(cs);
        return _ChipStyle(
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
          border: cs.tertiary,
          filled: true,
        );

      // 信息/蓝系：转入允许（使用 primary 派生）
      case _StatusKind.transferInAllowed:
        if (!active) return _disabledStyle(cs);
        return _ChipStyle(
          background: cs.primaryContainer,
          foreground: cs.onPrimaryContainer,
          border: cs.primary,
          filled: true,
        );

      // 启用账户/停用账户：品牌色强调 or 中性色弱化
      case _StatusKind.enabled:
        if (!active) {
          // 停用账户：中性色/灰系（弱化/描边）
          return _disabledStyle(cs);
        }
        // 启用账户：主色调强调（使用 Tonal 以保证可读性与对比）
        return _ChipStyle(
          background: cs.primaryContainer,
          foreground: cs.onPrimaryContainer,
          border: cs.primary,
          filled: true,
        );

      // 计入净资产：青/紫，避免冲突（使用 inverse 系列，跨深浅色对比良好）
      case _StatusKind.includeInNetWorth:
        if (!active) return _disabledStyle(cs);
        return _ChipStyle(
          background: cs.inverseSurface,
          foreground: cs.onInverseSurface,
          border: cs.inversePrimary,
          filled: true,
        );
    }
  }
}