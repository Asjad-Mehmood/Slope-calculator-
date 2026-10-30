// The product's name, version and colours, in one place. The release workflow stamps the version
// with --dart-define=APP_VERSION=x.y.z; a local build shows the version in pubspec.yaml.
import 'package:flutter/material.dart';

const appName = 'Slope Calculator';
const appTagline = 'Slope, gradient and chainage levels';
const appPublisher = 'Excel to KML';
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
const websiteUrl = 'https://www.exceltokml.com';

/// The logo's colours: deep navy with survey gold, the same family as Excel to KML and Traverse & Level.
abstract final class BrandColors {
  static const navy = Color(0xFF0A1A36);
  static const navyLight = Color(0xFF17386B);
  static const gold = Color(0xFFE9B949);
  static const goldLight = Color(0xFFF7D774);
}
