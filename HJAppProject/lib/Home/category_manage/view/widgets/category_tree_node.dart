import 'package:flutter/material.dart';

class CategoryTreeNode<T> extends StatelessWidget {
  const CategoryTreeNode({
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
  });

  final T node;
  final int depth;

  // Adapters
  final List<T> Function(T) childrenOf;
  final String Function(T) nameOf;
  final String? Function(T) remarkOf;
  final int Function(T) idOf;

  // Controlled expansion
  final bool Function(T) isExpanded;
  final void Function(T node, bool expanded) onToggleNode;

  // Actions
  final void Function(T node) onModify;
  final void Function(T node) onMoveToRecycle;
  final void Function(T node) onAddChild;

  @override
  Widget build(BuildContext context) {
    final List<T> children = childrenOf(node);
    final bool hasChildren = children.isNotEmpty;
    final int childCount = children.length;
    final String name = nameOf(node);
    final String? remark = remarkOf(node);
    final bool expanded = isExpanded(node);

    final Widget leading = Icon(
      hasChildren ? Icons.label : Icons.label_outline,
      size: 16,
      color: Theme.of(context).colorScheme.secondary,
    );

    final Widget countChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$childCount 子类',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );

    final Widget menu = PopupMenuButton<int>(
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
        const PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text('修改'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('移入回收站'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.green),
              SizedBox(width: 8),
              Text('新增子类'),
            ],
          ),
        ),
      ],
    );

    final Widget arrowIcon = Icon(
      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
    );

    final Widget trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        countChip,
        const SizedBox(width: 8),
        menu,
        const SizedBox(width: 8),
        hasChildren
            ? arrowIcon
            : InkWell(
                onTap: () => onToggleNode(node, !expanded),
                child: arrowIcon,
              ),
      ],
    );

    final Widget? subtitle = (remark != null && remark.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              remark,
              style: const TextStyle(color: Colors.grey),
              softWrap: true,
            ),
          )
        : null;

    final Widget tile = hasChildren
        ? ExpansionTile(
            key: ValueKey('node-\${idOf(node)}-\$expanded'),
            initiallyExpanded: expanded,
            leading: leading,
            title: Text(
              name,
              style: TextStyle(
                fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            trailing: trailing,
            onExpansionChanged: (v) => onToggleNode(node, v),
            subtitle: subtitle,
            children: children
                .map(
                  (c) => CategoryTreeNode<T>(
                    node: c,
                    depth: depth + 1,
                    childrenOf: childrenOf,
                    nameOf: nameOf,
                    remarkOf: remarkOf,
                    idOf: idOf,
                    isExpanded: isExpanded, // child will recompute via parent wrapper
                    onToggleNode: onToggleNode,
                    onModify: onModify,
                    onMoveToRecycle: onMoveToRecycle,
                    onAddChild: onAddChild,
                  ),
                )
                .toList(),
          )
        : ListTile(
            leading: leading,
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: trailing,
            subtitle: subtitle,
          );

    if (depth == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: tile,
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: 12.0 * depth),
      child: tile,
    );
  }
}