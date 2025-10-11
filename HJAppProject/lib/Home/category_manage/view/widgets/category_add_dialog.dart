import 'package:flutter/material.dart';

class ParentOption {
  final int id;
  final String label;
  const ParentOption({required this.id, required this.label});
}

class CategoryAddDialog extends StatefulWidget {
  const CategoryAddDialog({
    super.key,
    required this.titleText,
    required this.initialParentId,
    this.fixedParentNameFuture,
    this.fetchParentOptions,
    required this.onSubmit,
  });

  /// 标题文案，例如：新增支出分类 / 新增收入分类
  final String titleText;

  /// 初始父类ID，-1 表示一级分类可选父类
  final int initialParentId;

  /// 若 initialParentId != -1，展示只读的父级名称
  final Future<String>? fixedParentNameFuture;

  /// 若 initialParentId == -1，则通过该函数异步加载可选父级下拉项
  /// 返回 ParentOption(id,label) 列表
  final Future<List<ParentOption>> Function()? fetchParentOptions;

  /// 提交回调，由页面注入调用 Service
  final Future<void> Function({
    required int parentId,
    required String name,
    required bool enable,
    required int sort,
    String? remark,
  }) onSubmit;

  @override
  State<CategoryAddDialog> createState() => _CategoryAddDialogState();
}

class _CategoryAddDialogState extends State<CategoryAddDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late int _parentId = widget.initialParentId;
  String _name = '';
  bool _enable = true;
  String _sortText = '';
  String? _remark;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final bool fixedParent = widget.initialParentId != -1;

    return AlertDialog(
      title: Center(child: Text(widget.titleText)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fixedParent && widget.fixedParentNameFuture != null) ...[
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
                        '父级分类：$text（已固定）',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      );
                    },
                  ),
                ),
              ] else ...[
                FutureBuilder<List<ParentOption>>(
                  future: widget.fetchParentOptions?.call(),
                  builder: (context, snap) {
                    final items = (snap.data ?? const <ParentOption>[])
                        .map((opt) => DropdownMenuItem<int>(
                              value: opt.id,
                              child: Text(opt.label),
                            ))
                        .toList();
                    return DropdownButtonFormField<int>(
                      value: _parentId == -1 ? null : _parentId,
                      items: items,
                      decoration: const InputDecoration(
                        labelText: '父级分类（可选）',
                        helperText: '不选择则为一级分类',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _submitting ? null : (v) => setState(() => _parentId = (v ?? -1)),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
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
                      parentId: _parentId,
                      name: _name,
                      enable: _enable,
                      sort: int.tryParse(_sortText) ?? 0,
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