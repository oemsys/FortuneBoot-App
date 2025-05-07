import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/bloc/edit_todo_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/edit_select_item.dart';
import 'package:flutter_login_example/Home/edit_todo/view/category_select_field.dart';
import 'package:flutter_login_example/Home/edit_todo/view/tag_select_field.dart';
import 'package:flutter_login_example/Home/edit_todo/viewmodel/edit_field_cell_viewmodel.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/account_request.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/payee_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import 'package:intl/intl.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:todos_repository/todos_repository.dart';

class EditTodoPage extends StatelessWidget {
  const EditTodoPage({super.key});

  static Route<void> route({Todo? initialTodo}) {
    return MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => BlocProvider(
        create: (context) => EditTodoBloc(
          todosRepository: context.read<TodosRepository>(),
          initialTodo: initialTodo,
        ),
        child: const EditTodoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditTodoBloc, EditTodoState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == EditTodoStatus.success,
      listener: (context, state) => Navigator.of(context).pop(),
      child: EditTodoView(),
    );
  }
}

class EditTodoView extends StatefulWidget {
  EditTodoView({super.key, this.billType = BillType.expenditure});

  BillType billType;

  @override
  State<EditTodoView> createState() => _EditTodoViewState();
}

class _EditTodoViewState extends State<EditTodoView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isConfirmed = true;
  bool _isIncluded = true;

  // 选中的账本、账户、分类等
  BookSelectItem? _selectedBook;
  AccountSelectItem? _selectedAccount;
  AccountSelectItem? _selectedToAccount;
  PayeeSelectItem? _selectedPayee;
  final List<int> _selectedTagIds = [];
  final Map<int, double> _categoryAmountPairs = {};

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select((EditTodoBloc bloc) => bloc.state.status);
    final isNewTodo = context.select(
      (EditTodoBloc bloc) => bloc.state.isNewTodo,
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNewTodo ? '记一笔' : '编辑账单',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (status.isLoadingOrSuccess)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CupertinoActivityIndicator(),
            )
          else
            TextButton.icon(
              onPressed: _submitBill,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('保存'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      body: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 账单类型选择器
              _buildBillTypeSelector(),

              // 金额输入区域 - 突出显示
              _buildAmountSection(),

              // 主要信息区域
              Card(
                margin: const EdgeInsets.all(8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 16),
                      _buildAccountSection(),
                    ],
                  ),
                ),
              ),

              // 分类选择区域
              _buildCategorySection(),

              // 附加信息区域
              Card(
                margin: const EdgeInsets.all(8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTagSection(),
                      const SizedBox(height: 16),
                      _buildAdditionalOptionsSection(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 账单类型选择器
  Widget _buildBillTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SegmentedButton<BillType>(
        segments: const [
          ButtonSegment(
            value: BillType.expenditure,
            label: Text('支出'),
            icon: Icon(Icons.arrow_upward),
          ),
          ButtonSegment(
            value: BillType.income,
            label: Text('收入'),
            icon: Icon(Icons.arrow_downward),
          ),
          ButtonSegment(
            value: BillType.transfer,
            label: Text('转账'),
            icon: Icon(Icons.swap_horiz),
          ),
        ],
        selected: {widget.billType},
        onSelectionChanged: (Set<BillType> newSelection) {
          setState(() {
            widget.billType = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primaryContainer;
              }
              return Colors.transparent;
            },
          ),
        ),
      ),
    );
  }

  // 金额输入区域
  Widget _buildAmountSection() {
    final (amountColor, amountIcon) = switch (widget.billType) {
      BillType.expenditure => (
          Colors.red.shade700,
          Icons.remove_circle_outline
        ),
      BillType.income => (Colors.green.shade700, Icons.add_circle_outline),
      BillType.transfer => (Colors.blue.shade700, Icons.swap_horiz),
      _ => (Colors.grey.shade700, Icons.attach_money),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            amountColor.withOpacity(0.1),
            amountColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(amountIcon, size: 28, color: amountColor),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: amountColor.withOpacity(0.5),
                  fontSize: 32,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '¥',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  // 基本信息区域
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 账本选择
        _buildBookSelector(),
        const SizedBox(height: 16),

        // 标题输入
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: '标题',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLength: 50,
        ),
        const SizedBox(height: 8),

        // 日期时间选择
        InkWell(
          onTap: () async {
            final DateTime? dateTime = await showOmniDateTimePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              is24HourMode: true,
              isShowSeconds: false,
              minutesInterval: 1,
              secondsInterval: 1,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              constraints: const BoxConstraints(
                maxWidth: 350,
                maxHeight: 650,
              ),
              transitionBuilder: (context, anim1, anim2, child) {
                return FadeTransition(
                  opacity: anim1.drive(
                    Tween(
                      begin: 0,
                      end: 1,
                    ),
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
              barrierDismissible: true,
            );

            if (dateTime != null) {
              setState(() {
                _selectedDate = dateTime;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Text(
                  '日期时间',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 账本选择器
  Widget _buildBookSelector() {
    return FutureBuilder<List<DropdownItem<BookSelectItem>>>(
      future: () async {
        int groupId = context.read<BillsRepository>().groupId() ?? 1;
        return bookItems(BookService(),
            id: groupId, type: widget.billType.value);
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('加载账本失败');
        }

        final items = snapshot.data!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<BookSelectItem>(
            decoration: const InputDecoration(
              labelText: '账本',
              prefixIcon: Icon(Icons.book),
              border: InputBorder.none,
            ),
            items: items.map((item) {
              return DropdownMenuItem<BookSelectItem>(
                value: item.value,
                child: Text(item.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBook = value;
              });
            },
            isExpanded: true,
          ),
        );
      },
    );
  }

  // 账户区域
  Widget _buildAccountSection() {
    if (widget.billType == BillType.transfer) {
      return _buildTransferAccountSection();
    } else {
      return _buildNormalAccountSection();
    }
  }

  // 普通账户选择（支出/收入）
  Widget _buildNormalAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '账户信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 账户选择
        FutureBuilder<List<DropdownItem<AccountSelectItem>>>(
          future: () async {
            int groupId = context.read<BillsRepository>().groupId() ?? 1;
            return accountItems(AccountService(),
                id: groupId, type: widget.billType.value);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Text('加载账户失败');
            }

            final items = snapshot.data!;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<AccountSelectItem>(
                decoration: const InputDecoration(
                  labelText: '账户',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: InputBorder.none,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<AccountSelectItem>(
                    value: item.value,
                    child: Text(item.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccount = value;
                  });
                },
                isExpanded: true,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // 交易对象选择
        FutureBuilder<List<DropdownItem<PayeeSelectItem>>>(
          future: () async {
            final int bookId = context.read<BillsRepository>().bookId() ?? 1;
            return payeeItems(PayeeService(),
                id: bookId, type: widget.billType.value);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('加载交易对象失败');
            }

            final items = snapshot.data!;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<PayeeSelectItem>(
                decoration: const InputDecoration(
                  labelText: '交易对象',
                  prefixIcon: Icon(Icons.person),
                  border: InputBorder.none,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<PayeeSelectItem>(
                    value: item.value,
                    child: Text(item.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayee = value;
                  });
                },
                isExpanded: true,
              ),
            );
          },
        ),
      ],
    );
  }

  // 转账账户选择
  Widget _buildTransferAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '转账信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 转出账户
        FutureBuilder<List<DropdownItem<AccountSelectItem>>>(
          future: () async {
            final int groupId = context.read<BillsRepository>().groupId() ?? 1;
            return accountItems(AccountService(),
                id: groupId, type: widget.billType.value);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('加载账户失败');
            }

            final items = snapshot.data!;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<AccountSelectItem>(
                decoration: const InputDecoration(
                  labelText: '转出账户',
                  prefixIcon: Icon(Icons.arrow_upward),
                  border: InputBorder.none,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<AccountSelectItem>(
                    value: item.value,
                    child: Text(item.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccount = value;
                  });
                },
                isExpanded: true,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // 转入账户
        FutureBuilder<List<DropdownItem<AccountSelectItem>>>(
          future: () async {
            final int groupId = context.read<BillsRepository>().groupId() ?? 1;
            return accountItems(AccountService(),
                id: groupId, type: widget.billType.value);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('加载账户失败');
            }

            final items = snapshot.data!;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<AccountSelectItem>(
                decoration: const InputDecoration(
                  labelText: '转入账户',
                  prefixIcon: Icon(Icons.arrow_downward),
                  border: InputBorder.none,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<AccountSelectItem>(
                    value: item.value,
                    child: Text(item.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedToAccount = value;
                  });
                },
                isExpanded: true,
              ),
            );
          },
        ),
      ],
    );
  }

  // 分类选择区域
  Widget _buildCategorySection() {
    // 转账类型不需要分类
    if (widget.billType == BillType.transfer) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分类',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 快速选择常用分类
            _buildQuickCategorySelector(),
            const SizedBox(height: 16),

            // 分类选择器
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CategorySelectField(billType: widget.billType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 快速选择常用分类
  Widget _buildQuickCategorySelector() {
    // 这里可以根据用户的使用频率或者预设的常用分类来显示
    List<Map<String, dynamic>> quickCategories = [];

    if (widget.billType == BillType.expenditure) {
      quickCategories = [
        {'name': '餐饮', 'icon': Icons.restaurant},
        {'name': '交通', 'icon': Icons.directions_car},
        {'name': '购物', 'icon': Icons.shopping_bag},
        {'name': '娱乐', 'icon': Icons.movie},
        {'name': '日用', 'icon': Icons.home},
      ];
    } else if (widget.billType == BillType.income) {
      quickCategories = [
        {'name': '工资', 'icon': Icons.work},
        {'name': '奖金', 'icon': Icons.card_giftcard},
        {'name': '理财', 'icon': Icons.account_balance},
        {'name': '报销', 'icon': Icons.receipt},
        {'name': '其他', 'icon': Icons.more_horiz},
      ];
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickCategories.length,
        itemBuilder: (context, index) {
          final category = quickCategories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    // 选择该分类的逻辑
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData?,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category['name'] as String? ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 标签选择区域
  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TagSelectField(billType: widget.billType),
          ),
        ),
      ],
    );
  }

  // 附加选项区域
  Widget _buildAdditionalOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '附加信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 是否确认
        SwitchListTile(
          title: const Text('是否确认'),
          subtitle: const Text('确认后将会扣除对应账户金额'),
          value: _isConfirmed,
          onChanged: (value) {
            setState(() {
              _isConfirmed = value;
            });
          },
          secondary: const Icon(Icons.verified),
          contentPadding: EdgeInsets.zero,
        ),

        // 是否统计
        SwitchListTile(
          title: const Text('是否统计'),
          subtitle: const Text('纳入统计的账单会在报表中显示'),
          value: _isIncluded,
          onChanged: (value) {
            setState(() {
              _isIncluded = value;
            });
          },
          secondary: const Icon(Icons.bar_chart),
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 16),

        // 备注
        TextField(
          controller: _remarkController,
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
          maxLength: 300,
        ),
      ],
    );
  }

  // 提交账单
  void _submitBill() {
    // 验证必填字段
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额')),
      );
      return;
    }

    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择账本')),
      );
      return;
    }

    if (widget.billType != BillType.transfer && _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择账户')),
      );
      return;
    }

    if (widget.billType == BillType.transfer &&
        (_selectedAccount == null || _selectedToAccount == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择转出和转入账户')),
      );
      return;
    }

    // 构建请求参数
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    try {
      // 构建符合接口格式的请求数据
      final Map<String, dynamic> requestData = {
        "data": {
          "bookId": _selectedBook?.id,
          "title": _titleController.text.isNotEmpty
              ? _titleController.text
              : "未命名账单",
          "tradeTime": _selectedDate.toIso8601String(),
          "amount": amount,
          "billType": widget.billType.value,
          "confirm": _isConfirmed,
          "include": _isIncluded,
          "remark": _remarkController.text,
        }
      };

      // 根据账单类型添加不同的字段
      if (widget.billType == BillType.transfer) {
        // 转账类型
        requestData["data"]["accountId"] = _selectedAccount?.id;
        requestData["data"]["toAccountId"] = _selectedToAccount?.id;
      } else {
        // 支出或收入类型
        requestData["data"]["accountId"] = _selectedAccount?.id;
        requestData["data"]["payeeId"] = _selectedPayee?.id;

        // 获取分类金额对
        if (_categoryAmountPairs.isNotEmpty) {
          List<Map<String, dynamic>> categoryAmountPairList = [];
          _categoryAmountPairs.forEach((categoryId, categoryAmount) {
            categoryAmountPairList
                .add({"first": categoryId, "second": categoryAmount});
          });
          requestData["data"]["categoryAmountPair"] = categoryAmountPairList;
        }
      }

      // 添加标签ID列表
      if (_selectedTagIds.isNotEmpty) {
        requestData["data"]["tagIdList"] = _selectedTagIds;
      }

      // 打印请求数据，方便调试
      print('账单提交数据: $requestData');

      // 显示提交中的加载状态
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('正在提交账单...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // 调用API提交账单
      // 这里应该调用实际的API，目前使用Bloc模拟提交
      context.read<EditTodoBloc>().add(const EditTodoSubmitted());
    } catch (e) {
      // 处理错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交账单失败: $e')),
      );
    }
  }
}
