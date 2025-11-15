import 'package:flutter/material.dart';

/// Represents a color cluster found by the K-means algorithm.
///
/// Contains the dominant color, number of pixels in the cluster,
/// and the percentage of total pixels.
class ColorCluster {
  /// The dominant color of this cluster
  final Color color;

  /// Number of pixels in this cluster
  final int pixelCount;

  /// Percentage of total pixels in this cluster (0-100)
  final double percentage;

  /// Creates a ColorCluster instance.
  const ColorCluster({
    required this.color,
    required this.pixelCount,
    required this.percentage,
  });

  @override
  String toString() {
    return 'ColorCluster('
        'color: Color(0x${color.value.toRadixString(16).padLeft(8, '0')}), '
        'pixelCount: $pixelCount, '
        'percentage: ${percentage.toStringAsFixed(2)}%'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ColorCluster &&
        other.color == color &&
        other.pixelCount == pixelCount &&
        other.percentage == percentage;
  }

  @override
  int get hashCode {
    return Object.hash(color, pixelCount, percentage);
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'color': color.value,
      'pixelCount': pixelCount,
      'percentage': percentage,
      'hex': '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      'rgb': 'rgb(${color.red}, ${color.green}, ${color.blue})',
    };
  }
}
