import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kmeans_dominant_colors/kmeans_dominant_colors.dart';
import 'package:image/image.dart' as img;

void main() {
  group('KMeansDominantColors', () {
    test('extract colors from solid red image', () {
      // Create a solid red image
      final image = img.Image(height: 100, width: 100);
      for (int x = 0; x < 100; x++) {
        for (int y = 0; y < 100; y++) {
          image.setPixelRgba(x, y, 255, 0, 0, 255); // Added alpha value
        }
      }

      final colors = KMeansDominantColors.extract(image: image, count: 1);

      expect(colors.length, 1);
      expect(colors[0].red, 255);
      expect(colors[0].green, 0);
      expect(colors[0].blue, 0);
    });

    test('extract multiple colors from multi-color image', () {
      // Create an image with two distinct colors
      final image = img.Image(height: 100, width: 100);
      for (int x = 0; x < 100; x++) {
        for (int y = 0; y < 100; y++) {
          if (y < 50) {
            image.setPixelRgba(x, y, 255, 0, 0, 255); // Red
          } else {
            image.setPixelRgba(x, y, 0, 255, 0, 255); // Green
          }
        }
      }

      final colors = KMeansDominantColors.extract(image: image, count: 2);

      expect(colors.length, 2);
      // Should have both red and green colors
      final hasRed = colors.any(
          (color) => color.red == 255 && color.green == 0 && color.blue == 0);
      final hasGreen = colors.any(
          (color) => color.red == 0 && color.green == 255 && color.blue == 0);

      expect(hasRed, isTrue);
      expect(hasGreen, isTrue);
    });

    test('extractDetailed returns ColorCluster objects', () {
      final image = img.Image(height: 50, width: 50);
      for (int x = 0; x < 50; x++) {
        for (int y = 0; y < 50; y++) {
          image.setPixelRgba(x, y, 255, 0, 0, 255); // Added alpha value
        }
      }

      final clusters =
          KMeansDominantColors.extractDetailed(image: image, count: 1);

      expect(clusters.length, 1);
      expect(clusters[0].color.red, 255);
      expect(clusters[0].pixelCount, greaterThan(0));
      expect(clusters[0].percentage, closeTo(100.0, 0.1));
    });

    test('throws ArgumentError for invalid parameters', () {
      final image = img.Image(height: 10, width: 10);

      expect(() => KMeansDominantColors.extract(image: image, count: 0),
          throwsA(isA<ArgumentError>()));
      expect(() => KMeansDominantColors.extract(image: image, maxIterations: 0),
          throwsA(isA<ArgumentError>()));
      expect(() => KMeansDominantColors.extract(image: image, resizeWidth: 0),
          throwsA(isA<ArgumentError>()));
    });

    test('handles empty image gracefully', () {
      final image = img.Image(height: 0, width: 0);

      expect(() => KMeansDominantColors.extract(image: image),
          throwsA(isA<ArgumentError>()));
    });

    test('respects count parameter', () {
      final image = img.Image(height: 100, width: 100);
      for (int x = 0; x < 100; x++) {
        for (int y = 0; y < 100; y++) {
          image.setPixelRgba(x, y, 255, 0, 0, 255); // Added alpha value
        }
      }

      final colors = KMeansDominantColors.extract(image: image, count: 3);

      expect(colors.length, 1); // Only one color in image, so should return 1
    });
  });

  group('ColorUtils', () {
    test('colorDistance calculation', () {
      final color1 = [255, 0, 0];
      final color2 = [0, 255, 0];
      final distance = ColorUtils.colorDistance(color1, color2);

      expect(distance, closeTo(360.624, 0.1));
    });

    test('brightness calculation', () {
      final black = Color(0xFF000000);
      final white = Color(0xFFFFFFFF);
      final red = Color(0xFFFF0000);

      expect(ColorUtils.calculateBrightness(black), closeTo(0, 1));
      expect(ColorUtils.calculateBrightness(white), closeTo(255, 1));
      expect(ColorUtils.calculateBrightness(red), closeTo(139, 1));
    });

    test('color contrast detection', () {
      expect(ColorUtils.isLightColor(Colors.white), isTrue);
      expect(ColorUtils.isLightColor(Colors.black), isFalse);
      expect(ColorUtils.isDarkColor(Colors.black), isTrue);
      expect(ColorUtils.isDarkColor(Colors.white), isFalse);
    });

    test('hex string conversion', () {
      final color = Color(0xFFAABBCC);
      final hex = ColorUtils.toHexString(color);

      expect(hex, '#AABBCC');

      final fromHex = ColorUtils.fromHexString('#AABBCC');
      expect(fromHex, color);
    });
  });
}
