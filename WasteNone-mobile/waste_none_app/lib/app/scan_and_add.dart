import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';
import 'package:waste_none_app/app/utils/validators.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/common_widgets/product_image.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/services/flutter_notification.dart';

import 'models/fridge.dart';

class ScanAndAdd extends StatefulWidget with ProductQtyValidator {
  ScanAndAdd({
    @required this.auth,
    @required this.db,
    @required this.fridge,
    @required this.fridgeContent,
    @required this.user,
  });

  final AuthBase auth;
  final WNFirebaseDB db;
  final Fridge fridge;
  final List<FridgeItem> fridgeContent;
  final WasteNoneUser user;

  @override
  _ScanAndAddState createState() => _ScanAndAddState(
        auth: this.auth,
        db: this.db,
        fridge: this.fridge,
        fridgeContent: this.fridgeContent,
        user: this.user,
      );
}

class _ScanAndAddState extends State<ScanAndAdd> {
  _ScanAndAddState(
      {@required this.auth,
      @required this.db,
      @required this.fridge,
      @required this.fridgeContent,
      @required this.user,
      @required this.notificationsPlugin});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  final Fridge fridge;
  final List<FridgeItem> fridgeContent;
  Product product;

//  String usersFridgeNo = "1"; //default to be extended;

  String welcomeText = "WasteNone";
  String productInfo = "Product info";
  String productPic;

  bool _loadingProductData = false;

  DateTime selectedDate = DateTime.now();
  DateTime defaultSelectedDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1);
  bool _productFetched = false;

  @override
  void initState() {
    super.initState();
    selectedDate = defaultSelectedDate;
    _scanAction();
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingIndicator = _loadingProductData ? LoadingIndicator() : Container();

    return Scaffold(
      appBar: AppBar(title: Text(welcomeText), actions: <Widget>[
//        FlatButton(
//          child: Text('Logout', style: TextStyle(fontSize: 18)),
//          onPressed: _logOut,
//        )
      ]),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Center(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 30, left: 8, right: 8),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.30,
                            child: ProductImage(picLink: productPic),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: AutoSizeText(
                              productInfo,
                              style: new TextStyle(fontSize: 15.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: _productFetched,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 120, left: 20, right: 20),
                        child: CalendarDatePicker(
                          firstDate: DateTime.now(),
                          initialDate: selectedDate,
                          lastDate: DateTime(DateTime.now().year + 5, DateTime.now().month, DateTime.now().day),
                          initialCalendarMode: DatePickerMode.day,
                          onDateChanged: _dateChanged,
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
          Align(
            child: loadingIndicator,
            alignment: FractionalOffset.center,
          ),
        ],
      ),
      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: _productFetched,
              child: FloatingActionButton.extended(
                  onPressed: () => _showQtyDialog(context), //_showQtyDialog(context),
                  label: Text("Add"),
                  icon: Icon(Icons.ac_unit),
                  heroTag: "addbut"),
            ),
//            Padding(
//              padding: const EdgeInsets.all(8.0),
//              child: FloatingActionButton.extended(
//                  onPressed: () =>
//                      {Navigator.pop(context, true)}, //_scanAction,
//                  label: Text("Back"),
//                  icon: Icon(Icons.camera),
//                  heroTag: "scanbut"),
//            ),
          ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _dateChanged(DateTime picked) {
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
    return null;
  }

//  _removeFridge() async {
//    WasteNoneUser wasteNoneUser = await auth?.AuthResult;
//    var fridgeNo = "${wasteNoneUser.uid}-$usersFridgeNo";
//    db?.removeFridge(fridgeNo);
//  }

//---------------------------------- adding item -------------------------------

  final TextEditingController _qtyTextController = TextEditingController();

  String get _qty => _qtyTextController.text.trim();
  bool _qtyChanged = false;

  void _qtyChangedState() {
    setState(() {
      _qtyChanged = true;
    });
  }

  _showQtyDialog(BuildContext context) async {
    _qtyTextController.clear();
    _qtyChanged = false;
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(
                  child: new TextFormField(
                    controller: _qtyTextController,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: new InputDecoration(
                      labelText: 'Add quantity',
                      enabled: true,
                      errorText: widget.qtyValidator.isValid(_qty) ? widget.qtyErrorText : null,
                    ),
                    onChanged: (qty) => _qtyChangedState,
//                    validator: () => ProductQtyValueVaidator();
                  ),
                )
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('OK'),
                  onPressed: () {
                    _addItemToFridgeAction(_qtyTextController.text.toString());
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          );
        });
  }

  _addItemToFridgeAction(String qty) async {
    if (product != null) {
      if (widget.qtyValidator.isValid(_qtyTextController.text)) {
        bool isInProductsTable = await db?.isInProductsWNDB(product?.eanCode);
        if (!isInProductsTable) db?.addProduct(product);

        FridgeItem fridgeItem = await _prepareFridgeItem(qty);
        // todo remove
        WasteNoneUser wasteNoneUser = auth.currentUser();
        //todo remove
        if (fridgeItem != null && !fridgeItem.isEmpty()) {
          FridgeItem existingSimilarItem = _getCurrentFridgesSimilarItem(fridgeContent, fridgeItem);
          if (existingSimilarItem != null) {
            await _updateExistingItem(existingSimilarItem, fridgeItem);
            print("item updated");
          } else {
            await _addNewItem(fridgeItem);
            print("item added");
            Product product = await db.getProductByPUID(fridgeItem.product_puid);
            FlutterNotification().addExpiryNotification(auth.currentUser(), product, fridgeItem);
          }
          FlutterNotification().showItemAddedNotification(fridge, product, fridgeItem);
        }
        setState(() {
          productInfo = "";
          productPic = null;
        });

        selectedDate = defaultSelectedDate;

        _scanAction();
      }
    }
  }

  Future<void> _updateExistingItem(FridgeItem existingSimilarItem, FridgeItem fridgeItem) async {
    fridgeContent.remove(existingSimilarItem);
    existingSimilarItem.qty += fridgeItem.qty;
    String encryptionPassword = await readEncryptionPassword(auth.currentUser().uid);
    String encryptedUpdatedFridgeItem = existingSimilarItem.asEncodedString(encryptionPassword);
    db.updateEncryptedFridgeItem(existingSimilarItem.fridge_no, existingSimilarItem.dbKey, encryptedUpdatedFridgeItem);
    fridgeContent.add(existingSimilarItem);
    // setState() {
    // fridgeContent.add(existingSimilarItem);

    // for (FridgeItem existingInNewFridgeItem in newFridgeContent) {
    //   if (existingInNewFridgeItem.product_puid == fridgeItem.product_puid) {
    //     if (existingInNewFridgeItem.validDate == fridgeItem.validDate) {
    //       existingInNewFridgeItem.qty += fridgeItem.qty;
    //     }
    //   }
    // }
    // }
  }

  Future<void> _addNewItem(FridgeItem fridgeItem) async {
    //db.addToFridge(fridgeItem, wasteNoneUser.uid);
    String encryptionPassword = await readEncryptionPassword(auth.currentUser().uid);
    String encryptedFridgeItem = fridgeItem.asEncodedString(encryptionPassword);
    String dbKey = await db.addToFridgeEncrypted(encryptedFridgeItem, fridgeItem.fridge_no);
    fridgeItem.dbKey = dbKey;
    fridgeContent.add(fridgeItem);
  }

  FridgeItem _getCurrentFridgesSimilarItem(List<FridgeItem> fridgeItemList, FridgeItem fridgeItem) {
    for (FridgeItem existingFridgeItem in fridgeItemList) {
      if (existingFridgeItem.product_puid == fridgeItem.product_puid) {
        if (existingFridgeItem.validDate == fridgeItem.validDate) {
          return existingFridgeItem;
        }
      }
    }
    return null;
  }

  Future<FridgeItem> _prepareFridgeItem(String qty) async {
    FridgeItem fridgeItem = FridgeItem();
    WasteNoneUser wasteNoneUser = await auth.currentUser();
    fridgeItem.fridge_no = fridge.fridgeID;
    fridgeItem.product_puid = product?.puid;
    fridgeItem.qty = num.parse(qty);
    fridgeItem.validDate = "${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}";
    fridgeItem.comment = "comment 1";
    return fridgeItem;
  }
//---------------------------------- /adding item ------------------------------
//------------------------------ expiry notification  --------------------------

//----------------------------- /expiry notification  --------------------------
//---------------------------------- scan item ---------------------------------

  Future<String> _scanBarCode() async {
    var options = ScanOptions(
      autoEnableFlash: true,
    );
    var result = await BarcodeScanner.scan(options: options);
    print(productInfo);
    var eanCode = result.rawContent.toString();
    return eanCode;
  }

  void _scanAction() async {
    // String eanCode = await _scanBarCode();
    // var eanCode = '7630040403290';
    var eanCode = '5054563003232';
    // var eanCode = '5900197022548';

    _loadingProductData = true;

    print(eanCode);
    _productFetched = await _fetchFromWasteNoneDB(eanCode);
    print("product found in WasteNone database: $_productFetched");
    if (!_productFetched) {
      _productFetched = await _lookUpInGs1DB(eanCode);
      print("product found in GS1 database: $_productFetched");
    }
    if (_productFetched)
      showProduct();
    else
      _showNotFoundMsg();

    _loadingProductData = false;
  }

//---------------------------------- /scan item --------------------------------

//---------------------------------- WN DB -------------------------------------

  Future<bool> _fetchFromWasteNoneDB(String eanCode) async {
    print("about to fetch product data from WasteNone DB");
    Product productWNDB = await db?.getProductByEanCode(eanCode);
    if (productWNDB != null) {
      setState(() {
        product = productWNDB;
      });
      return true;
    }
    return false;
  }

//---------------------------------- /WN DB ------------------------------------

//---------------------------------- GS1 DB ------------------------------------

  Future<bool> _lookUpInGs1DB(String eanCode) async {
    print("about to fetch product data from GS1 DB");
    final gs1uri = "https://produktywsieci.gs1.pl/api/products/";
    final gs1user = 'wojciech.wkk@gmail.com';
    final gs1pass = '85d72d46c327fc0c5d9410860508800f8833b9d009832eb0b51f219387305704';
    final basicAuth = 'Basic ' + base64Encode(utf8.encode('$gs1user:$gs1pass'));

    Response response = await get("$gs1uri$eanCode?aggregation=SOCIAL",
        headers: <String, String>{'authorization': basicAuth, 'format': 'json'});

    final responseJson = json.decode(response.body);

    print(response.statusCode);
    if (response.statusCode == 200) {
      //print(response.body);

      Product productFromGs1 = Product();
      productFromGs1.puid = Uuid().v1();
      productFromGs1.name = _getSomeProdNameFromResponse(responseJson);
      productFromGs1.eanCode = eanCode;
      productFromGs1.brand = responseJson["Brand"] != null ? responseJson["Brand"] : responseJson["BrandOwner"];
      productFromGs1.owner = responseJson["BrandOwner"];
      productFromGs1.description = responseJson["Description"];
      var prodPicFromDB = responseJson["ProductImage"] != null
          ? responseJson["ProductImage"]
          : "https://image.shutterstock.com/z/stock-vector-avocado-green-flat-icon-on-white-background-434253583.jpg";
      productFromGs1.picLink = prodPicFromDB;
      productFromGs1.owner = responseJson["BrandOwner"];
      productFromGs1.type = null;

      print("fetched from gs1 product: ${responseJson["ProductName"]}");

      setState(() {
        product = productFromGs1;
      });
      return true;
    } else {
      print(responseJson["Message"]);
      return false;
    }
  }

  String _getSomeProdNameFromResponse(dynamic jsonResponse) {
    return jsonResponse["ProductName"] != null
        ? jsonResponse["ProductName"]
        : jsonResponse["Brand"] != null
            ? jsonResponse["Brand"]
            : jsonResponse["BrandOwner"] != null
                ? jsonResponse["BrandOwner"]
                : null;
  }

//---------------------------------- /GS1 DB -----------------------------------

  showProduct() {
    if (product != null) {
      print("create product\n${product.name}");
      var productInfoFromDB = "Product info:\n ";
      if (product.owner != null) productInfoFromDB += product.owner;
      if (product.owner != null || product.name != null) productInfoFromDB += "\n - product: \n";
      if (product.brand != null) productInfoFromDB += "${product.brand}";
      if (product.name != null) productInfoFromDB += "  ${product.name}";
      //    if (product.own != null)
      //      productInfoFromDB +=
      //      "\n - produced by:\n ${responseJson["Manufacturer"]}";
      setState(() {
        productInfo = productInfoFromDB;
        if (product.picLink != null) productPic = product.picLink;
      });
    }
  }

  _showNotFoundMsg() {
    print("product not found");
    setState(() {
      productInfo = "Product not found";
    });
  }
}
