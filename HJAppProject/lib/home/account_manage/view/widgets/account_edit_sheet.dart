import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hjproject/Home/account_manage/models/fortune_account.dart';
import 'package:hjproject/Request/account_request.dart';

class AccountEditSheet extends StatefulWidget {
  const AccountEditSheet({
    super.key,
    required this.account,
    required this.groupName,
  });

  final FortuneAccount account;
  final String groupName;

  @override
  State<AccountEditSheet> createState() => _AccountEditSheetState();
}

class _AccountEditSheetState extends State<AccountEditSheet> {
  final AccountQueryService _service = AccountQueryService();

  late TextEditingController _nameCtl;
  late TextEditingController _cardNoCtl;
  late TextEditingController _sortCtl;
  late TextEditingController _balanceCtl;
  late TextEditingController _initialBalanceCtl;
  late TextEditingController _remarkCtl;

  // 类型特有
  late TextEditingController _creditLimitCtl;
  late TextEditingController _aprCtl;
  DateTime? _billDay;
  DateTime? _repayDay;

  // 共同布尔参数
  late bool _include;
  late bool _canExpense;
  late bool _canIncome;
  late bool _enable;
  late bool _canTransferOut;
  late bool _canTransferIn;

  // 不可修改字段
  late int _accountType;
  late String _currencyCode;

  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final a = widget.account;

    _nameCtl = TextEditingController(text: a.accountName ?? '');
    _cardNoCtl = TextEditingController(text: a.cardNo ?? '');
    _sortCtl = TextEditingController(text: (a.sort ?? '').toString());
    _balanceCtl = TextEditingController(text: _fmtNum(a.balance));
    _initialBalanceCtl = TextEditingController(text: _fmtNum(a.initialBalance));
    _remarkCtl = TextEditingController(text: a.remark ?? '');

    _creditLimitCtl = TextEditingController(text: _fmtNum(a.creditLimit));
    _aprCtl = TextEditingController(text: _fmtNum(a.apr));
    _billDay = a.billDay;
    _repayDay = a.repayDay;

    _include = a.include;
    _canExpense = a.canExpense;
    _canIncome = a.canIncome;
    _enable = a.enable;
    _canTransferOut = a.canTransferOut;
    _canTransferIn = a.canTransferIn;

    _accountType = a.accountType ?? 1;
    _currencyCode = a.currencyCode ?? '';
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _cardNoCtl.dispose();
    _sortCtl.dispose();
    _balanceCtl.dispose();
    _initialBalanceCtl.dispose();
    _remarkCtl.dispose();
    _creditLimitCtl.dispose();
    _aprCtl.dispose();
    super.dispose();
  }

  String _fmtNum(num? v) {
    if (v == null) return '';
    return NumberFormat('0.########').format(v);
  }

  // 统一装饰（参考交易对象管理）
  InputDecoration _dec(BuildContext context, {required String label, String? hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 16,
      ),
      prefixIcon: Icon(icon),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
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

    final sortText = _sortCtl.text.trim();
    if (sortText.isNotEmpty) {
      final n = int.tryParse(sortText);
      if (n == null || n < 0) {
        _errorText = '顺序必须为非负整数';
        return false;
      }
    }

    double? balance = _tryDouble(_balanceCtl.text.trim());
    if (_balanceCtl.text.trim().isNotEmpty && balance == null) {
      _errorText = '余额必须为数值';
      return false;
    }

    double? initBal = _tryDouble(_initialBalanceCtl.text.trim());
    if (_initialBalanceCtl.text.trim().isNotEmpty && initBal == null) {
      _errorText = '初始余额必须为数值';
      return false;
    }
    if (initBal != null && initBal < 0) {
      _errorText = '初始余额必须为非负数';
      return false;
    }

    // 类型特有
    if (_accountType == 2 || _accountType == 4) {
      final lim = _tryDouble(_creditLimitCtl.text.trim());
      if (_creditLimitCtl.text.trim().isNotEmpty) {
        if (lim == null || lim < 0) {
          _errorText = '额度必须为非负数值';
          return false;
        }
      }
    }
    if (_accountType == 4) {
      final apr = _tryDouble(_aprCtl.text.trim());
      if (_aprCtl.text.trim().isNotEmpty) {
        if (apr == null || apr < 0) {
          _errorText = '利率必须为非负数值';
          return false;
        }
      }
    }

    // 日期格式在选择器中保证；允许为空
    return true;
  }

  double? _tryDouble(String s) {
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  Future<void> _pickDate({required bool isBillDay}) async {
    final now = DateTime.now();
    final init = isBillDay ? (_billDay ?? now) : (_repayDay ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isBillDay) {
          _billDay = picked;
        } else {
          _repayDay = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_valid) {
      setState(() {}); // 触发错误提示展示
      return;
    }
    setState(() {
      _busy = true;
    });

    final a0 = widget.account;
    final body = FortuneAccount(
      groupId: a0.groupId,
      accountId: a0.accountId,
      accountType: a0.accountType,
      currencyCode: a0.currencyCode,
      accountName: _nameCtl.text.trim(),
      cardNo: _cardNoCtl.text.trim().isEmpty ? null : _cardNoCtl.text.trim(),
      sort: _sortCtl.text.trim().isEmpty ? null : int.tryParse(_sortCtl.text.trim()),
      balance: _tryDouble(_balanceCtl.text.trim()),
      initialBalance: _tryDouble(_initialBalanceCtl.text.trim()),
      include: _include,
      canExpense: _canExpense,
      canIncome: _canIncome,
      enable: _enable,
      canTransferOut: _canTransferOut,
      canTransferIn: _canTransferIn,
      remark: _remarkCtl.text.trim(),
      // 类型特有
      creditLimit: _creditLimitCtl.text.trim().isEmpty ? null : _tryDouble(_creditLimitCtl.text.trim()),
      apr: _aprCtl.text.trim().isEmpty ? null : _tryDouble(_aprCtl.text.trim()),
      billDay: _billDay,
      repayDay: _repayDay,
    );

    try {
      final ok = await _service.modifyAccount(body);
      if (ok && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 不可修改字段展示：分组、类型、币种
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('当前分组/账户类型/币种', subtitle: '以下为只读展示，不能修改'),
              const SizedBox(height: 12),
              _readonlyRow('分组', widget.groupName, Icons.group),
              const SizedBox(height: 8),
              _readonlyRow('账户类型', _typeLabel(_accountType), Icons.category),
              const SizedBox(height: 8),
              _readonlyRow('币种', _currencyCode, Icons.currency_exchange),
            ],
          ),
        ),

        // 基本信息
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('基本信息', subtitle: '名称必填；卡号、排序可选'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtl,
                decoration: _dec(context, label: '账户名称', hint: '最长64字符', icon: Icons.badge),
                maxLength: 64,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (_) => _errorText,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardNoCtl,
                decoration: _dec(context, label: '卡号', hint: '可选', icon: Icons.credit_card),
                maxLength: 32,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortCtl,
                decoration: _dec(context, label: '顺序', hint: '非负整数，可留空', icon: Icons.sort),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                maxLength: 9,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // 金额类
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('金额', subtitle: '余额、初始余额为数值，初始余额须非负'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtl,
                decoration: _dec(context, label: '余额', hint: '可留空', icon: Icons.account_balance),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                textAlign: TextAlign.end,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialBalanceCtl,
                decoration: _dec(context, label: '初始余额', hint: '非负数值，可留空', icon: Icons.savings),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                textAlign: TextAlign.end,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // 布尔开关
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('使用范围与状态', subtitle: '与“启用账户/停用账户”开关样式保持一致'),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: const Text('计入资产'),
                value: _include,
                onChanged: (v) => setState(() => _include = v),
              ),
              SwitchListTile.adaptive(
                title: const Text('支出允许'),
                value: _canExpense,
                onChanged: (v) => setState(() => _canExpense = v),
              ),
              SwitchListTile.adaptive(
                title: const Text('收入允许'),
                value: _canIncome,
                onChanged: (v) => setState(() => _canIncome = v),
              ),
              SwitchListTile.adaptive(
                title: Text(_enable ? '启用账户' : '停用账户'),
                value: _enable,
                onChanged: (v) => setState(() => _enable = v),
              ),
              SwitchListTile.adaptive(
                title: const Text('转出允许'),
                value: _canTransferOut,
                onChanged: (v) => setState(() => _canTransferOut = v),
              ),
              SwitchListTile.adaptive(
                title: const Text('转入允许'),
                value: _canTransferIn,
                onChanged: (v) => setState(() => _canTransferIn = v),
              ),
            ],
          ),
        ),

        // 类型特有
        if (_accountType == 2 || _accountType == 4)
          _wrapGroupCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _groupTitle(_accountType == 2 ? '信用账户设置' : '贷款账户设置',
                    subtitle: _accountType == 2 ? '额度/账单日/还款日' : '额度/利率/还款日'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _creditLimitCtl,
                  decoration: _dec(context, label: '额度', hint: '非负数值，可留空', icon: Icons.stacked_bar_chart),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                  textAlign: TextAlign.end,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (_accountType == 4)
                  TextFormField(
                    controller: _aprCtl,
                    decoration: _dec(context, label: '利率', hint: '非负数值，可留空', icon: Icons.percent),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                    textAlign: TextAlign.end,
                    onChanged: (_) => setState(() {}),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: _accountType == 2 ? '账单日' : '还款日',
                        date: _accountType == 2 ? _billDay : _repayDay,
                        onPick: () => _pickDate(isBillDay: _accountType == 2),
                        onClear: () => setState(() {
                          if (_accountType == 2) {
                            _billDay = null;
                          } else {
                            _repayDay = null;
                          }
                        }),
                      ),
                    ),
                    if (_accountType == 2) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateField(
                          label: '还款日',
                          date: _repayDay,
                          onPick: () => _pickDate(isBillDay: false),
                          onClear: () => setState(() => _repayDay = null),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

        // 备注
        _wrapGroupCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('备注', subtitle: '可选项，最长200字符'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarkCtl,
                decoration: _dec(context, label: '备注', hint: '补充说明', icon: Icons.note),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: (_busy || !_valid) ? null : _submit,
            icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_busy ? '保存中...' : '保存修改'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(child: content),
      ),
    );
  }

  Widget _readonlyRow(String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceVariant.withOpacity(0.24),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dateField({required String label, required DateTime? date, required VoidCallback onPick, required VoidCallback onClear}) {
    final cs = Theme.of(context).colorScheme;
    final text = date == null ? '未选择' : DateFormat('yyyy-MM-dd').format(date);
    return InkWell(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label),
            const Spacer(),
            Text(text, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Tooltip(
              message: '清空',
              child: InkWell(
                onTap: onClear,
                child: Icon(Icons.clear, size: 18, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}