/// A Flutter package for extracting dominant colors from images using K-means clustering.
///
/// This package provides efficient algorithms to analyze images and extract
/// the most dominant colors, sorted by their prevalence in the image.
///
/// ## Features
/// - Extract dominant colors from any image
/// - Customizable number of colors to extract
/// - Configurable algorithm parameters
/// - High performance with image resizing
/// - Returns colors sorted by dominance
///
/// ## Usage
/// ```dart
/// import 'package:kmeans_dominant_colors/kmeans_dominant_colors.dart';
/// import 'package:image/image.dart' as img;
///
/// // Load your image
/// img.Image image = ...;
///
/// // Extract dominant colors
/// List<Color> dominantColors = KMeansDominantColors.extract(
///   image: image,
///   count: 5,
///   maxIterations: 10,
/// );
/// ```
library kmeans_dominant_colors;

export 'src/kmeans_dominant_colors.dart';
export 'src/models/color_cluster.dart';
export 'src/utils/color_utils.dart';
