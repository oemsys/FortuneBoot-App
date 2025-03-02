// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Easy Money`
  String get main_logo {
    return Intl.message(
      'Easy Money',
      name: 'main_logo',
      desc: '',
      args: [],
    );
  }

  /// `You are trying to login/sign up on server hosted on`
  String get login_message {
    return Intl.message(
      'You are trying to login/sign up on server hosted on',
      name: 'login_message',
      desc: '',
      args: [],
    );
  }

  /// `haoji.com`
  String get login_host {
    return Intl.message(
      'haoji.com',
      name: 'login_host',
      desc: '',
      args: [],
    );
  }

  /// `LOGIN`
  String get login_button_text {
    return Intl.message(
      'LOGIN',
      name: 'login_button_text',
      desc: '',
      args: [],
    );
  }

  /// `REGISTER`
  String get register {
    return Intl.message(
      'REGISTER',
      name: 'register',
      desc: '',
      args: [],
    );
  }

  /// `or login with`
  String get or_login_with {
    return Intl.message(
      'or login with',
      name: 'or_login_with',
      desc: '',
      args: [],
    );
  }

  /// `Authenticate`
  String get authenticate {
    return Intl.message(
      'Authenticate',
      name: 'authenticate',
      desc: '',
      args: [],
    );
  }

  /// `Forgot huh?`
  String get forgot_huh {
    return Intl.message(
      'Forgot huh?',
      name: 'forgot_huh',
      desc: '',
      args: [],
    );
  }

  /// `User`
  String get login_account {
    return Intl.message(
      'User',
      name: 'login_account',
      desc: '',
      args: [],
    );
  }

  /// `Pass`
  String get login_pass {
    return Intl.message(
      'Pass',
      name: 'login_pass',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get login_confirm {
    return Intl.message(
      'Confirm',
      name: 'login_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Term of services`
  String get term_of_services {
    return Intl.message(
      'Term of services',
      name: 'term_of_services',
      desc: '',
      args: [],
    );
  }

  /// `Email must contain '@' and end with '.com'`
  String get email_auth {
    return Intl.message(
      'Email must contain \'@\' and end with \'.com\'',
      name: 'email_auth',
      desc: '',
      args: [],
    );
  }

  /// `Password is empty`
  String get password_is_empty {
    return Intl.message(
      'Password is empty',
      name: 'password_is_empty',
      desc: '',
      args: [],
    );
  }

  /// `Required`
  String get service_required {
    return Intl.message(
      'Required',
      name: 'service_required',
      desc: '',
      args: [],
    );
  }

  /// `HELP ME`
  String get help_me {
    return Intl.message(
      'HELP ME',
      name: 'help_me',
      desc: '',
      args: [],
    );
  }

  /// `GO BACK`
  String get go_back {
    return Intl.message(
      'GO BACK',
      name: 'go_back',
      desc: '',
      args: [],
    );
  }

  /// `Not match!`
  String get not_match {
    return Intl.message(
      'Not match!',
      name: 'not_match',
      desc: '',
      args: [],
    );
  }

  /// `Don't feel bad. Happens all the time.`
  String get dont_worry_be_happy {
    return Intl.message(
      'Don\'t feel bad. Happens all the time.',
      name: 'dont_worry_be_happy',
      desc: '',
      args: [],
    );
  }

  /// `Lorem Ipsum is simply dummy text of the printing and typesetting industry`
  String get default_comment {
    return Intl.message(
      'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
      name: 'default_comment',
      desc: '',
      args: [],
    );
  }

  /// `Password rescued successfully`
  String get password_rescued_successfully {
    return Intl.message(
      'Password rescued successfully',
      name: 'password_rescued_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Oh no!`
  String get oh_no {
    return Intl.message(
      'Oh no!',
      name: 'oh_no',
      desc: '',
      args: [],
    );
  }

  /// `Succes!`
  String get succes {
    return Intl.message(
      'Succes!',
      name: 'succes',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Please fill in this form to complete the signup`
  String get fill_to_signup {
    return Intl.message(
      'Please fill in this form to complete the signup',
      name: 'fill_to_signup',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phone_number {
    return Intl.message(
      'Phone Number',
      name: 'phone_number',
      desc: '',
      args: [],
    );
  }

  /// `SUBMIT`
  String get sign_up_submit {
    return Intl.message(
      'SUBMIT',
      name: 'sign_up_submit',
      desc: '',
      args: [],
    );
  }

  /// `This isn't a valid phone number`
  String get valid_phone_number {
    return Intl.message(
      'This isn\'t a valid phone number',
      name: 'valid_phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Account is empty`
  String get user_auth_vaild {
    return Intl.message(
      'Account is empty',
      name: 'user_auth_vaild',
      desc: '',
      args: [],
    );
  }

  /// `User not exists`
  String get user_not_exist {
    return Intl.message(
      'User not exists',
      name: 'user_not_exist',
      desc: '',
      args: [],
    );
  }

  /// `Sign Up Success!`
  String get sign_up_success {
    return Intl.message(
      'Sign Up Success!',
      name: 'sign_up_success',
      desc: '',
      args: [],
    );
  }

  /// `Nickname`
  String get login_nickname {
    return Intl.message(
      'Nickname',
      name: 'login_nickname',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get login_email {
    return Intl.message(
      'Email',
      name: 'login_email',
      desc: '',
      args: [],
    );
  }

  /// `sex`
  String get sex {
    return Intl.message(
      'sex',
      name: 'sex',
      desc: '',
      args: [],
    );
  }

  /// `female`
  String get female {
    return Intl.message(
      'female',
      name: 'female',
      desc: '',
      args: [],
    );
  }

  /// `male`
  String get male {
    return Intl.message(
      'male',
      name: 'male',
      desc: '',
      args: [],
    );
  }

  /// `Currently, only two genders are supported. Please fill in 'Male' or 'Female'.`
  String get sex_valid {
    return Intl.message(
      'Currently, only two genders are supported. Please fill in \'Male\' or \'Female\'.',
      name: 'sex_valid',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
