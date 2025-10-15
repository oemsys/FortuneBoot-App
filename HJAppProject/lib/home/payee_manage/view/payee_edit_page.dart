import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hjproject/Home/payee_manage/model/payee.dart';
import 'package:hjproject/Home/payee_manage/data/payee_service.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_form.dart';

class PayeeEditPage extends StatefulWidget {
  final Payee payee;
  final int bookId;
  const PayeeEditPage({Key? key, required this.payee, required this.bookId}) : super(key: key);

  @override
  State<PayeeEditPage> createState() => _PayeeEditPageState();
}

class _PayeeEditPageState extends State<PayeeEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sortController;
  late final TextEditingController _remarkController;

  late final FocusNode _nameNode;
  late final FocusNode _sortNode;
  late final FocusNode _remarkNode;

  late bool _canExpense;
  late bool _canIncome;
  late bool _enable;

  bool _saving = false;
  bool _dirty = false;

  late final Map<String, dynamic> _initial;

  @override
  void initState() {
    super.initState();
    final p = widget.payee;
    _nameController = TextEditingController(text: p.payeeName);
    _sortController = TextEditingController(text: p.sort?.toString() ?? '');
    _remarkController = TextEditingController(text: p.remark ?? '');
    _canExpense = p.canExpense;
    _canIncome = p.canIncome;
    _enable = p.enable;

    _nameNode = FocusNode();
    _sortNode = FocusNode();
    _remarkNode = FocusNode();

    _initial = {
      'name': p.payeeName,
      'sort': p.sort?.toString() ?? '',
      'remark': p.remark ?? '',
      'canExpense': p.canExpense,
      'canIncome': p.canIncome,
      'enable': p.enable,
    };

    void listener() => _computeDirty();
    _nameController.addListener(listener);
    _sortController.addListener(listener);
    _remarkController.addListener(listener);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    _remarkController.dispose();
    _nameNode.dispose();
    _sortNode.dispose();
    _remarkNode.dispose();
    super.dispose();
  }

  void _computeDirty() {
    final now = {
      'name': _nameController.text,
      'sort': _sortController.text,
      'remark': _remarkController.text,
      'canExpense': _canExpense,
      'canIncome': _canIncome,
      'enable': _enable,
    };
    final changed = now.entries.any((e) => _initial[e.key] != e.value);
    if (_dirty != changed) {
      setState(() {
        _dirty = changed;
      });
    }
  }

  bool get _isValid {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 32) return false;
    final sortText = _sortController.text.trim();
    if (sortText.isNotEmpty) {
      final sort = int.tryParse(sortText);
      if (sort == null || sort < 0) return false;
    }
    final remark = _remarkController.text;
    if (remark.isNotEmpty && remark.length > 200) return false;
    return true;
  }

  Future<void> _onSave() async {
    if (!_isValid) {
      setState(() {}); // 触发表单校验显示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请检查表单填写是否正确'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await PayeeService().modify(
        payeeId: widget.payee.payeeId,
        bookId: widget.bookId,
        payeeName: _nameController.text.trim(),
        sort: _sortController.text.trim().isEmpty
            ? null
            : int.parse(_sortController.text.trim()),
        canExpense: _canExpense,
        canIncome: _canIncome,
        enable: _enable,
        remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存成功'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _dirty = false;
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // 回收站操作已移除

  Future<bool> _confirmLeave() async {
    if (!_dirty || _saving) return true;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: cs.surfaceTint,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          title: Text('放弃更改？', style: tt.titleMedium),
          content: const Text('当前页面存在未保存的更改，确定要离开并丢弃这些更改吗？'),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消', style: tt.labelLarge),
            ),
            OutlinedButton(
              style: ButtonStyle(
                side: MaterialStatePropertyAll(BorderSide(color: cs.error)),
                foregroundColor: MaterialStatePropertyAll(cs.error),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('离开', style: tt.labelLarge),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmLeave,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '修改交易对象',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: CupertinoScrollbar(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: PayeeForm(
                    nameController: _nameController,
                    sortController: _sortController,
                    remarkController: _remarkController,
                    nameNode: _nameNode,
                    sortNode: _sortNode,
                    remarkNode: _remarkNode,
                    canExpense: _canExpense,
                    canIncome: _canIncome,
                    enable: _enable,
                    onCanExpenseChanged: (v) {
                      setState(() {
                        _canExpense = v;
                      });
                      _computeDirty();
                    },
                    onCanIncomeChanged: (v) {
                      setState(() {
                        _canIncome = v;
                      });
                      _computeDirty();
                    },
                    onEnableChanged: (v) {
                      setState(() {
                        _enable = v;
                      });
                      _computeDirty();
                    },
                    onChanged: _computeDirty,
                    isBusy: _saving,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: '保存',
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
          onPressed: _saving || !_isValid ? null : _onSave,
          child: _saving
              ? const CupertinoActivityIndicator()
              : const Icon(Icons.check_rounded),
        ),
      ),
    );
  }
}