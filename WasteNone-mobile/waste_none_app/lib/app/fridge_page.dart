import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:waste_none_app/app/models/invite.dart';
import 'package:waste_none_app/app/scan_and_add.dart';
import 'package:waste_none_app/app/settings_window.dart';
import 'package:waste_none_app/app/utils/cryptography_util.dart';
import 'package:waste_none_app/app/utils/fridge_util.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';
import 'package:waste_none_app/app/utils/toast_util.dart';
import 'package:waste_none_app/common_widgets/item_qty_popup.dart';
import 'package:waste_none_app/services/local_nosql_cache.dart';
import 'package:waste_none_app/services/secure_storage.dart';
import 'package:waste_none_app/app/utils/validators.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/common_widgets/product_image.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/services/flutter_notification.dart';

import 'models/fridge.dart';
import 'models/product.dart';
import 'models/user.dart';

class FridgePage extends StatefulWidget with ProductQtyValidator {
  FridgePage({@required this.auth, @required this.db, @required this.userStreamCtrl});

  final AuthBase auth;
  final WNFirebaseDB db;
  final StreamController userStreamCtrl;

  @override
  State<StatefulWidget> createState() {
    return FridgePageState(auth: this.auth, db: this.db, userStreamCtrl: this.userStreamCtrl);
  }
}

class FridgePageState extends State<FridgePage> {
  FridgePageState({@required this.auth, @required this.db, @required this.userStreamCtrl});

  final AuthBase auth;
  final WNFirebaseDB db;
  final StreamController userStreamCtrl;

  WasteNoneUser user;
  List<Fridge> _usersFridges;
  Fridge _currentFridge;
  WasteNoneUser _sharedBy;

  int fridgeItemCount;
  List<FridgeItem> _usersCurrentFridgeItems;
  Map<String, Product> usersCurrentProducts;
  bool _loadingUserData = false;

  String welcomeText = "WasteNone";
  String exampleText;
  DateTime _notifyDate;

  //---------------------------- initial load data ---------------------------------------------------------------------
  @override
  initState() {
    super.initState();
    _loadingUserData = true;
    fridgeItemCount = 0;
  }

  final AsyncMemoizer _memoizer = AsyncMemoizer();

  initUserData() {
    return this._memoizer.runOnce(() async {
      await _fetchUserdata();
      await _fetchUserFridgeData();
      await _checkForFridgeShareInvites();
    });
  }

  Future<void> _fetchUserdata() async {
    WasteNoneUser fetchedUser = auth.currentUser();
    String usersUID = fetchedUser.uid;
    String displayName = fetchedUser.displayName;
    String welcomeString = 'Hi, $displayName';
    WasteNoneLogger().d(welcomeString);
    //WasteNoneLogger().d('fetch user data from db for: ${fetchedUser.toJson()}');
    // WasteNoneUser userFromDB = await db.getUserData(fetchedUser.uid);
    WasteNoneUser userFromDB = await db.getUserData(fetchedUser.uid);
    // String encryptedUserData = userFromDb["userData"];
    // String dbKey = userFromDb["dbKey"];
    // String encryptionPassword = await readEncryptionPassword(fetchedUser.uid);
    // WasteNoneLogger().d('about to decrypt user data for ${fetchedUser.displayName}');
    // String decryptedUserData = decryptAESCryptoJS(encryptedUserData, encryptionPassword);
    // WasteNoneUser userFromDB = WasteNoneUser.fromMap(dbKey, jsonDecode(decryptedUserData));
    WasteNoneLogger().d('full fetched user ${userFromDB?.toJson()}');

    Fridge fetchedFridge = await db.getFridge("$usersUID-1");
    //WasteNoneLogger().d(fetchedFridge?.toJson());
    List<Fridge> userFridges = new List<Fridge>();
    for (String fridgeID in userFromDB.getFridgeIDs()) {
      Fridge fridge = await db.getFridge(fridgeID);
      userFridges.add(fridge);
    }
    // List<Fridge> userFridges = await db.getUsersFridges(userFromDB);
    userFridges.forEach((element) {
      WasteNoneLogger().d(element.fridgeID);
    });
    userFridges.sort();

    if (mounted) {
      setState(() {
        user = userFromDB;
        welcomeText = welcomeString;
        _currentFridge = userFridges[0];
        _usersFridges = userFridges;
      });
    }

//    }
  }

  DateTime _setNotifyDate() {
    double _notifyAtForWidget = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_HRS, user.uid), 8);
    double _notifyDaysBefore = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_DAYS, user.uid), 2);
    DateTime notifyDateWithTime = DateTime.now().add(Duration(days: _notifyDaysBefore.toInt()));
    return DateTime(notifyDateWithTime.year, notifyDateWithTime.month, notifyDateWithTime.day);
  }

  Future<void> _fetchUserFridgeData() async {
    LinkedHashMap<String, Product> products = LinkedHashMap<String, Product>();
    List<FridgeItem> fetchedFridgeItems = await db.getFridgeContent(_currentFridge.fridgeID);
    //await fetchAndDescryptFridge(db, _currentFridge.fridgeID, user);
    if (fetchedFridgeItems?.iterator != null) {
      for (FridgeItem fetchedFridgeItem in fetchedFridgeItems) {
        Product product = await _getProductsDetails(fetchedFridgeItem?.product_ean);
        products[fetchedFridgeItem?.product_ean] = product;
      }
    }
    // WasteNoneLogger().d('fetched');
    if (mounted) {
      setState(() {
        fetchedFridgeItems.sort();
        _usersCurrentFridgeItems = fetchedFridgeItems;
        fridgeItemCount = _usersCurrentFridgeItems?.length;
        usersCurrentProducts = products;
        _loadingUserData = false;
        _notifyDate = _setNotifyDate();
      });
    }
  }

  Future _checkForFridgeShareInvites() async {
    List<ShareFridgeInvite> pendingInvites = await db.getAwaitingInvites(user.uid);
    if (pendingInvites != null) {
      WasteNoneLogger().d('You got ${pendingInvites.length} pending invites!');
      for (ShareFridgeInvite invite in pendingInvites) {
        WasteNoneLogger().d(invite.toJson());
        WasteNoneUser user = await db.getUserData(invite.senderUID);
        if (user != null) {
          bool accepted =
              await Navigator.push(context, MaterialPageRoute(builder: (context) => ShareFridgeInvitePopup(user)));
          if (accepted) {
            Fridge newSharedFridge = await db.getFridge(invite.fridgeID);
            _addFridgeForUser(newSharedFridge);
          }
          await db.removeShareFridgeInvite(invite);
        }
      }
    }
  }
  //---------------------------- /initial load data --------------------------------------------------------------------

  //---------------------------- flutter widgets -----------------------------------------------------------------------

  String buildFridgeLabel() {
    String fridgeLabel = '';

    if (_currentFridge != null && user != null) {
      if (_isSomeonesSharedFridge()) {
        if (_sharedBy != null && _sharedBy.displayName != null) {
          String sharedByLabelPart;
          if (_sharedBy.displayName.contains(" "))
            sharedByLabelPart =
                '${_sharedBy.displayName.split(" ").first} ${_sharedBy.displayName.split(" ")[1].substring(0, 2)}';
          else
            sharedByLabelPart =
                _sharedBy.displayName.length > 20 ? _sharedBy.displayName.substring(0, 25) : _sharedBy.displayName;
          fridgeLabel = '[$sharedByLabelPart] ';
        }
      }
      var indexOfFridge = _usersFridges?.indexOf(_currentFridge);
      fridgeLabel += _currentFridge?.displayName != null
          ? _currentFridge.displayName
          : indexOfFridge != null
              ? "fridge ${indexOfFridge + 1}"
              : "unknown fridge";

      return fridgeLabel;
    }
    return "";
  }

  bool _isSomeonesSharedFridge() {
    return !_currentFridge.fridgeID.startsWith(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingIndicator = _loadingUserData ? LoadingIndicator() : Container();

    final fridgeLabel = buildFridgeLabel();

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
                // usersCurrentProducts.length != 0
                RefreshIndicator(
                    onRefresh: () => _refreshCurrentFridge(),
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: ListView.builder(
                        itemCount: fridgeItemCount != null ? fridgeItemCount + 1 : 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return _sliderHeaderWidget(fridgeLabel);
                          }
                          if (_usersCurrentFridgeItems != null) {
                            index--;
                            Product productDetails = usersCurrentProducts[_usersCurrentFridgeItems[index]?.product_ean];
                            String productName = "${productDetails?.name}";
                            int qty = _usersCurrentFridgeItems[index]?.qty;
                            String description = "${_usersCurrentFridgeItems[index]?.validDate} ";
                            ProductImage productImage = ProductImage(
                              newProduct: false,
                              picLink: productDetails.picLink,
                              picFilePath: productDetails.picPath,
                            );
                            return _sliderFridgeItemWidget(productImage, productName, description, index, qty);
                          } else
                            return null;
                        },
                      ),
                    )),
                // : Center(child: loadingIndicator),
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
                    visible: snapshot.connectionState == ConnectionState.done,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton.extended(
                        onPressed: _loadingUserData ? null : _scanAndAdd,
                        label: Text("Scan and Add"),
                        icon: Icon(Icons.camera),
                      ),
                    ),
                  ),
                ]),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
          //notificationsPlugin: notificationsPlugin,
        ),
      ),
    ).whenComplete(() => _fetchUserFridgeData());
  }

  Widget _sliderHeaderWidget(String fridgeName) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32.0, right: 32.0),
      child: InkWell(
        onTap: () => _showNextFridge(),
        onLongPress: () => _showAllFridgesToGoToPopup(context),
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
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
//                Icon(Icons.arrow_left),
                      SizedBox(height: 25, child: Image.asset('images/wastenone_icon.jpg')),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('$fridgeName'),
                      ),
                      Icon(Icons.swap_vertical_circle),
                    ])),
              ),
              // CircleAvatar(child: Text("x ${qty.toString()}"))),
            ),
            actions: <Widget>[
              IconSlideAction(
                caption: 'Add fridge',
                color: Colors.green,
                icon: Icons.add_box,
                onTap: () => _addNewFridge(),
              ),
              IconSlideAction(
                caption: 'Edit label',
                color: Colors.indigo,
                icon: Icons.edit,
                onTap: () => _showEditFridgeLabelPopup(context),
              ),
            ],
            secondaryActions: <Widget>[
              IconSlideAction(
                caption: 'Share fridge',
                color: Colors.blue,
                icon: Icons.share_outlined,
                onTap: _shareFridgeAction,
              ),
              IconSlideAction(
                caption: 'Delete fridge',
                color: Colors.red,
                icon: Icons.delete,
                onTap: _deleteFridge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _shareFridgeAction() async {
    if (user.isAnonymous())
      showShortBadToast("Only for logged in users!");
    else {
      String email = await showDialog<String>(
        context: context,
        builder: (context) => ShareFridgeEmailInputPopup(),
      );
      if (email != null) {
        WasteNoneLogger().d('share fridge with: $email');
        WasteNoneUser receiveUser = await db.getUserByEmail(email);
        if (receiveUser == null) {
          showLongBadToast("Whops! There is no WasteNone user with this email (but we all know there should! ;))");
        } else {
          bool inviteAlreadyExists = await _inviteExists(receiveUser);
          if (inviteAlreadyExists)
            showShortBadToast("This invitation already exists.");
          else {
            _sendShareInvite(receiveUser);
            showGoodToast("Invitation sent to user: $email");
          }
        }
      }
    }
  }

  Future<bool> _inviteExists(WasteNoneUser receiveUser) async {
    return await db.invitationExists(ShareFridgeInvite(user.uid, receiveUser.uid, _currentFridge.fridgeID));
  }

  _sendShareInvite(WasteNoneUser receiveUser) async {
    db.inviteUserToShareFridge(ShareFridgeInvite(user.uid, receiveUser.uid, _currentFridge.fridgeID));
  }

  _showPreviousFridge() async {
    if (_usersFridges.length > 1) {
      int currentFridgeListIndex = _usersFridges.indexOf(_currentFridge);
      int newFridgeNo = currentFridgeListIndex > 0 ? currentFridgeListIndex - 1 : _usersFridges.length - 1;
      _showFridge(_usersFridges[newFridgeNo].fridgeID);
    }
  }

  _showNextFridge() async {
    if (_usersFridges.length > 1) {
      int currentFridgeListIndex = _usersFridges.indexOf(_currentFridge);
      int newFridgeNo = (currentFridgeListIndex + 1) % _usersFridges.length;
      _showFridge(_usersFridges[newFridgeNo].fridgeID);
    }
  }

  _showAllFridgesToGoToPopup(BuildContext context) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: _usersFridges.length * 53.0,
              child: ListView.builder(
                  itemCount: _usersFridges.length,
                  itemBuilder: (BuildContext context, int index) {
                    var text = _usersFridges[index].displayName != null
                        ? '${_usersFridges[index].displayName}'
                        : 'fridge ${index + 1}'; //${usersFridges[index].fridgeNo}';
                    return GestureDetector(
                      child: getFridgeListItemBox(text),
                      onTap: () {
                        Navigator.pop(context);
                        // _showFridge(usersFridges[index].fridgeNo);
                        _showFridge(_usersFridges[index].fridgeID);
                      },
                    );
                  }),
            ),
            actions: <Widget>[
              getCancelButton(context),
            ],
          );
        });
  }

  _showFridge(String fridgeID) async {
    var fridgeOwner = _currentFridge.fridgeID.substring(0, 28);
    WasteNoneUser sharingUser;
    if (fridgeOwner != user.uid) sharingUser = await db.getUserData(fridgeOwner);

    if (mounted) {
      WasteNoneLogger().d('show user fridge ID. $fridgeID');
      setState(() {
        _currentFridge = _usersFridges.firstWhere((element) => element.fridgeID == fridgeID);
        _sharedBy = sharingUser;
        _fetchUserFridgeData();
      });
    }
  }

  final TextEditingController _fridgeLabelTextController = TextEditingController();

  String get _fridgeLabel => _fridgeLabelTextController.text.trim();
  bool _fridgeLabelChanged = false;

  void _fridgeLabelChangedState() {
    setState(() {
      _fridgeLabelChanged = true;
    });
  }

  _showEditFridgeLabelPopup(BuildContext context) async {
    _fridgeLabelTextController.clear();
    _fridgeLabelChanged = false;
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Change fridge name:'),
            content: new Row(
              children: <Widget>[
                new Expanded(
                  child: new TextFormField(
                    controller: _fridgeLabelTextController,
                    keyboardType: TextInputType.text,
                    autofocus: true,
                    textAlign: TextAlign.right,
                    decoration: new InputDecoration(
                      labelText: 'New name',
                      enabled: true,
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
                    _editFridgeLabel(_fridgeLabelTextController.text.toString());
                    Navigator.pop(context);
                  }),
              getCancelButton(context),
            ],
          );
        });
  }

  Future<void> _editFridgeLabel(String newFridgeLabel) async {
    _currentFridge.displayName = newFridgeLabel;
    WasteNoneLogger().d('${_currentFridge.fridgeID} change label to $newFridgeLabel');
    await db.updateFridge(_currentFridge);
    // user.sortFridgeList();
    _usersFridges.firstWhere((element) => element.fridgeID == _currentFridge.fridgeID).displayName = newFridgeLabel;
    _refreshCurrentFridge();
    _sortUserFridges();
  }

  _sortUserFridges() {
    // if (mounted)
    setState(() {
      _usersFridges.sort();
      WasteNoneLogger().d('sorting:');
    });
  }

  Future<void> _addNewFridge() async {
    if (user != null) {
      if (user.getFridgeIDs().length < 9) {
        WasteNoneLogger().d("add new fridge user: ${user.toJson()}, fridge count: ${_usersFridges.length}");
        Fridge maxNoFridge = _usersFridges.reduce((max, element) => element.fridgeNo > max.fridgeNo ? element : max);
        int newFridgeNo = maxNoFridge.fridgeNo + 1;
        Fridge newFridge = Fridge("${user.uid}-$newFridgeNo", newFridgeNo);
        await db.addFridge(newFridge);

        _addFridgeForUser(newFridge);
      } else {
        WasteNoneLogger().d('User tried adding 10th fridge.');
        showShortBadToast("You can't have more than 9 fridges.");
      }
    }
  }

  _addFridgeForUser(Fridge usersNewFridge) {
    user.addFridgeID(usersNewFridge.fridgeID);
    db.updateUser(user);
    _usersFridges.add(usersNewFridge);
    _sortUserFridges();
    _currentFridge = usersNewFridge;
    _showFridge(usersNewFridge.fridgeID);
  }

  bool _firstDeletePress = true;
  Future<void> _deleteFridge() async {
    if (_firstDeletePress) {
      _firstDeletePress = false;
      WasteNoneLogger().d('delete fridge ${_currentFridge.fridgeID}');
      var currentIndex = _usersFridges.indexOf(_currentFridge);
      if (_usersFridges.length == 1) {
        db.emptyFridge(_currentFridge.fridgeID);
        _showFridge(_currentFridge.fridgeID);
      } else {
        db.deleteFridge(_currentFridge.fridgeID);
        user.removeFridgeID(_currentFridge.fridgeID);
        db.updateUser(user);

        _usersFridges.removeWhere((element) => element.fridgeID == _currentFridge.fridgeID);
        _sortUserFridges();
        //if we delete first one, show next, if we delete any other show previous
        int nextToShowIndex = currentIndex == 0 ? 0 : currentIndex - 1;
        _showFridge(_usersFridges[nextToShowIndex].fridgeID);
      }
      _firstDeletePress = true;
    }
  }

  Widget _sliderFridgeItemWidget(
      ProductImage productImage, String productName, String description, int index, int qty) {
    return Slidable(
      actionPane: SlidableScrollActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
          color: _setItemColor(description),
          child: ListTile(
              onTap: () => {
                    Slidable.of(context)?.open(actionType: SlideActionType.primary),
                  },
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
              leading: productImage,
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
          onTap: () => _showChangeDateDialog(context, index),
        ),
        IconSlideAction(
          caption: 'Change qty',
          color: Colors.indigo,
          icon: Icons.content_cut,
          onTap: () => _changeItemQty(context, index),
        ),
      ],
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Move',
          color: Colors.green,
          icon: Icons.call_split,
          onTap: () => _moveToAnotherFridge(index, context),
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

  Color _setItemColor(String date) {
    DateTime itemDate = new DateFormat("yyyy-MM-dd ").parse(date);
    DateTime nowDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    //WasteNoneLogger().d('setColor: $notifyDate vs. $date: $itemDate');
    return nowDate.compareTo(itemDate) > 0
        ? Colors.lightGreen[300]
        : nowDate == itemDate
            ? Colors.red[300]
            : _notifyDate.compareTo(itemDate) <= 0
                ? Colors.white
                : Colors.red[200];
  }

  Future<void> _changeFridgeItemDate(int index) async {
    WasteNoneLogger().d('changeFridgeItemDate');
    FridgeItem fridgeItem = _usersCurrentFridgeItems[index];
    if (selectedDate != null) {
      fridgeItem.validDate = '${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}';

      // String usersEncryptionPass = await readEncryptionPassword(user.uid);
      // String encryptedFridgeItem = fridgeItem.asEncodedString(usersEncryptionPass);
      // await db.updateEncryptedFridgeItem(fridgeItem.fridge_id, fridgeItem.dbKey, encryptedFridgeItem);
      await db.updateFridgeItem(fridgeItem);
      _refreshCurrentFridge();
    }
  }

  DateTime selectedDate;

  _dateChanged(DateTime picked) {
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
    return null;
  }

  bool _changeDateFirstPress = true;
  _showChangeDateDialog(BuildContext context, int index) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child: CalendarDatePicker(
                firstDate: DateTime.now(),
                initialDate: _usersCurrentFridgeItems[index].getValidDateAsDate(),
                lastDate: DateTime(DateTime.now().year + 5, DateTime.now().month, DateTime.now().day),
                initialCalendarMode: DatePickerMode.day,
                onDateChanged: _dateChanged,
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('OK'),
                  onPressed: () {
                    if (_changeDateFirstPress) {
                      _changeFridgeItemDate(index);
                      Navigator.pop(context);
                      _changeDateFirstPress = false;
                    }
                  }),
              getCancelButton(context),
            ],
          );
        });
  }

  Future<void> _changeFridgeItemQty(int index, String newQty) async {
    WasteNoneLogger().d('changeFridgeItemQty');
    FridgeItem fridgeItem = _usersCurrentFridgeItems[index];

    WasteNoneLogger().d('from ${fridgeItem.qty}');
    fridgeItem.qty = int.parse(newQty);
    WasteNoneLogger().d('to ${fridgeItem.qty}');
    // String usersEncryptionPass = await readEncryptionPassword(user.uid);
    // String encryptedFridgeItem = fridgeItem.asEncodedString(usersEncryptionPass);
    // await db.updateEncryptedFridgeItem(fridgeItem.fridge_id, fridgeItem.dbKey, encryptedFridgeItem);

    await db.updateFridgeItem(fridgeItem);
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

  bool _changeQtyFirstPress = true;
  _changeItemQty(BuildContext context, int index) async {
    FridgeItem changeQtyItemFridgeItem = _usersCurrentFridgeItems[index];

    int newQty = await showDialog<int>(
      context: context,
      builder: (context) => ItemQtySelectionPopup(
        titleText: 'Select new quantity',
        maxQty: 99,
        defaultQty: changeQtyItemFridgeItem.qty,
      ),
    );
    _changeFridgeItemQty(index, newQty.toString());
  }

  Future<void> _deleteFridgeItem(int index) async {
    FridgeItem toBeDeletedFridgeItem = _usersCurrentFridgeItems[index];
    Product product = await db.getProductByEanCode(toBeDeletedFridgeItem.product_ean);
    FlutterNotification().removeNotification(product, toBeDeletedFridgeItem);
    // await db.deleteEncryptedFridgeItem(toBeDeletedFridgeItem.fridge_id, toBeDeletedFridgeItem.dbKey);
    await db.deleteFridgeItem(toBeDeletedFridgeItem);
    FlutterNotification().clearNotifications();
    _refreshCurrentFridge();
  }

  final TextEditingController _fridgeIDToMoveItemToController = TextEditingController();

  String get _fridgeIDToMoveItemTo => _fridgeIDToMoveItemToController.text.trim();
  bool _fridgeIDToMoveItemToChanged = false;

  void _fridgeIDToMoveItemToChangedState() {
    setState(() {
      _fridgeIDToMoveItemToChanged = true;
    });
  }

  Future _moveToAnotherFridge(int moveItemIndex, BuildContext context) async {
    if (_usersFridges.length == 1)
      _showOnlyOneFridgeError();
    else {
      int moveQty = await _howManyItemsShouldBeMoved(moveItemIndex, context);
      WasteNoneLogger().d('moveQty: $moveQty');
      if (moveQty != null) _moveItemFridgeSelectionPopup(moveItemIndex, moveQty, context);
    }
  }

  _showOnlyOneFridgeError() {
    showShortBadToast("You got only one fridge defined.");
  }

  Future<int> _howManyItemsShouldBeMoved(int moveItemIndex, BuildContext context) async {
    int maxQty = _usersCurrentFridgeItems[moveItemIndex].qty;
    if (maxQty != null) {
      if (maxQty == 1) {
        return 1;
      } else
        return await showDialog<int>(
          context: context,
          builder: (context) => ItemQtySelectionPopup(
            titleText: 'Select quantity to move',
            maxQty: maxQty,
            defaultQty: maxQty,
          ),
        );
    }
    return null;
  }

  bool _destinationSelected = false;
  _moveItemFridgeSelectionPopup(int moveItemIndex, int qty, BuildContext context) async {
    _fridgeIDToMoveItemToController.clear();
    _fridgeIDToMoveItemToChanged = false;
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: user.getFridgeIDs().length * 53.0,
              child: ListView.builder(
                  itemCount: _usersFridges.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (_usersFridges[index].fridgeID != _currentFridge.fridgeID) {
                      var text = _usersFridges[index].fridgeID.startsWith(user.uid) ? '' : '[shared]';
                      text += _usersFridges[index].displayName != null
                          ? '${_usersFridges[index].displayName}'
                          : 'fridge ${_usersFridges[index].fridgeNo}';
                      return GestureDetector(
                        child: getFridgeListItemBox(text),
                        onTap: () => !_destinationSelected
                            ? _moveItemToAnotherFridge(moveItemIndex, qty, _usersFridges[index].fridgeID)
                            : null,
                      );
                    } else
                      return Container();
                  }),
            ),
            actions: <Widget>[
              getCancelButton(context),
            ],
          );
        });
  }

  FlatButton getCancelButton(BuildContext context) {
    return new FlatButton(
        child: const Text('Cancel'),
        onPressed: () {
          Navigator.pop(context);
        });
  }

  Widget getFridgeListItemBox(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey[200],
          border: Border.all(color: Colors.white),
        ),
        height: 55,
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 2, bottom: 2),
              child: SizedBox(height: 25, child: Image.asset('images/wastenone_icon.jpg')),
            ),
            Center(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Future<void> _moveItemToAnotherFridge(int index, int moveQty, String fridgeID) async {
    _destinationSelected = true;
    WasteNoneLogger().d('move to another fridge $index: ${_usersCurrentFridgeItems[index].toJson()}');
    FridgeItem fridgeItem = _usersCurrentFridgeItems[index];

    //delete or deduct in current fridge
    if (fridgeItem.qty == moveQty) {
      // await db.deleteEncryptedFridgeItem(fridgeItem.fridge_id, fridgeItem.dbKey);
      await db.deleteFridgeItem(fridgeItem);
    } else {
      await _changeFridgeItemQty(index, '${fridgeItem.qty - moveQty}');
    }

    //add to another fridge
    fridgeItem.fridge_id = fridgeID;
    fridgeItem.qty = moveQty;

    List<FridgeItem> destinationFridgeItems =
        await db.getFridgeContent(fridgeID); //fetchAndDescryptFridge(db, fridgeID, user);
    FridgeItem existingSimilarItem = getSimilarItemInFridge(destinationFridgeItems, fridgeItem);
    if (existingSimilarItem != null) {
      WasteNoneLogger().d('update');
      await _updateExistingItem(destinationFridgeItems, existingSimilarItem, fridgeItem);
    } else {
      // String encryptionPassword = await readEncryptionPassword(user.uid);
      // await db.addToFridgeEncrypted(fridgeItem.asEncodedString(encryptionPassword), fridgeID);
      await db.addToFridge(fridgeItem, user.uid);
    }
    _destinationSelected = false;
    Navigator.pop(context);
    _refreshCurrentFridge();
  }

  Future<void> _updateExistingItem(
      List<FridgeItem> fridgeContent, FridgeItem existingSimilarItem, FridgeItem fridgeItem) async {
    existingSimilarItem.qty += fridgeItem.qty;
    db.updateFridgeItem(existingSimilarItem);
  }
  //---------------------------- /flutter widgets ----------------------------------------------------------------------

  Future<Product> _getProductsDetails(String productEan) async {
    // local cache -> wastenone db
    var productJson = await getProductFromCacheByEANCode(productEan);
    Product product = productJson != null ? Product.fromMap(productJson) : null;
    if (product != null) return product;
    return await db.getProductByEanCode(productEan);
  }

  Future<void> _refreshCurrentFridge() async {
    _showFridge(_currentFridge.fridgeID);
  }

  void _scanAndAdd() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ScanAndAdd(
                  auth: auth,
                  db: db,
                  fridge: _currentFridge,
                  fridgeContent: _usersCurrentFridgeItems,
                  user: user,
                ))).whenComplete(() => {_fetchUserFridgeData()});
  }

  Future<void> _logOut() async {
    try {
      if (user.isAnonymous()) {
        await db.deleteUser(user);
      }
      userStreamCtrl.sink.add(null);
      await auth.logOut();
    } catch (e) {
      WasteNoneLogger().d(e.toString());
    }
  }
}

//---------------------------- share fridge ----------------------------------------------------------------------------
class ShareFridgeEmailInputPopup extends StatefulWidget {
  ShareFridgeEmailInputPopup();

  @override
  State<StatefulWidget> createState() {
    return ShareFridgeEmailInputPopupState();
  }
}

class ShareFridgeEmailInputPopupState extends State<ShareFridgeEmailInputPopup> {
  ShareFridgeEmailInputPopupState() {}

  // String email;
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share fridge with another user:'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 130,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 220,
                child: TextFormField(
                  decoration: new InputDecoration(
                    labelText: "Email",
                    hintText: 'email@email.com',
                  ),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.singleLineFormatter],
                  controller: emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => EmailValidator.validate(value) ? null : "Invalid email format",
                  autofocus: true,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: const Text('OK'),
            onPressed: () {
              //_showMoveToAnotherFridgeLocationPopup(moveItemIndex, moveQty.toInt(), context);
              Navigator.of(context).pop(emailController.text);
            }),
        FlatButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            }),
      ],
    );
  }
}

class ShareFridgeInvitePopup extends StatefulWidget {
  ShareFridgeInvitePopup(this.sender);

  final WasteNoneUser sender;

  @override
  State<StatefulWidget> createState() {
    return ShareFridgeInvitePopupState(sender);
  }
}

class ShareFridgeInvitePopupState extends State<ShareFridgeInvitePopup> {
  ShareFridgeInvitePopupState(this.sender) {}

  WasteNoneUser sender;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Fridge shared'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 80,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 220,
                child: Text(
                    'You have invitation from user ${sender?.displayName} to share a fridge. \nDo you want to accept?'),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: const Text('YES'),
            onPressed: () {
              Navigator.of(context).pop(true);
            }),
        FlatButton(
            child: const Text('NO'),
            onPressed: () {
              Navigator.of(context).pop(false);
            }),
      ],
    );
  }
}
//---------------------------- /share fridge ---------------------------------------------------------------------------

//---------------------------- move fridge item ------------------------------------------------------------------------

//---------------------------- /move fridge item -----------------------------------------------------------------------
