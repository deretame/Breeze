import 'package:cookie_jar/cookie_jar.dart';

class JmConfig {
  static final cookieJar = CookieJar(ignoreExpires: true);

  static String device = '';

  static const webUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

  static const jmVersion = '1.7.2';

  static const jmAuthKey = '18comicAPPContent';

  static const scrambleId = '220980';

  static const kJmSecret = '185Hcomic3PAPP7R';

  static const baseUrls = [
    'https://www.jmeadpoolcdn.one',
    'https://www.jmeadpoolcdn.life',
    'https://www.jmapiproxyxxx.one',
    'https://www.jmfreedomproxy.xyz',
  ];

  static const imagesUrls = [
    'https://cdn-msp.jmapiproxy3.cc',
    'https://cdn-msp3.jmapiproxy3.cc',
    'https://cdn-msp2.jmapiproxy1.cc',
    'https://cdn-msp3.jmapiproxy3.cc',
    'https://cdn-msp2.jmapiproxy4.cc',
    'https://cdn-msp2.jmapiproxy3.cc',
  ];

  static String get baseUrl => baseUrls[0];

  static String get imagesUrl => imagesUrls[0];
}
