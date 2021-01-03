import 'dart:io';
import 'package:flutter/cupertino.dart';

class ProductImage extends StatelessWidget {
  ProductImage({@required this.newProduct, this.picLink, this.picFile});

  final bool newProduct;
  final String picLink;
  final File picFile;

  @override
  Widget build(BuildContext context) {
    if (newProduct) return Image(image: AssetImage('images/take_picture.jpg'));
    if (picLink == null)
      return Image(image: AssetImage('images/avocado.jpg'));
    else if (picFile != null)
      return FadeInImage(image: FileImage(picFile), placeholder: AssetImage('images/avocado.jpg'));
    else
      return FadeInImage(image: NetworkImage(picLink), placeholder: AssetImage('images/avocado.jpg'));
  }
}
