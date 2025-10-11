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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text(widget.titleText)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.fixedParentNameFuture != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FutureBuilder<String>(
                    future: widget.fixedParentNameFuture,
                    builder: (context, snapshot) {
                      final text = snapshot.hasData ? snapshot.data! : '加载中...';
                      return Text(
                        '父级分类：$text',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: '分类名称（必填）',
                  border: OutlineInputBorder(),
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
                title: const Text('启用状态（必填）'),
                value: _enable,
                onChanged: _submitting ? null : (v) => setState(() => _enable = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _sortText,
                decoration: const InputDecoration(
                  labelText: '顺序（数字，可选）',
                  border: OutlineInputBorder(),
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
                initialValue: _remark,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => _remark = v.trim().isEmpty ? null : v.trim(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton.icon(
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
          label: const Text('保存'),
        ),
      ],
    );
  }
}