import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:waste_none_app/app/add_product.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/settings_window.dart';
import 'package:waste_none_app/app/utils/fridge_util.dart';
import 'package:waste_none_app/app/utils/toast_util.dart';
import 'package:waste_none_app/common_widgets/item_qty_popup.dart';
import 'package:waste_none_app/services/local_nosql_cache.dart';
import 'package:waste_none_app/services/secure_storage.dart';
import 'package:waste_none_app/app/utils/validators.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/common_widgets/product_image.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/services/flutter_notification.dart';

import 'fridge_page.dart';
import 'fridge_page.dart';
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
  // String _productPicLink;
  // String _productPicPath;
  ProductImage _productImage;

  bool _loadingProductData = false;

  DateTime selectedDate = DateTime.now();
  DateTime defaultSelectedDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1);
  bool _productFetched = false;

  List<String> exampleEanCodes;
  int eanItemIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedDate = defaultSelectedDate;
    exampleEanCodes = [
      // '7630040403290',
      // '5054563003232',
      // '5900197022548',
      // '5900012005947',
      // '20645229',
      // '5900334012685',
      // '5449000133328',
      // '5901785301854',
      '5601009310333' //porto
    ];
    _scanAction();
    _productImage = ProductImage(newProduct: false);
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingIndicator = _loadingProductData ? LoadingIndicator() : Container();

    return Scaffold(
      appBar: AppBar(title: Text(welcomeText)),
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
                            height: MediaQuery.of(context).size.width * 0.30,
                            child: _productImage,
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
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: _productFetched,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  onPressed: () => _showQtyDialog(context), //_showQtyDialog(context),
                  label: Text("Add"),
                  icon: Icon(Icons.ac_unit),
                  heroTag: "addbut",
                ),
              ),
            ),
            Visibility(
              visible: _productFetched,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context), //_showQtyDialog(context),
                  label: Text("Cancel"),
                  icon: Icon(Icons.cancel_sharp),
                  heroTag: "cancel",
                ),
              ),
            ),
            Visibility(
              visible: !_productFetched,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  onPressed: () => _addNewProduct(), //_showQtyDialog(context),
                  label: Text("Add Manually"),
                  icon: Icon(Icons.add),
                  heroTag: "addProduct",
                ),
              ),
            ),
            Visibility(
              visible: !_productFetched,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  onPressed: () => _scanAction(), //_showQtyDialog(context),
                  label: Text("Scan Another"),
                  icon: Icon(Icons.camera),
                  heroTag: "scan",
                ),
              ),
            ),
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

  // final TextEditingController _qtyTextController = TextEditingController();
  //
  // String get _qty => _qtyTextController.text.trim();
  // bool _qtyChanged = false;
  //
  // void _qtyChangedState() {
  //   setState(() {
  //     _qtyChanged = true;
  //   });
  // }

//   _showQtyDialog(BuildContext context) async {
//     _qtyTextController.clear();
//     _qtyChanged = false;
//     await showDialog<String>(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             content: new Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextFormField(
//                     controller: _qtyTextController,
//                     inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
//                     keyboardType: TextInputType.number,
//                     autofocus: true,
//                     decoration: new InputDecoration(
//                       labelText: 'Add quantity',
//                       enabled: true,
//                       errorText: widget.qtyValidator.isValid(_qty) ? widget.qtyErrorText : null,
//                     ),
//                     onChanged: (qty) => _qtyChangedState,
// //                    validator: () => ProductQtyValueVaidator();
//                   ),
//                 )
//               ],
//             ),
//             actions: <Widget>[
//               new FlatButton(
//                   child: const Text('OK'),
//                   onPressed: () {
//                     _addItem();
//                   }),
//               new FlatButton(
//                   child: const Text('Cancel'),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   }),
//             ],
//           );
//         });
//   }
  _showQtyDialog(BuildContext context) async {
    int addQty = await showDialog<int>(
      context: context,
      builder: (context) => ItemQtySelectionPopup(
        titleText: 'Select quantity',
        maxQty: 99,
        defaultQty: 1,
      ),
    );
    WasteNoneLogger().d('addQty: $addQty');
    if (addQty != null) _addItem(addQty);
  }

  _addItem(int qty) async {
    FridgeItem fridgeItem = await _prepareFridgeItem(qty);
    await _addItemToFridgeAction(fridgeItem);
    Navigator.pop(context);
    _scanAction();
  }

  _addItemToFridgeAction(FridgeItem fridgeItem) async {
    if (product != null) {
      if (fridgeItem != null && !fridgeItem.isEmpty()) {
        FridgeItem existingSimilarItem = getSimilarItemInFridge(fridgeContent, fridgeItem);
        if (existingSimilarItem != null) {
          await _updateExistingItem(existingSimilarItem, fridgeItem);
          WasteNoneLogger().d("item updated");
        } else {
          await _addNewItem(fridgeItem);
          Map<String, dynamic> productJson = await getProductFromCacheByEANCode(fridgeItem.product_ean);
          Product product = Product.fromMap(productJson);
          if (product == null) product = await db.getProductByEanCode(fridgeItem.product_ean);
          if (product != null) FlutterNotification().addExpiryNotification(auth.currentUser(), product, fridgeItem);

          WasteNoneLogger().d("item added");
        }
        // FlutterNotification().showItemAddedNotification(fridge, product, fridgeItem);
        String fridgeName = fridge.displayName != null ? ' ${fridge.displayName}' : '';
        showGoodToast("Added ${product.name} to your fridge$fridgeName.");
      }
      if (mounted) {
        setState(() {
          productInfo = "";
          _productImage = null;
        });
      }
      selectedDate = defaultSelectedDate;
    }
  }

  Future<void> _updateExistingItem(FridgeItem existingSimilarItem, FridgeItem fridgeItem) async {
    fridgeContent.remove(existingSimilarItem);
    existingSimilarItem.qty += fridgeItem.qty;
    String encryptionPassword = await readEncryptionPassword(auth.currentUser().uid);
    String encryptedUpdatedFridgeItem = existingSimilarItem.asEncodedString(encryptionPassword);
    // db.updateEncryptedFridgeItem(existingSimilarItem.fridge_id, existingSimilarItem.dbKey, encryptedUpdatedFridgeItem);
    db.updateFridgeItem(existingSimilarItem);
    fridgeContent.add(existingSimilarItem);
  }

  Future<void> _addNewItem(FridgeItem fridgeItem) async {
    //db.addToFridge(fridgeItem, wasteNoneUser.uid);
    // String encryptionPassword = await readEncryptionPassword(auth.currentUser().uid);
    // String encryptedFridgeItem = fridgeItem.asEncodedString(encryptionPassword);
    // String dbKey = await db.addToFridgeEncrypted(encryptedFridgeItem, fridgeItem.fridge_id);
    String dbKey = await db.addToFridge(fridgeItem, user.uid);
    fridgeItem.dbKey = dbKey;
    fridgeContent.add(fridgeItem);
  }

  Future<FridgeItem> _prepareFridgeItem(int qty) async {
    FridgeItem fridgeItem = FridgeItem();
    fridgeItem.fridge_id = fridge.fridgeID;
    fridgeItem.product_ean = product?.eanCode;
    fridgeItem.qty = qty;
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
    WasteNoneLogger().d(productInfo);
    var eanCode = result.rawContent.toString();
    return eanCode;
  }

  void _scanAction() async {
    String eanCode = await _scanBarCode();
    // String eanCode = exampleEanCodes[eanItemIndex];
    // eanItemIndex = eanItemIndex % exampleEanCodes.length;

    _loadingProductData = true;

    _productFetched = await _fetchFromLocalCache(eanCode);
    WasteNoneLogger().d("product found in local cache: $_productFetched");

    if (!_productFetched) {
      _productFetched = await _fetchFromWasteNoneDB(eanCode);
      WasteNoneLogger().d("product found in WasteNone database: $_productFetched");
      if (!_productFetched) {
        _productFetched = await _lookUpInExtDB(eanCode);
        WasteNoneLogger().d("product found in external database: $_productFetched");

        //add to the WasteNone database
        if (product != null) db.addProduct(product);
      }
      //add to user cache
      if (product != null) storeProductToLocalCache(product);
    }

    if (_productFetched)
      setProductInfo();
    else
      _showNotFoundMsg(eanCode);

    _loadingProductData = false;
  }

//---------------------------------- /scan item --------------------------------

  Future<bool> _fetchFromLocalCache(String eanCode) async {
    var productJson = await getProductFromCacheByEANCode(eanCode);
    if (productJson != null) {
      // if (mounted)
      setState(() {
        product = Product.fromMap(productJson);
      });
      return true;
    } else
      return false;
  }
//---------------------------------- WN DB -------------------------------------

  Future<bool> _fetchFromWasteNoneDB(String eanCode) async {
    WasteNoneLogger().d("about to fetch product data from WasteNone DB");
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

//-------------------------------- PRODUCT DB ----------------------------------

  Future<bool> _lookUpInExtDB(String eanCode) async {
    WasteNoneLogger().d("about to fetch product data from external DB");
    final uri = "https://world.openfoodfacts.org/api/v0/product/";
    final uriWithEan = '$uri$eanCode.json';

    Response response = await get('$uriWithEan', headers: <String, String>{'format': 'json'});

    final responseJson = json.decode(response.body);
    final productJson = responseJson["product"];

    WasteNoneLogger().d(uriWithEan);
    WasteNoneLogger().d(response.statusCode);
    WasteNoneLogger().d(response.body);
    if (response.statusCode == 200 && responseJson["status_verbose"] == 'product found') {
      WasteNoneLogger().d(response.body);

      Product productFromGs1 = Product(eanCode);
      productFromGs1.name = _getSomeProdNameFromResponse(productJson);
      productFromGs1.brand = productJson["brands"];
      productFromGs1.ingredients = productJson["ingredients_text"];
      var prodPicFromDB = productJson["image_front_url"] != null
          ? productJson["image_front_url"]
          : "https://image.shutterstock.com/z/stock-vector-avocado-green-flat-icon-on-white-background-434253583.jpg";
      productFromGs1.picLink = prodPicFromDB;
      productFromGs1.size = productJson["quantity"] != null ? productJson["quantity"] : productJson["serving_size"];
      productFromGs1.type = null;

      WasteNoneLogger().d("fetched from external db product: ${productJson["product_name"]}");

      setState(() {
        product = productFromGs1;
      });
      return true;
    } else {
      WasteNoneLogger().d("Product not found :(");
      return false;
    }
  }

  String _getSomeProdNameFromResponse(dynamic jsonResponse) {
    return jsonResponse["product_name"] != null
        ? jsonResponse["product_name"]
        : jsonResponse["brands"] != null
            ? jsonResponse["brands"]
            : jsonResponse["BrandOwner"] != null
                ? jsonResponse["BrandOwner"]
                : null;
  }

//-------------------------------- /PRODUCT DB -----------------------------------

//------------------------------- ADD NEW PRODUCT --------------------------------

  void _addNewProduct() async {
    WasteNoneLogger().d('add new product manually');
    Product newProduct = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddProductPage(
                  auth: auth,
                  db: db,
                  user: user,
                  newProduct: product != null ? product : Product(null),
                ))).whenComplete(() => {WasteNoneLogger().d('product added..')});
    setState(() {
      product = newProduct;
      if (newProduct?.picPath != null) _productImage = ProductImage(newProduct: false, picFilePath: newProduct.picPath);
    });
    setProductInfo();
  }

//------------------------------- /ADD NEW PRODUCT -------------------------------

  setProductInfo() {
    if (product != null) {
      WasteNoneLogger().d("create product\n${product.name}");
      var productInfoFromDB = ""; //""Productct info:\n ";

      if (product.brand != null) productInfoFromDB += "${product.brand}\n";
      if (product.name != null) productInfoFromDB += "  ${product.name}";
      if (product.size != null) productInfoFromDB += " \n  ${product.size}";

      if (mounted)
        setState(() {
          productInfo = productInfoFromDB;
          _productImage = ProductImage(newProduct: false, picLink: product.picLink, picFilePath: product.picPath);
          _productFetched = true;
        });
    }
  }

  _showNotFoundMsg(String eanCode) {
    WasteNoneLogger().d("product not found :(");
    if (mounted)
      setState(() {
        productInfo = "Product not found :(";
        product = Product(eanCode);
      });
  }
}
