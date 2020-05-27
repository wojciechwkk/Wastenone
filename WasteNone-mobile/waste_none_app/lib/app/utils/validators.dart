abstract class StringValidator {
  bool isValid(String value);
}

//------------------------------- log in ---------------------------------------

class NonEmptyStringValidator implements StringValidator {
  @override
  bool isValid(String value) {
    return value.isNotEmpty;
  }
}

class PasswordStringValidator implements StringValidator {
  @override
  bool isValid(String value) {
    return value.isNotEmpty && value.length > 5;
  }
}

class EmailStringValidator implements StringValidator {
  @override
  bool isValid(String value) {
    if (value.isEmpty || !value.contains('@')) {
      return false;
    } else {
      final emailParts = value.split('@');
      if (!emailParts[1].contains('.')) {
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

//------------------------------ /log in ---------------------------------------

//------------------------------ item qty --------------------------------------

class ProductQtyValueValidator implements StringValidator {
  @override
  bool isValid(String value) {
    print(
        "validator: $value is OK: ${value.isNotEmpty && num.parse(value) < 10000}");
    return value.isNotEmpty && num.parse(value) < 10000;
  }
}

class ProductQtyValidator {
  final StringValidator qtyValidator = ProductQtyValueValidator();
  final String qtyErrorText = "Do you REALLY have more than 9999 of these?";
}
//------------------------------ /item qty -------------------------------------
