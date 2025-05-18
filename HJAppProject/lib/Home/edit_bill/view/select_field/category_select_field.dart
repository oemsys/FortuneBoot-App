import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/home/edit_bill/models/edit_select_item.dart';
import 'package:hjproject/home/todos_overview/models/bill_item.dart';
import 'package:hjproject/request/category_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';

class CategoryTreeWidget extends StatefulWidget {
  CategoryTreeWidget(
      {super.key,
      required this.categories,
      required this.billType,
      this.onCategorySelected,
      required this.categoryAmountPairs});
  List<CategorySelectItem> categories;
  Function(Map<int, double>)? onCategorySelected;
  Map<int, double> categoryAmountPairs;
  BillType billType;

  @override
  State<CategoryTreeWidget> createState() => CategoryTreeWidgetState();
}

class CategoryTreeWidgetState extends State<CategoryTreeWidget> {
  CategorySelectItem? _selectedMainCategory;
  CategorySelectItem? _selectedSubCategory;
  CategorySelectItem? _selectedThirdCategory;
  TextEditingController _amountController = TextEditingController();
  // 展开的二级分类ID列表（用于控制UI展开/折叠）
  List<int> _expandedSecondLevelIds = [];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 已选择的分类和金额
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分类: ${_getSelectedCategoryPath()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^-?\d*\.?\d{0,5}')), // 允许负号、数字和最多5位小数
                        ],
                        decoration: InputDecoration(
                          labelText: '金额',
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
                        if (amount != null && amount != 0) {
                          if (_selectedMainCategory == null) {
                            ScaffoldMessenger.of(context)
                                .removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请选择当前费用所属分类')),
                            );
                            return;
                          }
                          setState(() {
                            // 优先使用三级分类，其次二级分类，最后一级分类
                            categorys();
                            _amountController.clear();
                            // 收起键盘
                            FocusScope.of(context).unfocus();
                          });
                        } else {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('请输入非零金额')),
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
              ],
            ),
          ),
        ),
        if (widget.categoryAmountPairs.isNotEmpty) _buildSelectedCategories(),

        // 分类选择器
        _buildCategorySelector(widget.categories),
      ],
    );
  }

  Map<int, double> categorys() {
    final amount = double.tryParse(_amountController.text);
    if (amount != null && amount != 0) {
      if (_selectedMainCategory == null) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请选择当前费用所属分类')),
        );
      } else {
        final categoryId = _selectedThirdCategory?.id ??
            _selectedSubCategory?.id ??
            _selectedMainCategory!.id;
        widget.categoryAmountPairs[categoryId] = amount;
      }
    }
    return widget.categoryAmountPairs;
  }

  // 已选择的分类和金额
  Widget _buildSelectedCategories() {
    widget.onCategorySelected?.call(widget.categoryAmountPairs);
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
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.categoryAmountPairs.length,
          itemBuilder: (context, index) {
            final categoryId = widget.categoryAmountPairs.keys.elementAt(index);
            final amount = widget.categoryAmountPairs[categoryId];

            // 查找分类名称
            String categoryName = CategorySelectItem.getFullPathById(
                widget.categories, categoryId);

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                            widget.categoryAmountPairs.remove(categoryId);
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
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '一级分类',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected =
                          _selectedMainCategory?.id == category.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                        child: ChoiceChip(
                          label: Text(category.title),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMainCategory =
                                  selected ? category : null;
                              _selectedSubCategory = null;
                              _selectedThirdCategory = null;
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
              ],
            ),
          ),
        ),

        // 二级分类选择
        if (_selectedMainCategory != null &&
            _selectedMainCategory!.children != null)
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '二级分类',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedMainCategory!.children!.map((subCategory) {
                      final isSelected =
                          _selectedSubCategory?.id == subCategory.id;
                      final hasThirdLevel = subCategory.children != null &&
                          subCategory.children!.isNotEmpty;
                      final isExpanded =
                          _expandedSecondLevelIds.contains(subCategory.id);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: hasThirdLevel
                                ? () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedSecondLevelIds
                                            .remove(subCategory.id);
                                      } else {
                                        _expandedSecondLevelIds
                                            .add(subCategory.id);
                                      }
                                    });
                                  }
                                : null,
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(subCategory.title),
                                  if (hasThirdLevel)
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 16,
                                    ),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSubCategory =
                                      selected ? subCategory : null;
                                  _selectedThirdCategory = null;

                                  // 如果选中且有三级分类，自动展开
                                  if (selected &&
                                      hasThirdLevel &&
                                      !isExpanded) {
                                    _expandedSecondLevelIds.add(subCategory.id);
                                  }
                                });
                              },
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : null,
                              ),
                              backgroundColor: Colors.transparent,
                              selectedColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                          ),

                          // 三级分类
                          if (hasThirdLevel && isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, top: 4.0, bottom: 8.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    subCategory.children!.map((thirdCategory) {
                                  final isThirdSelected =
                                      _selectedThirdCategory?.id ==
                                          thirdCategory.id;
                                  return ChoiceChip(
                                    label: Text(thirdCategory.title),
                                    selected: isThirdSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedThirdCategory =
                                            selected ? thirdCategory : null;
                                      });
                                    },
                                    labelStyle: TextStyle(
                                      color: isThirdSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onTertiary
                                          : null,
                                      fontSize: 12,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    selectedColor:
                                        Theme.of(context).colorScheme.tertiary,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 获取当前选择的分类路径
  String _getSelectedCategoryPath() {
    if (_selectedMainCategory == null) return '';

    String path = _selectedMainCategory!.title;

    if (_selectedSubCategory != null) {
      path += ' > ${_selectedSubCategory!.title}';

      if (_selectedThirdCategory != null) {
        path += ' > ${_selectedThirdCategory!.title}';
      }
    }

    return path;
  }
}
