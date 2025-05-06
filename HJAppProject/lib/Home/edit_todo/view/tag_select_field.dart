import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/edit_select_item.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/tag_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';

class TagSelectField extends StatefulWidget {
  TagSelectField({super.key, required this.billType});
  BillType billType;

  @override
  State<TagSelectField> createState() => _TagSelectFieldState();
}

class _TagSelectFieldState extends State<TagSelectField> {
  // 已选择的标签ID列表
  List<int> _selectedTagIds = [];
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TagSelectItem>>(
      future: tagFutureItems(context, widget.billType),
      builder: (context, snapshot) {
        // 处理不同状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                Text('加载标签失败: ${snapshot.error}'),
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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.local_offer_outlined, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text('没有可用的标签'),
              ],
            ),
          );
        }

        // 数据加载成功，构建UI
        final tags = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 已选择的标签
            if (_selectedTagIds.isNotEmpty)
              _buildSelectedTags(tags),
            
            // 标签选择器
            _buildTagSelector(tags),
          ],
        );
      },
    );
  }
  
  // 已选择的标签
  Widget _buildSelectedTags(List<TagSelectItem> allTags) {
    // 从所有标签中找出已选择的标签
    List<TagSelectItem> selectedTags = [];
    
    for (int tagId in _selectedTagIds) {
      // 在所有标签中查找匹配的ID
      for (var tag in allTags) {
        if (tag.id == tagId) {
          selectedTags.add(tag);
          break;
        }
        
        // 检查子标签
        if (tag.children != null) {
          for (var childTag in tag.children!) {
            if (childTag.id == tagId) {
              selectedTags.add(childTag);
              break;
            }
          }
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选择的标签',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag.title),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedTagIds.remove(tag.id);
                  });
                },
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          Divider(),
        ],
      ),
    );
  }
  
  // 标签选择器
  Widget _buildTagSelector(List<TagSelectItem> tags) {
    // 将标签分组显示
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tags.map((tag) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主标签
              _buildTagGroup(tag),
              
              // 子标签
              if (tag.children != null && tag.children!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tag.children!.map((childTag) {
                      return FilterChip(
                        label: Text(childTag.title),
                        selected: _selectedTagIds.contains(childTag.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!_selectedTagIds.contains(childTag.id)) {
                                _selectedTagIds.add(childTag.id);
                              }
                            } else {
                              _selectedTagIds.remove(childTag.id);
                            }
                          });
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: Theme.of(context).colorScheme.secondaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      );
                    }).toList(),
                  ),
                ),
              SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  // 标签组
  Widget _buildTagGroup(TagSelectItem tag) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, size: 16),
            SizedBox(width: 8),
            Text(
              tag.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        FilterChip(
          label: Text(tag.title),
          selected: _selectedTagIds.contains(tag.id),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (!_selectedTagIds.contains(tag.id)) {
                  _selectedTagIds.add(tag.id);
                }
              } else {
                _selectedTagIds.remove(tag.id);
              }
            });
          },
          backgroundColor: Colors.transparent,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

Future<List<TagSelectItem>> tagFutureItems(
    BuildContext context, BillType billType) async {
  TagService tagService = TagService();
  var response = await tagService.getEnableList(
      context.read<BillsRepository>().bookId() ?? 1,
      type: billType.value);
  List<TagSelectItem> tagItems = [];
  if (response.code == 0) {
    var list = response.data as List? ?? [];
    for (final item in list) {
      tagItems.add(TagSelectItem.fromJson(
          Map<String, dynamic>.from(item as Map? ?? {})));
    }
  }
  return tagItems;
}
