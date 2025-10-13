import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../data/tag_service.dart';

class TagEditPage extends StatefulWidget {
  final int tagId;
  final String name;
  final bool enable;
  final int sort;
  final String? remark;
  final bool canExpense;
  final bool canIncome;
  final bool canTransfer;
  final int parentId;
  final int bookId;

  const TagEditPage({
    Key? key,
    required this.tagId,
    required this.name,
    required this.enable,
    required this.sort,
    this.remark,
    required this.canExpense,
    required this.canIncome,
    required this.canTransfer,
    required this.parentId,
    required this.bookId,
  }) : super(key: key);

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sortController = TextEditingController();
  final _remarkController = TextEditingController();

  bool _enable = true;
  bool _canExpense = false;
  bool _canIncome = false;
  bool _canTransfer = false;
  bool _isLoading = false;
  bool _dirty = false;

  final TagPageService _service = TagPageService();

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

  void _markDirty() {
    if (!_dirty) {
      setState(() {
        _dirty = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _sortController.text = widget.sort.toString();
    _remarkController.text = widget.remark ?? '';
    _enable = widget.enable;
    _canExpense = widget.canExpense;
    _canIncome = widget.canIncome;
    _canTransfer = widget.canTransfer;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑标签'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基本信息',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '标签名称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入标签名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sortController,
                      decoration: const InputDecoration(
                        labelText: '排序',
                        border: OutlineInputBorder(),
                        helperText: '数字越小排序越靠前',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入排序数字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 0),
                    // 备注字段已移至表单底部（复用交易对象管理文案与校验）
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标签设置',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('启用'),
                      subtitle: const Text('是否启用此标签'),
                      value: _enable,
                      onChanged: (value) {
                        setState(() => _enable = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('可支出'),
                      subtitle: const Text('是否可用于支出记录'),
                      value: _canExpense,
                      onChanged: (value) {
                        setState(() => _canExpense = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('可收入'),
                      subtitle: const Text('是否可用于收入记录'),
                      value: _canIncome,
                      onChanged: (value) {
                        setState(() => _canIncome = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('可转账'),
                      subtitle: const Text('是否可用于转账记录'),
                      value: _canTransfer,
                      onChanged: (value) {
                        setState(() => _canTransfer = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '备注',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '可选，最长200个字符',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value != null && value.length > 200) {
                          return '备注长度不能超过200';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.modifyTag(
        enable: _enable,
        tagId: widget.tagId,
        tagName: _nameController.text.trim(),
        bookId: widget.bookId,
        parentId: widget.parentId,
        sort: int.parse(_sortController.text),
        canExpense: _canExpense,
        canIncome: _canIncome,
        canTransfer: _canTransfer,
        remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}