import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:HJProject/home/app/app.dart';
import 'package:HJProject/home/app/app_bloc_observer.dart';
import 'package:HJProject/repository/api/bills_api.dart';
import 'package:HJProject/repository/repository/bills_repository.dart';

void bootstrap({required BillsApi billsApi}) {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log(error.toString(), stackTrace: stack);
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  runApp(App(
    createBillsRepository: () => BillsRepository(billsApi: billsApi),
  ));
}
