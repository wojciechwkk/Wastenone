import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';
import 'package:waste_none_app/services/firebase_database.dart';

import 'cryptography_util.dart';

FridgeItem getSimilarItemInFridge(List<FridgeItem> fridgeItemList, FridgeItem fridgeItem) {
  for (FridgeItem existingFridgeItem in fridgeItemList) {
    if (existingFridgeItem.product_puid == fridgeItem.product_puid) {
      if (existingFridgeItem.validDate == fridgeItem.validDate) {
        return existingFridgeItem;
      }
    }
  }
  return null;
}

Future<List<FridgeItem>> fetchAndDescryptFridge(WNFirebaseDB db, String fridgeId, WasteNoneUser user) async {
  List<FridgeItem> fetchedFridgeItems = new List<FridgeItem>();
  Map<String, String> fetchedEncryptedFridgeItems = await db?.getFridgeEncryptedContent(fridgeId, user.uid);
  if (fetchedEncryptedFridgeItems != null) {
    String encryptionPassword = await readEncryptionPassword(user.uid);
    fetchedFridgeItems = decryptFridgeList(fetchedEncryptedFridgeItems, encryptionPassword);
    if (fetchedFridgeItems == null) {
      // print("your fridge is empty");
      return new List<FridgeItem>();
    } else {
      // print("theres ${fetchedFridgeItems?.length} items in this fridge");
      return fetchedFridgeItems;
    }
  }
  return new List<FridgeItem>();
}
