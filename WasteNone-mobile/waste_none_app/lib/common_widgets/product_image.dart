import 'package:flutter/cupertino.dart';

class ProductImage extends StatelessWidget {
  ProductImage({this.picLink});

  final String picLink;

  @override
  Widget build(BuildContext context) {
    if (picLink == null)
      return Image(image: AssetImage('images/avocado.jpg'));
    else
      return FadeInImage(
          image: NetworkImage(picLink),
          placeholder: AssetImage('images/avocado.jpg'));
  }
}
