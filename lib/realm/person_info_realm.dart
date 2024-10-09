import 'package:realm/realm.dart';

part 'person_info_realm.realm.dart';

@RealmModel()
class _PersonInfoRealm {
  @PrimaryKey()
  late String id;

  late DateTime birthday;
  late String email;
  late String gender;
  late String name;
  late String slogan;
  late String title;
  late bool verified;
  late int exp;
  late int level;
  late List<String> characters;
  late DateTime createdAt;
  late _Avatar? avatar;
  late bool isPunched;
  late String character;
}

@RealmModel()
class _Avatar {
  late String originalName;
  late String path;
  late String fileServer;
}
