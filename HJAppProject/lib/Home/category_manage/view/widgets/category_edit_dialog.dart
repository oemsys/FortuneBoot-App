import 'package:flutter/material.dart';

class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({
    super.key,
    required this.titleText,
    required this.initialName,
    required this.initialEnable,
    required this.initialSort,
    required this.initialRemark,
    this.fixedParentNameFuture,
    required this.onSubmit,
  });

  /// 标题文案，例如：修改支出分类 / 修改收入分类
  final String titleText;

  /// 初始字段
  final String initialName;
  final bool initialEnable;
  final int initialSort;
  final String? initialRemark;

  /// 若提供则展示固定父级名称（只读），用于编辑保留父级
  final Future<String>? fixedParentNameFuture;

  /// 提交回调，由页面注入调用 Service
  /// 约定：抛错由页面负责提示；组件内部仅处理 loading/禁用状态
  final Future<void> Function({
    required String name,
    required bool enable,
    required int sort,
    String? remark,
  }) onSubmit;

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _name = widget.initialName;
  late bool _enable = widget.initialEnable;
  late String _sortText = widget.initialSort.toString();
  late String? _remark = widget.initialRemark;

  bool _submitting = false;

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
              widget.titleText,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.fixedParentNameFuture != null)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: Semantics(
                          label: '父级分类（只读）',
                          child: Card(
                            color: cs.surfaceVariant,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: cs.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: FutureBuilder<String>(
                                future: widget.fixedParentNameFuture,
                                builder: (context, snapshot) {
                                  final text = snapshot.hasData ? snapshot.data! : '加载中...';
                                  return Text(
                                    '父级分类：$text',
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('nameField'),
                      initialValue: _name,
                      autofocus: true,
                      style: tt.bodyMedium,
                      decoration: _inputDecoration(
                        context: context,
                        label: '分类名称（必填）',
                        hint: '请输入分类名称',
                        prefixIcon: Icons.label_outline,
                      ),
                      onChanged: (v) => _name = v.trim(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '请输入分类名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      dense: false,
                      contentPadding: EdgeInsets.zero,
                      title: Text('启用状态（必填）', style: tt.bodyMedium),
                      value: _enable,
                      onChanged: _submitting ? null : (v) => setState(() => _enable = v),
                      secondary: const Icon(Icons.toggle_on),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('sortField'),
                      initialValue: _sortText,
                      style: tt.bodyMedium,
                      decoration: _inputDecoration(
                        context: context,
                        label: '顺序（数字，可选）',
                        hint: '请输入数字',
                        prefixIcon: Icons.format_list_numbered,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _sortText = v.trim(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = int.tryParse(v);
                        if (n == null) return '顺序需为数字';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
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
                      onChanged: (v) => _remark = v.trim().isEmpty ? null : v.trim(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              style: _secondaryButtonStyle(context),
              child: Text('取消', style: tt.labelLarge),
            ),
            Tooltip(
              message: '保存',
              child: FilledButton.icon(
                style: _primaryButtonStyle(context),
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _submitting = true);
                        try {
                          await widget.onSubmit(
                            name: _name,
                            enable: _enable,
                            sort: int.tryParse(_sortText) ?? widget.initialSort,
                            remark: _remark,
                          );
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          setState(() => _submitting = false);
                          // 错误提示交由页面统一处理（SnackBar）
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