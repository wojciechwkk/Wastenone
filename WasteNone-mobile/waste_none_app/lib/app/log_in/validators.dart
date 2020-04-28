abstract class StringValidator {
  bool isValid(String value);
}

class NonEmptyStringValidator implements StringValidator {
  @override
  bool isValid(String value) {
    return value.isNotEmpty;
  }
}
class PasswordStringValidator implements StringValidator {
  @override
  bool isValid(String value) {
    print('password: ${value} is valid: ${value.isNotEmpty && value.length > 5}');
    return value.isNotEmpty && value.length > 5;
  }
}

class EmailStringValidator implements StringValidator {
  @override
  bool isValid(String value) {
    if( value.isEmpty || !value.contains('@') ) {
      return false;
    }
    else {
      final emailParts = value.split('@');
      if(!emailParts[1].contains('.'))
      {
        return false;
      }
    }
    return true;
  }
}

class EmailAndPasswordStringValidator {
  final StringValidator emailValidator = EmailStringValidator();
  final StringValidator passwordValidator = PasswordStringValidator();
  final StringValidator displayNameValidator = NonEmptyStringValidator();
  final String invalidEmailErrorText = "Invalid email format";
  final String invalidPasswordErrorText = "Password can't be empty";
  final String invalidDisplayNameErrorText = "Display Name can't be empty";
}
