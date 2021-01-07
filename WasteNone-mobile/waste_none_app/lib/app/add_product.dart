import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart' as cup;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';
import 'package:waste_none_app/common_widgets/product_image.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/services/local_nosql_cache.dart';

import 'models/product.dart';

class AddProductPage extends StatefulWidget {
  AddProductPage({@required this.auth, @required this.db, @required this.user, @required this.newProduct});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;
  final Product newProduct;

  @override
  State<StatefulWidget> createState() =>
      _AddProductPageState(auth: this.auth, db: this.db, user: this.user, newProduct: newProduct);
}

class _AddProductPageState extends State<AddProductPage> {
  _AddProductPageState({@required this.auth, @required this.db, @required this.user, @required this.newProduct});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;
  final Product newProduct;

  TextEditingController _newProductEANController = TextEditingController();
  TextEditingController _newProductBrandController = TextEditingController();
  TextEditingController _newProductNameController = TextEditingController();
  TextEditingController _newProductSizeController = TextEditingController();
  TextEditingController _newProductUnitController = cup.TextEditingController();

  final picker = ImagePicker();
  ProductImage _image;

  // unit picker
  int _selectedColorIndex = 0;
  double itemExtent = 44.0;
  FixedExtentScrollController scrollController;
  Set<String> units;

  @override
  void initState() {
    scrollController = FixedExtentScrollController(initialItem: _selectedColorIndex);
    String unitSystem = getSettingsKey(SettingsKeysEnum.UNIT_SYSTEM, user.uid);
    // print(unitSystem);
    units = unitSystem == 'Metric' ? {'x', 'g', 'kg', 'ml', 'l'} : {'x', 'lb', 'oz'};
    _image = ProductImage(
      newProduct: true,
      picLink: null,
      picFilePath: null,
    );
    _newProductEANController.text = newProduct.eanCode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30, left: 8, right: 8),
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.30,
                          height: MediaQuery.of(context).size.width * 0.30,
                          child: FlatButton(
                            child: _image,
                            onPressed: _takePicture,
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _newProductEANController,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: new InputDecoration(
                                  labelText: 'EAN Code',
                                  enabled: true,
                                ),
                                enabled: false,
                                // onChanged: (qty) => _qtyChangedState,
                              ),
                              TextFormField(
                                controller: _newProductBrandController,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.singleLineFormatter],
                                keyboardType: TextInputType.text,
                                autofocus: true,
                                decoration: new InputDecoration(
                                  labelText: 'Brand',
                                  enabled: true,
                                ),
                                // onChanged: (qty) => _qtyChangedState,
                              ),
                              TextFormField(
                                controller: _newProductNameController,
                                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.singleLineFormatter],
                                keyboardType: TextInputType.text,
                                autofocus: true,
                                decoration: new InputDecoration(
                                  labelText: 'Product Name',
                                  enabled: true,
                                ),
                                // onChanged: (qty) => _qtyChangedState,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.28,
                                    child: TextFormField(
                                      controller: _newProductSizeController,
                                      textAlign: TextAlign.right,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.singleLineFormatter
                                      ],
                                      keyboardType: TextInputType.number,
                                      autofocus: true,
                                      decoration: new InputDecoration(
                                        labelText: 'Size',
                                        enabled: true,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0, top: 15.0),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.13,
                                      child: cup.CupertinoPicker(
                                        scrollController: scrollController,
                                        itemExtent: itemExtent,
                                        looping: true,
                                        offAxisFraction: -0.5,
                                        children: <Widget>[
                                          for (var i = 0; i < units?.length; i++)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  units.elementAt(i),
                                                  style: TextStyle(color: Colors.black, fontSize: 15),
                                                ),
                                              ],
                                            ),
                                        ],
                                        onSelectedItemChanged: (int index) {
                                          _newProductUnitController.text = units.elementAt(index);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              //UNIT
                            ],
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Visibility(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  onPressed: _addProduct,
                  label: Text("Add"),
                  icon: Icon(Icons.check),
                  heroTag: 'add_product',
                ),
              ),
            ),
            Visibility(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).pop(),
                  label: Text("Cancel"),
                  icon: Icon(Icons.cancel),
                  heroTag: 'cancel_adding_product',
                ),
              ),
            ),
          ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  _addProduct() {
    newProduct.name = _newProductNameController.text;
    newProduct.brand = _newProductBrandController.text;
    newProduct.size = _newProductSizeController.text + _newProductUnitController.text;
    newProduct.picPath = _image.picFilePath; //TODO: add the local drive link for now.
    print(newProduct.toJson());
    storeProductToLocalCache(newProduct);
    showAddedNotification();
    Navigator.pop(context, newProduct);
  }

  showAddedNotification() {
    Fluttertoast.showToast(
        msg: "You have added a new product to your database! :)",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.lightGreen,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<File> getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    print(pickedFile.path);
    return File(pickedFile.path);
    // return pickedFile.path;
    // setState(() {
    //   if (pickedFile != null) {
    //     //
    //     return pickedFile.path;
    //   } else {
    //     print('No image selected.');
    //   }
    // });
  }

  _takePicture() async {
    print('take a picture');
    File imageFile = await getImage();

    setState(() {
      imageCache.clear();
      imageCache.clearLiveImages();
      imageCache.evict(_image);
      _image = ProductImage(newProduct: false, picLink: null, picFilePath: imageFile.path);
    });
  }
}
