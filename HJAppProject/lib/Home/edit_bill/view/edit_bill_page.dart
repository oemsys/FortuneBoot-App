import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjProject/home/edit_bill/bloc/edit_bill_bloc.dart';
import 'package:hjProject/home/edit_bill/models/edit_select_item.dart';
import 'package:hjProject/home/edit_bill/view/select_field/category_select_field.dart';
import 'package:hjProject/home/edit_bill/view/select_field/tag_select_field.dart';
import 'package:hjProject/home/todos_overview/models/bill_item.dart';
import 'package:hjProject/home/todos_overview/models/bill_item_add.dart';
import 'package:hjProject/generated/l10n.dart';
import 'package:hjProject/repository/repository/bills_repository.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class EditBillPage extends StatelessWidget {
  const EditBillPage({super.key});

  static Route<void> route({BillItemAdd? initialBill}) {
    return MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => BlocProvider(
        create: (context) => EditBillBloc(
          billRepository: context.read<BillsRepository>(),
          initialBill: initialBill,
        )..add(EditBillInitialized(
            BillType.fromValue(initialBill?.data?.billType ?? 1) ??
                BillType.expenditure)),
        child: const EditBillPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<EditBillBloc, EditBillState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == EditBillStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(S.current.todosOverviewErrorSnackbarText),
                    ),
                  );
              }
            },
          ),
          BlocListener<EditBillBloc, EditBillState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == EditBillStatus.closed) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.isNewBill ? '添加成功' : '修改成功'),
                    ),
                  );
                Navigator.of(context).pop();
              }
            },
          ),
          BlocListener<EditBillBloc, EditBillState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == EditBillStatus.submitFailed) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('添加失败'),
                    ),
                  );
              }
            },
          ),
        ],
        child: BlocListener<EditBillBloc, EditBillState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == EditBillStatus.success,
          listener: (context, state) => (),
          child: EditBillView(),
        ));
  }
}

class EditBillView extends StatefulWidget {
  EditBillView({super.key});

  @override
  State<EditBillView> createState() => _EditBillViewState();
}

class _EditBillViewState extends State<EditBillView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  ValueNotifier<bool> _isCategoryExpanded = ValueNotifier(true);
  ValueNotifier<bool> _isTagExpanded = ValueNotifier(true);
  ValueNotifier<bool?> _confirm = ValueNotifier(null);
  ValueNotifier<bool?> _include = ValueNotifier(null);
  ValueNotifier<String?> _tradeTimeStr = ValueNotifier(null);

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select((EditBillBloc bloc) => bloc.state.status);
    final state = context.select((EditBillBloc bloc) => bloc.state);
    if (_confirm.value == null || _include.value == null) {
      _confirm.value = state.editBill.data!.confirm;
      _include.value = state.editBill.data!.include;
    }
    final isNewBill = context.select(
      (EditBillBloc bloc) => bloc.state.isNewBill,
    );

    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: S.current.editTodoSaveButtonTooltip,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        onPressed:
            status.isLoadingOrInit ? null : () => _submitBill(state.editBill),
        child: status.isLoadingOrInit
            ? const CupertinoActivityIndicator()
            : const Icon(Icons.check_rounded),
      ),
      appBar: AppBar(
        title: Text(
          isNewBill ? '记一笔' : '编辑账单',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   if (status.isLoadingOrSuccess)
        //     const Padding(
        //       padding: EdgeInsets.all(16.0),
        //       child: CupertinoActivityIndicator(),
        //     )
        //   else
        //     TextButton.icon(
        //       onPressed: _submitBill,
        //       icon: const Icon(Icons.check_circle_outline),
        //       label: const Text('保存'),
        //       style: TextButton.styleFrom(
        //         foregroundColor: theme.colorScheme.primary,
        //       ),
        //     ),
        // ],
      ),
      body: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 账单类型选择器
              _buildBillTypeSelector(),

              // 金额输入区域 - 突出显示
              // _buildAmountSection(),

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
                    ],
                  ),
                ),
              ),
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

  BillType curBillType() {
    var state = context.watch<EditBillBloc>().state;
    return BillType.fromValue(state.editBill.data?.billType ?? 1) ??
        BillType.expenditure;
  }

  // 账单类型选择器
  Widget _buildBillTypeSelector() {
    var enable =
        context.watch<EditBillBloc>().state.status != EditBillStatus.loading;
    var billType = curBillType();
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
        segments: [
          ButtonSegment(
            enabled: enable,
            value: BillType.expenditure,
            label: Text('支出'),
            icon: Icon(Icons.arrow_upward),
          ),
          ButtonSegment(
            enabled: enable,
            value: BillType.income,
            label: Text('收入'),
            icon: Icon(Icons.arrow_downward),
          ),
          ButtonSegment(
            enabled: enable,
            value: BillType.transfer,
            label: Text('转账'),
            icon: Icon(Icons.swap_horiz),
          ),
        ],
        selected: {billType},
        onSelectionChanged: (Set<BillType> newSelection) {
          context
              .read<EditBillBloc>()
              .add(EditBillTypeChange(newSelection.first));
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
  // Widget _buildAmountSection() {
  //   var billType = curBillType();
  //   final (amountColor, amountIcon) = switch (billType) {
  //     BillType.expenditure => (
  //         Colors.red.shade700,
  //         Icons.remove_circle_outline
  //       ),
  //     BillType.income => (Colors.green.shade700, Icons.add_circle_outline),
  //     BillType.transfer => (Colors.blue.shade700, Icons.swap_horiz),
  //     _ => (Colors.grey.shade700, Icons.attach_money),
  //   };

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           amountColor.withOpacity(0.1),
  //           amountColor.withOpacity(0.05),
  //         ],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(amountIcon, size: 28, color: amountColor),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: TextField(
  //             controller: _amountController,
  //             keyboardType:
  //                 const TextInputType.numberWithOptions(decimal: true),
  //             textAlign: TextAlign.end,
  //             style: TextStyle(
  //               fontSize: 32,
  //               fontWeight: FontWeight.bold,
  //               color: amountColor,
  //             ),
  //             decoration: InputDecoration(
  //               hintText: '0.00',
  //               hintStyle: TextStyle(
  //                 color: amountColor.withOpacity(0.5),
  //                 fontSize: 32,
  //               ),
  //               border: InputBorder.none,
  //               contentPadding: EdgeInsets.zero,
  //             ),
  //             inputFormatters: [
  //               FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Text(
  //           '¥',
  //           style: TextStyle(
  //             fontSize: 24,
  //             fontWeight: FontWeight.bold,
  //             color: amountColor,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // 基本信息区域
  Widget _buildBasicInfoSection() {
    var state = context.watch<EditBillBloc>().state;
    var initDate = state.editBill.data!.tradeDate;
    _titleController.text = state.editBill.data?.title ?? '';
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
        // _buildBookSelector(),
        // const SizedBox(height: 16),

        // 标题输入
        TextField(
          controller: _titleController,
          onChanged: (value) {
            state.editBill.data?.title = value;
          },
          decoration: InputDecoration(
            hintText: '请输入标题',
            labelText: '标题',
            labelStyle: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.title),
            // 统一所有状态下的边框样式
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue), // 聚焦状态边框颜色
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red), // 错误状态边框颜色
              borderRadius: BorderRadius.circular(12),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLength: 50,
        ),
        const SizedBox(height: 8),

        // 日期时间选择
        ValueListenableBuilder(
            valueListenable: _tradeTimeStr,
            builder: (_, value, __) {
              return InkWell(
                onTap: () async {
                  final DateTime? dateTime = await showOmniDateTimePicker(
                    context: context,
                    initialDate: value != null
                        ? DateFormat('yyyy-MM-dd HH:mm').parse(value)
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
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
                    _tradeTimeStr.value =
                        DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
                    state.editBill.data?.tradeTime = _tradeTimeStr.value;
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        state.editBill.data?.tradeTime ??
                            DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(DateTime.now()),
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
              );
            }),
      ],
    );
  }

  // 账户区域
  Widget _buildAccountSection() {
    if (curBillType() == BillType.transfer) {
      return _buildTransferAccountSection();
    } else {
      return _buildNormalAccountSection();
    }
  }

  // 普通账户选择（支出/收入）
  Widget _buildNormalAccountSection() {
    var state = context.watch<EditBillBloc>().state;
    var items = curBillType() == BillType.income
        ? state.incomeAccountList
        : state.expenseAccountList;
    var payeeItems = state.payeeList;
    AccountSelectItem? selectItem;
    for (final item in items) {
      if (item.value.id == state.editBill.data?.accountId) {
        selectItem = item.value;
        break;
      }
    }
    PayeeSelectItem? payeeSelectItem;
    for (final item in payeeItems) {
      if (item.value.id == state.editBill.data?.payeeId) {
        payeeSelectItem = item.value;
        break;
      }
    }
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
        Container(
          padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<AccountSelectItem>(
            key: Key('${curBillType()}_account'),
            value: selectItem,
            decoration: const InputDecoration(
              labelText: '账户',
              prefixIcon: Icon(Icons.account_balance_wallet),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            items: items.map((item) {
              return DropdownMenuItem<AccountSelectItem>(
                value: item.value,
                child: Text(item.label),
              );
            }).toList(),
            onChanged: (value) {
              state.editBill.data?.accountId = value?.id;
            },
            isExpanded: true,
          ),
        ),
        const SizedBox(height: 16),

        // 交易对象选择
        Container(
          padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<PayeeSelectItem>(
            key: Key('${curBillType()}_payee'),
            value: payeeSelectItem,
            decoration: const InputDecoration(
              labelText: '交易对象',
              contentPadding: EdgeInsets.zero,
              prefixIcon: Icon(Icons.person),
              border: InputBorder.none,
            ),
            items: payeeItems.map((item) {
              return DropdownMenuItem<PayeeSelectItem>(
                value: item.value,
                child: Text(item.label),
              );
            }).toList(),
            onChanged: (value) {
              state.editBill.data?.payeeId = value?.id;
            },
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  // 转账账户选择
  Widget _buildTransferAccountSection() {
    var state = context.watch<EditBillBloc>().state;
    if (state.editBill.data?.amount != null) {
      _amountController.text = (state.editBill.data?.amount ?? 0).toString();
    }
    final inItems = state.transferAccountList;
    final outItems = state.transferOutAccountList;
    AccountSelectItem? selectInItem;
    for (final item in outItems) {
      if (item.value.id == state.editBill.data?.accountId) {
        selectInItem = item.value;
        break;
      }
    }
    AccountSelectItem? selectOutItem;
    for (final item in inItems) {
      if (item.value.id == state.editBill.data?.toAccountId) {
        selectOutItem = item.value;
        break;
      }
    }
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
        TextField(
          controller: _amountController,
          onChanged: (value) {
            state.editBill.data?.amount = double.tryParse(value) ?? 0;
          },
          keyboardType: TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,5}')), // 允许数字和最多两位小数
          ],
          decoration: InputDecoration(
            hintText: '请输入金额',
            labelText: '金额',
            labelStyle: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.monetization_on_outlined),
            // 统一所有状态下的边框样式
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue), // 聚焦状态边框颜色
              borderRadius: BorderRadius.circular(12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red), // 错误状态边框颜色
              borderRadius: BorderRadius.circular(12),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLength: 50,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<AccountSelectItem>(
            key: Key('${curBillType()}_transfer'),
            value: selectOutItem,
            decoration: const InputDecoration(
              labelText: '转入账户',
              contentPadding: EdgeInsets.zero,
              prefixIcon: Icon(Icons.arrow_upward),
              border: InputBorder.none,
            ),
            items: inItems.map((item) {
              return DropdownMenuItem<AccountSelectItem>(
                value: item.value,
                child: Text(item.label),
              );
            }).toList(),
            onChanged: (value) {
              state.editBill.data?.toAccountId = value?.id;
            },
            isExpanded: true,
          ),
        ),
        const SizedBox(height: 16),

        // 转入账户
        Container(
          padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<AccountSelectItem>(
            key: Key('${curBillType()}_transfer_in'),
            value: selectInItem,
            decoration: const InputDecoration(
              labelText: '转出账户',
              contentPadding: EdgeInsets.zero,
              prefixIcon: Icon(Icons.arrow_downward),
              border: InputBorder.none,
            ),
            items: outItems.map((item) {
              return DropdownMenuItem<AccountSelectItem>(
                value: item.value,
                child: Text(item.label),
              );
            }).toList(),
            onChanged: (value) {
              state.editBill.data?.accountId = value?.id;
            },
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  // 分类选择区域
  Widget _buildCategorySection() {
    // 转账类型不需要分类
    var billType = curBillType();
    if (billType == BillType.transfer) {
      return const SizedBox.shrink();
    }
    var state = context.watch<EditBillBloc>().state;
    List<Map<String, num>> curCategroy =
        state.editBill.data?.categoryAmountPair ?? [];
    Map<int, double> categoryAmountPair = {};
    curCategroy.forEach((Map<String, num> category) {
      var amount = category["amount"] as num? ?? 0.0;
      var categoryId = category["categoryId"] as num? ?? 0;

      categoryAmountPair[categoryId.toInt()] = amount.toDouble();
    });

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
              '费用',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 快速选择常用分类
            // _buildQuickCategorySelector(),
            const SizedBox(height: 16),

            // 分类选择器
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CategoryTreeWidget(
                    key: Key('${billType}_category'),
                    categoryAmountPairs: categoryAmountPair,
                    categories: state.categoryList,
                    billType: billType,
                    onCategorySelected: (categorys) {
                      List<Map<String, num>> categoryAmountPairList = [];
                      categorys.forEach((categoryId, categoryAmount) {
                        categoryAmountPairList.add({
                          "categoryId": categoryId,
                          "amount": categoryAmount
                        });
                      });
                      state.editBill.data?.categoryAmountPair =
                          categoryAmountPairList;
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 快速选择常用分类
  Widget _buildQuickCategorySelector() {
    BillType billType = curBillType();
    // 这里可以根据用户的使用频率或者预设的常用分类来显示
    List<Map<String, dynamic>> quickCategories = [];

    if (billType == BillType.expenditure) {
      quickCategories = [
        {'name': '餐饮', 'icon': Icons.restaurant},
        {'name': '交通', 'icon': Icons.directions_car},
        {'name': '购物', 'icon': Icons.shopping_bag},
        {'name': '娱乐', 'icon': Icons.movie},
        {'name': '日用', 'icon': Icons.home},
      ];
    } else if (billType == BillType.income) {
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
    var state = context.watch<EditBillBloc>().state;
    return ValueListenableBuilder(
        valueListenable: _isTagExpanded,
        builder: (b, expanded, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                  onTap: () {
                    _isTagExpanded.value = !expanded;
                  },
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '标签',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      expanded
                          ? Icon(Icons.expand_more)
                          : Icon(Icons.expand_less),
                    ],
                  )),
              const SizedBox(height: 16),
              Visibility(
                visible: !expanded,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TagTreeSelection(
                        key: Key('${curBillType()}_tag'),
                        selectedTagIds: state.editBill.data?.tagIdList ?? [],
                        tags: state.tagList,
                        onTagSelected: (tags) {
                          state.editBill.data?.tagIdList = tags;
                        }),
                  ),
                ),
              )
            ],
          );
        });
  }

  // 附加选项区域
  Widget _buildAdditionalOptionsSection() {
    var state = context.watch<EditBillBloc>().state;
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
        ValueListenableBuilder(
            valueListenable: _confirm,
            builder: (_, confirm, __) {
              return SwitchListTile(
                title: const Text('是否确认'),
                subtitle: const Text('确认后将会扣除对应账户金额'),
                value: confirm ?? true,
                onChanged: (value) {
                  state.editBill.data?.confirm = value;
                  _confirm.value = value;
                },
                secondary: const Icon(Icons.verified),
                contentPadding: EdgeInsets.zero,
              );
            }),
        ValueListenableBuilder(
            valueListenable: _include,
            builder: (_, include, __) {
              return SwitchListTile(
                title: const Text('是否统计'),
                subtitle: const Text('纳入统计的账单会在报表中显示'),
                value: include ?? true,
                onChanged: (value) {
                  state.editBill.data?.include = value;
                  _include.value = value;
                },
                secondary: const Icon(Icons.bar_chart),
                contentPadding: EdgeInsets.zero,
              );
            }),

        const SizedBox(height: 16),

        // 备注
        TextField(
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.multiline,
          controller: _remarkController,
          onChanged: (value) {
            state.editBill.data?.remark = value;
          },
          decoration: InputDecoration(
            labelText: '备注',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
          maxLength: 300,
        ),
      ],
    );
  }

  // 提交账单
  void _submitBill(BillItemAdd billItemAdd) {
    // 验证必填字段
    print('lxjtodo: _submitBill $billItemAdd');
    if (!(billItemAdd.data!.title?.isNotEmpty == true)) {
      billItemAdd.data!.title = '未命名账单';
    }
    if (billItemAdd.data?.billType == BillType.transfer.value) {
      if (billItemAdd.data!.amount == null || billItemAdd.data!.amount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填入费用')),
        );
        return;
      }
    } else {
      if (!(billItemAdd.data?.categoryAmountPair?.isNotEmpty == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填入费用')),
        );
        return;
      }
    }

    if (billItemAdd.data?.billType == BillType.transfer.value) {
      // 转账类型
      if (billItemAdd.data?.accountId == null ||
          billItemAdd.data?.toAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择转账账户')),
        );
        return;
      }
    }
    context.read<EditBillBloc>().add(EditBillSubmitted());
  }
}
