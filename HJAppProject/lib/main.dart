import 'package:flutter/material.dart';
import 'package:flutter_login_example/repository/api/local_bills_storage_api.dart';
import 'package:flutter_login_example/home/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final billsApi = LocalStorageBillsApi(
    plugin: await SharedPreferences.getInstance(),
  );

  bootstrap(billsApi: billsApi);
}