import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/Home/payee_manage/data/payee_service.dart';
import 'package:hjproject/Home/payee_manage/model/payee.dart';
import 'package:hjproject/Home/payee_manage/view/widgets/payee_list_view.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_pager.dart';
import 'package:hjproject/Home/payee_manage/view/payee_add_page.dart';

/// 交易对象管理页面：首屏展示列表，下拉刷新，错误/加载/空态 + 分页条
class PayeeManagePage extends StatefulWidget {
  const PayeeManagePage({Key? key}) : super(key: key);

  @override
  State<PayeeManagePage> createState() => _PayeeManagePageState();
}

class _PayeeManagePageState extends State<PayeeManagePage> {
  final PayeeService _service = PayeeService();

  bool _loading = true;
  String? _error;
  List<Payee> _rows = const <Payee>[];
  int _total = 0;

  // 分页状态
  int _pageNum = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 完全复用“分类管理”中的账本ID获取方式
      final bookId = context.read<BillsRepository>().bookId() ?? 1;
      final data = await _service.fetch(
        bookId: bookId,
        pageNum: _pageNum,
        pageSize: _pageSize,
      );
      setState(() {
        _rows = data.rows;
        _total = data.total;
        _error = null;
      });
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

Future<void> _openAddPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PayeeAddPage()),
    );
    if (result == true) {
      await _load(); // 仅刷新当前页
    }
  }
  @override
  Widget build(BuildContext context) {
    double horizontalPadding() {
      final width = MediaQuery.of(context).size.width;
      if (width < 600) return 16;
      if (width < 1024) return 20;
      return 24;
    }

    final hPadding = horizontalPadding();

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易对象管理'),
        actions: [
          IconButton(
            tooltip: '新增',
            icon: const Icon(Icons.add),
            onPressed: _openAddPage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              // 下拉刷新保持当前页，不重置 _pageNum
              onRefresh: _load,
              child: PayeeListView(
                loading: _loading,
                error: _error,
                total: _total,
                currentPage: _pageNum,
                rows: _rows,
                onRetry: _load,
                onMovedToRecycleBin: _load, // 成功后保持当前页刷新
              ),
            ),
          ),
          // 分页条仅在“非加载且无错误”时展示；空态也展示总量并可翻页
          if (!_loading && _error == null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: CategoryPager(
                total: _total,
                hasPrev: _pageNum > 1,
                hasNext: _pageNum * _pageSize < _total,
                onPrev: _goPrev,
                onNext: _goNext,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}