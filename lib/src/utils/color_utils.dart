import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Utility class for color-related calculations and conversions.
class ColorUtils {
  /// Calculates the Euclidean distance between two colors in RGB space.
  ///
  /// [color1]: First color as [r, g, b]
  /// [color2]: Second color as [r, g, b]
  ///
  /// Returns the Euclidean distance between the two colors.
  static double colorDistance(List<int> color1, List<int> color2) {
    final dr = color1[0] - color2[0];
    final dg = color1[1] - color2[1];
    final db = color1[2] - color2[2];
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  /// Calculates the perceptual brightness of a color.
  ///
  /// Uses the formula: sqrt(0.299 * R² + 0.587 * G² + 0.114 * B²)
  ///
  /// Returns a value between 0 (dark) and 255 (bright).
  static double calculateBrightness(Color color) {
    return math.sqrt(
      0.299 * color.red * color.red +
          0.587 * color.green * color.green +
          0.114 * color.blue * color.blue,
    );
  }

  /// Determines if a color is light (suitable for dark text).
  ///
  /// Returns true if the color is light, false if dark.
  static bool isLightColor(Color color) {
    return calculateBrightness(color) > 128;
  }

  /// Determines if a color is dark (suitable for light text).
  ///
  /// Returns true if the color is dark, false if light.
  static bool isDarkColor(Color color) {
    return !isLightColor(color);
  }

  /// Gets a contrasting text color for a background color.
  ///
  /// Returns white for dark backgrounds, black for light backgrounds.
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Converts a color to its hex string representation.
  ///
  /// Example: Color(0xFFAABBCC) -> "#AABBCC"
  static String toHexString(Color color, {bool includeHash = true}) {
    final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    return includeHash ? '#$hex' : hex;
  }

  /// Converts a hex string to a Color object.
  ///
  /// Supports formats: "#AABBCC", "AABBCC", "#FFAABBCC", "FFAABBCC"
  static Color fromHexString(String hexString) {
    try {
      String hex = hexString.replaceAll('#', '');

      if (hex.length == 6) {
        hex = 'FF$hex'; // Add full opacity
      }

      if (hex.length == 8) {
        final value = int.parse(hex, radix: 16);
        return Color(value);
      }

      throw FormatException('Invalid hex color format: $hexString');
    } catch (e) {
      throw FormatException('Invalid hex color: $hexString');
    }
  }
}
