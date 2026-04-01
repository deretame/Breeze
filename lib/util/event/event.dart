class NoticeSync {}

class NeedLogin {
  String from;
  Map<String, dynamic>? scheme;
  Map<String, dynamic>? data;
  String? message;

  NeedLogin({required this.from, this.scheme, this.data, this.message});
}
