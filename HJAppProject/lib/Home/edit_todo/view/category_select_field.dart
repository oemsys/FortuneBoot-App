import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/edit_select_item.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/category_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';

class CategorySelectField extends StatefulWidget {
  CategorySelectField({super.key, required this.billType});
  BillType billType;

  @override
  State<CategorySelectField> createState() => _CategorySelectFieldState();
}

class _CategorySelectFieldState extends State<CategorySelectField> {
  CategorySelectItem? _selectedMainCategory;
  CategorySelectItem? _selectedSubCategory;
  TextEditingController _amountController = TextEditingController();
  Map<int, double> _categoryAmountPairs = {};
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategorySelectItem>>(
      future: categroyFutureItems(context, widget.billType),
      builder: (context, snapshot) {
        // 处理不同状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text('加载分类失败: ${snapshot.error}'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text('重试'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.category_outlined, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text('没有可用的分类'),
              ],
            ),
          );
        }

        // 数据加载成功，构建UI
        final categories = snapshot.data!;
        return Column(
          children: [
            // 已选择的分类和金额
            if (_categoryAmountPairs.isNotEmpty)
              _buildSelectedCategories(),
            
            // 分类选择器
            _buildCategorySelector(categories),
          ],
        );
      },
    );
  }
  
  // 已选择的分类和金额
  Widget _buildSelectedCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '已选择的分类',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _categoryAmountPairs.length,
          itemBuilder: (context, index) {
            final categoryId = _categoryAmountPairs.keys.elementAt(index);
            final amount = _categoryAmountPairs[categoryId];
            
            // 查找分类名称
            String categoryName = '未知分类';
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '¥${amount?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.billType == BillType.expenditure
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _categoryAmountPairs.remove(categoryId);
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 16),
        Divider(),
      ],
    );
  }
  
  // 分类选择器
  Widget _buildCategorySelector(List<CategorySelectItem> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主分类选择
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: categories.map((category) {
              final isSelected = _selectedMainCategory?.id == category.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category.title),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMainCategory = selected ? category : null;
                      _selectedSubCategory = null;
                    });
                  },
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  backgroundColor: Colors.transparent,
                  selectedColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ),
        
        // 子分类选择
        if (_selectedMainCategory != null && _selectedMainCategory!.children != null)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _selectedMainCategory!.children!.map((subCategory) {
                final isSelected = _selectedSubCategory?.id == subCategory.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(subCategory.title),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubCategory = selected ? subCategory : null;
                      });
                    },
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSecondary
                          : null,
                    ),
                    backgroundColor: Colors.transparent,
                    selectedColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
              }).toList(),
            ),
          ),
        
        // 金额输入和添加按钮
        if (_selectedMainCategory != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '分类金额',
                      hintText: '请输入金额',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text);
                    if (amount != null && amount > 0) {
                      setState(() {
                        final categoryId = _selectedSubCategory?.id ?? _selectedMainCategory!.id;
                        _categoryAmountPairs[categoryId] = amount;
                        _amountController.clear();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('请输入有效金额')),
                      );
                    }
                  },
                  child: Text('添加'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<List<CategorySelectItem>> categroyFutureItems(
    BuildContext context, BillType billType) async {
  CategoryService categoryService = CategoryService();
  var response = await categoryService.getEnableList(
      context.read<BillsRepository>().bookId() ?? 1,
      type: billType.value);
  List<CategorySelectItem> categroyItems = [];
  if (response.code == 0) {
    var list = response.data as List? ?? [];
    for (final item in list) {
      categroyItems.add(CategorySelectItem.fromJson(
          Map<String, dynamic>.from(item as Map? ?? {})));
    }
  }
  return categroyItems;
}
