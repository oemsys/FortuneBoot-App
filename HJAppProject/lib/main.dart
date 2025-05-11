import 'package:flutter/material.dart';
import 'package:hjproject/repository/api/local_bills_storage_api.dart';
import 'package:hjproject/home/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final billsApi = LocalStorageBillsApi(
    plugin: await SharedPreferences.getInstance(),
  );

  bootstrap(billsApi: billsApi);
}
