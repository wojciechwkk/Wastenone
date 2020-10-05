import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:waste_none_app/app/scan_and_add.dart';
import 'package:waste_none_app/app/settings_window.dart';
import 'package:waste_none_app/app/utils/cryptography_util.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';
import 'package:waste_none_app/app/utils/validators.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/common_widgets/product_image.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';

import 'models/fridge.dart';
import 'models/product.dart';
import 'models/user.dart';

class FridgePage extends StatefulWidget with ProductQtyValidator {
  FridgePage(
      {@required this.auth, @required this.db, @required this.userStreamCtrl});

  final AuthBase auth;
  final WNFirebaseDB db;
  final StreamController userStreamCtrl;

  @override
  State<StatefulWidget> createState() {
    return FridgePageState(
        auth: this.auth, db: this.db, userStreamCtrl: this.userStreamCtrl);
  }
}

class FridgePageState extends State<FridgePage> {
  FridgePageState(
      {@required this.auth, @required this.db, @required this.userStreamCtrl});

  final AuthBase auth;
  final WNFirebaseDB db;
  final StreamController userStreamCtrl;

  WasteNoneUser user;
  Fridge currentFridge;

//  int currentFridgeNo = 1; //default value ugly hardcode
//  String fridgeID;

  int fridgeItemCount;
  List<FridgeItem> usersCurrentFridgeItems;
  Map<String, Product> usersCurrentProducts;
  bool _loadingUserData = false;

  String welcomeText = "WasteNone";
  String exampleText;

  //---------------------------- initial load data -----------------------------
  @override
  initState() {
    super.initState();
    _loadingUserData = true;
    fridgeItemCount = 0;
    //_fetchUserdata().then((value) => _fetchUserFridgeData());
  }

  final AsyncMemoizer _memoizer = AsyncMemoizer();

  initUserData() {
    return this._memoizer.runOnce(() async {
      await _fetchUserdata();
      await _fetchUserFridgeData();
    });
  }

  Future<void> _fetchUserdata() async {
    WasteNoneUser fetchedUser = auth.currentUser();
    String usersUID = fetchedUser.uid;
    String displayName = fetchedUser.displayName;
    String welcomeString = 'Hi, $displayName';
    print(welcomeString);
    print('fetch user data from db for: ${fetchedUser.toJson()}');
    // WasteNoneUser userFromDB = await db.getUserData(fetchedUser.uid);
    String encryptedUserData = await db.getUserData(fetchedUser.uid);
    String encryptionPassword = await readEncryptionPassword(fetchedUser.uid);
    print('about to decrypt user data for ${fetchedUser.displayName}');
    String decryptedFridgeItem =
        decryptAESCryptoJS(encryptedUserData, encryptionPassword);

    WasteNoneUser userFromDB = WasteNoneUser.fromMap(
        fetchedUser.dbRef, jsonDecode(decryptedFridgeItem));
    print('full fetch ${userFromDB?.toJson()}');

    Fridge fetchedFridge = await db.getFridge("$usersUID-1");
    print(fetchedFridge?.toJson());

    setState(() {
      if (mounted) {
        user = userFromDB;
        welcomeText = welcomeString;
        currentFridge = fetchedFridge;
      }
    });

//    }
  }

  Future<void> _fetchUserFridgeData() async {
    LinkedHashMap<String, Product> products = LinkedHashMap<String, Product>();

    List<FridgeItem> fetchedFridgeItems = null;
    // List<FridgeItem> fetchedFridgeItems =
    //     await db?.getFridgeContent(currentFridge?.fridgeID, user.uid);
    Map<String, String> fetchedEncryptedFridgeItems =
        await db?.getFridgeEncryptedContent(currentFridge?.fridgeID, user.uid);
    if (fetchedEncryptedFridgeItems != null) {
      String encryptionPassword = await readEncryptionPassword(user.uid);
      fetchedFridgeItems =
          decryptFridgeList(fetchedEncryptedFridgeItems, encryptionPassword);
      if (fetchedFridgeItems == null) {
        print("your fridge is empty");
      } else {
        print("recognized fridge: ${currentFridge?.fridgeID}");

        print("found ${fetchedFridgeItems?.length} items in the fridge");
        if (fetchedFridgeItems?.iterator != null) {
          for (FridgeItem fetchedFridgeItem in fetchedFridgeItems) {
            Product product =
                await _getProductsDetails(fetchedFridgeItem?.product_puid);
            products[fetchedFridgeItem?.product_puid] = product;
          }
        }
      }
    }
    setState(() {
      if (mounted) {
        usersCurrentFridgeItems = fetchedFridgeItems;
        fridgeItemCount = usersCurrentFridgeItems?.length;
        usersCurrentProducts = products;
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

    var indexOfFridge = user?.getFridgeIDs()?.indexOf(currentFridge?.fridgeID);
//    indexOfFridge++;
    final fridgeLabel = currentFridge?.displayName != null
        ? currentFridge.displayName
        : indexOfFridge != null
            ? "fridge ${indexOfFridge + 1}"
            : "fridge";

    return FutureBuilder(
      future: this.initUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(welcomeText), actions: <Widget>[
              // FlatButton(
              // child: Text('Logout', style: TextStyle(fontSize: 18)),
              // onPressed: _logOut)

              PopupMenuButton<String>(
                onSelected: _appBarSettingsClick,
                itemBuilder: (BuildContext context) {
                  return {'Settings', 'Logout'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              ),
            ]),
            body: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: ListView.builder(
                    itemCount:
                        fridgeItemCount != null ? fridgeItemCount + 1 : 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return _sliderHeaderWidget(fridgeLabel);
                      }
                      if (usersCurrentFridgeItems != null) {
                        index--;
                        Product productDetails = usersCurrentProducts[
                            usersCurrentFridgeItems[index]?.product_puid];
                        String productName = "${productDetails?.name}";
                        int qty = usersCurrentFridgeItems[index]?.qty;
                        String description =
                            "${usersCurrentFridgeItems[index]?.validDate} ";
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        } else {
          return LoadingIndicator();
        }
      },
    );
  }

  void _appBarSettingsClick(String value) {
    switch (value) {
      case 'Logout':
        _logOut();
        break;
      case 'Settings':
        _showSettingsPopup();
        break;
    }
  }

  void _showSettingsPopup() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SettingsWindow(
                  auth: auth,
                  db: db,
                  user: user,
                ))); //.whenComplete(() => ());
  }

  Widget _sliderHeaderWidget(String fridgeName) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32.0, right: 32.0),
      child: InkWell(
        onTap: () => _showNextFridge(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Slidable(
            key: Key(fridgeName),
            actionPane: SlidableBehindActionPane(),
            actionExtentRatio: 0.25,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey[200],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Center(
                child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
//                Icon(Icons.arrow_left),
                          Icon(Icons.swap_vertical_circle),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('$fridgeName'),
                          ),
                        ])),
              ),
              // CircleAvatar(child: Text("x ${qty.toString()}"))),
            ),
            actions: <Widget>[
              IconSlideAction(
                caption: 'Add fridge',
                color: Colors.green,
                icon: Icons.add_box,
                onTap: () => _addNewFridge(), //_moveToAnotherFridgeSomeNumber
              ),
              IconSlideAction(
                caption: 'Edit label',
                color: Colors.indigo,
                icon: Icons.edit,
                onTap: () => _showFridgeLabelPopup(context),
              ),
            ],
            secondaryActions: <Widget>[
              IconSlideAction(
                caption: 'Delete fridge',
                color: Colors.red,
                icon: Icons.delete,
                onTap: () =>
                    _deleteFridge(), //Navigator.of(context).pop('DeleteFridge'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showNextFridge() async {
    if (user?.getFridgeIDs()?.length > 1) {
//      print('currentFridge.fridgeID: ${currentFridge.fridgeID}');
      int currentFridgeListIndex =
          user?.getFridgeIDs()?.indexOf(currentFridge.fridgeID);
      var newFridgeNo =
          (currentFridgeListIndex + 1) % user?.getFridgeIDs()?.length;
//      print(
//          'currentFridgeListIndex: $currentFridgeListIndex, newFridgeId: $newFridgeNo');
//      print('change fridge from ${currentFridge.fridgeID} to $newFridgeNo');
      _showFridge(newFridgeNo);
    }
  }

  _showFridge(int newFridgeNo) async {
    if (mounted) {
      print('show user fridge no. $newFridgeNo');
      String nextFridgeID = user?.getFridgeIDs()[newFridgeNo];
      var fetchedCurrentFridge = await db.getFridge(nextFridgeID);
      setState(() {
        currentFridge = fetchedCurrentFridge;
        _fetchUserFridgeData();
      });
    }
  }

  final TextEditingController _fridgeLabelTextController =
      TextEditingController();

  String get _fridgeLabel => _fridgeLabelTextController.text.trim();
  bool _fridgeLabelChanged = false;

  void _fridgeLabelChangedState() {
    setState(() {
      _fridgeLabelChanged = true;
    });
  }

  _showFridgeLabelPopup(BuildContext context) async {
    _fridgeLabelTextController.clear();
    _fridgeLabelChanged = false;
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(
                  child: new TextFormField(
                    controller: _fridgeLabelTextController,
                    keyboardType: TextInputType.text,
                    autofocus: true,
                    decoration: new InputDecoration(
                      labelText: 'Add new fridge label',
                      enabled: true,
//                        errorText: widget.qtyValidator.isValid(_qty)
//                            ? widget.qtyErrorText
//                            : null,
                    ),
                    onChanged: (qty) => _fridgeLabelChangedState,
//                    validator: () => ProductQtyValueVaidator();
                  ),
                )
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('OK'),
                  onPressed: () {
                    _editFridgeLabel(
                        _fridgeLabelTextController.text.toString());
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

  Future<void> _editFridgeLabel(String newFridgeLabel) async {
    currentFridge.displayName = newFridgeLabel;
    print('change label to $newFridgeLabel');
    await db.updateFridge(currentFridge);
    _refreshCurrentFridge();
  }

  Future<void> _addNewFridge() async {
    if (user != null) {
      print(
          "add new fridge user: ${user.toJson()}, fridge count: ${user.fridgesAdded}");
      int newFridgeNo = user.fridgesAdded + 1;
      Fridge newFridge = Fridge("${user.uid}-$newFridgeNo", newFridgeNo);
      await db.addFridge(newFridge);
      user.addFridgeID(newFridge.fridgeID);

      String usersEncryptionPass = await readEncryptionPassword(user.uid);
      db.updateUser(user, user.asEncodedString(usersEncryptionPass));

      currentFridge = newFridge;
      _showFridge(user.getFridgeIDs().indexOf(newFridge.fridgeID));
    }
  }

  Future<void> _deleteFridge() async {
    print('delete fridge ${currentFridge.fridgeID}');
    var usersIndexOfFridge =
        user.getFridgeIDs().indexOf(currentFridge.fridgeID);
    if (usersIndexOfFridge == 0) {
//      var fridgeId = '${user.uid}-$currentFridgeNo';
      db.emptyFridge(currentFridge.fridgeID);
      _showFridge(usersIndexOfFridge);
    } else {
      db.deleteFridge(currentFridge.fridgeID);
      user.removeFridgeID(currentFridge.fridgeID);
      String usersEncryptionPass = await readEncryptionPassword(user.uid);
      db.updateUser(user, user.asEncodedString(usersEncryptionPass));
      _showFridge(--usersIndexOfFridge);
    }
  }

  Widget _sliderFridgeItemWidget(String productLink, String productName,
      String description, int index, int qty) {
    return Slidable(
      actionPane: SlidableScrollActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
          color: Colors.white,
          child: ListTile(
              onTap: () => {
                    Slidable.of(context)
                        ?.open(actionType: SlideActionType.primary),
                  },
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
              leading: ProductImage(picLink: productLink),
              //title: Text('Tile n°$index'),
              title: Text(productName),
              subtitle: Text(description),
              trailing: Container(
                width: 45,
                margin: new EdgeInsets.all(2.0),
                alignment: Alignment(0.0, 0.0),
                child: Text(
                  "x${qty.toString()}",
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.blueGrey[200],
                ),
              ))
          // CircleAvatar(child: Text("x ${qty.toString()}"))),
          ),
      actions: <Widget>[
        IconSlideAction(
          caption: 'Change date',
          color: Colors.blue,
          icon: Icons.date_range,
          onTap: () => _showChangeDateDialog(
              context, index), //_moveToAnotherFridgeSomeNumber
        ),
        IconSlideAction(
          caption: 'Change qty',
          color: Colors.indigo,
          icon: Icons.content_cut,
          onTap: () => _showQtyDialog(
              context, index), //Navigator.of(context).pop('Share'),
        ),
      ],
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Move',
          color: Colors.green,
          icon: Icons.call_split,
          onTap: () => _showMoveToAnotherFridgePopup(
              index, context), //_moveToAnotherFridgeSomeNumber
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => _deleteFridgeItem(index),
        ),
      ],
    );
  }

  Future<void> _changeFridgeItemDate(int index) async {
    print('changeFridgeItemDate');
    FridgeItem fridgeItem = usersCurrentFridgeItems[index];
    fridgeItem.validDate =
        '${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}';

    // await db.updateFridgeItem(fridgeItem);
    String usersEncryptionPass = await readEncryptionPassword(user.uid);

    String encryptedFridgeItem =
        fridgeItem.asEncodedString(usersEncryptionPass);
    await db.updateEncryptedFridgeItem(
        fridgeItem.fridge_no, fridgeItem.dbKey, encryptedFridgeItem);
    _refreshCurrentFridge();
  }

  DateTime selectedDate;
  _dateChanged(DateTime picked) {
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
    return null;
  }

  _showChangeDateDialog(BuildContext context, int index) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child: CalendarDatePicker(
                firstDate: DateTime.now(),
                initialDate: new DateTime(DateTime.now().year,
                    DateTime.now().month, DateTime.now().day + 1),
                lastDate: DateTime(DateTime.now().year + 5,
                    DateTime.now().month, DateTime.now().day),
                initialCalendarMode: DatePickerMode.day,
                onDateChanged: _dateChanged,
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('OK'),
                  onPressed: () {
                    _changeFridgeItemDate(index);
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

  Future<void> _changeFridgeItemQty(int index, String newQty) async {
    print('changeFridgeItemQty');
    FridgeItem fridgeItem = usersCurrentFridgeItems[index];
    fridgeItem.qty = int.parse(newQty);
    // await db.updateFridgeItem(fridgeItem);
    String usersEncryptionPass = await readEncryptionPassword(user.uid);

    String encryptedFridgeItem =
        fridgeItem.asEncodedString(usersEncryptionPass);
    await db.updateEncryptedFridgeItem(
        fridgeItem.fridge_no, fridgeItem.dbKey, encryptedFridgeItem);
    _refreshCurrentFridge();
  }

  final TextEditingController _qtyTextController = TextEditingController();
  String get _qty => _qtyTextController.text.trim();
  bool _qtyChanged = false;
  void _qtyChangedState() {
    setState(() {
      _qtyChanged = true;
    });
  }

  _showQtyDialog(BuildContext context, int index) async {
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
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: new InputDecoration(
                      labelText: 'Add new quantity',
                      enabled: true,
//                      errorText: widget.qtyValidator.isValid(_qty)
//                          ? widget.qtyErrorText
//                          : null,
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
                    _changeFridgeItemQty(
                        index, _qtyTextController.text.toString());
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

  Future<void> _deleteFridgeItem(int index) async {
    // await db.deleteFridgeItem(usersCurrentFridgeItems[index]);
    FridgeItem toBeDeletedFridgeItem = usersCurrentFridgeItems[index];
    await db.deleteEncryptedFridgeItem(
        toBeDeletedFridgeItem.fridge_no, toBeDeletedFridgeItem.dbKey);
    _refreshCurrentFridge();
  }

  final TextEditingController _fridgeIDToMoveItemToController =
      TextEditingController();
  String get _fridgeIDToMoveItemTo =>
      _fridgeIDToMoveItemToController.text.trim();
  bool _fridgeIDToMoveItemToChanged = false;
  void _fridgeIDToMoveItemToChangedState() {
    setState(() {
      _fridgeIDToMoveItemToChanged = true;
    });
  }

  _showMoveToAnotherFridgePopup(int indexx, BuildContext context) async {
    _fridgeIDToMoveItemToController.clear();
    _fridgeIDToMoveItemToChanged = false;
    List<Fridge> usersFridges = await db.getUsersFridges(user);
//    usersFridges.map((e) => print(e.toJson()));
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
//          if (user?.getFridgeIDs()?.length > 1) {
          return AlertDialog(
            content: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: user.getFridgeIDs().length * 55.0,
              child: ListView.builder(
                  itemCount: usersFridges.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (usersFridges[index].fridgeID !=
                        currentFridge.fridgeID) {
                      var text = usersFridges[index].displayName != null
                          ? 'fridge ${usersFridges[index].fridgeNo}: ${usersFridges[index].displayName}'
                          : 'fridge ${usersFridges[index].fridgeNo}';
                      return GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[200],
                            border: Border.all(color: Colors.white),
                          ),
                          height: 55,
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.call_split),
                              ),
                              Center(child: Text(text)),
                            ],
                          ),
                        ),
                        onTap: () => _moveItemToAnotherFridge(
                            indexx, usersFridges[index].fridgeID),
                      );
                    } else
                      return Container();
                  }),
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          );
//          } else {
//            print('You just got 1 fridge!');
//            return null;
//          }
        });
  }

  Future<void> _moveItemToAnotherFridge(int index, String fridgeID) async {
//    if (currentFridge.fridgeID != fridgeID) {
    print('move $index: ${usersCurrentFridgeItems[index].toJson()}');
    FridgeItem fridgeItem = usersCurrentFridgeItems[index];
    // await db.deleteFridgeItem(fridgeItem);
    await db.deleteEncryptedFridgeItem(fridgeItem.fridge_no, fridgeItem.dbKey);
    fridgeItem.fridge_no = fridgeID;
    // await db.addToFridge(fridgeItem, user.uid);

    String encryptionPassword = await readEncryptionPassword(user.uid);
    await db.addToFridgeEncrypted(
        fridgeItem.asEncodedString(encryptionPassword), fridgeItem.fridge_no);
    Navigator.pop(context);
    _refreshCurrentFridge();
//    }
  }

  //---------------------------- /flutter widgets ------------------------------

  Future<Product> _getProductsDetails(String puid) async {
    return await db.getProductByPUID(puid);
  }

  _refreshCurrentFridge() {
    _showFridge(user.getFridgeIDs().indexOf(currentFridge.fridgeID));
  }

  void _scanAndAdd() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ScanAndAdd(
                  auth: auth,
                  db: db,
                  fridgeId: currentFridge.fridgeID,
                ))).whenComplete(() => _fetchUserFridgeData());
  }

  Future<void> _logOut() async {
    try {
      if (user.isAnonymous()) {
        await db.deleteUser(user);
      }
      userStreamCtrl.sink.add(null);
      await auth.logOut();
    } catch (e) {
      print(e.toString());
    }
  }
}
