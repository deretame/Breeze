import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';

class JmConfig {
  static final cookieJar = CookieJar(ignoreExpires: true);

  static String device = '';

  static String _token = '';

  static String _timestamp = '';

  static const webUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

  static const jmVersion = '1.8.1';

  static const jmAuthKey = '18comicAPPContent';

  static const scrambleId = '220980';

  static const kJmSecret = '185Hcomic3PAPP7R';

  static int baseUrlIndex = 0;

  static const baseUrls = [
    'https://www.cdnzack.cc',
    'https://www.cdnsha.org',
    'https://www.cdnliu.org',
    'https://www.cdnntr.cc',
  ];

  static void setBaseUrlIndex(int index) {
    baseUrlIndex = index;
  }

  static int imagesUrlIndex = 0;

  static const imagesUrls = [
    'https://cdn-msp12.jmdanjonproxy.xyz',
    'https://tencent.jmdanjonproxy.xyz',
    'https://cdn-msp3.jmapiproxy1.cc',
    'https://cdn-msp.jmapiproxy1.cc',
  ];

  static void setImagesUrlIndex(int index) {
    imagesUrlIndex = index;
  }

  static String get baseUrl => baseUrls[baseUrlIndex];

  static String get imagesUrl => imagesUrls[imagesUrlIndex];

  static String get userImagesUrl => 'https://cdn-msp3.jmapinodeudzn.net';

  static String get token {
    if (_token.isEmpty) {
      _token =
          md5
              .convert(utf8.encode('$timestamp${JmConfig.jmVersion}'))
              .toString();
    }
    return _token;
  }

  static String get timestamp {
    if (_timestamp.isEmpty) {
      _timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    }
    return _timestamp;
  }

  static final categoryMap = {
    '最新a漫': '0',
    '同人': tongRenTypeMap,
    '单本': danBenTypeMap,
    '短篇': duanPianTypeMap,
    '其他类': qiTaLeiTypeMap,
    '韩漫': hanManTypeMap,
    'English Manga': meiManTypeMap,
    'Cosplay': 'another_cosplay',
    '3D': '3D',
    '禁漫汉化组': '禁漫汉化组',
  };

  static final rankingTypeMap = {
    '最新': 'new',
    '最多点赞': 'tf',
    '总排行': 'mv',
    '月排行': 'mv_m',
    '周排行': 'mv_w',
    '日排行': 'mv_t',
  };

  static final tongRenTypeMap = {
    '全部': 'doujin',
    '汉化': 'doujin_chinese',
    '日语': 'doujin_japanese',
    'CG图集': 'doujin_CG',
  };

  static final danBenTypeMap = {
    '全部': 'single',
    '汉化': 'single_chinese',
    '日语': 'single_japanese',
    '青年漫': 'single_youth',
  };

  static final duanPianTypeMap = {
    '全部': 'short',
    '汉化': 'short_chinese',
    '日语': 'short_japanese',
  };

  static final qiTaLeiTypeMap = {
    '全部': 'another',
    '其他漫画': 'another_other',
    '3D': 'another_3d',
    '角色扮演': 'another_cosplay',
  };

  static final hanManTypeMap = {'全部': 'hanman', '汉化': 'hanman_chinese'};

  static final meiManTypeMap = {
    '全部': 'meiman',
    'IRODORI': 'meiman_irodori',
    'FAKKU': 'meiman_fakku',
    '18scan': 'meiman_18scan',
    'Manhwa': 'meiman_manhwa',
    'Comic': 'meiman_comic',
    'Other': 'meiman_other',
  };
}
