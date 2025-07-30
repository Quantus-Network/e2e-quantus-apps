import 'package:flutter/material.dart';

extension MediaQueryDataExtension on MediaQueryData {
  bool get isTablet => size.width > 600;
}
