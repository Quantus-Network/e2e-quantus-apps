import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// A record to hold the distinct styling properties for each sphere variant.
typedef _SphereStyle = ({
  Gradient gradient,
  double opacity,
  double blur,
});

/// A widget that displays a blurred, colored sphere with various gradient styles.
class Sphere extends StatelessWidget {
  /// The variant of the sphere, from 1 to 16. Each variant has a unique
  /// gradient, opacity, and blur effect.
  final int variant;

  /// The size (width and height) of the sphere in logical pixels.
  final double size;

  const Sphere({
    super.key,
    required this.variant,
    required this.size,
  }) : assert(variant >= 1 && variant <= 16, 'Variant must be between 1 and 16');

  // A map that holds the pre-defined styles for all 16 variants.
  // This approach keeps the build method clean and makes styles easy to manage.
  static final Map<int, _SphereStyle> _sphereStyles = {
    1: (
      gradient: _createGradient(128, [
        (const Color(0xFFED4CCE), 0.2888),
        (const Color(0xFF0000FF), 0.6576),
        (const Color(0xFF1F1FA3), 0.9243),
      ]),
      opacity: 0.3,
      blur: 6.0,
    ),
    2: (
      gradient: _createGradient(324, [
        (const Color(0xFFED4CCE), 0.1505),
        (const Color(0xFF0000FF), 0.5254),
        (const Color(0xFF1F1FA3), 0.8209),
      ]),
      opacity: 0.6,
      blur: 15.5,
    ),
    3: (
      gradient: _createGradient(160, [
        (const Color(0xFFED4CCE), 0.1487),
        (const Color(0xFF0000FF), 0.6367),
        (const Color(0xFF0C1014), 0.9356),
      ]),
      opacity: 0.5,
      blur: 15.0,
    ),
    4: (
      gradient: _createGradient(46, [
        (const Color(0xFFED4CCE), 0.0823),
        (const Color(0xFF0000FF), 0.5637),
        (const Color(0xFF1F1FA3), 0.8585),
      ]),
      opacity: 1.0,
      blur: 16.5,
    ),
    5: (
      gradient: _createGradient(161, [
        (const Color(0xFFED4CCE), 0.1125),
        (const Color(0xFF1F1FA3), 0.3345),
        (const Color(0xFF0C1014), 0.4990),
      ]),
      opacity: 1.0,
      blur: 16.5,
    ),
    6: (
      gradient: _createGradient(127, [
        (const Color(0xFFED4CCE), 0.2250),
        (const Color(0xFFFFE91F), 0.5740),
      ]),
      opacity: 1.0,
      blur: 16.5,
    ),
    7: (
      gradient: _createGradient(145, [
        (const Color(0xFFFFE91F), 0.2702),
        (const Color(0xFFED4CCE), 0.4591),
        (const Color(0xFF0000FF), 0.6739),
        (const Color(0xFF1F1FA3), 0.8085),
      ]),
      opacity: 1.0,
      blur: 15.0,
    ),
    8: (
      gradient: _createGradient(-41, [
        (const Color(0xFFED4CCE), 0.1500),
        (const Color(0xFF0000FF), 0.5575),
        (const Color(0xFF1F1FA3), 0.8532),
      ]),
      opacity: 0.5,
      blur: 15.0,
    ),
    9: (
      gradient: _createGradient(160, [
        (const Color(0xFFED4CCE), 0.0992),
        (const Color(0xFF0000FF), 0.6961),
        (const Color(0xFF1F1FA3), 1.0616),
      ]),
      opacity: 0.5,
      blur: 15.0,
    ),
    10: (
      gradient: _createGradient(315, [
        (const Color(0xFFED4CCE), 0.3578),
        (const Color(0xFFFFE91F), 0.8641),
      ]),
      opacity: 1.0,
      blur: 16.5,
    ),
    11: (
      gradient: _createGradient(44, [
        (const Color(0xFFED4CCE), 0.0800),
        (const Color(0xFF1F1FA3), 0.5614),
        (const Color(0xFF0C1014), 0.8562),
      ]),
      opacity: 1.0,
      blur: 12.5,
    ),
    12: (
      gradient: _createGradient(136, [
        (const Color(0xFFED4CCE), 0.1801),
        (const Color(0xFF0000FF), 0.6615),
        (const Color(0xFF1F1FA3), 0.9563),
      ]),
      opacity: 0.8,
      blur: 75.0,
    ),
    13: (
      gradient: _createGradient(236, [
        (const Color(0xFFED4CCE), 0.1389),
        (const Color(0xFFFFE91F), 1.0068),
      ]),
      opacity: 1.0,
      blur: 25.0,
    ),
    14: (
      gradient: _createGradient(270, [
        (const Color(0xFFED4CCE), -0.0843),
        (const Color(0xFF0000FF), 0.5946),
        (const Color(0xFF1F1FA3), 1.0104),
      ]),
      opacity: 1.0,
      blur: 9.0,
    ),
    15: (
      gradient: _createGradient(183, [
        (const Color(0xFFFFE91F), 0.1369),
        (const Color(0xFFED4CCE), 0.4101),
        (const Color(0xFF0000FF), 0.7207),
        (const Color(0xFF1F1FA3), 0.9154),
      ]),
      opacity: 1.0,
      blur: 15.0,
    ),
    16: (
      gradient: _createGradient(46, [
        (const Color(0xFFED4CCE), 0.0823),
        (const Color(0xFF1F1FA3), 0.5637),
        (const Color(0xFF0C1014), 0.8585),
      ]),
      opacity: 1.0,
      blur: 12.5,
    ),
  };

  /// Helper function to create a LinearGradient with rotation.
  static Gradient _createGradient(
      double degrees, List<(Color, double)> colorStops) {
    return LinearGradient(
      colors: colorStops.map((cs) => cs.$1).toList(),
      stops: colorStops.map((cs) => cs.$2).toList(),
      transform: GradientRotation(degrees * (math.pi / 180)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the style for the given variant.
    final style = _sphereStyles[variant]!;
    
    // The CSS blur in pixels is roughly sigma * 2 in Flutter.
    final double sigma = style.blur / 2;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Opacity(
        opacity: style.opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: style.gradient,
          ),
        ),
      ),
    );
  }
}
