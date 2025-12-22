class Validators {
  static bool isValidXStatusUrl(String url) {
    final regex = RegExp(
      r'^https?:\/\/(www\.|mobile\.)?(x\.com|twitter\.com)\/[A-Za-z0-9_]{1,15}\/status\/\d{10,25}(\?.*)?$',
    );

    return regex.hasMatch(url);
  }
}
