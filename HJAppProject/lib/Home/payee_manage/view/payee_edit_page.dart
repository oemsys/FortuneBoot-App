import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hjproject/Home/payee_manage/model/payee.dart';
import 'package:hjproject/Home/payee_manage/data/payee_service.dart';

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
  late bool _canExpense;
  late bool _canIncome;
  late bool _enable;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.payee;
    _nameController = TextEditingController(text: p.payeeName);
    _sortController = TextEditingController(text: p.sort.toString());
    _remarkController = TextEditingController(text: p.remark ?? '');
    _canExpense = p.canExpense;
    _canIncome = p.canIncome;
    _enable = p.enable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 32) return false;
    final sortText = _sortController.text.trim();
    final sort = int.tryParse(sortText);
    if (sort == null || sort < 0) return false;
    final remark = _remarkController.text;
    if (remark.isNotEmpty && remark.length > 200) return false;
    return true;
  }

  Future<void> _onSave() async {
    if (!_isValid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请检查表单填写是否正确')));
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
        sort: int.parse(_sortController.text.trim()),
        canExpense: _canExpense,
        canIncome: _canIncome,
        enable: _enable,
        remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  EdgeInsets _horizontalPaddingForWidth(double width) {
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 16);
    if (width < 1024) return const EdgeInsets.symmetric(horizontal: 20);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _horizontalPaddingForWidth(constraints.maxWidth);
        return Scaffold(
          appBar: AppBar(
            title: const Text('编辑交易对象'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: (_saving || !_isValid) ? null : _onSave,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: padding.copyWith(top: 12, bottom: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '名称',
                            hintText: '请输入名称（必填，最长32个字符）',
                          ),
                          maxLength: 32,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return '名称不能为空';
                            if (t.length > 32) return '名称长度不能超过32';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sortController,
                          decoration: const InputDecoration(
                            labelText: '排序',
                            hintText: '请输入非负整数',
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.number,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return '排序不能为空';
                            final n = int.tryParse(t);
                            if (n == null) return '必须为整数';
                            if (n < 0) return '必须为非负数';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          title: const Text('支出'),
                          value: _canExpense,
                          onChanged: (v) => setState(() => _canExpense = v),
                        ),
                        SwitchListTile.adaptive(
                          title: const Text('收入'),
                          value: _canIncome,
                          onChanged: (v) => setState(() => _canIncome = v),
                        ),
                        SwitchListTile.adaptive(
                          title: const Text('启用'),
                          value: _enable,
                          onChanged: (v) => setState(() => _enable = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _remarkController,
                          decoration: const InputDecoration(
                            labelText: '备注',
                            hintText: '可选，最长200个字符',
                          ),
                          maxLines: 3,
                          maxLength: 200,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) {
                            final t = (v ?? '');
                            if (t.isNotEmpty && t.length > 200) return '备注长度不能超过200';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}