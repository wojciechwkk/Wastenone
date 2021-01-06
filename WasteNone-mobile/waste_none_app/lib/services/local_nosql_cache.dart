import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';

const _PRODUCT_KEY = "product";
storeProductToLocalCache(Product product) async {
  String localCachePath = await getLocalCachePath();
  Database localCache = await databaseFactoryIo.openDatabase(localCachePath);
  var store = StoreRef.main();
  await StoreRef.main().record('$_PRODUCT_KEY-${product.eanCode}').put(localCache, product.toJson());
  // var productJson = json.encode(product.toJson();
}

Future<dynamic> getProductFromCacheByEANCode(String eanCode) async {
  String localCachePath = await getLocalCachePath();
  Database localCache = await databaseFactoryIo.openDatabase(localCachePath);
  var productJson = await StoreRef.main().record('$_PRODUCT_KEY-$eanCode').get(localCache) as Map;
  return productJson;
}
