import 'package:realm/realm.dart';

part 'person_info_realm.realm.dart';

@RealmModel()
class _PersonInfoRealm {
  @PrimaryKey()
  late final String id;

  late final DateTime birthday;
  late final String email;
  late final String gender;
  late final String name;
  late final String slogan;
  late final String title;
  late final bool verified;
  late final int exp;
  late final int level;
  late final List<String> characters;
  late final DateTime createdAt;
  late final _Avatar? avatar;
  late final bool isPunched;
  late final String character;
}

@RealmModel()
class _Avatar {
  late final String originalName;
  late final String path;
  late final String fileServer;
}
