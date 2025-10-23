import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/home/payee_manage/data/payee_service.dart';
import 'package:hjproject/home/payee_manage/model/payee.dart';
import 'package:hjproject/home/payee_manage/view/enhanced_payee_add_page.dart';
import 'package:hjproject/home/payee_manage/view/enhanced_payee_edit_page.dart';
import 'package:hjproject/home/payee_manage/view/widgets/enhanced_payee_move_to_recycle_dialog.dart';

// 导入增强版组件
import 'package:hjproject/home/payee_manage/constants/design_system.dart' as ds;
import 'package:hjproject/home/payee_manage/view/widgets/enhanced_payee_card.dart';
import 'package:hjproject/home/payee_manage/view/widgets/enhanced_payee_empty_state.dart';
import 'package:hjproject/home/payee_manage/view/widgets/enhanced_payee_loading_state.dart';
import 'package:hjproject/home/payee_manage/view/widgets/enhanced_payee_type_selector.dart';
import 'package:hjproject/Home/tag_manage/view/widgets/tag_pager.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_summary_bar.dart';

/// 增强版交易对象管理页面
/// 采用响应式设计和现代化UI组件
class PayeeManagePage extends StatefulWidget {
  const PayeeManagePage({Key? key}) : super(key: key);

  @override
  State<PayeeManagePage> createState() => _PayeeManagePageState();
}

class _PayeeManagePageState extends State<PayeeManagePage>
    with TickerProviderStateMixin {
  final PayeeService _service = PayeeService();

  bool _loading = true;
  String? _error;
  List<Payee> _rows = const <Payee>[];
  int _total = 0;

  // 分页状态
  int _pageNum = 1;
  final int _pageSize = 20;

  // 类型筛选状态
  PayeeFilterType _selectedFilter = PayeeFilterType.all;

  // 动画控制器
  late AnimationController _listAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _listFadeAnimation;
  late Animation<Offset> _listSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // 导航去抖，避免快速连点导致 navigator 锁冲突
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _load();
  }

  void _initAnimations() {
    // 列表动画控制器
    _listAnimationController = AnimationController(
      duration: ds.Durations.normal,
      vsync: this,
    );

    // FAB动画控制器
    _fabAnimationController = AnimationController(
      duration: ds.Durations.fast,
      vsync: this,
    );

    // 列表淡入动画
    _listFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: ds.AnimationCurves.easeOut,
    ));

    // 列表滑入动画
    _listSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: ds.AnimationCurves.easeOut,
    ));

    // FAB缩放动画
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: ds.AnimationCurves.bounce,
    ));

    // 启动FAB动画
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 完全复用"分类管理"中的账本ID获取方式
      final bookId = context.read<BillsRepository>().bookId() ?? 1;
      final data = await _service.fetch(
        bookId: bookId,
        pageNum: _pageNum,
        pageSize: _pageSize,
        filterType: _selectedFilter, // 添加筛选参数
      );
      setState(() {
        _rows = data.rows;
        _total = data.total;
        _error = null;
      });
      
      // 触发列表动画
      if (_rows.isNotEmpty) {
        _listAnimationController.reset();
        _listAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _goPrev() {
    if (_pageNum > 1) {
      setState(() {
        _pageNum -= 1;
      });
      _load();
    }
  }

  void _goNext() {
    if (_pageNum * _pageSize < _total) {
      setState(() {
        _pageNum += 1;
      });
      _load();
    }
  }

// 新增交易对象入口 - 改为Page导航
  Future<void> _onAddPayeePressed() async {
    if (_isNavigating) return;
    _isNavigating = true;
    await Future.delayed(Duration.zero);

    final bool? ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const EnhancedPayeeAddPage(),
      ),
    );

    _isNavigating = false;

    if (ok == true) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('新增成功'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
      await _load(); // 刷新当前页
    }
  }

  Future<void> _onMoveToRecyclePressed(Payee item) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => EnhancedPayeeMoveToRecycleDialog(
        payee: item,
        onConfirm: () async {
          final bookId = context.read<BillsRepository>().bookId() ?? item.bookId;
          await _service.moveToRecycleBin(bookId: bookId, payeeId: item.payeeId);
        },
      ),
    );
    
    if (ok == true) {
      setState(() {
        _total = (_total > 0) ? _total - 1 : 0;
      });

      final int startIndex = (_pageNum - 1) * _pageSize;
      if (_rows.isEmpty && _pageNum > 1 && startIndex >= _total) {
        setState(() {
          _pageNum -= 1;
        });
      }

      // 刷新当前页（同步顶部摘要/统计）
      _load();
    }
  }

  Future<void> _onEditPayee(Payee item) async {
    if (_isNavigating) return;
    _isNavigating = true;

    final bookId = context.read<BillsRepository>().bookId() ?? item.bookId;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedPayeeEditPage(payee: item, bookId: bookId),
      ),
    );

    _isNavigating = false;

    if (result == true) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('编辑成功'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
      await _load(); // 刷新当前页
    }
  }

  /// 处理筛选类型变更
  void _onFilterChanged(PayeeFilterType filter) {
    setState(() {
      _selectedFilter = filter;
      _pageNum = 1; // 重置到第一页
    });
    _load(); // 重新加载数据
  }

  /// 获取网格子项的宽高比
  double _getGridAspectRatio(BuildContext context, int crossAxisCount) {
    if (context.isMobile) {
      return 1.3; // 移动端稍微高一些
    } else if (context.isTablet) {
      return crossAxisCount == 2 ? 1.2 : 1.1; // 平板根据列数调整
    } else {
      return crossAxisCount >= 4 ? 1.0 : 1.1; // 桌面端更紧凑
    }
  }

  /// 构建头部区域，包含类型选择器和统计信息
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 类型选择器 - 响应式布局
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.isMobile ? ds.Spacing.md : ds.Spacing.lg,
              vertical: ds.Spacing.sm,
            ),
            child: EnhancedPayeeTypeSelector(
              selectedType: _selectedFilter,
              onTypeChanged: _onFilterChanged,
            ),
          ),
          SizedBox(height: ds.Spacing.xs),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '交易对象',
          style: ds.PayeeTextStyles.pageTitle,
        ),
        actions: [
          ScaleTransition(
            scale: _fabScaleAnimation,
            child: IconButton(
              tooltip: '新增交易对象',
              icon: const Icon(Icons.add),
              onPressed: _onAddPayeePressed,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 添加类型选择器和统计信息区域
          _buildHeaderSection(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildEnhancedBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBody(BuildContext context) {
    // 使用增强版组件的三态切换
    if (_loading) {
      return const EnhancedPayeeLoadingState(
        message: '正在加载交易对象数据...',
      );
    }
    
    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_rows.isEmpty) {
      return EnhancedPayeeEmptyState(
        onAddPayee: _onAddPayeePressed,
      );
    }

    return _buildPayeeList(context);
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: ds.PayeeDesignSystemExtension(context).responsiveHorizontalPadding,
      children: [
        SizedBox(height: ds.Spacing.xxxl),
        Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 48,
        ),
        SizedBox(height: ds.Spacing.md),
        Center(
          child: Text(
            _error ?? '加载失败',
            style: ds.PayeeTextStyles.emptyStateDescription.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: ds.Spacing.lg),
        Center(
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: ds.Spacing.lg,
                vertical: ds.Spacing.md,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayeeList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 响应式网格布局
        final crossAxisCount = context.gridColumns;
        
        if (crossAxisCount == 1) {
          // 移动端：列表布局
          return FadeTransition(
            opacity: _listFadeAnimation,
            child: SlideTransition(
              position: _listSlideAnimation,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: ds.PayeeDesignSystemExtension(context).responsiveHorizontalPadding,
                itemCount: _rows.length + 3,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: ds.Spacing.md,
                        bottom: ds.Spacing.sm,
                      ),
                      child: CategorySummaryBar(
                        typeText: '交易对象',
                        total: _total,
                        currentPage: _pageNum,
                      ),
                    );
                  }
                  
                  if (index == _rows.length + 1) {
                    return _buildPaginationSection(context);
                  }
                  
                  if (index == _rows.length + 2) {
                    return SizedBox(height: ds.Spacing.md);
                  }
                  
                  final payee = _rows[index - 1];
                  return AnimatedBuilder(
                    animation: _listAnimationController,
                    builder: (context, child) {
                      final animationValue = Curves.easeOut.transform(
                        (_listAnimationController.value * _rows.length - (index - 1)).clamp(0.0, 1.0),
                      );
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - animationValue)),
                        child: Opacity(
                          opacity: animationValue,
                          child: EnhancedPayeeCard(
                            payee: payee,
                            onTap: () => _onEditPayee(payee),
                            onEdit: () => _onEditPayee(payee),
                            onMoveToRecycle: () => _onMoveToRecyclePressed(payee),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        } else {
          // 平板/桌面端：网格布局
          return FadeTransition(
            opacity: _listFadeAnimation,
            child: SlideTransition(
              position: _listSlideAnimation,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: ds.PayeeDesignSystemExtension(context).responsiveHorizontalPadding,
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: ds.Spacing.md,
                          bottom: ds.Spacing.sm,
                        ),
                        child: CategorySummaryBar(
                          typeText: '交易对象',
                          total: _total,
                          currentPage: _pageNum,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: ds.PayeeDesignSystemExtension(context).responsiveHorizontalPadding,
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: _getGridAspectRatio(context, crossAxisCount),
                        crossAxisSpacing: context.isMobile ? ds.Spacing.sm : ds.Spacing.md,
                        mainAxisSpacing: context.isMobile ? ds.Spacing.sm : ds.Spacing.md,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final payee = _rows[index];
                          return AnimatedBuilder(
                            animation: _listAnimationController,
                            builder: (context, child) {
                              final animationValue = Curves.easeOut.transform(
                                (_listAnimationController.value * _rows.length - index).clamp(0.0, 1.0),
                              );
                              return Transform.scale(
                                scale: 0.8 + (0.2 * animationValue),
                                child: Opacity(
                                  opacity: animationValue,
                                  child: EnhancedPayeeCard(
                                    payee: payee,
                                    onTap: () => _onEditPayee(payee),
                                    onEdit: () => _onEditPayee(payee),
                                    onMoveToRecycle: () => _onMoveToRecyclePressed(payee),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: _rows.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildPaginationSection(context),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: ds.Spacing.md),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPaginationSection(BuildContext context) {
    if (_total <= _pageSize) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ds.Spacing.md,
        vertical: ds.Spacing.md,
      ),
      child: TagPager(
        total: _total,
        hasPrev: _pageNum > 1,
        hasNext: _pageNum * _pageSize < _total,
        onPrev: _goPrev,
        onNext: _goNext,
      ),
    );
  }
}
