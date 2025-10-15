import 'package:flutter/material.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_loading_indicator.dart';

/// 交易对象加载态：复用分类管理的加载指示样式
class PayeeLoadingIndicator extends StatelessWidget {
  const PayeeLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryLoadingIndicator();
  }
}