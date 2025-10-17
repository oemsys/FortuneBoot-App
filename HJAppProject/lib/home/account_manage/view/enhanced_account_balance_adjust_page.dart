import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hjproject/Home/account_manage/models/fortune_account.dart';
import 'package:hjproject/Request/account_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/request/book_request.dart';
import 'package:hjproject/Home/setting_page/view/widgets/selection_bottom_sheet.dart';
import 'package:hjproject/Home/account_manage/constants/design_system.dart' as ds;

/// 增强版余额调整页面
/// 基于原有Sheet功能，改为Page形式展现，使用统一设计系统，提升UI/UX体验
class EnhancedAccountBalanceAdjustPage extends StatefulWidget {
  const EnhancedAccountBalanceAdjustPage({
    super.key,
    required this.account,
  });

  final FortuneAccount account;

  @override
  State<EnhancedAccountBalanceAdjustPage> createState() => _EnhancedAccountBalanceAdjustPageState();
}

class _EnhancedAccountBalanceAdjustPageState extends State<EnhancedAccountBalanceAdjustPage>
    with TickerProviderStateMixin {
  final AccountQueryService _service = AccountQueryService();

  // 动画控制器
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _balanceCtl = TextEditingController();
  final TextEditingController _titleCtl = TextEditingController();
  final TextEditingController _remarkCtl = TextEditingController();

  DateTime _tradeTime = DateTime.now();
  int? _bookId;
  String? _bookName;
  Map<int, String> _bookMap = {};
  bool _isNavigating = false;

  bool _submitting = false;

  String? _balanceError;
  String? _tradeTimeError;
  String? _bookError;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: ds.AnimationDurations.fast,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: ds.AnimationCurves.easeOut,
    ));

    // 启动动画
    _fadeController.forward();
  }

  void _initData() {
    // 默认值：余额填入当前余额，tradeTime 为当前时间；bookId 来自当前账本
    final repo = context.read<BillsRepository>();
    _bookId = repo.bookId() ?? 1;
    _bookName = null; // 延迟拉取名称，避免阻塞
    
    // 显示货币符号，仅做前缀展示（不参与校验）
    if (widget.account.balance != null) {
      _balanceCtl.text = _formatNumber(widget.account.balance);
    }
    
    _loadBookList();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _balanceCtl.dispose();
    _titleCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    final fmt = NumberFormat('#,##0.##');
    return fmt.format(value);
  }

  double? _parseNumber(String text) {
    if (text.trim().isEmpty) return null;
    final cleanText = text.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(cleanText);
  }

  Future<void> _loadBookList() async {
    try {
      final repo = context.read<BillsRepository>();
      final groupId = repo.groupId() ?? 1;
      final bookService = BookService();
      final response = await bookService.getEnableList(groupId);
      if (response.code == 0) {
        final list = (response.data as List? ?? []);
        final map = <int, String>{};
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = (m['bookId'] as num?)?.toInt() ?? 0;
          final name = (m['bookName'] ?? '').toString();
          final enable = (m['enable'] is bool) ? (m['enable'] as bool) : true;
          if (enable) {
            map[id] = name.isEmpty ? '账本$id' : name;
          }
        }
        setState(() {
          _bookMap = map;
          _bookName = map[_bookId ?? 0] ?? '未知账本';
        });
      } else {
        setState(() {
          _bookName = '未知账本';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookName = '未知账本';
        });
      }
    }
  }

  // 增强版输入框装饰
  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    bool hasError = false,
    Widget? prefix,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      labelText: label,
      labelStyle: ds.TextStyles.inputLabel,
      hintStyle: ds.TextStyles.inputHint,
      prefixIcon: Icon(
        icon,
        color: hasError 
            ? theme.colorScheme.error 
            : theme.colorScheme.onSurfaceVariant,
      ),
      prefix: prefix,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: hasError 
              ? theme.colorScheme.error 
              : theme.colorScheme.outline,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: hasError 
              ? theme.colorScheme.error 
              : theme.colorScheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: EdgeInsets.symmetric(
        horizontal: ds.Spacing.md,
        vertical: ds.Spacing.md,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ds.Spacing.md,
        vertical: ds.Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(ds.Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, subtitle),
            SizedBox(height: ds.Spacing.md),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ds.TextStyles.sectionTitle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: ds.Spacing.xs),
          Text(
            subtitle,
            style: ds.TextStyles.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentBalanceCard() {
    final theme = Theme.of(context);
    final currentBalance = widget.account.balance ?? 0.0;
    
    return _buildSectionCard(
      title: '当前余额',
      subtitle: '账户当前的余额信息',
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: ds.Spacing.md),
          Expanded(
            child: Text(
              _formatNumber(currentBalance),
              style: ds.TextStyles.balanceAmount.copyWith(
                color: currentBalance >= 0 
                    ? ds.FinanceColors.income 
                    : ds.FinanceColors.expense,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ds.Spacing.sm,
              vertical: ds.Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(ds.BorderRadiusValues.pill),
            ),
            child: Text(
              widget.account.currencyCode ?? 'CNY',
              style: ds.TextStyles.caption.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: ds.FontWeights.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDifference() {
    final theme = Theme.of(context);
    final currentBalance = widget.account.balance ?? 0.0;
    final newBalance = _parseNumber(_balanceCtl.text) ?? 0.0;
    final difference = newBalance - currentBalance;
    
    if (difference == 0) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: ds.Spacing.md),
      padding: EdgeInsets.all(ds.Spacing.md),
      decoration: BoxDecoration(
        color: difference > 0 
            ? ds.FinanceColors.incomeLight
            : ds.FinanceColors.expenseLight,
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.sm),
      ),
      child: Row(
        children: [
          Icon(
            difference > 0 ? Icons.trending_up : Icons.trending_down,
            color: difference > 0 
                ? ds.FinanceColors.income 
                : ds.FinanceColors.expense,
            size: 16,
          ),
          SizedBox(width: ds.Spacing.sm),
          Text(
            difference > 0 ? '增加' : '减少',
            style: ds.TextStyles.caption.copyWith(
              color: difference > 0 
                  ? ds.FinanceColors.income 
                  : ds.FinanceColors.expense,
              fontWeight: ds.FontWeights.medium,
            ),
          ),
          SizedBox(width: ds.Spacing.sm),
          Text(
            _formatNumber(difference.abs()),
            style: ds.TextStyles.bodyMedium.copyWith(
              color: difference > 0 
                  ? ds.FinanceColors.income 
                  : ds.FinanceColors.expense,
              fontWeight: ds.FontWeights.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: ds.TextStyles.inputLabel.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: ds.Spacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
          child: Container(
            padding: EdgeInsets.all(ds.Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
              border: Border.all(
                color: errorText != null 
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: ds.Spacing.sm),
                Expanded(
                  child: Text(
                    formatter.format(dateTime),
                    style: ds.TextStyles.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: ds.Spacing.xs),
          Text(
            errorText,
            style: ds.TextStyles.caption.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookField({
    required String label,
    required String bookName,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: ds.TextStyles.inputLabel.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: ds.Spacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
          child: Container(
            padding: EdgeInsets.all(ds.Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
              border: Border.all(
                color: errorText != null 
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: ds.Spacing.sm),
                Expanded(
                  child: Text(
                    bookName,
                    style: ds.TextStyles.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: ds.Spacing.xs),
          Text(
            errorText,
            style: ds.TextStyles.caption.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tradeTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_tradeTime),
      );
      
      if (time != null && mounted) {
        setState(() {
          _tradeTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _tradeTimeError = null;
        });
      }
    }
  }

  Future<void> _selectBook(BuildContext context) async {
    // 去抖，避免一次点击触发多次导航操作
    if (_isNavigating) return;
    _isNavigating = true;
    await Future.delayed(Duration.zero);

    final groupId = context.read<BillsRepository>().groupId() ?? 1;
    final resp = await BookService().getEnableList(groupId);
    if (!mounted) {
      _isNavigating = false;
      return;
    }
    if (resp.code != 0) {
      _isNavigating = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.msg ?? '获取账本失败'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    final list = (resp.data as List? ?? []);
    final options = <SelectionOption<Map>>[];
    for (final e in list) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = (m['bookId'] as num?)?.toInt() ?? 0;
      final name = (m['bookName'] ?? '').toString();
      final enable = (m['enable'] is bool) ? (m['enable'] as bool) : true;
      if (!enable) continue;
      options.add(SelectionOption<Map>(
        label: name.isEmpty ? '账本$id' : name,
        value: {'id': id, 'name': name},
        selected: id == _bookId,
      ));
    }
    if (!mounted) {
      _isNavigating = false;
      return;
    }
    final selected = await showModalBottomSheet<SelectionOption<Map>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ds.BorderRadiusValues.lg)),
      ),
      builder: (ctx) => SelectionBottomSheet<Map>(
        title: '选择账本',
        options: options,
        onSelected: (opt) {
          // 仅关闭账本选择层本身
          Navigator.pop(ctx, opt);
        },
      ),
    );
    _isNavigating = false;
    if (selected != null && mounted) {
      setState(() {
        _bookId = (selected.value['id'] as int?) ?? _bookId;
        _bookName = (selected.value['name'] as String?) ?? _bookName;
        if (_bookId != null && (_bookName?.isNotEmpty == true)) {
          _bookMap[_bookId!] = _bookName!;
        }
        _bookError = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    // 清除之前的错误
    setState(() {
      _balanceError = null;
      _tradeTimeError = null;
      _bookError = null;
    });

    // 验证输入
    bool hasError = false;
    
    final newBalance = _parseNumber(_balanceCtl.text);
    if (newBalance == null) {
      setState(() {
        _balanceError = '请输入有效的余额';
      });
      hasError = true;
    }
    
    if (_bookId == null) {
      setState(() {
        _bookError = '请选择账本';
      });
      hasError = true;
    }
    
    if (hasError) return;

    setState(() {
      _submitting = true;
    });

    try {
      final success = await _service.balanceAdjust(
        accountId: widget.account.accountId!,
        balance: newBalance!,
        tradeTime: _tradeTime,
        bookId: _bookId!,
        title: _titleCtl.text.trim().isEmpty ? null : _titleCtl.text.trim(),
        remark: _remarkCtl.text.trim().isEmpty ? null : _remarkCtl.text.trim(),
      );
      
      if (success && mounted) {
        // 成功动画
        await _fadeController.reverse();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balanceError = '调整失败：${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  bool _hasErrors() {
    return _balanceError != null || _tradeTimeError != null || _bookError != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          '余额调整',
          style: ds.TextStyles.pageTitle,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_submitting)
            Container(
              margin: EdgeInsets.only(right: ds.Spacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: ds.Spacing.sm),

              // 账户信息卡片
              _buildSectionCard(
                title: '账户信息',
                subtitle: '${widget.account.accountName} · ${widget.account.currencyCode ?? 'CNY'}',
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ds.Spacing.sm),
                      decoration: BoxDecoration(
                        color: ds.FinanceColors.transferLight,
                        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.sm),
                      ),
                      child: Icon(
                        Icons.account_balance_outlined,
                        color: ds.FinanceColors.transfer,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: ds.Spacing.md),
                    Expanded(
                      child: Text(
                        widget.account.accountName ?? '未知账户',
                        style: ds.TextStyles.bodyMedium.copyWith(
                          fontWeight: ds.FontWeights.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 当前余额卡片
              _buildCurrentBalanceCard(),

              // 调整后余额卡片
              _buildSectionCard(
                title: '调整后余额',
                subtitle: '请输入调整后的新余额',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _balanceCtl,
                      decoration: _buildInputDecoration(
                        label: '新余额',
                        hint: '请输入调整后的余额',
                        icon: Icons.edit,
                        hasError: _balanceError != null,
                        prefix: Text(
                          '${widget.account.currencyCode ?? 'CNY'} ',
                          style: ds.TextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: ds.FontWeights.medium,
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-,]'))
                      ],
                      textAlign: TextAlign.end,
                      onChanged: (value) {
                        setState(() {
                          _balanceError = null;
                        });
                      },
                    ),
                    if (_balanceError != null) ...[
                      SizedBox(height: ds.Spacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _balanceError!,
                          style: ds.TextStyles.caption.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    if (_balanceCtl.text.isNotEmpty) _buildBalanceDifference(),
                  ],
                ),
              ),

              // 交易详情卡片
              _buildSectionCard(
                title: '交易详情',
                subtitle: '设置调整的相关信息',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtl,
                      decoration: _buildInputDecoration(
                        label: '调整标题',
                        hint: '请输入调整原因或标题',
                        icon: Icons.title,
                      ),
                    ),
                    SizedBox(height: ds.Spacing.md),
                    
                    _buildDateTimeField(
                      label: '交易时间',
                      dateTime: _tradeTime,
                      onTap: () => _selectDateTime(context),
                      errorText: _tradeTimeError,
                    ),
                    SizedBox(height: ds.Spacing.md),
                    
                    _buildBookField(
                      label: '所属账本',
                      bookName: _bookName ?? '加载中...',
                      onTap: () => _selectBook(context),
                      errorText: _bookError,
                    ),
                    SizedBox(height: ds.Spacing.md),
                    
                    TextFormField(
                      controller: _remarkCtl,
                      maxLines: 3,
                      decoration: _buildInputDecoration(
                        label: '备注',
                        hint: '请输入备注信息（可选）',
                        icon: Icons.notes,
                      ),
                    ),
                  ],
                ),
              ),

              // 错误提示
              if (_hasErrors())
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: ds.Spacing.md,
                    vertical: ds.Spacing.sm,
                  ),
                  padding: EdgeInsets.all(ds.Spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(ds.BorderRadiusValues.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          SizedBox(width: ds.Spacing.sm),
                          Text(
                            '请修正以下问题：',
                            style: ds.TextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: ds.FontWeights.medium,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds.Spacing.sm),
                      if (_balanceError != null)
                        Padding(
                          padding: EdgeInsets.only(left: ds.Spacing.lg, bottom: ds.Spacing.xs),
                          child: Text(
                            '• $_balanceError',
                            style: ds.TextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      if (_tradeTimeError != null)
                        Padding(
                          padding: EdgeInsets.only(left: ds.Spacing.lg, bottom: ds.Spacing.xs),
                          child: Text(
                            '• $_tradeTimeError',
                            style: ds.TextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      if (_bookError != null)
                        Padding(
                          padding: EdgeInsets.only(left: ds.Spacing.lg, bottom: ds.Spacing.xs),
                          child: Text(
                            '• $_bookError',
                            style: ds.TextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              SizedBox(height: ds.Spacing.xl),
            ],
          ),
        ),
      ),
      
      // 底部操作按钮
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ds.Spacing.lg).copyWith(
          bottom: ds.Spacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ds.Spacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
                  ),
                ),
                child: Text(
                  '取消',
                  style: ds.TextStyles.buttonText,
                ),
              ),
            ),
            SizedBox(width: ds.Spacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _submitting ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ds.Spacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        '确认调整',
                        style: ds.TextStyles.buttonText.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}