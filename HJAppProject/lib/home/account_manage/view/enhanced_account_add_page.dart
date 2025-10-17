import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hjproject/Request/account_request.dart';
import 'package:hjproject/request/group_request.dart';
import 'package:hjproject/Home/setting_page/view/widgets/selection_bottom_sheet.dart';
import 'package:hjproject/Home/account_manage/constants/design_system.dart' as ds;

/// 增强版新增账户页面
/// 基于原有Sheet功能，改为Page形式展现，使用统一设计系统，提升UI/UX体验
class EnhancedAccountAddPage extends StatefulWidget {
  const EnhancedAccountAddPage({
    super.key,
    required this.groupId,
    required this.accountType,
  });

  final int groupId;
  final int accountType;

  @override
  State<EnhancedAccountAddPage> createState() => _EnhancedAccountAddPageState();
}

class _EnhancedAccountAddPageState extends State<EnhancedAccountAddPage>
    with TickerProviderStateMixin {
  final AccountQueryService _service = AccountQueryService();
  
  // 动画控制器
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late TextEditingController _nameCtl;
  late TextEditingController _cardNoCtl;
  late TextEditingController _sortCtl;
  late TextEditingController _balanceCtl;
  late TextEditingController _remarkCtl;

  // 六个状态（默认选中/启用）
  bool _include = true;
  bool _canExpense = true;
  bool _canIncome = true;
  bool _enable = true;
  bool _canTransferOut = true;
  bool _canTransferIn = true;

  // 币种模板
  List<CurrencyOption> _currencyOptions = const <CurrencyOption>[];
  String? _selectedCurrencyCode;
  bool _loadingCurrency = true;
  String? _currencyLoadError;

  // 分组名称
  String _groupName = '未知分组';

  bool _busy = false;
  String? _errorText;
  bool _isNavigating = false;

  // 表单验证错误
  String? _nameError;
  String? _currencyError;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _loadData();
  }

  void _initControllers() {
    _nameCtl = TextEditingController();
    _cardNoCtl = TextEditingController();
    _sortCtl = TextEditingController();
    _balanceCtl = TextEditingController();
    _remarkCtl = TextEditingController();
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

  void _loadData() {
    _loadGroupName();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameCtl.dispose();
    _cardNoCtl.dispose();
    _sortCtl.dispose();
    _balanceCtl.dispose();
    _remarkCtl.dispose();
    super.dispose();
  }

  Future<void> _loadGroupName() async {
    try {
      final resp = await GroupService().getByGroupId(widget.groupId);
      if (resp.code == 0) {
        final data = (resp.data as Map?) ?? {};
        final name = (data['groupName'] ?? '').toString();
        if (name.isNotEmpty && mounted) {
          setState(() {
            _groupName = name;
          });
        }
      }
    } catch (_) {
      // 保持默认"未知分组"
    }
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _loadingCurrency = true;
      _currencyLoadError = null;
    });
    try {
      final list = await _service.getCurrencyTemplate();
      if (mounted) {
        setState(() {
          _currencyOptions = list;
          _loadingCurrency = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currencyLoadError = e.toString();
          _loadingCurrency = false;
        });
      }
    }
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'CNY':
        return '¥';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currencyCode;
    }
  }

  String _getCurrencyName(String currencyCode) {
    switch (currencyCode) {
      case 'CNY':
        return '人民币';
      case 'USD':
        return '美元';
      case 'EUR':
        return '欧元';
      case 'GBP':
        return '英镑';
      case 'JPY':
        return '日元';
      default:
        return currencyCode;
    }
  }

  List<Map<String, String>> _getAllCurrencies() {
    return [
      {'code': 'CNY', 'name': '人民币'},
      {'code': 'USD', 'name': '美元'},
      {'code': 'EUR', 'name': '欧元'},
      {'code': 'GBP', 'name': '英镑'},
      {'code': 'JPY', 'name': '日元'},
    ];
  }

  // 增强版输入框装饰
  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    bool hasError = false,
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

  Widget _buildReadonlyRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(ds.Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(ds.BorderRadiusValues.sm),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: ds.Spacing.sm),
          Text(
            label,
            style: ds.TextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: ds.Spacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: ds.TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(int t) {
    switch (t) {
      case 1:
        return '活期账户';
      case 2:
        return '信用账户';
      case 3:
        return '资产账户';
      case 4:
        return '贷款账户';
      default:
        return '账户';
    }
  }

  double? _tryDouble(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.trim());
  }

  bool get _valid {
    _errorText = null;
    _nameError = null;
    _currencyError = null;

    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      _nameError = '账户名称不能为空';
      return false;
    }
    if (name.length > 64) {
      _nameError = '账户名称长度不能超过64';
      return false;
    }

    if (_selectedCurrencyCode == null || _selectedCurrencyCode!.trim().isEmpty) {
      _currencyError = '请选择币种';
      return false;
    }

    final sortText = _sortCtl.text.trim();
    if (sortText.isNotEmpty) {
      final n = int.tryParse(sortText);
      if (n == null || n < 0) {
        _errorText = '顺序必须为非负整数';
        return false;
      }
    }

    final balText = _balanceCtl.text.trim();
    if (balText.isNotEmpty && _tryDouble(balText) == null) {
      _errorText = '余额必须为数值';
      return false;
    }

    return true;
  }

  Future<void> _openCurrencySelector() async {
    if (_isNavigating) return;
    _isNavigating = true;
    await Future.delayed(Duration.zero);

    final options = _currencyOptions
        .map((e) => SelectionOption<String>(
              label: e.label,
              value: e.label,
              selected: e.label == _selectedCurrencyCode,
            ))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ds.BorderRadiusValues.xl),
            ),
          ),
          child: SelectionBottomSheet<String>(
            title: '选择币种',
            options: options,
            onSelected: (opt) {
              setState(() {
                _selectedCurrencyCode = opt.value;
                _currencyError = null;
              });
            },
          ),
        );
      },
    );

    _isNavigating = false;
  }

  Future<void> _submit() async {
    if (!_valid) {
      setState(() {});
      return;
    }

    setState(() {
      _busy = true;
    });

    final String? cardNo =
        _cardNoCtl.text.trim().isEmpty ? null : _cardNoCtl.text.trim();
    final int? sort =
        _sortCtl.text.trim().isEmpty ? null : int.tryParse(_sortCtl.text.trim());
    final double? balance = _tryDouble(_balanceCtl.text.trim());
    final String? remark =
        _remarkCtl.text.trim().isEmpty ? null : _remarkCtl.text.trim();

    try {
      final ok = await _service.addAccount(
        groupId: widget.groupId,
        accountName: _nameCtl.text.trim(),
        accountType: widget.accountType,
        currencyCode: _selectedCurrencyCode!.trim(),
        cardNo: cardNo,
        sort: sort,
        balance: balance,
        remark: remark,
        canExpense: _canExpense,
        canIncome: _canIncome,
        canTransferOut: _canTransferOut,
        canTransferIn: _canTransferIn,
        include: _include,
        enable: _enable,
      );
      if (ok && mounted) {
        // 添加成功动画
        await _fadeController.reverse();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ds.BorderRadiusValues.sm),
            ),
          ),
        );
      }
    }
  }

  // 修复适用范围选择的对齐问题 - 使用固定宽度的FilterChip
  Widget _buildFixedWidthChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 120, // 固定宽度，解决对齐问题
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check : icon,
              size: 16,
              color: selected 
                  ? theme.colorScheme.onPrimary 
                  : theme.colorScheme.onSurface,
            ),
            SizedBox(width: ds.Spacing.xs),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: onChanged,
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ds.BorderRadiusValues.pill),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: ds.Spacing.sm,
      runSpacing: ds.Spacing.sm,
      children: [
        _buildFixedWidthChip(
          label: '计入资产',
          selected: _include,
          onChanged: (v) => setState(() => _include = v),
          icon: Icons.account_balance_wallet,
        ),
        _buildFixedWidthChip(
          label: '支出允许',
          selected: _canExpense,
          onChanged: (v) => setState(() => _canExpense = v),
          icon: Icons.remove_circle_outline,
        ),
        _buildFixedWidthChip(
          label: '收入允许',
          selected: _canIncome,
          onChanged: (v) => setState(() => _canIncome = v),
          icon: Icons.add_circle_outline,
        ),
        _buildFixedWidthChip(
          label: '启用账户',
          selected: _enable,
          onChanged: (v) => setState(() => _enable = v),
          icon: Icons.toggle_on,
        ),
        _buildFixedWidthChip(
          label: '转出允许',
          selected: _canTransferOut,
          onChanged: (v) => setState(() => _canTransferOut = v),
          icon: Icons.call_made,
        ),
        _buildFixedWidthChip(
          label: '转入允许',
          selected: _canTransferIn,
          onChanged: (v) => setState(() => _canTransferIn = v),
          icon: Icons.call_received,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          '新增账户',
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
          if (_busy)
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

              // 账户类型信息卡片
              _buildSectionCard(
                title: '账户类型信息',
                subtitle: '当前分组和账户类型（只读）',
                child: Column(
                  children: [
                    _buildReadonlyRow('分组', _groupName, Icons.group),
                    SizedBox(height: ds.Spacing.sm),
                    _buildReadonlyRow(
                      '账户类型',
                      _typeLabel(widget.accountType),
                      Icons.category,
                    ),
                  ],
                ),
              ),

              // 基本信息卡片
              _buildSectionCard(
                title: '基本信息',
                subtitle: '账户名称必填，其他信息可选',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtl,
                      decoration: _buildInputDecoration(
                        label: '账户名称',
                        hint: '最长64字符',
                        icon: Icons.badge,
                        hasError: _nameError != null,
                      ),
                      maxLength: 64,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    if (_nameError != null) ...[
                      SizedBox(height: ds.Spacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _nameError!,
                          style: ds.TextStyles.caption.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: ds.Spacing.md),
                    
                    // 币种选择
                    InkWell(
                      onTap: _openCurrencySelector,
                      borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
                      child: Container(
                        padding: EdgeInsets.all(ds.Spacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currencyError != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.currency_exchange,
                              color: _currencyError != null
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: ds.Spacing.md),
                            Expanded(
                              child: Text(
                                _selectedCurrencyCode ?? '请选择币种',
                                style: ds.TextStyles.bodyMedium.copyWith(
                                  color: _selectedCurrencyCode == null
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_currencyError != null) ...[
                      SizedBox(height: ds.Spacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _currencyError!,
                          style: ds.TextStyles.caption.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: ds.Spacing.md),
                    
                    TextFormField(
                      controller: _cardNoCtl,
                      decoration: _buildInputDecoration(
                        label: '卡号',
                        hint: '可选',
                        icon: Icons.credit_card,
                      ),
                      maxLength: 32,
                    ),
                    SizedBox(height: ds.Spacing.md),
                    TextFormField(
                      controller: _balanceCtl,
                      decoration: _buildInputDecoration(
                        label: '余额',
                        hint: '可留空',
                        icon: Icons.account_balance,
                        hasError: _errorText?.contains('余额') == true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))
                      ],
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),

              // 使用范围与状态卡片
              _buildSectionCard(
                title: '使用范围与状态',
                subtitle: '设置账户的使用权限和状态',
                child: _buildStatusChips(),
              ),

              // 顺序与备注卡片
              _buildSectionCard(
                title: '顺序与备注',
                subtitle: '顺序为数值（可空），备注可多行',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _sortCtl,
                      decoration: _buildInputDecoration(
                        label: '顺序',
                        hint: '非负整数，可留空',
                        icon: Icons.sort,
                        hasError: _errorText?.contains('顺序') == true,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      maxLength: 9,
                    ),
                    SizedBox(height: ds.Spacing.md),
                    TextFormField(
                      controller: _remarkCtl,
                      maxLines: 4,
                      decoration: _buildInputDecoration(
                        label: '备注',
                        hint: '可留空',
                        icon: Icons.notes,
                      ),
                    ),
                  ],
                ),
              ),

              // 错误提示
              if (_errorText != null)
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(width: ds.Spacing.sm),
                      Expanded(
                        child: Text(
                          _errorText!,
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
                onPressed: _busy ? null : () => Navigator.pop(context),
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
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ds.Spacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
                  ),
                ),
                icon: _busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  '新增',
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

  Widget _buildCurrencySelector() {
    final theme = Theme.of(context);
    
    if (_loadingCurrency) {
      return Container(
        padding: EdgeInsets.all(ds.Spacing.md),
        child: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: ds.Spacing.md),
            Text(
              '正在加载币种模板...',
              style: ds.TextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_currencyLoadError != null) {
      return Container(
        padding: EdgeInsets.all(ds.Spacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(ds.BorderRadiusValues.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            SizedBox(width: ds.Spacing.sm),
            Expanded(
              child: Text(
                _currencyLoadError!,
                style: ds.TextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadCurrencies,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _openCurrencySelector,
      borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
      child: Container(
        padding: EdgeInsets.all(ds.Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: _currencyError != null
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(ds.BorderRadiusValues.md),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Icon(
              Icons.currency_exchange,
              color: _currencyError != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: ds.Spacing.md),
            Expanded(
              child: Text(
                _selectedCurrencyCode ?? '请选择币种',
                style: ds.TextStyles.bodyMedium.copyWith(
                  color: _selectedCurrencyCode == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}