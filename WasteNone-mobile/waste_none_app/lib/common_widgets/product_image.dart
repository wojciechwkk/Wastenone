import 'dart:io';
import 'package:flutter/cupertino.dart';

class ProductImage extends StatelessWidget {
  ProductImage({
    @required this.newProduct,
    this.picLink,
    this.picFilePath,
  });

  final bool newProduct;
  final String picLink;
  final String picFilePath;

  @override
  Widget build(BuildContext context) {
    if (newProduct) return Image(image: AssetImage('images/take_picture.jpg'));
    if (picFilePath != null)
      return FadeInImage(image: FileImage(File(picFilePath)), placeholder: AssetImage('images/avocado.jpg'));
    if (picLink != null)
      return FadeInImage(image: NetworkImage(picLink), placeholder: AssetImage('images/avocado.jpg'));
    return Image(image: AssetImage('images/avocado.jpg'));
  }
}
