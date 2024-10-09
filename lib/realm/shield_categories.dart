import 'package:realm/realm.dart';

part 'shield_categories.realm.dart';

@RealmModel()
class _ShieldedCategories {
  @PrimaryKey()
  late String id;

  late Map<String, bool> map;
}
