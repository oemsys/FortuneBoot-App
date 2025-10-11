import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/util/dio_client.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({Key? key}) : super(key: key);

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  static const int expenseType = 1;
  static const int incomeType = 2;

  int _categoryType = expenseType;
  int _currentPage = 1;
  int _total = 0;
  int _lastPageSize = 0;
  bool _loading = true;
  String? _error;
  List<CategoryNode> _roots = [];
  final Set<int> _expandedNodeIds = {};
 
  final CategoryPageService _service = CategoryPageService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bookId = context.read<BillsRepository>().bookId() ?? 1;
      final data = await _service.fetch(
        bookId: bookId,
        categoryType: _categoryType,
        pageNum: _currentPage,
      );
      setState(() {
        _total = data.total;
        _roots = data.rows;
        _lastPageSize = data.rows.length;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _switchType(int type) {
    if (_categoryType == type) return;
    setState(() {
      _categoryType = type;
      _currentPage = 1;
    });
    _load();
  }

  bool get _hasPrev => _currentPage > 1;

  bool get _hasNext {
    if (_lastPageSize <= 0) return false;
    return _currentPage * _lastPageSize < _total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
      ),
      body: Column(
        children: [
          _buildTopSwitcher(context),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _currentPage = 1;
                await _load();
              },
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSwitcher(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(8),
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
      child: Row(
        children: [
          Expanded(child: _typeButton(expenseType, '支出分类')),
          const SizedBox(width: 8),
          Expanded(child: _typeButton(incomeType, '收入分类')),
        ],
      ),
    );
  }

  Widget _typeButton(int type, String label) {
    final selected = _categoryType == type;
    final color = Theme.of(context).primaryColor;
    return InkWell(
      onTap: () => _switchType(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_roots.isEmpty) {
      return ListView(
        children: [
          _buildSummaryBar(),
          const SizedBox(height: 80),
          const Center(child: Text('暂无分类')),
          const SizedBox(height: 16),
          _buildPager(),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildSummaryBar(),
        ..._roots.map((n) => _buildNode(n, 0)),
        const SizedBox(height: 8),
        _buildPager(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(_error ?? '加载失败', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final typeText = _categoryType == expenseType ? '支出' : '收入';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _categoryType == expenseType
                      ? Icons.remove_circle
                      : Icons.add_circle,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$typeText分类 共$_total项',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text('第 $_currentPage 页', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildParentCard(CategoryNode node) {
    final childCount = node.children.length;
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
      child: ExpansionTile(
        leading: _buildLeading(node.children.isNotEmpty),
        title: Text(
          node.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            if (node.remark != null && node.remark!.isNotEmpty)
              Flexible(
                child: Text(
                  node.remark!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            if (childCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$childCount 子类',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
        children: node.children.isEmpty
            ? [
                const ListTile(
                    title: Text('无子分类', style: TextStyle(color: Colors.grey)))
              ]
            : node.children.map((c) => _buildChildTile(c)).toList(),
      ),
    );
  }

  Widget _buildChildTile(CategoryNode node) {
    return ListTile(
      leading: _buildLeading(node.children.isNotEmpty),
      title: Row(
        children: [
          Expanded(
            child: Text(
              node.categoryName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
      subtitle: (node.remark != null && node.remark!.isNotEmpty)
          ? Text(node.remark!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
    );
  }

  Widget _buildLeading(bool hasChildren) {
    return Icon(
      hasChildren ? Icons.label : Icons.label_outline,
      size: 16,
      color: Theme.of(context).colorScheme.secondary,
    );
  }

// 右侧对齐：x个子类 | 三点菜单 | 展开箭头
  Widget _buildTrailing(CategoryNode node, bool hasChildren, int childCount) {
    // 固定第一列宽度以实现对齐
    const double countWidth = 88;
    final Widget countChip = hasChildren
        ? SizedBox(
            width: countWidth,
            child: Container(
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
            ),
          )
        : const SizedBox(width: countWidth);

    final Widget menu = PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 1) {
          _confirmMoveToRecycle(node);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('移入回收站'),
            ],
          ),
        ),
      ],
    );

    final Widget arrow = hasChildren
        ? Icon(
            _expandedNodeIds.contains(node.categoryId)
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
          )
        : Opacity(
            opacity: 0.0,
            child: const Icon(Icons.keyboard_arrow_down),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        countChip,
        const SizedBox(width: 8),
        menu,
        const SizedBox(width: 8),
        arrow,
      ],
    );
  }

  // 递归渲染任意层级的分类节点
  Widget _buildNode(CategoryNode node, int depth) {
    final bool hasChildren = node.children.isNotEmpty;
    final int childCount = node.children.length;

    final subtitleRow = (node.remark != null && node.remark!.isNotEmpty)
        ? Row(
            children: [
              Flexible(
                child: Text(
                  node.remark!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    final Widget tile = hasChildren
        ? ExpansionTile(
            leading: _buildLeading(true),
            title: Text(
              node.categoryName,
              style: TextStyle(
                fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // x个子类徽标（左侧）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$childCount 子类',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 8),
                // 三点菜单：移入回收站（中间）
                PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 1) {
                      _confirmMoveToRecycle(node);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('移入回收站'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // 展开子类箭头（最右侧）
                Icon(
                  _expandedNodeIds.contains(node.categoryId)
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedNodeIds.add(node.categoryId);
                } else {
                  _expandedNodeIds.remove(node.categoryId);
                }
              });
            },
            subtitle: subtitleRow,
            children:
                node.children.map((c) => _buildNode(c, depth + 1)).toList(),
          )
        : ListTile(
            leading: _buildLeading(false),
            title: Text(
              node.categoryName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 无子类不显示“x个子类”和展开箭头，仅保留三点菜单
                // 统一对齐：使用公共 trailing 构建方法
                _buildTrailing(node, false, 0),
              ],
            ),
            subtitle: (node.remark != null && node.remark!.isNotEmpty)
                ? Text(node.remark!,
                    maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
          );

    if (depth == 0) {
      // 顶层节点使用卡片样式
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
    } else {
      // 子层级添加缩进即可
      return Padding(
        padding: EdgeInsets.only(left: 12.0 * depth),
        child: tile,
      );
    }
  }

  Future<void> _confirmMoveToRecycle(CategoryNode node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('移入回收站'),
          content: Text('将分类“${node.categoryName}”移入回收站？其子分类也将一并处理。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _moveToRecycle(node);
    }
  }

  Future<void> _moveToRecycle(CategoryNode node) async {
    try {
      setState(() {
        _loading = true;
      });
      final bookId = context.read<BillsRepository>().bookId() ?? 1;
      await _service.moveToRecycleBin(
        bookId: bookId,
        categoryId: node.categoryId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已移入回收站')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: ${e.toString()}')),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildPager() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _hasPrev
                ? () {
                    setState(() => _currentPage -= 1);
                    _load();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('上一页'),
          ),
          Expanded(
            child: Center(
              child: Text(
                '共 $_total 条',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _hasNext
                ? () {
                    setState(() => _currentPage += 1);
                    _load();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('下一页'),
          ),
        ],
      ),
    );
  }
}

class CategoryPageService {
  final Dio _dio = DioClient().dio;

  Future<CategoryPageData> fetch({
    required int bookId,
    required int categoryType,
    required int pageNum,
  }) async {
    final response = await _dio.get(
      '/fortune/category/getPage',
      queryParameters: {
        'bookId': bookId,
        'recycleBin': false,
        'categoryType': categoryType,
        'pageNum': pageNum,
      },
    );
    if (response.statusCode == 200) {
      final data = response.data;
      final code = data['code'] as int? ?? -1;
      if (code == 0) {
        final d = data['data'] as Map<String, dynamic>? ?? {};
        return CategoryPageData.fromJson(d);
      } else {
        final msg = data['msg']?.toString() ?? '服务返回错误';
        throw Exception(msg);
      }
    } else {
      throw Exception('网络错误: ${response.statusCode}');
    }
  }

  Future<void> moveToRecycleBin({
    required int bookId,
    required int categoryId,
  }) async {
    final response = await _dio.patch(
      '/fortune/category/$bookId/$categoryId/moveToRecycleBin',
    );
    if (response.statusCode == 200) {
      final data = response.data;
      final code = data['code'] as int? ?? -1;
      if (code == 0) {
        return;
      } else {
        final msg = data['msg']?.toString() ?? '操作失败';
        throw Exception(msg);
      }
    } else {
      throw Exception('网络错误: ${response.statusCode}');
    }
  }
}

class CategoryPageData {
  final int total;
  final List<CategoryNode> rows;

  CategoryPageData({required this.total, required this.rows});

  factory CategoryPageData.fromJson(Map<String, dynamic> json) {
    final total = json['total'] as int? ?? 0;
    final rowsList = (json['rows'] as List? ?? [])
        .map((e) => CategoryNode.fromJson(e as Map<String, dynamic>))
        .toList();
    return CategoryPageData(total: total, rows: rowsList);
  }
}

class CategoryNode {
  final int categoryId;
  final String categoryName;
  final int categoryType;
  final int bookId;
  final int parentId;
  final int sort;
  final String? remark;
  final bool enable;
  final bool recycleBin;
  final List<CategoryNode> children;

  CategoryNode({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.bookId,
    required this.parentId,
    required this.sort,
    required this.remark,
    required this.enable,
    required this.recycleBin,
    required this.children,
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    return CategoryNode(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      categoryType: (json['categoryType'] as num?)?.toInt() ?? 1,
      bookId: (json['bookId'] as num?)?.toInt() ?? 0,
      parentId: (json['parentId'] as num?)?.toInt() ?? -1,
      sort: (json['sort'] as num?)?.toInt() ?? 0,
      remark: json['remark']?.toString(),
      enable: json['enable'] as bool? ?? true,
      recycleBin: json['recycleBin'] as bool? ?? false,
      children: (json['children'] as List? ?? [])
          .map((e) => CategoryNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
