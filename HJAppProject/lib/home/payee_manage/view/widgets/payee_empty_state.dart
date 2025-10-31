import 'package:flutter/material.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_empty_state.dart';

/// 交易对象空态：复用分类管理的视觉风格，保持一致性
class PayeeEmptyState extends StatelessWidget {
  const PayeeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryEmptyState();
  }
}