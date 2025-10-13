import 'package:flutter/material.dart';

class TagTreeNode<T> extends StatelessWidget {
  const TagTreeNode({
    super.key,
    required this.node,
    required this.depth,
    required this.childrenOf,
    required this.nameOf,
    required this.remarkOf,
    required this.idOf,
    required this.isExpanded,
    required this.onToggleNode,
    required this.onModify,
    required this.onMoveToRecycle,
    required this.onAddChild,
    this.enableOf,
    this.canExpenseOf,
    this.canIncomeOf,
    this.canTransferOf,
  });

  final T node;
  final int depth;

  // Adapters
  final List<T> Function(T) childrenOf;
  final String Function(T) nameOf;
  final String? Function(T) remarkOf;
  final int Function(T) idOf;
  final bool Function(T)? enableOf;
  final bool Function(T)? canExpenseOf;
  final bool Function(T)? canIncomeOf;
  final bool Function(T)? canTransferOf;

  // Controlled expansion
  final bool Function(T) isExpanded;
  final void Function(T node, bool expanded) onToggleNode;

  // Actions
  final void Function(T node) onModify;
  final void Function(T node) onMoveToRecycle;
  final void Function(T node) onAddChild;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final List<T> children = childrenOf(node);
    final bool hasChildren = children.isNotEmpty;
    final int childCount = children.length;
    final String name = nameOf(node);
    final String? remark = remarkOf(node);
    final bool expanded = isExpanded(node);

    final Widget leading = Icon(
      hasChildren ? Icons.label : Icons.label_outline,
      size: 16,
      color: cs.secondary,
    );

    // 构建状态标识
    Widget _buildStatusChips() {
      final List<Widget> chips = [];
      
      if (enableOf != null && !enableOf!(node)) {
        chips.add(_buildStatusChip('禁用', Colors.grey, cs));
      }
      
      if (canExpenseOf != null && canExpenseOf!(node)) {
        chips.add(_buildStatusChip('支出', Colors.red, cs));
      }
      
      if (canIncomeOf != null && canIncomeOf!(node)) {
        chips.add(_buildStatusChip('收入', Colors.green, cs));
      }
      
      if (canTransferOf != null && canTransferOf!(node)) {
        chips.add(_buildStatusChip('转账', Colors.blue, cs));
      }
      
      if (chips.isEmpty) return const SizedBox.shrink();
      
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: chips,
      );
    }

    final Widget countChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$childCount 子标签',
        textAlign: TextAlign.center,
        style: tt.labelSmall?.copyWith(color: cs.onSecondaryContainer),
      ),
    );

    final Widget menu = Tooltip(
      message: '更多操作',
      child: PopupMenuButton<int>(
        tooltip: '更多操作',
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 0) {
            onModify(node);
          } else if (value == 1) {
            onMoveToRecycle(node);
          } else if (value == 2) {
            onAddChild(node);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                Icon(Icons.add, color: cs.tertiary),
                const SizedBox(width: 8),
                const Text('新增子标签'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 0,
            child: Row(
              children: [
                Icon(Icons.edit, color: cs.primary),
                const SizedBox(width: 8),
                const Text('修改'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: cs.error),
                const SizedBox(width: 8),
                const Text('移入回收站'),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget arrowIcon = Icon(
      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      color: cs.outline,
    );

    final Widget trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasChildren) countChip,
        if (hasChildren) const SizedBox(width: 8),
        menu,
        const SizedBox(width: 8),
        hasChildren
            ? arrowIcon
            : InkWell(
                onTap: () => onToggleNode(node, !expanded),
                borderRadius: BorderRadius.circular(8),
                child: arrowIcon,
              ),
      ],
    );

    final Widget? subtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (remark != null && remark.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              remark,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              softWrap: true,
            ),
          ),
        const SizedBox(height: 4),
        _buildStatusChips(),
      ],
    );

    final Widget tile = hasChildren
        ? ExpansionTile(
            key: ValueKey('tag-node-${idOf(node)}-$expanded'),
            initiallyExpanded: expanded,
            leading: leading,
            title: Text(
              name,
              style: depth == 0
                  ? tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                  : tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: trailing,
            onExpansionChanged: (v) => onToggleNode(node, v),
            subtitle: subtitle,
            children: children
                .map(
                  (c) => TagTreeNode<T>(
                    node: c,
                    depth: depth + 1,
                    childrenOf: childrenOf,
                    nameOf: nameOf,
                    remarkOf: remarkOf,
                    idOf: idOf,
                    isExpanded: isExpanded, // child recomputes via parent
                    onToggleNode: onToggleNode,
                    onModify: onModify,
                    onMoveToRecycle: onMoveToRecycle,
                    onAddChild: onAddChild,
                    enableOf: enableOf,
                    canExpenseOf: canExpenseOf,
                    canIncomeOf: canIncomeOf,
                    canTransferOf: canTransferOf,
                  ),
                )
                .toList(),
          )
        : ListTile(
            leading: leading,
            title: Text(
              name,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: trailing,
            subtitle: subtitle,
          );

    if (depth == 0) {
      final double targetElevation = (expanded && hasChildren) ? 2.0 : 1.0;
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetElevation, end: targetElevation),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: value,
            color: cs.surface,
            surfaceTintColor: cs.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: tile,
          );
        },
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: 12.0 * depth),
      child: tile,
    );
  }

  Widget _buildStatusChip(String label, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}