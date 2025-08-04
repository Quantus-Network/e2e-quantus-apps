import 'package:flutter/material.dart';

// Will be deleted after finished migrating to extension below
extension MediaQueryDataExtension on MediaQueryData {
  bool get isTablet => size.width > 600;
}

extension MediaQueryExtension on BuildContext {
  bool get isTablet => MediaQuery.of(this).size.width > 600;
}
