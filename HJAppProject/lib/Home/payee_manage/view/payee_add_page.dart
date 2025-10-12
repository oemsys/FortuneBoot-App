import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/Home/payee_manage/data/payee_service.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_form.dart';

class PayeeAddPage extends StatefulWidget {
  const PayeeAddPage({Key? key}) : super(key: key);

  @override
  State<PayeeAddPage> createState() => _PayeeAddPageState();
}

class _PayeeAddPageState extends State<PayeeAddPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sortController;
  late final TextEditingController _remarkController;

  late final FocusNode _nameNode;
  late final FocusNode _sortNode;
  late final FocusNode _remarkNode;

  bool _canExpense = true;
  bool _canIncome = true;
  bool _enable = true;

  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _sortController = TextEditingController();
    _remarkController = TextEditingController();

    _nameNode = FocusNode();
    _sortNode = FocusNode();
    _remarkNode = FocusNode();

    void markDirty() {
      if (!_dirty) {
        setState(() {
          _dirty = true;
        });
      }
    }

    _nameController.addListener(markDirty);
    _sortController.addListener(markDirty);
    _remarkController.addListener(markDirty);
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
      final bookId = context.read<BillsRepository>().bookId() ?? 1;
      await PayeeService().add(
        bookId: bookId,
        payeeName: _nameController.text.trim(),
        sort: _sortController.text.trim().isEmpty
            ? null
            : int.parse(_sortController.text.trim()),
        canExpense: _canExpense,
        canIncome: _canIncome,
        enable: _enable,
        remark: _remarkController.text.trim().isEmpty
            ? null
            : _remarkController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('新增成功'),
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
            '新增交易对象',
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
                        _dirty = true;
                      });
                    },
                    onCanIncomeChanged: (v) {
                      setState(() {
                        _canIncome = v;
                        _dirty = true;
                      });
                    },
                    onEnableChanged: (v) {
                      setState(() {
                        _enable = v;
                        _dirty = true;
                      });
                    },
                    onChanged: () {
                      if (!_dirty) {
                        setState(() {
                          _dirty = true;
                        });
                      }
                    },
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