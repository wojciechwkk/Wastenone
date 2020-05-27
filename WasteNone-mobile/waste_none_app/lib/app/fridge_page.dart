import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:waste_none_app/app/scan_and_add/scan_and_add.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/common_widgets/product_image.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';

import 'models/product.dart';

class FridgePage extends StatefulWidget {
  FridgePage({@required this.auth, @required this.db});

  final AuthBase auth;
  final WNFirebaseDB db;

  @override
  State<StatefulWidget> createState() {
    return FridgePageState(auth: this.auth, db: this.db);
  }
}

class FridgePageState extends State<FridgePage> {
  FridgePageState({@required this.auth, @required this.db});

  final AuthBase auth;
  final WNFirebaseDB db;

  WasteNoneUser user;
  String fridgeID;
  int fridgeItemCount = 0;
  List<FridgeItem> usersFridgeItems;
  Map<String, Product> usersProducts;
  bool _loadingUserData = false;

  int usersFridgeNo = 1; //default value ugly hardcode
  String welcomeText = "WasteNone";
  String exampleText;

  //---------------------------- initial load data -----------------------------
  @override
  initState() {
    super.initState();
    _loadingUserData = true;
    _fetchUserdata().then((value) => _fetchUserFridgeData());
  }

  Future<void> _fetchUserdata() async {
    WasteNoneUser wasteNoneUser = await auth.currentUser();
    String usersUID = wasteNoneUser.uid;
    String displayName = wasteNoneUser.displayName;
    print('Hi, $displayName');

    setState(() {
      if (mounted) {
        welcomeText = "Hi, $displayName";
        fridgeID = "$usersUID-$usersFridgeNo";
      }
    });
  }

  _fetchUserFridgeData() async {
    LinkedHashMap<String, Product> products = LinkedHashMap<String, Product>();
    List<FridgeItem> fetchedFridgeItems = await db?.getFridgeContent(fridgeID);
    if (fetchedFridgeItems == null) {
      print("your fridge is empty");
    } else {
      print("recognized fridge: $fridgeID");

      print("found ${fetchedFridgeItems.length} items in the fridge");
      if (fetchedFridgeItems?.iterator != null) {
        for (FridgeItem fetchedFridgeItem in fetchedFridgeItems) {
          Product product =
              await _getProductsDetails(fetchedFridgeItem.product_puid);
          products[fetchedFridgeItem.product_puid] = product;
        }
      }
    }
    setState(() {
      if (mounted) {
        usersFridgeItems = fetchedFridgeItems;
        fridgeItemCount = usersFridgeItems?.length;
        usersProducts = products;
        _loadingUserData = false;
      }
    });
  }

  //---------------------------- /initial load data ----------------------------

  //---------------------------- flutter widgets -------------------------------

  @override
  Widget build(BuildContext context) {
    Widget loadingIndicator =
        _loadingUserData ? LoadingIndicator() : Container();

    return Scaffold(
      appBar: AppBar(title: Text(welcomeText), actions: <Widget>[
        FlatButton(
            child: Text('Logout', style: TextStyle(fontSize: 18)),
            onPressed: _logOut)
      ]),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ListView.builder(
              itemCount: fridgeItemCount,
              itemBuilder: (BuildContext context, int index) {
                if (usersFridgeItems != null) {
                  Product productDetails =
                      usersProducts[usersFridgeItems[index]?.product_puid];
                  String productName = "${productDetails?.name}";
                  int qty = usersFridgeItems[index]?.qty;
                  String description = "${usersFridgeItems[index]?.validDate} ";
                  String productLink = productDetails?.picLink;

                  return _sliderFridgeItemWidget(
                      productLink, productName, description, index, qty);
                } else
                  return null;
              },
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton.extended(
                onPressed: _loadingUserData ? null : _scanAndAdd,
                label: Text("Scan and Add"),
                icon: Icon(Icons.camera),
              ),
            ),
          ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _sliderFridgeItemWidget(String productLink, String productName,
      String description, int index, int qty) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
          color: Colors.white,
          child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
              leading: ProductImage(picLink: productLink),
              //title: Text('Tile n°$index'),
              title: Text(productName),
              subtitle: Text(description),
              trailing: Container(
                width: 45,
                margin: new EdgeInsets.all(4.0),
                alignment: Alignment(0.0, 0.0),
                child: Text(
                  "x${qty.toString()}",
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.blueGrey,
                ),
              ))
          // CircleAvatar(child: Text("x ${qty.toString()}"))),
          ),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Change date',
          color: Colors.blue,
          icon: Icons.date_range,
          onTap: () => null, //_moveToAnotherFridgeSomeNumber
        ),
        IconSlideAction(
          caption: 'Change qty',
          color: Colors.indigo,
          icon: Icons.content_cut,
          onTap: () => Navigator.of(context).pop('Share'),
        ),
      ],
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Move',
          color: Colors.green,
          icon: Icons.call_split,
          onTap: () => null, //_moveToAnotherFridgeSomeNumber
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => Navigator.of(context).pop('Delete'),
        ),
      ],
    );
  }

  //---------------------------- /flutter widgets ------------------------------

  Future<Product> _getProductsDetails(String puid) async {
    return await db.getProductByPUID(puid);
  }

  void _scanAndAdd() {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ScanAndAdd(auth: auth, db: db)))
        .whenComplete(() => _fetchUserFridgeData());
  }

  Future<void> _logOut() async {
    try {
      await auth.logOut();
    } catch (e) {
      print(e.toString());
    }
  }
}
