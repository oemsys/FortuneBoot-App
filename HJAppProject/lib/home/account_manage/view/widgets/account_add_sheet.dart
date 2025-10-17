import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hjproject/Request/account_request.dart';
import 'package:hjproject/request/group_request.dart';
import 'package:hjproject/Home/setting_page/view/widgets/selection_bottom_sheet.dart';

/// 新增账户底部表单面板
/// - 只读展示：分组名称、账户类型
/// - 必填：账户名称、币种（从模板接口加载）、六状态（默认选中）
/// - 可选：卡号、排序、余额、备注
class AccountAddSheet extends StatefulWidget {
  const AccountAddSheet({
    super.key,
    required this.groupId,
    required this.accountType,
  });

  final int groupId;
  final int accountType;

  @override
  State<AccountAddSheet> createState() => _AccountAddSheetState();
}

class _AccountAddSheetState extends State<AccountAddSheet> {
  final AccountQueryService _service = AccountQueryService();

  late TextEditingController _nameCtl;
  late TextEditingController _cardNoCtl;
  late TextEditingController _sortCtl;
  late TextEditingController _balanceCtl;
  late TextEditingController _remarkCtl;

  // 六个状态（默认选中/启用）
  bool _include = true;
  bool _canExpense = true;
  bool _canIncome = true;
  bool _enable = true;
  bool _canTransferOut = true;
  bool _canTransferIn = true;

  // 币种模板
  List<CurrencyOption> _currencyOptions = const <CurrencyOption>[];
  String? _selectedCurrencyCode;
  bool _loadingCurrency = true;
  String? _currencyLoadError;

  // 分组名称
  String _groupName = '未知分组';

  bool _busy = false;
  String? _errorText;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _cardNoCtl = TextEditingController();
    _sortCtl = TextEditingController();
    _balanceCtl = TextEditingController();
    _remarkCtl = TextEditingController();

    _loadGroupName();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _cardNoCtl.dispose();
    _sortCtl.dispose();
    _balanceCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  Future<void> _loadGroupName() async {
    try {
      final resp = await GroupService().getByGroupId(widget.groupId);
      if (resp.code == 0) {
        final data = (resp.data as Map?) ?? {};
        final name = (data['groupName'] ?? '').toString();
        if (name.isNotEmpty) {
          setState(() {
            _groupName = name;
          });
        }
      }
    } catch (_) {
      // 保持默认“未知分组”
    }
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _loadingCurrency = true;
      _currencyLoadError = null;
    });
    try {
      final list = await _service.getCurrencyTemplate();
      setState(() {
        _currencyOptions = list;
        _loadingCurrency = false;
        // 若后端仅返回 label 作为代码（如 "CNY"），则直接用 label 作为 currencyCode
        if (list.isNotEmpty && _selectedCurrencyCode == null) {
          // 不默认选择，要求用户明确选择；保持为 null
        }
      });
    } catch (e) {
      setState(() {
        _currencyLoadError = e.toString();
        _loadingCurrency = false;
      });
    }
  }

  // 统一装饰（参考编辑页）
  InputDecoration _dec(BuildContext context,
      {required String label, String? hint, required IconData icon}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      labelText: label,
      labelStyle: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 16,
      ),
      prefixIcon: Icon(icon),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.error),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _wrapGroupCard(Widget child) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _groupTitle(String title, {String? subtitle}) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: tt.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
        ],
      ],
    );
  }

  Widget _readonlyRow(String label, String value, IconData icon) {
    final tt = Theme.of(context).textTheme;
    final hintColor = Theme.of(context).hintColor;
    return Row(
      children: [
        Icon(icon, size: 20, color: hintColor),
        const SizedBox(width: 8),
        Text(label, style: tt.bodyMedium?.copyWith(color: hintColor)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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

  double? _tryDouble(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.trim());
  }

  bool get _valid {
    _errorText = null;

    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      _errorText = '账户名称不能为空';
      return false;
    }
    if (name.length > 64) {
      _errorText = '账户名称长度不能超过64';
      return false;
    }

    if (_selectedCurrencyCode == null || _selectedCurrencyCode!.trim().isEmpty) {
      _errorText = '请选择币种';
      return false;
    }

    final sortText = _sortCtl.text.trim();
    if (sortText.isNotEmpty) {
      final n = int.tryParse(sortText);
      if (n == null || n < 0) {
        _errorText = '顺序必须为非负整数';
        return false;
      }
    }

    final balText = _balanceCtl.text.trim();
    if (balText.isNotEmpty && _tryDouble(balText) == null) {
      _errorText = '余额必须为数值';
      return false;
    }

    return true;
  }

  Future<void> _openCurrencySelector() async {
    // 去抖，避免一次点击触发多次导航操作
    if (_isNavigating) return;
    _isNavigating = true;
    await Future.delayed(Duration.zero);

    final options = _currencyOptions
        .map((e) => SelectionOption<String>(
              label: e.label,
              value: e.label, // 使用 label 作为提交的 currencyCode
              selected: e.label == _selectedCurrencyCode,
            ))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SelectionBottomSheet<String>(
          title: '选择币种',
          options: options,
          onSelected: (opt) {
            setState(() {
              _selectedCurrencyCode = opt.value;
            });
          },
        );
      },
    );

    _isNavigating = false;
  }

  Future<void> _submit() async {
    if (!_valid) {
      setState(() {}); // 触发错误提示展示
      return;
    }
    setState(() {
      _busy = true;
    });

    final String? cardNo =
        _cardNoCtl.text.trim().isEmpty ? null : _cardNoCtl.text.trim();
    final int? sort =
        _sortCtl.text.trim().isEmpty ? null : int.tryParse(_sortCtl.text.trim());
    final double? balance = _tryDouble(_balanceCtl.text.trim());
    final String? remark =
        _remarkCtl.text.trim().isEmpty ? null : _remarkCtl.text.trim();

    try {
      final ok = await _service.addAccount(
        groupId: widget.groupId,
        accountName: _nameCtl.text.trim(),
        accountType: widget.accountType,
        currencyCode: _selectedCurrencyCode!.trim(),
        cardNo: cardNo,
        sort: sort,
        balance: balance,
        remark: remark,
        canExpense: _canExpense,
        canIncome: _canIncome,
        canTransferOut: _canTransferOut,
        canTransferIn: _canTransferIn,
        include: _include,
        enable: _enable,
      );
      if (ok && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 只读展示：分组、类型
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('当前分组/账户类型', subtitle: '以下为只读展示，不能修改'),
              const SizedBox(height: 12),
              _readonlyRow('分组', _groupName, Icons.group),
              const SizedBox(height: 8),
              _readonlyRow('账户类型', _typeLabel(widget.accountType), Icons.category),
            ],
          ),
        ),

        // 基本信息
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('基本信息', subtitle: '名称必填；卡号、余额可选'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtl,
                decoration: _dec(context,
                    label: '账户名称', hint: '最长64字符', icon: Icons.badge),
                maxLength: 64,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (_) => _errorText,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardNoCtl,
                decoration: _dec(context,
                    label: '卡号', hint: '可选', icon: Icons.credit_card),
                maxLength: 32,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtl,
                decoration: _dec(context,
                    label: '余额', hint: '可留空', icon: Icons.account_balance),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))
                ],
                textAlign: TextAlign.end,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // 币种选择
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('币种', subtitle: '从模板接口加载，提交时使用代码（如 CNY）'),
              const SizedBox(height: 12),
              if (_loadingCurrency) ...[
                Row(
                  children: [
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('正在加载币种模板...', style: tt.bodyMedium),
                  ],
                ),
              ] else if (_currencyLoadError != null) ...[
                Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currencyLoadError!,
                        style: tt.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCurrencies,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ] else ...[
                ListTile(
                  title: Text(
                    _selectedCurrencyCode ?? '请选择币种',
                    style: tt.bodyMedium?.copyWith(
                      color: _selectedCurrencyCode == null
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                    ),
                  ),
                  leading: const Icon(Icons.currency_exchange),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openCurrencySelector,
                ),
              ],
            ],
          ),
        ),

        // 六状态 Chip（Wrap 单行，可自动换行）
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('使用范围与状态', subtitle: '沿用统一 Chip 风格，窄屏自动换行'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('计入资产'),
                    selected: _include,
                    onSelected: (v) => setState(() => _include = v),
                  ),
                  ChoiceChip(
                    label: const Text('支出允许'),
                    selected: _canExpense,
                    onSelected: (v) => setState(() => _canExpense = v),
                  ),
                  ChoiceChip(
                    label: const Text('收入允许'),
                    selected: _canIncome,
                    onSelected: (v) => setState(() => _canIncome = v),
                  ),
                  ChoiceChip(
                    label: Text(_enable ? '启用账户' : '停用账户'),
                    selected: _enable,
                    onSelected: (v) => setState(() => _enable = v),
                  ),
                  ChoiceChip(
                    label: const Text('转出允许'),
                    selected: _canTransferOut,
                    onSelected: (v) => setState(() => _canTransferOut = v),
                  ),
                  ChoiceChip(
                    label: const Text('转入允许'),
                    selected: _canTransferIn,
                    onSelected: (v) => setState(() => _canTransferIn = v),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 金额与备注
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('顺序与备注', subtitle: '顺序为数值（可空），备注可多行'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortCtl,
                decoration: _dec(context,
                    label: '顺序', hint: '非负整数，可留空', icon: Icons.sort),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                maxLength: 9,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarkCtl,
                maxLines: 4,
                decoration: _dec(context,
                    label: '备注', hint: '可留空', icon: Icons.notes),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 底部操作
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: const Text('新增'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              child: content,
            );
          },
        ),
      ),
    );
  }
}