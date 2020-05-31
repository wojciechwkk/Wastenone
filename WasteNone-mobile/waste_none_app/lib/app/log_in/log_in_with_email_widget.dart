import 'package:flutter/material.dart';
import 'package:waste_none_app/app/models/fridge.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/validators.dart';
import 'package:waste_none_app/common_widgets/form_submit_button.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';

enum LogInWithEmailFormType { logIn, createUser }

class LogInWithEmailForm extends StatefulWidget
    with EmailAndPasswordStringValidator {
  LogInWithEmailForm({@required this.auth, @required this.db});

  final AuthBase auth;
  final WNFirebaseDB db;

  @override
  State<StatefulWidget> createState() =>
      new _LogInWithEmailFormState(auth: auth, db: db);
}

class _LogInWithEmailFormState extends State<LogInWithEmailForm> {
  _LogInWithEmailFormState({@required this.auth, @required this.db});

  final AuthBase auth;
  final WNFirebaseDB db;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  final FocusNode _displayNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  String get _email => _emailController.text.trim();
  String get _password => _passwordController.text.trim();
  String get _displayName => _displayNameController.text.trim();

  LogInWithEmailFormType _formType = LogInWithEmailFormType.logIn;

//  bool _submitted = false;
  bool _isLoading = false;
  bool _isEmailEdited = false;
  bool _isPasswordEdited = false;
  bool _isDisplayNameEdited = false;

  void _submit() async {
    print('submit called');
    setState(() {
//      _submitted = true;
      _isLoading = true;
    });
    try {
      if (widget.emailValidator.isValid(_email) &&
          widget.passwordValidator.isValid(_password)) {
        if (_formType == LogInWithEmailFormType.logIn) {
          auth.logInWithEmailAndPassword(_email, _password);
        } else {
          if (widget.displayNameValidator.isValid(_displayName)) {
            WasteNoneUser user =
                await auth.createUser(_email, _password, _displayName);
            await db.createUser(user);
            _isLoading = false;
          }
        }
      }
    } catch (e) {
      print(e.toString());
    } finally {}
  }

  void _updateState() {
    setState(() {
      _isEmailEdited = true;
      _isPasswordEdited = true;
      _isDisplayNameEdited = true;
    });
  }

  void _toggleFormType() {
    setState(() {
//      _submitted = false;
      _isEmailEdited = false;
      _isPasswordEdited = false;
      _isDisplayNameEdited = false;
      _formType = _formType == LogInWithEmailFormType.logIn
          ? LogInWithEmailFormType.createUser
          : LogInWithEmailFormType.logIn;
    });
    _emailController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  void _displayNameEditComplete() {
    FocusScope.of(context).requestFocus(_emailFocusNode);
  }

  void _emailEditComplete() {
    final newFocus = widget.emailValidator.isValid(_email)
        ? _passwordFocusNode
        : _emailFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Container _buildContent() {
    bool submitEnabled = widget.emailValidator.isValid(_email) &&
        widget.passwordValidator.isValid(_password) &&
        ((_formType == LogInWithEmailFormType.createUser) ==
            widget.displayNameValidator.isValid(_displayName)) &&
        !_isLoading;

    final submitButtonText =
        _formType == LogInWithEmailFormType.logIn ? 'Log in' : 'Create User';
    final toggleFormTypeButtonText = _formType == LogInWithEmailFormType.logIn
        ? "Don\'t have an account? Create User"
        : 'Already have an account? Log in';
    return Container(
        color: Colors.white,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          _buildDisplayNameWidget(),
          _buildEmailWidget(),
          _buildPasswordWidget(),
          SizedBox(height: 8.0),
          FormSubmitButton(
            text: submitButtonText,
            onPressed: submitEnabled ? _submit : null,
          ),
          FlatButton(
            child: Text(toggleFormTypeButtonText),
            onPressed: _toggleFormType,
          )
        ]));
  }

//  DISPLAY NAME WIDGET
  Visibility _buildDisplayNameWidget() {
    bool showError = _isDisplayNameEdited &
        !widget.displayNameValidator.isValid(_displayName);
    return Visibility(
      visible: _formType == LogInWithEmailFormType.createUser,
      child: TextField(
        controller: _displayNameController,
        focusNode: _displayNameFocusNode,
        decoration: InputDecoration(
          labelText: 'Display Name',
          errorText: showError ? widget.invalidDisplayNameErrorText : null,
          enabled: !_isLoading,
        ),
        obscureText: false,
        textInputAction: TextInputAction.next,
        onChanged: (displayName) => _updateState(),
        onEditingComplete: _displayNameEditComplete,
      ),
    );
  }

//  EMAIL WIDGET
  TextField _buildEmailWidget() {
    bool showError =
        _isEmailEdited & !widget.displayNameValidator.isValid(_email);
    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'email@email.com',
        errorText: showError ? widget.invalidEmailErrorText : null,
        enabled: !_isLoading,
      ),
      autocorrect: false,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: (email) => _updateState(),
      onEditingComplete: _emailEditComplete,
    );
  }

//  PASSWORD WIDGET
  TextField _buildPasswordWidget() {
    bool showError =
        _isPasswordEdited & !widget.displayNameValidator.isValid(_password);
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      decoration: InputDecoration(
        labelText: 'Password',
        errorText: showError ? widget.invalidPasswordErrorText : null,
        enabled: !_isLoading,
      ),
      obscureText: true,
      autocorrect: false,
      onChanged: (password) => _updateState(),
      onEditingComplete: _submit,
    );
  }
}
