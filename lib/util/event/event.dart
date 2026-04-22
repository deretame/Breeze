class NoticeSync {
  final bool force;

  const NoticeSync({this.force = false});
}

class NeedLogin {
  String from;
  Map<String, dynamic>? scheme;
  Map<String, dynamic>? data;
  String? message;

  NeedLogin({required this.from, this.scheme, this.data, this.message});
}
