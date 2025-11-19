import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:kmeans_dominant_colors/kmeans_dominant_colors.dart';

class ColorExtractionPage extends StatefulWidget {
  const ColorExtractionPage({super.key});

  @override
  State<ColorExtractionPage> createState() => _ColorExtractionPageState();
}

// Data class to pass image data to compute function
class ImageProcessData {
  final Uint8List imageBytes;
  final int colorCount;
  final int maxIterations;

  ImageProcessData({
    required this.imageBytes,
    this.colorCount = 5,
    this.maxIterations = 15,
  });
}

// Data class to return results from compute function
class ColorExtractionResult {
  final List<Color> dominantColors;
  final List<ColorCluster> detailedClusters;

  ColorExtractionResult({
    required this.dominantColors,
    required this.detailedClusters,
  });
}

// The heavy computation function that runs in a separate isolate
ColorExtractionResult _extractColorsInIsolate(ImageProcessData data) {
  try {
    // Decode image
    final image = img.decodeImage(data.imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Extract basic colors
    final colors = KMeansDominantColors.extract(
      image: image,
      count: data.colorCount,
      maxIterations: data.maxIterations,
    );

    // Extract detailed clusters
    final clusters = KMeansDominantColors.extractDetailed(
      image: image,
      count: data.colorCount,
      maxIterations: data.maxIterations,
    );

    return ColorExtractionResult(
      dominantColors: colors,
      detailedClusters: clusters,
    );
  } catch (e) {
    throw Exception('Color extraction failed: $e');
  }
}

class _ColorExtractionPageState extends State<ColorExtractionPage> {
  List<Color>? _dominantColors;
  List<ColorCluster>? _detailedClusters;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedImage;

  final _imageAssets = [
    'assets/sample1.jpg',
    'assets/sample2.jpg',
    'assets/sample3.jpg',
    'assets/sample4.jpg',
    'assets/sample5.jpg',
    'assets/sample6.jpg',
    'assets/sample7.jpeg',
    'assets/sample8.jpeg',
  ];

  // Cache for loaded images
  final Map<String, Uint8List> _imageCache = {};

  Future<Uint8List?> _loadImageBytes(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath];
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      _imageCache[assetPath] = bytes;
      return bytes;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load image: $e';
      });
      return null;
    }
  }

  Future<void> _extractColors(String assetPath) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedImage = assetPath;
      _dominantColors = null;
      _detailedClusters = null;
      _errorMessage = null;
    });

    try {
      final imageBytes = await _loadImageBytes(assetPath);
      if (imageBytes == null) return;

      // Run the heavy computation in a separate isolate
      final result = await compute(
        _extractColorsInIsolate,
        ImageProcessData(
          imageBytes: imageBytes,
          colorCount: 5,
          maxIterations: 15,
        ),
      );

      setState(() {
        _dominantColors = result.dominantColors;
        _detailedClusters = result.detailedClusters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error extracting colors: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Image:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _imageAssets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final asset = _imageAssets[index];
              final isSelected = _selectedImage == asset;
              return GestureDetector(
                onTap: _isLoading ? null : () => _extractColors(asset),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: FutureBuilder<Uint8List?>(
                    future: _loadImageBytes(asset),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImage() {
    if (_selectedImage == null) return const SizedBox.shrink();

    return FutureBuilder<Uint8List?>(
      future: _loadImageBytes(_selectedImage!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                height: 300,
                width: double.infinity,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Failed to load image'),
            ),
          );
        } else {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Widget _buildColorPalette(List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎨 Dominant Colors:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = colors[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.getContrastingTextColor(color),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ColorUtils.toHexString(color).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedClusters(List<ColorCluster> clusters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Detailed Analysis:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: clusters.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cluster = clusters[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cluster.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    ColorUtils.toHexString(cluster.color).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.getContrastingTextColor(cluster.color),
                    ),
                  ),
                  subtitle: Text(
                    '${cluster.pixelCount} pixels (${cluster.percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: ColorUtils.getContrastingTextColor(cluster.color)
                          .withOpacity(0.9),
                    ),
                  ),
                  tileColor: cluster.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              // Image selector

              _buildImageSelector(),
              const SizedBox(height: 20),

              // Selected image
              if (_selectedImage != null) _buildSelectedImage(),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ),

              // Color palette
              if (_dominantColors != null) ...[
                _buildColorPalette(_dominantColors!),
                const SizedBox(height: 20),
              ],

              // Detailed clusters
              if (_detailedClusters != null) ...[
                _buildDetailedClusters(_detailedClusters!),
                const SizedBox(height: 20),
              ],

              // Empty state
              if (_selectedImage == null &&
                  !_isLoading &&
                  _errorMessage == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.color_lens_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Select an image to extract colors',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
