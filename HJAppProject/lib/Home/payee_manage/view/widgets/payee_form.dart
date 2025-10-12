import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 与账单编辑页统一的分组卡片样式
Widget wrapGroupCard(Widget child) {
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

/// 分组标题（与账单编辑页视觉层级一致）
class GroupTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const GroupTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: tt.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ],
    );
  }
}
// 统一装饰（复刻“记一笔”输入框：圆角12、灰边、聚焦蓝、错误红、label样式、前缀图标）
InputDecoration buildUnifiedInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    labelText: label,
    labelStyle: TextStyle(
      color: Colors.grey.shade700,
      fontSize: 16,
    ),
    prefixIcon: Icon(icon),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.blue),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red),
      borderRadius: BorderRadius.circular(12),
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// 名称输入（对齐“标题”）
class PayeeNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
  final VoidCallback onChanged;

  const PayeeNameField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: buildUnifiedInputDecoration(
        context,
        label: '名称',
        hint: '请输入名称（必填，最长32个字符）',
        icon: Icons.title,
      ),
      maxLength: 32,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return '名称不能为空';
        if (t.length > 32) return '名称长度不能超过32';
        return null;
      },
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
      onChanged: (_) => onChanged(),
    );
  }
}

/// 顺序输入（对齐“金额”，但仅允许非负整数、无币种/小数/分隔，右对齐）
class PayeeOrderField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
  final VoidCallback onChanged;

  const PayeeOrderField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: buildUnifiedInputDecoration(
        context,
        label: '排序',
        hint: '请输入非负整数',
        icon: Icons.sort,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.end, // 右对齐视觉对齐金额输入
      maxLength: 9,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return '排序不能为空';
        final n = int.tryParse(t);
        if (n == null) return '必须为整数';
        if (n < 0) return '必须为非负数';
        return null;
      },
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
      onChanged: (_) => onChanged(),
    );
  }
}

/// 备注输入（对齐“备注”，多行、同装饰样式）
class PayeeRemarkField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  const PayeeRemarkField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: buildUnifiedInputDecoration(
        context,
        label: '备注',
        hint: '可选，最长200个字符',
        icon: Icons.note,
      ),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.done,
      maxLines: 3,
      maxLength: 200,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) {
        final t = (v ?? '');
        if (t.isNotEmpty && t.length > 200) {
          return '备注长度不能超过200';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );
  }
}

/// 交易对象表单（新增/编辑复用）
/// 不包含底部操作条与提交逻辑，仅负责渲染与校验提示
class PayeeForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController sortController;
  final TextEditingController remarkController;

  final FocusNode nameNode;
  final FocusNode sortNode;
  final FocusNode remarkNode;

  final bool canExpense;
  final bool canIncome;
  final bool enable;

  final ValueChanged<bool> onCanExpenseChanged;
  final ValueChanged<bool> onCanIncomeChanged;
  final ValueChanged<bool> onEnableChanged;

  /// 当任一输入变更时，用于标记脏态
  final VoidCallback onChanged;

  /// 是否处于忙碌态（统一禁用交互）
  final bool isBusy;

  const PayeeForm({
    super.key,
    required this.nameController,
    required this.sortController,
    required this.remarkController,
    required this.nameNode,
    required this.sortNode,
    required this.remarkNode,
    required this.canExpense,
    required this.canIncome,
    required this.enable,
    required this.onCanExpenseChanged,
    required this.onCanIncomeChanged,
    required this.onEnableChanged,
    required this.onChanged,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isBusy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 基本信息
          wrapGroupCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GroupTitle(
                  title: '基本信息',
                  subtitle: '填写名称与排序，名称必填且不超过32字符；排序为非负整数',
                ),
                const SizedBox(height: 16),
                PayeeNameField(
                  controller: nameController,
                  focusNode: nameNode,
                  nextFocus: sortNode,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 12),
                PayeeOrderField(
                  controller: sortController,
                  focusNode: sortNode,
                  nextFocus: remarkNode,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),

          // 使用范围开关
          wrapGroupCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GroupTitle(
                  title: '使用范围',
                  subtitle: '控制该交易对象可用于“支出/收入”，以及是否启用',
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  title: const Text('支出'),
                  subtitle: const Text('该交易对象可用于支出账目'),
                  value: canExpense,
                  onChanged: (v) => onCanExpenseChanged(v),
                ),
                SwitchListTile.adaptive(
                  title: const Text('收入'),
                  subtitle: const Text('该交易对象可用于收入账目'),
                  value: canIncome,
                  onChanged: (v) => onCanIncomeChanged(v),
                ),
                SwitchListTile.adaptive(
                  title: const Text('启用'),
                  subtitle: const Text('禁用后不可在新增账目中选择'),
                  value: enable,
                  onChanged: (v) => onEnableChanged(v),
                ),
              ],
            ),
          ),

          // 备注
          wrapGroupCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GroupTitle(
                  title: '备注',
                  subtitle: '可选项，最长200字符，用于补充说明',
                ),
                const SizedBox(height: 16),
                PayeeRemarkField(
                  controller: remarkController,
                  focusNode: remarkNode,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}