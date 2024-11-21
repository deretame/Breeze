import 'package:flutter/material.dart';

import '../bika/bika.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('个人')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[BikaUserInfoWidget()],
        ),
      ),
    );
  }
}
