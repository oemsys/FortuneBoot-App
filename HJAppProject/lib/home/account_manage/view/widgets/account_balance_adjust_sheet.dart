import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

import 'package:hjproject/Home/account_manage/models/fortune_account.dart';
import 'package:hjproject/Request/account_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/request/book_request.dart';
import 'package:hjproject/Home/setting_page/view/widgets/selection_bottom_sheet.dart';

class AccountBalanceAdjustSheet extends StatefulWidget {
  const AccountBalanceAdjustSheet({super.key, required this.account});

  final FortuneAccount account;

  @override
  State<AccountBalanceAdjustSheet> createState() => _AccountBalanceAdjustSheetState();
}

class _AccountBalanceAdjustSheetState extends State<AccountBalanceAdjustSheet> {
  final AccountQueryService _service = AccountQueryService();
  final TextEditingController _balanceCtl = TextEditingController();
  final TextEditingController _titleCtl = TextEditingController();
  final TextEditingController _remarkCtl = TextEditingController();

  DateTime _tradeTime = DateTime.now();
  int? _bookId;
  String? _bookName;

  bool _submitting = false;

  String? _balanceError;
  String? _tradeTimeError;
  String? _bookError;

  @override
  void initState() {
    super.initState();
    // 默认值：余额填入当前余额，tradeTime 为当前时间；bookId 来自当前账本
    final repo = context.read<BillsRepository>();
    _bookId = repo.bookId() ?? 1;
    _bookName = null; // 延迟拉取名称，避免阻塞
    // 显示货币符号，仅做前缀展示（不参与校验）
    if (widget.account.balance != null) {
      _balanceCtl.text = _fmtNum(widget.account.balance);
    }
  }

  @override
  void dispose() {
    _balanceCtl.dispose();
    _titleCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  String _fmtNum(num? v) {
    if (v == null) return '';
    return NumberFormat('0.########').format(v);
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    IconData? icon,
    String? errorText,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      labelText: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 16,
      ),
      prefixIcon: icon == null ? null : Icon(icon),
      prefixText: prefixText,
      errorText: errorText,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.error),
        borderRadius: BorderRadius.circular(12),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _wrapCard(Widget child) {
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

  bool get _valid {
    _balanceError = null;
    _tradeTimeError = null;
    _bookError = null;

    // 余额必填
    final s = _balanceCtl.text.trim();
    final v = double.tryParse(s);
    if (s.isEmpty) {
      _balanceError = '目标余额不能为空';
    } else if (v == null) {
      _balanceError = '请输入有效数字';
    }

    if (_bookId == null) {
      _bookError = '请选择账本';
    }
    if (_tradeTime == null) {
      _tradeTimeError = '请选择调整时间';
    }

    return _balanceError == null && _bookError == null && _tradeTimeError == null;
  }

  String get _tradeTimeText => DateFormat('yyyy-MM-dd HH:mm:ss').format(_tradeTime);

  Future<void> _pickTradeTime() async {
    final picked = await showOmniDateTimePicker(
      context: context,
      initialDate: _tradeTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      type: OmniDateTimePickerType.dateAndTime,
      is24HourMode: true,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(maxWidth: 480),
    );
    if (picked != null) {
      setState(() {
        _tradeTime = picked;
      });
    }
  }

  Future<void> _selectBook() async {
    final groupId = context.read<BillsRepository>().groupId() ?? 1;
    final resp = await BookService().getEnableList(groupId);
    if (!mounted) return;
    if (resp.code != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.msg ?? '获取账本失败'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    final list = (resp.data as List? ?? []);
    final options = <SelectionOption<Map>>[];
    for (final e in list) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = (m['bookId'] as num?)?.toInt() ?? 0;
      final name = (m['bookName'] ?? '').toString();
      final enable = (m['enable'] is bool) ? (m['enable'] as bool) : true;
      if (!enable) continue;
      options.add(SelectionOption<Map>(
        label: name.isEmpty ? '账本$id' : name,
        value: {'id': id, 'name': name},
        selected: id == _bookId,
      ));
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<SelectionOption<Map>>(
      context: context,
      builder: (ctx) => SelectionBottomSheet<Map>(
        title: '选择账本',
        options: options,
        onSelected: (opt) {
          Navigator.pop(ctx, opt);
        },
      ),
    );
    if (selected != null) {
      setState(() {
        _bookId = (selected.value['id'] as int?) ?? _bookId;
        _bookName = (selected.value['name'] as String?) ?? _bookName;
      });
    }
  }

  Future<void> _submit() async {
    if (!_valid) {
      setState(() {});
      return;
    }
    final accountId = widget.account.accountId;
    if (accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('账户ID缺失，无法调整'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final ok = await _service.balanceAdjust(
        accountId: accountId,
        balance: double.tryParse(_balanceCtl.text.trim()) ?? 0,
        tradeTime: _tradeTime,
        bookId: _bookId ?? 0,
        title: _titleCtl.text.trim().isEmpty ? null : _titleCtl.text.trim(),
        remark: _remarkCtl.text.trim().isEmpty ? null : _remarkCtl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('调整失败'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currencySym = widget.account.currencySymbol;

    final body = SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.swap_vert, color: cs.primary),
                    const SizedBox(width: 8),
                    const Text('余额调整', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      tooltip: '关闭',
                      icon: const Icon(Icons.close),
                      onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              // 账户信息（只读）
              _wrapCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('账户信息', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _readonlyRow('账户名称', widget.account.accountName ?? '未命名账户', Icons.account_balance_wallet),
                  ],
                ),
              ),
              // 账户信息（只读）
              _wrapCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('标题', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Semantics(
                      label: '标题输入',
                      child: TextFormField(
                        controller: _titleCtl,
                        decoration: _dec(label: '标题（可选）', hint: '例：期初对账', icon: Icons.title),
                        maxLength: 64,
                      ),
                    ),
                  ],
                ),
              ),
              // 目标余额
              _wrapCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('目标余额', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Semantics(
                      label: '目标余额输入框',
                      child: TextFormField(
                        controller: _balanceCtl,
                        decoration: _dec(
                          label: '目标余额',
                          hint: '必填，支持小数',
                          icon: Icons.account_balance,
                          errorText: _balanceError,
                          prefixText: currencySym.isEmpty ? null : '$currencySym ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        textAlign: TextAlign.end,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
              // 时间与账本
              _wrapCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('调整信息', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // 时间
                    Semantics(
                      label: '调整时间选择',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.schedule, color: cs.primary),
                        title: const Text('调整时间'),
                        subtitle: Text(_tradeTimeText),
                        onTap: _submitting ? null : _pickTradeTime,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                    if (_tradeTimeError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(_tradeTimeError!, style: TextStyle(color: cs.error, fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                    // 账本
                    Semantics(
                      label: '账本选择',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.menu_book, color: cs.primary),
                        title: const Text('账本'),
                        subtitle: Text(
                          (_bookName == null || _bookName!.isEmpty)
                              ? '当前账本（ID: ${_bookId ?? '-'}）'
                              : _bookName!,
                        ),
                        onTap: _submitting ? null : _selectBook,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                    if (_bookError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(_bookError!, style: TextStyle(color: cs.error, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              // 附加信息：标题、备注
              _wrapCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('附加信息', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Semantics(
                      label: '备注输入',
                      child: TextFormField(
                        controller: _remarkCtl,
                        decoration: _dec(label: '备注（可选）', hint: '多行输入', icon: Icons.notes),
                        maxLines: 3,
                        maxLength: 200,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 提交按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Semantics(
                    button: true,
                    label: '确认调整',
                    child: FilledButton(
                      onPressed: (_submitting || !_valid) ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                              ),
                            )
                          : const Text('确认调整'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    return body;
  }

  Widget _readonlyRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}