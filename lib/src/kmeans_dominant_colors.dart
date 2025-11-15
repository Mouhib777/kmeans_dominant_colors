import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'models/color_cluster.dart';
import 'utils/color_utils.dart';

/// Main class for extracting dominant colors from images using K-means clustering.
///
/// This class provides static methods to analyze images and extract the most
/// prevalent colors using the K-means clustering algorithm.
///
/// Example:
/// ```dart
/// final image = await loadImage('assets/image.jpg');
/// final colors = KMeansDominantColors.extract(
///   image: image,
///   count: 5,
///   maxIterations: 15,
/// );
/// ```
class KMeansDominantColors {
  /// Default width for image resizing (for performance)
  static const int _defaultResizeWidth = 100;

  /// Default number of dominant colors to extract
  static const int _defaultColorCount = 3;

  /// Default maximum iterations for K-means algorithm
  static const int _defaultMaxIterations = 10;

  /// Extracts dominant colors from an image using K-means clustering.
  ///
  /// [image]: The input image to analyze (required)
  /// [count]: Number of dominant colors to extract (default: 3)
  /// [maxIterations]: Maximum iterations for K-means algorithm (default: 10)
  /// [resizeWidth]: Width to resize image for performance (default: 100)
  ///
  /// Returns a list of [Color] objects sorted by dominance (most dominant first).
  ///
  /// Throws [ArgumentError] if parameters are invalid.
  ///
  /// Example:
  /// ```dart
  /// final colors = KMeansDominantColors.extract(
  ///   image: myImage,
  ///   count: 5,
  ///   maxIterations: 15,
  /// );
  /// ```
  static List<Color> extract({
    required img.Image image,
    int count = _defaultColorCount,
    int maxIterations = _defaultMaxIterations,
    int resizeWidth = _defaultResizeWidth,
  }) {
    _validateParameters(
      image: image,
      count: count,
      maxIterations: maxIterations,
      resizeWidth: resizeWidth,
    );

    // Get color clusters with detailed information
    final clusters = _extractColorClusters(
      image: image,
      count: count,
      maxIterations: maxIterations,
      resizeWidth: resizeWidth,
    );

    // Convert to Flutter Colors and return
    return clusters.map((cluster) => cluster.color).toList();
  }

  /// Extracts dominant colors with detailed cluster information.
  ///
  /// Returns a list of [ColorCluster] objects containing color, size,
  /// and percentage information.
  ///
  /// This method provides more detailed information about each color cluster
  /// including the percentage of pixels in each cluster.
  static List<ColorCluster> extractDetailed({
    required img.Image image,
    int count = _defaultColorCount,
    int maxIterations = _defaultMaxIterations,
    int resizeWidth = _defaultResizeWidth,
  }) {
    _validateParameters(
      image: image,
      count: count,
      maxIterations: maxIterations,
      resizeWidth: resizeWidth,
    );

    return _extractColorClusters(
      image: image,
      count: count,
      maxIterations: maxIterations,
      resizeWidth: resizeWidth,
    );
  }

  /// Validates input parameters and throws [ArgumentError] if invalid.
  static void _validateParameters({
    required img.Image image,
    required int count,
    required int maxIterations,
    required int resizeWidth,
  }) {
    if (count <= 0) {
      throw ArgumentError('Color count must be greater than 0');
    }
    if (maxIterations <= 0) {
      throw ArgumentError('Max iterations must be greater than 0');
    }
    if (resizeWidth <= 0) {
      throw ArgumentError('Resize width must be greater than 0');
    }
    if (image.width == 0 || image.height == 0) {
      throw ArgumentError('Image dimensions cannot be zero');
    }
  }

  /// Core K-means clustering implementation.
  static List<ColorCluster> _extractColorClusters({
    required img.Image image,
    required int count,
    required int maxIterations,
    required int resizeWidth,
  }) {
    // Step 1: Resize image for performance
    final resizedImage = img.copyResize(
      image,
      width: resizeWidth,
      interpolation: img.Interpolation.average,
    );

    // Step 2: Extract pixel data
    final pixels = _extractPixels(resizedImage);

    // Step 3: Initialize centroids using K-means++ for better results
    List<List<int>> centroids = _initializeCentroidsPlusPlus(pixels, count);

    // Step 4: Perform K-means iterations
    List<List<List<int>>> clusters = List.generate(count, (_) => []);

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      // Clear previous clusters
      for (var cluster in clusters) {
        cluster.clear();
      }

      // Assign each pixel to the nearest centroid
      _assignPixelsToClusters(pixels, centroids, clusters);

      // Calculate new centroids
      final newCentroids = _calculateNewCentroids(clusters);

      // Check for convergence
      if (_centroidsEqual(centroids, newCentroids)) {
        centroids = newCentroids;
        break;
      }

      centroids = newCentroids;
    }

    // Step 5: Convert to ColorCluster objects and calculate percentages
    return _createColorClusters(centroids, clusters, pixels.length);
  }

  /// Extracts RGB pixel data from the image.
  static List<List<int>> _extractPixels(img.Image image) {
    final pixels = <List<int>>[];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        pixels.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
    }

    return pixels;
  }

  /// Initializes centroids using K-means++ algorithm for better distribution.
  static List<List<int>> _initializeCentroidsPlusPlus(
    List<List<int>> pixels,
    int count,
  ) {
    if (pixels.isEmpty) return [];
    if (count == 1) return [List.from(pixels.first)];

    final random = math.Random();
    final centroids = <List<int>>[];

    // First centroid: choose randomly
    centroids.add(List.from(pixels[random.nextInt(pixels.length)]));

    // Subsequent centroids: choose with probability proportional to distance squared
    for (int i = 1; i < count; i++) {
      final distances = _calculateDistancesToNearestCentroid(pixels, centroids);
      final nextCentroidIndex = _chooseNextCentroidIndex(distances, random);
      centroids.add(List.from(pixels[nextCentroidIndex]));
    }

    return centroids;
  }

  /// Calculates distances from each pixel to its nearest centroid.
  static List<double> _calculateDistancesToNearestCentroid(
    List<List<int>> pixels,
    List<List<int>> centroids,
  ) {
    return pixels.map((pixel) {
      double minDistance = double.infinity;
      for (final centroid in centroids) {
        final distance = ColorUtils.colorDistance(pixel, centroid);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      return minDistance;
    }).toList();
  }

  /// Chooses the next centroid index using weighted probability.
  static int _chooseNextCentroidIndex(
      List<double> distances, math.Random random) {
    final totalDistance = distances.reduce((a, b) => a + b);
    var randomValue = random.nextDouble() * totalDistance;

    for (int i = 0; i < distances.length; i++) {
      randomValue -= distances[i];
      if (randomValue <= 0) {
        return i;
      }
    }

    return distances.length - 1;
  }

  /// Assigns each pixel to the nearest centroid cluster.
  static void _assignPixelsToClusters(
    List<List<int>> pixels,
    List<List<int>> centroids,
    List<List<List<int>>> clusters,
  ) {
    for (final pixel in pixels) {
      int nearestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < centroids.length; i++) {
        final distance = ColorUtils.colorDistance(pixel, centroids[i]);
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      clusters[nearestIndex].add(pixel);
    }
  }

  /// Calculates new centroids from current clusters.
  static List<List<int>> _calculateNewCentroids(
      List<List<List<int>>> clusters) {
    final newCentroids = <List<int>>[];

    for (final cluster in clusters) {
      if (cluster.isEmpty) continue;

      final avgR =
          (cluster.map((p) => p[0]).reduce((a, b) => a + b) / cluster.length)
              .round();
      final avgG =
          (cluster.map((p) => p[1]).reduce((a, b) => a + b) / cluster.length)
              .round();
      final avgB =
          (cluster.map((p) => p[2]).reduce((a, b) => a + b) / cluster.length)
              .round();

      newCentroids.add([avgR, avgG, avgB]);
    }

    return newCentroids;
  }

  /// Creates ColorCluster objects from centroids and clusters.
  static List<ColorCluster> _createColorClusters(
    List<List<int>> centroids,
    List<List<List<int>>> clusters,
    int totalPixels,
  ) {
    final colorClusters = <ColorCluster>[];

    for (int i = 0; i < centroids.length; i++) {
      if (clusters[i].isEmpty) continue;

      final centroid = centroids[i];
      final clusterSize = clusters[i].length;
      final percentage = (clusterSize / totalPixels * 100);

      colorClusters.add(ColorCluster(
        color: Color.fromRGBO(centroid[0], centroid[1], centroid[2], 1.0),
        pixelCount: clusterSize,
        percentage: percentage,
      ));
    }

    // Sort by cluster size (descending)
    colorClusters.sort((a, b) => b.pixelCount.compareTo(a.pixelCount));

    return colorClusters;
  }

  /// Checks if two sets of centroids are equal.
  static bool _centroidsEqual(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i][0] != b[i][0] || a[i][1] != b[i][1] || a[i][2] != b[i][2]) {
        return false;
      }
    }

    return true;
  }
}
