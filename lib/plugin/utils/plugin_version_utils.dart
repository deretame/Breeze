/// Compares two version strings.
///
/// Returns a positive integer if [leftRaw] is greater than [rightRaw],
/// a negative integer if it is smaller, and 0 if they are equal.
///
/// Tokens are split into numeric and alphabetic chunks. Numeric tokens are
/// compared as integers; alphabetic tokens are compared lexicographically.
/// When a numeric token is compared to an alphabetic token, the numeric one
/// is considered greater, matching the original implementation.
int compareVersion(String leftRaw, String rightRaw) {
  final left = _tokenizeVersion(leftRaw);
  final right = _tokenizeVersion(rightRaw);
  final max = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < max; i++) {
    final leftToken = i < left.length ? left[i] : 0;
    final rightToken = i < right.length ? right[i] : 0;

    if (leftToken is int && rightToken is int) {
      if (leftToken != rightToken) {
        return leftToken.compareTo(rightToken);
      }
      continue;
    }
    if (leftToken is String && rightToken is String) {
      final cmp = leftToken.compareTo(rightToken);
      if (cmp != 0) {
        return cmp;
      }
      continue;
    }

    if (leftToken is int && rightToken is String) {
      return 1;
    }
    if (leftToken is String && rightToken is int) {
      return -1;
    }
  }
  return 0;
}

List<Object> _tokenizeVersion(String raw) {
  var normalized = raw.trim();
  if (normalized.isEmpty) {
    return const <Object>[0];
  }
  if (normalized.length >= 2 &&
      (normalized.startsWith('v') || normalized.startsWith('V')) &&
      RegExp(r'[0-9A-Za-z]').hasMatch(normalized[1])) {
    normalized = normalized.substring(1);
  }
  final parts = RegExp(
    r'[0-9]+|[A-Za-z]+',
  ).allMatches(normalized).map((match) => match.group(0)!).toList();
  if (parts.isEmpty) {
    return <Object>[normalized.toLowerCase()];
  }
  return parts.map((part) => int.tryParse(part) ?? part.toLowerCase()).toList();
}
