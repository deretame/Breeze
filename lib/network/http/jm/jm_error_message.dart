String sanitizeJmErrorMessage(String? raw, {String fallback = '服务器异常，请稍后再试'}) {
  final msg = (raw ?? '').trim();
  if (msg.isEmpty) {
    return fallback;
  }

  const friendlyMessages = {
    '连接服务器超时',
    '请求发送超时',
    '响应接收超时',
    '请求被取消',
    '网络连接失败',
    '未知网络错误',
    '登录过期，请重新登录',
  };
  if (friendlyMessages.contains(msg)) {
    return msg;
  }

  final lower = msg.toLowerCase();
  const serverInternalKeywords = [
    'mysql',
    'mariadb',
    'database',
    'sql',
    'sqlstate',
    'postgres',
    'redis',
    'traceback',
    'stack trace',
    'exception',
    'fatal error',
    'warning:',
    'notice:',
    'conn2',
  ];

  if (lower.contains('<!doctype html') ||
      lower.contains('<html') ||
      lower.contains('<body')) {
    return fallback;
  }

  for (final keyword in serverInternalKeywords) {
    if (lower.contains(keyword)) {
      return fallback;
    }
  }

  if (lower.contains('could not connect') ||
      lower.contains('connection refused') ||
      lower.contains('timed out') ||
      lower.contains('timeout')) {
    return '网络连接不稳定，请稍后再试';
  }

  if (msg.length > 120) {
    return fallback;
  }

  return msg;
}
