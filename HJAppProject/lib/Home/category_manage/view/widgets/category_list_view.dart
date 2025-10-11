import 'package:flutter/material.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_summary_bar.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_pager.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_empty_state.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_loading_indicator.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_error_view.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_tree_node.dart';

class CategoryListView<T> extends StatelessWidget {
  const CategoryListView({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.typeText,
    required this.total,
    required this.currentPage,
    required this.roots,
    required this.expandedNodeIds,
    required this.childrenOf,
    required this.nameOf,
    required this.remarkOf,
    required this.idOf,
    required this.onToggleNode,
    required this.onModify,
    required this.onMoveToRecycle,
    required this.onAddChild,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  final String typeText; // '支出' 或 '收入'
  final int total;
  final int currentPage;

  final List<T> roots;
  final Set<int> expandedNodeIds;

  // Adapters
  final List<T> Function(T) childrenOf;
  final String Function(T) nameOf;
  final String? Function(T) remarkOf;
  final int Function(T) idOf;

  // Actions
  final void Function(T node, bool expanded) onToggleNode;
  final void Function(T node) onModify;
  final void Function(T node) onMoveToRecycle;
  final void Function(T node) onAddChild;

  // Pager
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const CategoryLoadingIndicator();
    }
    if (error != null) {
      return CategoryErrorView(message: error ?? '加载失败', onRetry: onRetry);
    }
    if (roots.isEmpty) {
      return ListView(
        children: [
          CategorySummaryBar(typeText: typeText, total: total, currentPage: currentPage),
          const SizedBox(height: 80),
          const CategoryEmptyState(),
          const SizedBox(height: 16),
          CategoryPager(total: total, hasPrev: hasPrev, hasNext: hasNext, onPrev: onPrev, onNext: onNext),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        CategorySummaryBar(typeText: typeText, total: total, currentPage: currentPage),
        ...roots.map(
          (n) => CategoryTreeNode<T>(
            node: n,
            depth: 0,
            childrenOf: childrenOf,
            nameOf: nameOf,
            remarkOf: remarkOf,
            idOf: idOf,
            isExpanded: (x) => expandedNodeIds.contains(idOf(x)),
            onToggleNode: onToggleNode,
            onModify: onModify,
            onMoveToRecycle: onMoveToRecycle,
            onAddChild: onAddChild,
          ),
        ),
        const SizedBox(height: 8),
        CategoryPager(total: total, hasPrev: hasPrev, hasNext: hasNext, onPrev: onPrev, onNext: onNext),
        const SizedBox(height: 8),
      ],
    );
  }
}