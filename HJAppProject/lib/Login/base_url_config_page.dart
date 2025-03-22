import 'package:flutter/material.dart';
import 'package:flutter_login_example/Login/login_constants.dart';
import 'package:flutter_login_example/login_screen.dart';
import 'package:flutter_login_example/generated/l10n.dart';
import 'package:dio/dio.dart';

class BaseUrlConfigPage extends StatefulWidget {
  static const routeName = '/base_url_config';

  const BaseUrlConfigPage({Key? key}) : super(key: key);

  @override
  _BaseUrlConfigPageState createState() => _BaseUrlConfigPageState();
}

class _BaseUrlConfigPageState extends State<BaseUrlConfigPage> {
  final _formKey = GlobalKey<FormState>();
  String _protocol = 'http';
  final TextEditingController _domainController = TextEditingController(text: 'localhost');
  final TextEditingController _portController = TextEditingController(text: '8080');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).baseUrlConfig),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _protocol,
                        items: ['http', 'https'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _protocol = newValue!;
                          });
                        },
                        decoration: InputDecoration(labelText: S.of(context).protocol),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _domainController,
                        decoration: InputDecoration(labelText: S.of(context).domain),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.of(context).pleaseEnterDomain;
                          }
                          // IPv4, IPv6, 或域名的简单验证
                          final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                          final ipv6Regex = RegExp(r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
                          final domainRegex = RegExp(r'^[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})?$');
                          if (value != 'localhost' && !ipv4Regex.hasMatch(value) && !ipv6Regex.hasMatch(value) && !domainRegex.hasMatch(value)) {
                            return S.of(context).invalidDomain;
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _portController,
                        decoration: InputDecoration(labelText: S.of(context).port),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.of(context).pleaseEnterPort;
                          }
                          final port = int.tryParse(value);
                          if (port == null || port < 0 || port > 65535) {
                            return S.of(context).invalidPort;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(S.of(context).confirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final baseUrl = '$_protocol://${_domainController.text}:${_portController.text}';
      LoginConstants.baseUrl = baseUrl;

      try {
        final dio = Dio();
        final response = await dio.get('$baseUrl/getApiVersion');
        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map<String, dynamic> && responseData['code'] == 0) {
            final apiVersion = responseData['data'] as String;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginScreen(),
              ),
            );
          } else {
            _showErrorDialog(S.of(context).serverConnectionFailed);
          }
        } else {
          _showErrorDialog(S.of(context).serverConnectionFailed);
        }
      } catch (e) {
        _showErrorDialog(S.of(context).serverConnectionFailed);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }
}
