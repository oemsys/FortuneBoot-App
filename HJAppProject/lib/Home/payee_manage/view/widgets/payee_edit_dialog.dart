import 'package:flutter/material.dart';
import 'package:hjproject/Home/payee_manage/model/payee.dart';

/// 交易对象编辑对话框
/// - 风格参考：分类管理的编辑对话框
/// - 返回：确认时返回 Map，取消返回 null
class PayeeEditDialog extends StatefulWidget {
  const PayeeEditDialog({
    super.key,
    required this.initial,
  });

  final Payee initial;

  @override
  State<PayeeEditDialog> createState() => _PayeeEditDialogState();
}

class _PayeeEditDialogState extends State<PayeeEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _name = widget.initial.payeeName;
  late String _sortText = widget.initial.sort.toString();
  late bool _canExpense = widget.initial.canExpense;
  late bool _canIncome = widget.initial.canIncome;
  late bool _enable = widget.initial.enable;
  late String? _remark = widget.initial.remark;

  bool _submitting = false;
  bool _formValid = true;

  void _revalidate() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _formValid = valid;
    });
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      alignLabelWithHint: true,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  ButtonStyle _primaryButtonStyle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ButtonStyle(
      minimumSize: const MaterialStatePropertyAll(Size(64, 44)),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed)) {
          return cs.onPrimary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.hovered)) {
          return cs.onPrimary.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return cs.onPrimary.withOpacity(0.12);
        }
        return null;
      }),
    );
  }

  ButtonStyle _secondaryButtonStyle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ButtonStyle(
      minimumSize: const MaterialStatePropertyAll(Size(64, 44)),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      side: MaterialStatePropertyAll(BorderSide(color: cs.outlineVariant)),
      foregroundColor: MaterialStatePropertyAll(cs.onSurfaceVariant),
      overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed)) {
          return cs.primary.withOpacity(0.08);
        }
        if (states.contains(MaterialState.hovered)) {
          return cs.primary.withOpacity(0.06);
        }
        if (states.contains(MaterialState.focused)) {
          return cs.primary.withOpacity(0.08);
        }
        return null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final horizontalPadding = w < 600 ? 16.0 : (w < 1024 ? 20.0 : 24.0);

        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: cs.surfaceTint,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          title: Center(
            child: Text(
              '编辑交易对象',
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 560, maxHeight: 600),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Form(
                key: _formKey,
                onChanged: _revalidate,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 名称（必填）
                    TextFormField(
                      key: const ValueKey('payeeNameField'),
                      initialValue: _name,
                      autofocus: true,
                      style: tt.bodyMedium,
                      decoration: _inputDecoration(
                        context: context,
                        label: '名称（必填）',
                        hint: '请输入名称',
                        prefixIcon: Icons.label_outline,
                      ),
                      onChanged: (v) {
                        _name = v.trim();
                        _revalidate();
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '请输入名称';
                        }
                        if (v.trim().length > 32) {
                          return '名称过长（最多32字）';
                        }
                        return null;
                      },
                      maxLength: 32,
                    ),
                    const SizedBox(height: 12),
                    // 排序（整数）
                    TextFormField(
                      key: const ValueKey('sortField'),
                      initialValue: _sortText,
                      style: tt.bodyMedium,
                      decoration: _inputDecoration(
                        context: context,
                        label: '排序（数字）',
                        hint: '请输入非负整数',
                        prefixIcon: Icons.format_list_numbered,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _sortText = v.trim();
                        _revalidate();
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '请输入排序数字';
                        final n = int.tryParse(v.trim());
                        if (n == null) return '排序需为整数';
                        if (n < 0) return '排序需为非负整数';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // 支出/收入/启用
                    SwitchListTile(
                      dense: false,
                      contentPadding: EdgeInsets.zero,
                      title: Text('支出允许', style: tt.bodyMedium),
                      value: _canExpense,
                      onChanged: _submitting ? null : (v) => setState(() => _canExpense = v),
                      secondary: const Icon(Icons.arrow_upward),
                    ),
                    SwitchListTile(
                      dense: false,
                      contentPadding: EdgeInsets.zero,
                      title: Text('收入允许', style: tt.bodyMedium),
                      value: _canIncome,
                      onChanged: _submitting ? null : (v) => setState(() => _canIncome = v),
                      secondary: const Icon(Icons.arrow_downward),
                    ),
                    SwitchListTile(
                      dense: false,
                      contentPadding: EdgeInsets.zero,
                      title: Text('启用', style: tt.bodyMedium),
                      value: _enable,
                      onChanged: _submitting ? null : (v) => setState(() => _enable = v),
                      secondary: const Icon(Icons.toggle_on),
                    ),
                    const SizedBox(height: 12),
                    // 备注（可选）
                    TextFormField(
                      key: const ValueKey('remarkField'),
                      initialValue: _remark,
                      style: tt.bodyMedium,
                      decoration: _inputDecoration(
                        context: context,
                        label: '备注（可选）',
                        hint: '可填写备注信息',
                        prefixIcon: Icons.notes_outlined,
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (v) => _remark = v.trim().isEmpty ? null : v.trim(),
                    ),
                    const SizedBox(height: 8),
                    // 只读信息（隐藏/只读）
                    Semantics(
                      label: '只读信息',
                      child: Text(
                        'ID: ${widget.initial.payeeId} · 账本: ${widget.initial.bookId}',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
              style: _secondaryButtonStyle(context),
              child: Text('取消', style: tt.labelLarge),
            ),
            Tooltip(
              message: '保存',
              child: FilledButton.icon(
                style: _primaryButtonStyle(context),
                onPressed: _submitting || !_formValid
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          _revalidate();
                          return;
                        }
                        setState(() => _submitting = true);
                        // 组装编辑后的字段并返回（网络请求在外部进行）
                        final result = <String, dynamic>{
                          'payeeName': _name,
                          'sort': int.tryParse(_sortText) ?? widget.initial.sort,
                          'canExpense': _canExpense,
                          'canIncome': _canIncome,
                          'enable': _enable,
                          if (_remark != null) 'remark': _remark,
                        };
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(result);
                        }
                      },
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text('保存', style: tt.labelLarge),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        );
      },
    );
  }
}