import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/bloc/edit_todo_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/view/accound_page.dart';
import 'package:flutter_login_example/Home/edit_todo/view/edit_field_cell.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:todos_repository/todos_repository.dart';
import '../../../generated/l10n.dart';

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
  @override
  Widget build(BuildContext context) {
    // return AccordionPage();
    final status = context.select((EditTodoBloc bloc) => bloc.state.status);
    final isNewTodo = context.select(
      (EditTodoBloc bloc) => bloc.state.isNewTodo,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNewTodo
              ? S.current.editTodoAddAppBarTitle
              : S.current.editTodoEditAppBarTitle,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: S.current.editTodoSaveButtonTooltip,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        onPressed: status.isLoadingOrSuccess
            ? null
            : () => context.read<EditTodoBloc>().add(const EditTodoSubmitted()),
        child: status.isLoadingOrSuccess
            ? const CupertinoActivityIndicator()
            : const Icon(Icons.check_rounded),
      ),
      body: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: _buildFieldCells(widget.billType),
            ),
          ),
        ),
      ),
    );
  }

  List<EditFieldCell> _buildFieldCells(BillType billType) {
    var changeField = <EditFieldCell>[];
    if (billType == BillType.expenditure || billType == BillType.income) {
      changeField = [
        EditFieldCell(type: EditFieldType.account, billType: widget.billType),
        EditFieldCell(type: EditFieldType.category, billType: widget.billType),
        EditFieldCell(type: EditFieldType.target, billType: widget.billType),
      ];
    } else if (billType == BillType.transfer) {
      changeField = [
        EditFieldCell(
            type: EditFieldType.transferOutAccount, billType: widget.billType),
        EditFieldCell(
            type: EditFieldType.transferInAccount, billType: widget.billType),
        EditFieldCell(
            type: EditFieldType.transferAmount, billType: widget.billType),
      ];
    }
    return [
      EditFieldCell(
        type: EditFieldType.billType,
        billType: widget.billType,
        onTypeChange: (type) {
          print('lxjtodo: dropdownField type: $type');
          setState(() {
            widget.billType = type;
          });
        },
      ),
      EditFieldCell(type: EditFieldType.book, billType: widget.billType),
      EditFieldCell(type: EditFieldType.title, billType: widget.billType),
      EditFieldCell(type: EditFieldType.time, billType: widget.billType),
      ...changeField,
      EditFieldCell(type: EditFieldType.tag, billType: widget.billType),
      EditFieldCell(type: EditFieldType.confirm, billType: widget.billType),
      EditFieldCell(type: EditFieldType.statistics, billType: widget.billType),
      EditFieldCell(type: EditFieldType.remark, billType: widget.billType),
    ];
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditTodoBloc>().state;
    final hintText = state.initialTodo?.title ?? '';

    return TextFormField(
      key: const Key('editTodoView_title_textFormField'),
      initialValue: state.title,
      decoration: InputDecoration(
        enabled: !state.status.isLoadingOrSuccess,
        labelText: S.current.editTodoTitleLabel,
        hintText: hintText,
      ),
      maxLength: 50,
      inputFormatters: [
        LengthLimitingTextInputFormatter(50),
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
      ],
      onChanged: (value) {
        context.read<EditTodoBloc>().add(EditTodoTitleChanged(value));
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditTodoBloc>().state;
    final hintText = state.initialTodo?.description ?? '';

    return TextFormField(
      key: const Key('editTodoView_description_textFormField'),
      initialValue: state.description,
      decoration: InputDecoration(
        enabled: !state.status.isLoadingOrSuccess,
        labelText: S.current.editTodoDescriptionLabel,
        hintText: hintText,
      ),
      maxLength: 300,
      maxLines: 7,
      inputFormatters: [
        LengthLimitingTextInputFormatter(300),
      ],
      onChanged: (value) {
        context.read<EditTodoBloc>().add(EditTodoDescriptionChanged(value));
      },
    );
  }
}
