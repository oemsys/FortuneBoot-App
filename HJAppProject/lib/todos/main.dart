import 'package:flutter/widgets.dart';
import 'package:flutter_login_example/todos/bootstrap.dart';
import 'package:local_storage_todos_api/local_storage_todos_api.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final todosApi = LocalStorageTodosApi(
//     plugin: await SharedPreferences.getInstance(),
//   );

//   bootstrap(todosApi: todosApi);
// }


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final todosApi = LocalStorageTodosApi(
    plugin: await SharedPreferences.getInstance(),
  );

  bootstrap(todosApi: todosApi);
}

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final todosApi = LocalStorageTodosApi(
//     plugin: await SharedPreferences.getInstance(),
//   );

//   bootstrap(todosApi: todosApi);
// }