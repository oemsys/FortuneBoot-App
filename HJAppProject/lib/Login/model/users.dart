const mockUsers = {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
  'near.huscarl@gmail.com': 'subscribe to pewdiepie',
  '@.com': '.',
};

class UserDataSingleton {
  static const String userInfo = 'userInfo';
  // 私有静态实例
  static final UserDataSingleton _instance = UserDataSingleton._internal();
  
  // 数据存储核心结构
  Map<String, dynamic> _userData = {};

  // 工厂构造函数返回唯一实例
  factory UserDataSingleton() => _instance;

  // 私有构造函数防止外部实例化
  UserDataSingleton._internal();

  // 数据操作方法
  void set(String key, dynamic value) => _userData[key] = value;
  
  dynamic get(String key) => _userData[key];
  
  void remove(String key) => _userData.remove(key);
  
  void clear() => _userData.clear();
  
  bool containsKey(String key) => _userData.containsKey(key);
}